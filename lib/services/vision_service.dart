import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class PersonSighting {
  final bool present;
  final double bearingFrac; // -1 (far left) .. +1 (far right), 0 = centered
  final double sizeFrac; // face bbox height / image height — proxy for closeness
  final bool facingCamera;
  final double headYawDeg; // 0 = facing camera, larger = turned away
  const PersonSighting({
    required this.present,
    this.bearingFrac = 0,
    this.sizeFrac = 0,
    this.facingCamera = false,
    this.headYawDeg = 0,
  });
  static const none = PersonSighting(present: false);
}

/// Wraps the phone camera + Google ML Kit Face Detection to answer the two
/// questions RSSI and a magnetometer never could: which direction is the
/// person actually in, and are they facing the rover. This is what solves
/// the "stance" part of your door-trigger logic, using headEulerAngleY —
/// no separate pose model needed for v1.
///
/// NOT COMPILED OR RUN HERE — same disclaimer as real_bt_service.dart. This
/// sandbox can't install Flutter or camera/ML Kit native dependencies. The
/// camera-image-to-InputImage conversion in [_toInputImage] is the single
/// most version-sensitive part of this file (plane format, rotation,
/// byte layout differ across camera package versions) — if face detection
/// silently returns nothing once you run this, check that function first
/// against the current `camera` + `google_mlkit_face_detection` example
/// apps on pub.dev, since the conversion recipe does shift between
/// versions.
///
/// Also: camera + ML Kit need a real device. Most emulators either have no
/// camera or a fake feed that won't produce detectable faces.
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

  Stream<PersonSighting> get sightings => _sightingCtrl.stream;

  Future<void> start() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available on this device.');
    }
    // Back camera: the rover is "looking" for the person out in front of
    // it, same as the physical ultrasonic sensor's field of view.
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(cam, ResolutionPreset.low, enableAudio: false);
    await _controller!.initialize();
    await _controller!.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    if (_busy || _controller == null) return;
    _busy = true;
    _processFrame(image).whenComplete(() => _busy = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final inputImage = _toInputImage(image, _controller!.description);
      if (inputImage == null) return;
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) {
        _sightingCtrl.add(PersonSighting.none);
        return;
      }
      // Largest face in frame = nearest / most relevant person.
      faces.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
      final f = faces.first;
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      final cx = f.boundingBox.left + f.boundingBox.width / 2;
      final bearingFrac = (((cx / imgW) - 0.5) * 2).clamp(-1.0, 1.0);
      final sizeFrac = (f.boundingBox.height / imgH).clamp(0.0, 1.0);
      final yaw = f.headEulerAngleY ?? 0;
      _sightingCtrl.add(PersonSighting(
        present: true,
        bearingFrac: bearingFrac,
        sizeFrac: sizeFrac,
        facingCamera: yaw.abs() < 20,
        headYawDeg: yaw,
      ));
    } catch (_) {
      // Drop this frame; the next one will retry. A single bad frame
      // shouldn't kill the stream.
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription description) {
    try {
      final bytes = _concatenatePlanes(image.planes);
      final rotation =
          InputImageRotationValue.fromRawValue(description.sensorOrientation) ??
              InputImageRotation.rotation0deg;
      final format =
          InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = BytesBuilder();
    for (final plane in planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  Future<void> stop() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void dispose() {
    stop();
    _detector.close();
    _sightingCtrl.close();
  }
}
