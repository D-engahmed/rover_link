import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class PersonSighting {
  final bool present;
  final double bearingFrac;
  final double sizeFrac;
  final bool facingCamera;
  final double headYawDeg;

  const PersonSighting({
    required this.present,
    this.bearingFrac = 0,
    this.sizeFrac = 0,
    this.facingCamera = false,
    this.headYawDeg = 0,
  });

  static const none = PersonSighting(present: false);
}

/// Phone-camera perception for the follow/door workflow.
///
/// ML Kit is fed only formats it supports for the target platform:
/// NV21 on Android and BGRA8888 on iOS. The old implementation concatenated
/// arbitrary camera planes, which could silently produce invalid ML Kit input.
class VisionService {
  CameraController? _controller;
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableTracking: false,
    ),
  );
  final _sightingCtrl = StreamController<PersonSighting>.broadcast();
  bool _busy = false;
  bool _starting = false;

  Stream<PersonSighting> get sightings => _sightingCtrl.stream;
  CameraController? get controller => _controller;

  Future<void> start() async {
    if (_starting || (_controller?.value.isInitialized ?? false)) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No cameras available on this device.');
      }

      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final imageFormat = Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888;

      final controller = CameraController(
        cam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormat,
      );

      _controller = controller;
      await controller.initialize();
      await controller.startImageStream(_onFrame);
    } finally {
      _starting = false;
    }
  }

  void _onFrame(CameraImage image) {
    if (_busy || _controller == null) return;
    _busy = true;
    _processFrame(image).whenComplete(() => _busy = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final inputImage = _toInputImage(image, controller.description);
      if (inputImage == null) return;

      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) {
        _sightingCtrl.add(PersonSighting.none);
        return;
      }

      faces.sort(
        (a, b) => b.boundingBox.height.compareTo(a.boundingBox.height),
      );
      final face = faces.first;
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      if (imageWidth <= 0 || imageHeight <= 0) return;

      final centerX = face.boundingBox.left + face.boundingBox.width / 2;
      final bearing = (((centerX / imageWidth) - 0.5) * 2)
          .clamp(-1.0, 1.0)
          .toDouble();
      final size = (face.boundingBox.height / imageHeight)
          .clamp(0.0, 1.0)
          .toDouble();
      final yaw = face.headEulerAngleY ?? 0.0;

      _sightingCtrl.add(PersonSighting(
        present: true,
        bearingFrac: bearing,
        sizeFrac: size,
        facingCamera: yaw.abs() < 20,
        headYawDeg: yaw,
      ));
    } catch (_) {
      // Drop a bad frame. Perception must remain alive for the next frame.
    }
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraDescription description,
  ) {
    try {
      if (Platform.isAndroid) {
        // CameraX may report yuv420 while the payload is configured as NV21.
        // ML Kit accepts the NV21 payload as a single plane in this mode.
        if (image.planes.length != 1) return null;
        final format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format != InputImageFormat.nv21) return null;
        final plane = image.planes.first;
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _androidRotation(description.sensorOrientation),
            format: InputImageFormat.nv21,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }

      if (Platform.isIOS) {
        if (image.planes.length != 1) return null;
        final format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format != InputImageFormat.bgra8888) return null;
        final plane = image.planes.first;
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }
    } catch (_) {
      // Unsupported platform/format: perception simply stays inactive.
    }
    return null;
  }

  InputImageRotation _androidRotation(int sensorOrientation) {
    return InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    _busy = false;
    if (controller == null) return;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Camera may already have stopped due to lifecycle/permission changes.
    }
    await controller.dispose();
  }

  void dispose() {
    unawaited(stop());
    _detector.close();
    _sightingCtrl.close();
  }
}
