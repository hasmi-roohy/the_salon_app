import 'package:flutter/material.dart';
import '../../domain/services/ar_overlay_renderer.dart';

/// Widget to render AR overlays (hairstyles, beards) on camera feed
class ArOverlayWidget extends StatelessWidget {
  final HairstyleOverlay? hairstyleOverlay;
  final BeardOverlay? beardOverlay;
  final List<NailOverlay>? nailOverlays;
  final String? hairstyleModelPath;
  final String? beardModelPath;
  final List<String>? nailDesignPaths;

  const ArOverlayWidget({
    Key? key,
    this.hairstyleOverlay,
    this.beardOverlay,
    this.nailOverlays,
    this.hairstyleModelPath,
    this.beardModelPath,
    this.nailDesignPaths,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hairstyle overlay
        if (hairstyleOverlay != null)
          _buildHairstyleOverlay(context, hairstyleOverlay!),

        // Beard overlay
        if (beardOverlay != null)
          _buildBeardOverlay(context, beardOverlay!),

        // Nail overlays
        if (nailOverlays != null)
          ...nailOverlays!
              .asMap()
              .entries
              .map((entry) => _buildNailOverlay(context, entry.value, entry.key)),
      ],
    );
  }

  Widget _buildHairstyleOverlay(BuildContext context, HairstyleOverlay overlay) {
    return Transform.translate(
      offset: overlay.position - Offset(50 * overlay.scale, 60 * overlay.scale),
      child: Transform.rotate(
        angle: overlay.rotationZ * 3.14159 / 180,
        child: Transform.scale(
          scale: overlay.scale,
          child: Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.person_outline,
                color: Colors.purple,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeardOverlay(BuildContext context, BeardOverlay overlay) {
    return Transform.translate(
      offset: overlay.position - Offset(overlay.jawlineWidth / 4, 20),
      child: Transform.rotate(
        angle: overlay.rotationZ * 3.14159 / 180,
        child: Container(
          width: overlay.jawlineWidth / 2,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.brown, width: 1.5),
          ),
          child: Center(
            child: Text(
              '█ █ █',
              style: TextStyle(
                color: Colors.brown.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNailOverlay(
    BuildContext context,
    NailOverlay overlay,
    int nailIndex,
  ) {
    final nailColors = [
      Colors.red,
      Colors.pink,
      Colors.red.shade400,
      Colors.pink.shade300,
      Colors.red.shade600,
    ];

    return Transform.translate(
      offset: overlay.position - Offset(20 * overlay.scale, 20 * overlay.scale),
      child: Transform.rotate(
        angle: overlay.rotationZ * 3.14159 / 180,
        child: Transform.scale(
          scale: overlay.scale * 100,
          child: Container(
            width: 40,
            height: 50,
            decoration: BoxDecoration(
              color: nailColors[nailIndex % nailColors.length],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// High-performance 3D model renderer for AR overlays
/// This uses Canvas for 2D projection of 3D geometry
class ModelRenderer extends CustomPainter {
  final List<Vector3> vertices;
  final List<Face> faces;
  final Matrix4 viewMatrix;
  final Offset position;
  final double scale;

  ModelRenderer({
    required this.vertices,
    required this.faces,
    required this.viewMatrix,
    required this.position,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Project 3D vertices to 2D screen coordinates
    final projectedVertices = <Offset>[];
    for (final vertex in vertices) {
      final projected = _project3DTo2D(vertex, position, scale);
      projectedVertices.add(projected);
    }

    // Draw faces
    for (final face in faces) {
      if (face.vertices.length < 3) continue;

      final points = <Offset>[];
      for (final vertexIndex in face.vertices) {
        if (vertexIndex < projectedVertices.length) {
          points.add(projectedVertices[vertexIndex]);
        }
      }

      if (points.isNotEmpty) {
        canvas.drawPath(
          _createPath(points),
          paint,
        );
        canvas.drawPath(
          _createPath(points),
          strokePaint,
        );
      }
    }
  }

  Offset _project3DTo2D(Vector3 vertex, Offset screenCenter, double scale) {
    // Simple perspective projection
    final projected = Offset(
      screenCenter.dx + vertex.x * scale,
      screenCenter.dy + vertex.y * scale,
    );
    return projected;
  }

  Path _createPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(ModelRenderer oldDelegate) {
    return oldDelegate.position != position || oldDelegate.scale != scale;
  }
}

/// 3D Vector for model rendering
class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3({required this.x, required this.y, required this.z});

  Vector3 operator +(Vector3 other) =>
      Vector3(x: x + other.x, y: y + other.y, z: z + other.z);

  Vector3 operator *(double scalar) =>
      Vector3(x: x * scalar, y: y * scalar, z: z * scalar);

  double distance(Vector3 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return (dx * dx + dy * dy + dz * dz).sqrt();
  }
}

/// 3D Face/Polygon definition
class Face {
  final List<int> vertices; // Indices into vertex list
  final Color? color;

  Face({required this.vertices, this.color});
}

/// Simple OBJ model loader (placeholder)
class ModelLoader {
  static Future<({List<Vector3> vertices, List<Face> faces})> loadObj(
    String assetPath,
  ) async {
    // TODO: Implement actual OBJ loading
    // For now, return a simple cube
    return (
      vertices: [
        Vector3(x: -1, y: -1, z: -1),
        Vector3(x: 1, y: -1, z: -1),
        Vector3(x: 1, y: 1, z: -1),
        Vector3(x: -1, y: 1, z: -1),
        Vector3(x: -1, y: -1, z: 1),
        Vector3(x: 1, y: -1, z: 1),
        Vector3(x: 1, y: 1, z: 1),
        Vector3(x: -1, y: 1, z: 1),
      ],
      faces: [
        Face(vertices: [0, 1, 2, 3]),
        Face(vertices: [4, 5, 6, 7]),
        Face(vertices: [0, 1, 5, 4]),
        Face(vertices: [2, 3, 7, 6]),
        Face(vertices: [0, 3, 7, 4]),
        Face(vertices: [1, 2, 6, 5]),
      ],
    );
  }
}
