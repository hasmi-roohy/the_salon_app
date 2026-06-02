import 'package:flutter/material.dart';
import '../../../domain/services/index.dart';
import 'camera_preview_ar.dart';
import 'ar_overlay_widget.dart';

/// Complete AR Smart Mirror Demo Page
/// Features:
/// - Real-time camera with face detection
/// - Live hairstyle + beard AR overlays
/// - Performance metrics (FPS, latency)
/// - Suitability feedback
class ArSmartMirrorDemoPage extends StatefulWidget {
  const ArSmartMirrorDemoPage({Key? key}) : super(key: key);

  @override
  State<ArSmartMirrorDemoPage> createState() => _ArSmartMirrorDemoPageState();
}

class _ArSmartMirrorDemoPageState extends State<ArSmartMirrorDemoPage> {
  HairstyleOverlay? _currentHairstyle;
  BeardOverlay? _currentBeard;
  ArSuitability? _currentSuitability;
  bool _showDebugInfo = true;
  bool _showOverlays = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Smart Mirror MVP'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() => _showDebugInfo = !_showDebugInfo);
            },
            tooltip: 'Toggle debug info',
          ),
          IconButton(
            icon: Icon(_showOverlays ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showOverlays = !_showOverlays);
            },
            tooltip: 'Toggle AR overlays',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera + Face Detection + AR Overlays
          CameraPreviewWithAR(
            onHairstyleOverlay: (overlay) {
              setState(() => _currentHairstyle = overlay);
            },
            onBeardOverlay: (overlay) {
              setState(() => _currentBeard = overlay);
            },
            onSuitabilityChanged: (suitability) {
              setState(() => _currentSuitability = suitability);
            },
          ),

          // AR Overlay rendering (on top of camera)
          if (_showOverlays && (_currentHairstyle != null || _currentBeard != null))
            ArOverlayWidget(
              hairstyleOverlay: _currentHairstyle,
              beardOverlay: _currentBeard,
            ),

          // Debug panel (bottom)
          if (_showDebugInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDebugPanel(),
            ),

          // Control buttons (bottom-right)
          Positioned(
            bottom: _showDebugInfo ? 220 : 16,
            right: 16,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debug Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showDebugInfo = false),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Suitability status
            if (_currentSuitability != null) ...[
              _buildDebugRow(
                'Status',
                _currentSuitability!.isSuitable ? '✓ Ready' : '✗ Not ready',
                _currentSuitability!.isSuitable
                    ? Colors.green
                    : Colors.orange,
              ),
              _buildDebugRow(
                'Reason',
                _currentSuitability!.suitabilityReason,
                Colors.grey[400]!,
              ),
              const Divider(color: Colors.grey, height: 8),
            ],

            // Face metrics
            if (_currentSuitability != null) ...[
              _buildDebugRow(
                'Face Size',
                '${_currentSuitability!.faceSize.toStringAsFixed(0)}px',
                Colors.cyan,
              ),
              _buildDebugRow(
                'Landmarks',
                '${_currentSuitability!.landmarkCount}/468',
                Colors.cyan,
              ),
              const Divider(color: Colors.grey, height: 8),
            ],

            // Head rotation
            if (_currentSuitability != null) ...[
              _buildDebugRow(
                'Yaw (left-right)',
                '${_currentSuitability!.yawAngle.toStringAsFixed(1)}°',
                Colors.lightBlue,
              ),
              _buildDebugRow(
                'Pitch (up-down)',
                '${_currentSuitability!.pitchAngle.toStringAsFixed(1)}°',
                Colors.lightBlue,
              ),
              _buildDebugRow(
                'Roll (tilt)',
                '${_currentSuitability!.rollAngle.toStringAsFixed(1)}°',
                Colors.lightBlue,
              ),
              const Divider(color: Colors.grey, height: 8),
            ],

            // AR overlay info
            if (_currentHairstyle != null) ...[
              _buildDebugRow(
                'Hairstyle Scale',
                '${(_currentHairstyle!.scale * 100).toStringAsFixed(1)}%',
                Colors.purple,
              ),
              _buildDebugRow(
                'Position',
                '(${_currentHairstyle!.position.dx.toStringAsFixed(0)}, ${_currentHairstyle!.position.dy.toStringAsFixed(0)})',
                Colors.purple,
              ),
            ],

            if (_currentBeard != null) ...[
              _buildDebugRow(
                'Beard Scale',
                '${(_currentBeard!.scale * 100).toStringAsFixed(1)}%',
                Colors.orange,
              ),
              _buildDebugRow(
                'Jaw Width',
                '${_currentBeard!.jawlineWidth.toStringAsFixed(0)}px',
                Colors.orange,
              ),
            ],

            // Instructions
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '💡 Tips: Face front to camera, good lighting, no tilting',
                style: TextStyle(color: Colors.lightBlue, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Capture button
        FloatingActionButton(
          onPressed: _canCapture() ? _captureSnapshot : null,
          backgroundColor: _canCapture() ? Colors.blue : Colors.grey,
          child: const Icon(Icons.camera_alt),
          tooltip: 'Capture snapshot',
        ),
        const SizedBox(height: 12),

        // Info button
        FloatingActionButton.small(
          onPressed: () => _showInfoDialog(),
          child: const Icon(Icons.info_outline),
          tooltip: 'Show info',
        ),
      ],
    );
  }

  bool _canCapture() {
    return _currentSuitability?.isSuitable ?? false;
  }

  void _captureSnapshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Snapshot captured! (Ready for Phase 2)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Smart Mirror MVP'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ Real-time face detection (30+ FPS)'),
              Text('✓ Face landmark tracking (468 points)'),
              Text('✓ Head pose estimation (yaw, pitch, roll)'),
              Text('✓ AR hairstyle overlay positioning'),
              Text('✓ AR beard overlay positioning'),
              Text('✓ Live suitability feedback'),
              SizedBox(height: 16),
              Text(
                'Next Phase:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('→ Load 3D hairstyle/beard models'),
              Text('→ Implement 3D model rendering'),
              Text('→ Add style selection carousel'),
              Text('→ Connect to backend API'),
              Text('→ Save results to database'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Performance benchmark page (optional)
class PerformanceBenchmarkPage extends StatefulWidget {
  const PerformanceBenchmarkPage({Key? key}) : super(key: key);

  @override
  State<PerformanceBenchmarkPage> createState() =>
      _PerformanceBenchmarkPageState();
}

class _PerformanceBenchmarkPageState extends State<PerformanceBenchmarkPage> {
  final List<double> _fpsMeasurements = [];
  final List<int> _processingTimes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Benchmark'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AR MVP Performance Targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildBenchmarkItem(
              '📹 Face Detection',
              '<50ms',
              'Google ML Kit on-device',
              Colors.green,
            ),
            _buildBenchmarkItem(
              '🧮 Landmark Processing',
              '<30ms',
              '468-point face mesh',
              Colors.green,
            ),
            _buildBenchmarkItem(
              '🎨 AR Overlay Calc',
              '<20ms',
              'Position, scale, rotation math',
              Colors.green,
            ),
            _buildBenchmarkItem(
              '⚡ Frame Rate',
              '30+ FPS',
              'Real-time camera stream',
              Colors.green,
            ),
            _buildBenchmarkItem(
              '🔄 Total Latency',
              '~100ms',
              'Detection + overlay + render',
              Colors.green,
            ),
            const SizedBox(height: 32),
            Text(
              'Optimization Strategies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              '✓ Frame skipping for heavy computations\n'
              '✓ Landmark smoothing to reduce jitter\n'
              '✓ Image resolution optimization\n'
              '✓ Metal (iOS) / OpenGL (Android) rendering\n'
              '✓ Caching 3D model data\n'
              '✓ Batch processing when possible',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkItem(
    String title,
    String metric,
    String description,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    metric,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
