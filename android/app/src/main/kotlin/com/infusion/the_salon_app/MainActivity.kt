package com.infusion.the_salon_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handChannel = "the_salon_app/hand_landmarks"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, handChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "detectHandLandmarks" -> {
                        val path = call.argument<String>("imagePath")
                        if (path.isNullOrBlank()) {
                            result.error("missing_path", "imagePath is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(detectHandLandmarks(path))
                        } catch (error: Exception) {
                            result.error(
                                "hand_landmark_failed",
                                error.message ?: "Could not detect hand landmarks.",
                                null,
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun detectHandLandmarks(imagePath: String): List<Map<String, Double>> {
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Could not decode image.")
        val rotatedBitmap = rotateBitmapForExif(bitmap, imagePath)
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(
                BaseOptions.builder()
                    .setModelAssetPath("hand_landmarker.task")
                    .build(),
            )
            .setRunningMode(RunningMode.IMAGE)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.35f)
            .setMinHandPresenceConfidence(0.35f)
            .setMinTrackingConfidence(0.35f)
            .build()

        HandLandmarker.createFromOptions(this, options).use { landmarker ->
            val detection = landmarker.detect(mpImage)
            return firstHandLandmarks(detection)
        }
    }

    private fun firstHandLandmarks(result: HandLandmarkerResult): List<Map<String, Double>> {
        val hand = result.landmarks().firstOrNull() ?: return emptyList()
        return hand.map { landmark ->
            mapOf(
                "x" to landmark.x().toDouble(),
                "y" to landmark.y().toDouble(),
                "z" to landmark.z().toDouble(),
            )
        }
    }

    private fun rotateBitmapForExif(bitmap: Bitmap, imagePath: String): Bitmap {
        val rotation = when (ExifInterface(imagePath).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL,
        )) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        if (rotation == 0f) return bitmap
        val matrix = Matrix().apply { postRotate(rotation) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
}
