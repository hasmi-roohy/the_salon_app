import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/services/ar_overlay_renderer.dart';
import '../../domain/services/face_detection_service.dart';

enum TryOnCategory { hairstyle, beard, nailArt }

class TryOnStyle {
  final String id;
  final String name;
  final TryOnCategory category;
  final String assetPath;
  final Color? tint;
  final double size;
  final double widthFactor;
  final double heightFactor;
  final double verticalOffsetFactor;

  const TryOnStyle({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.tint,
    this.size = 1,
    this.widthFactor = 1,
    this.heightFactor = 1,
    this.verticalOffsetFactor = 0,
  });
}

class AiSmartMirrorWorkspace extends StatefulWidget {
  const AiSmartMirrorWorkspace({super.key});

  @override
  State<AiSmartMirrorWorkspace> createState() => _AiSmartMirrorWorkspaceState();
}

class _AiSmartMirrorWorkspaceState extends State<AiSmartMirrorWorkspace> {
  static const _styles = [
    TryOnStyle(
      id: 'textured-black',
      name: 'Textured black',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/textured-black.png',
      size: 1.08,
    ),
    TryOnStyle(
      id: 'textured-brown',
      name: 'Warm brown quiff',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/warm-brown-quiff.png',
      size: 1.12,
    ),
    TryOnStyle(
      id: 'textured-burgundy',
      name: 'Burgundy crop',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/burgundy-crop.png',
      size: 1.1,
    ),
    TryOnStyle(
      id: 'slick-back',
      name: 'Slick back',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/slick-back.png',
      size: 1.12,
    ),
    TryOnStyle(
      id: 'curly-fade',
      name: 'Curly fade',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/curly-fade.png',
      size: 1.12,
    ),
    TryOnStyle(
      id: 'classic-side-part',
      name: 'Classic side part',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/classic-side-part.png',
      size: 1.12,
    ),
    TryOnStyle(
      id: 'long-layered',
      name: 'Long butterfly',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/long-layered.png',
      widthFactor: 1.12,
      heightFactor: 3.2,
      verticalOffsetFactor: 1.05,
    ),
    TryOnStyle(
      id: 'layered-lob',
      name: 'Layered lob',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/layered-lob.png',
      widthFactor: 1.08,
      heightFactor: 2.25,
      verticalOffsetFactor: 0.62,
    ),
    TryOnStyle(
      id: 'long-curly',
      name: 'Long curls',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/long-curly.png',
      widthFactor: 1.18,
      heightFactor: 3.15,
      verticalOffsetFactor: 1.02,
    ),
    TryOnStyle(
      id: 'sleek-bob',
      name: 'Sleek bob',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/sleek-bob.png',
      widthFactor: 1.05,
      heightFactor: 2.15,
      verticalOffsetFactor: 0.58,
    ),
    TryOnStyle(
      id: 'box-braids',
      name: 'Box braids',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/box-braids.png',
      widthFactor: 1.08,
      heightFactor: 3.35,
      verticalOffsetFactor: 1.12,
    ),
    TryOnStyle(
      id: 'high-ponytail',
      name: 'High ponytail',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/high-ponytail.png',
      widthFactor: 1.18,
      heightFactor: 3.1,
      verticalOffsetFactor: 0.72,
    ),
    TryOnStyle(
      id: 'full-beard-black',
      name: 'Full beard',
      category: TryOnCategory.beard,
      assetPath: 'assets/tryon/beard/full-beard.png',
    ),
    TryOnStyle(
      id: 'full-beard-brown',
      name: 'Brown beard',
      category: TryOnCategory.beard,
      assetPath: 'assets/tryon/beard/full-beard.png',
      tint: Color(0xff69402e),
    ),
    TryOnStyle(
      id: 'burgundy-gold',
      name: 'Burgundy gold',
      category: TryOnCategory.nailArt,
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
    ),
    TryOnStyle(
      id: 'rose-gold',
      name: 'Rose gold',
      category: TryOnCategory.nailArt,
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
      tint: Color(0xffc87878),
    ),
  ];

  final _picker = ImagePicker();
  final _detector = FaceDetectionService();
  final _renderer = ArOverlayRenderer();
  final _prompt = TextEditingController();
  final _resultKey = GlobalKey();

  Uint8List? _photo;
  Size? _photoSize;
  Face? _face;
  TryOnCategory _category = TryOnCategory.hairstyle;
  TryOnStyle _style = _styles.first;
  Offset _adjustment = Offset.zero;
  Offset _startAdjustment = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _scale = 1;
  double _startScale = 1;
  double _rotation = 0;
  double _startRotation = 0;
  bool _working = false;
  String _status = 'Upload a photo, then tap a style model below.';

  @override
  void dispose() {
    _detector.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final selected = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 1600,
    );
    if (selected == null) return;
    setState(() {
      _working = true;
      _status = 'Preparing your photo...';
    });
    final selectedCategory = _category;

    try {
      final bytes = await selected.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('Could not read this photo.');
      final faces = selectedCategory == TryOnCategory.nailArt
          ? <Face>[]
          : await _detector.detectFaces(InputImage.fromFilePath(selected.path));
      final face = faces.isEmpty
          ? null
          : faces.reduce(
              (a, b) =>
                  a.boundingBox.width * a.boundingBox.height >
                      b.boundingBox.width * b.boundingBox.height
                  ? a
                  : b,
            );
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _face = face;
        _resetTransform();
        _status = selectedCategory == TryOnCategory.nailArt
            ? 'Hand photo ready. Drag and resize the nail model over your fingertips.'
            : face == null
            ? 'No face found. Nail models still work; use a clearer portrait for hair or beard.'
            : 'Photo ready. Tap any model to convert the preview.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _status =
              'Could not process this photo. Try a clear, upright photo with the face visible.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _selectCategory(TryOnCategory category) {
    setState(() {
      _category = category;
      _style = _styles.firstWhere((style) => style.category == category);
      _resetTransform();
      _status = category == TryOnCategory.nailArt
          ? _photo == null
                ? 'Upload a top-down hand photo with fingers slightly spread.'
                : 'Drag and resize the nail model over your fingertips.'
          : _photo == null
          ? 'Upload a clear, upright portrait, then tap a style model.'
          : 'Tap a model below to update the converted preview.';
    });
  }

  void _selectStyle(TryOnStyle style) {
    setState(() {
      _style = style;
      _resetTransform();
      _status = _photo == null
          ? 'Now upload a photo to try ${style.name}.'
          : '${style.name} applied automatically.';
    });
  }

  void _applyPrompt() {
    final prompt = _prompt.text.trim().toLowerCase();
    if (prompt.isEmpty) {
      setState(() => _status = 'Describe the style you want first.');
      return;
    }
    final category = prompt.contains('beard') || prompt.contains('moustache')
        ? TryOnCategory.beard
        : prompt.contains('nail')
        ? TryOnCategory.nailArt
        : TryOnCategory.hairstyle;
    final candidates = _styles.where((style) => style.category == category);
    final match = candidates.firstWhere(
      (style) => style.name.toLowerCase().split(' ').any(prompt.contains),
      orElse: () => candidates.first,
    );
    setState(() {
      _category = category;
      _style = match;
      _resetTransform();
      _status = '${match.name} selected from your prompt.';
    });
  }

  void _resetTransform() {
    _adjustment = Offset.zero;
    _scale = 1;
    _rotation = 0;
  }

  Future<Uint8List> _captureResult() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _resultKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('The try-on result is not ready.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Could not create the result image.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _saveResult() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Saving result to your gallery...';
    });
    try {
      final bytes = await _captureResult();
      await Gal.putImageBytes(
        bytes,
        name: 'salon_tryon_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        setState(() => _status = 'Result saved to your gallery.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Could not save the result. Check photo access.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _shareResult() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Preparing result to share...';
    });
    try {
      final bytes = await _captureResult();
      final fileName =
          'salon_tryon_${DateTime.now().millisecondsSinceEpoch}.png';
      final resultBox =
          _resultKey.currentContext?.findRenderObject() as RenderBox?;
      final shareOrigin = resultBox == null
          ? null
          : resultBox.localToGlobal(Offset.zero) & resultBox.size;
      await SharePlus.instance.share(
        ShareParams(
          text: 'My virtual try-on result from The Salon App',
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: [fileName],
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (mounted) {
        setState(() => _status = 'Result ready to share.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not share the result.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = _styles
        .where((style) => style.category == _category)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xfff7f3f0),
      appBar: AppBar(title: const Text('AI Virtual Try-On')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Upload your photo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text('Then tap a model to instantly preview the style.'),
            const SizedBox(height: 14),
            RepaintBoundary(
              key: _resultKey,
              child: _ResultPreview(
                photo: _photo,
                photoSize: _photoSize,
                face: _face,
                category: _category,
                style: _style,
                renderer: _renderer,
                adjustment: _adjustment,
                scale: _scale,
                rotation: _rotation,
                onGestureStart: (details) {
                  _startAdjustment = _adjustment;
                  _startFocalPoint = details.focalPoint;
                  _startScale = _scale;
                  _startRotation = _rotation;
                },
                onGestureUpdate: (details) => setState(() {
                  _adjustment =
                      _startAdjustment + details.focalPoint - _startFocalPoint;
                  _scale = (_startScale * details.scale).clamp(0.3, 3);
                  _rotation = _startRotation + details.rotation;
                }),
                onChoosePhoto: () => _pickPhoto(ImageSource.gallery),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _working
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload photo'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _working
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Take photo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _photo == null || _working ? null : _saveResult,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Save result'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _photo == null || _working ? null : _shareResult,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_working)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(child: Text(_status)),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Choose a model',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            SegmentedButton<TryOnCategory>(
              segments: const [
                ButtonSegment(
                  value: TryOnCategory.hairstyle,
                  label: Text('Hair'),
                ),
                ButtonSegment(value: TryOnCategory.beard, label: Text('Beard')),
                ButtonSegment(
                  value: TryOnCategory.nailArt,
                  label: Text('Nails'),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (value) => _selectCategory(value.first),
            ),
            if (_category == TryOnCategory.nailArt) ...[
              const SizedBox(height: 12),
              _NailPhotoGuide(
                onReset: () => setState(() {
                  _resetTransform();
                  _status =
                      'Nail position reset. Drag it onto your fingertips.';
                }),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: models.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final model = models[index];
                  return _ModelCard(
                    style: model,
                    selected: _style.id == model.id,
                    onTap: () => _selectStyle(model),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _prompt,
              onSubmitted: (_) => _applyPrompt(),
              decoration: InputDecoration(
                labelText: 'Describe the style you want',
                hintText: 'Example: warm brown haircut',
                suffixIcon: IconButton(
                  onPressed: _applyPrompt,
                  icon: const Icon(Icons.auto_awesome),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: drag, pinch, or rotate the applied model for a better fit.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final TryOnStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _ModelCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffdfe8ff) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xff245ca8) : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _StyleImage(style: style)),
            const SizedBox(height: 5),
            Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NailPhotoGuide extends StatelessWidget {
  final VoidCallback onReset;

  const _NailPhotoGuide({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfffff4df),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.back_hand_outlined, size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'For nails: place one hand flat on a plain surface, point '
                'fingertips upward, spread fingers slightly, and photograph '
                'straight from above. Let the hand fill most of the photo.',
              ),
            ),
            IconButton(
              onPressed: onReset,
              tooltip: 'Reset nail position',
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  final Uint8List? photo;
  final Size? photoSize;
  final Face? face;
  final TryOnCategory category;
  final TryOnStyle style;
  final ArOverlayRenderer renderer;
  final Offset adjustment;
  final double scale;
  final double rotation;
  final ValueChanged<ScaleStartDetails> onGestureStart;
  final ValueChanged<ScaleUpdateDetails> onGestureUpdate;
  final VoidCallback onChoosePhoto;

  const _ResultPreview({
    required this.photo,
    required this.photoSize,
    required this.face,
    required this.category,
    required this.style,
    required this.renderer,
    required this.adjustment,
    required this.scale,
    required this.rotation,
    required this.onGestureStart,
    required this.onGestureUpdate,
    required this.onChoosePhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (photo == null || photoSize == null) {
      return Card(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Center(
            child: FilledButton.tonalIcon(
              onPressed: onChoosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Upload photo'),
            ),
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: photoSize!.width / photoSize!.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final placement = _placement(constraints.biggest);
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(photo!, fit: BoxFit.fill),
                if (placement != null)
                  Positioned(
                    left: placement.center.dx - placement.width / 2,
                    top: placement.center.dy - placement.height / 2,
                    width: placement.width,
                    height: placement.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onScaleStart: onGestureStart,
                      onScaleUpdate: onGestureUpdate,
                      child: Padding(
                        padding: category == TryOnCategory.nailArt
                            ? const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 18,
                              )
                            : EdgeInsets.zero,
                        child: Transform.rotate(
                          angle: placement.rotation,
                          child: _StyleImage(style: style),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Chip(label: Text('Result: ${style.name}')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _Placement? _placement(Size viewSize) {
    final imageScale = viewSize.width / photoSize!.width;
    if (category == TryOnCategory.nailArt) {
      return _Placement(
        center:
            Offset(viewSize.width * 0.47, viewSize.height * 0.42) + adjustment,
        width: viewSize.width * 0.5 * scale * style.size,
        height: viewSize.height * 0.13 * scale * style.size,
        rotation: rotation,
      );
    }
    if (face == null) return null;
    if (category == TryOnCategory.beard) {
      final overlay = renderer.calculateBeardOverlay(face!);
      return _Placement(
        center: overlay.center * imageScale + adjustment,
        width: overlay.width * imageScale * scale * style.size,
        height: overlay.height * imageScale * scale * style.size,
        rotation: -overlay.rotation + rotation,
      );
    }
    final overlay = renderer.calculateHairstyleOverlay(face!);
    return _Placement(
      center:
          overlay.center * imageScale +
          Offset(0, overlay.height * imageScale * style.verticalOffsetFactor) +
          adjustment,
      width:
          overlay.width * imageScale * scale * style.size * style.widthFactor,
      height:
          overlay.height * imageScale * scale * style.size * style.heightFactor,
      rotation: -overlay.rotation + rotation,
    );
  }
}

class _StyleImage extends StatelessWidget {
  final TryOnStyle style;

  const _StyleImage({required this.style});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(style.assetPath, fit: BoxFit.contain);
    final tint = style.tint;
    if (tint == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: image,
    );
  }
}

class _Placement {
  final Offset center;
  final double width;
  final double height;
  final double rotation;

  const _Placement({
    required this.center,
    required this.width,
    required this.height,
    required this.rotation,
  });
}
