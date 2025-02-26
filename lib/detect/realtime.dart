import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: ColorDetectorApp(camera: cameras.first)));
}

class ColorDetectorApp extends StatefulWidget {
  final CameraDescription camera;

  const ColorDetectorApp({Key? key, required this.camera}) : super(key: key);

  @override
  _ColorDetectorAppState createState() => _ColorDetectorAppState();
}

class _ColorDetectorAppState extends State<ColorDetectorApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Color _detectedColor = Colors.black;
  String _colorName = "Unknown";
  String _hexValue = "#000000";
  Timer? _colorDetectionTimer;
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _controller.initialize();

      // Lock the orientation to portrait mode
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Set the camera orientation
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      // Set initial flash mode
      await _controller.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {});
        _startColorDetection();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    try {
      FlashMode newMode;
      switch (_currentFlashMode) {
        case FlashMode.off:
          newMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
        default:
          newMode = FlashMode.off;
      }

      await _controller.setFlashMode(newMode);
      setState(() {
        _currentFlashMode = newMode;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  void _startColorDetection() {
    _colorDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _detectColor();
    });
  }

  Future<void> _detectColor() async {
    if (!_controller.value.isInitialized) return;

    try {
      final image = await _controller.takePicture();
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Get the center pixel
        final centerX = decodedImage.width ~/ 2;
        final centerY = decodedImage.height ~/ 2;

        // Get the average color of a small area around the center
        final areaSize = 5; // 5x5 pixel area
        int totalR = 0, totalG = 0, totalB = 0;
        int count = 0;

        for (int x = centerX - areaSize; x <= centerX + areaSize; x++) {
          for (int y = centerY - areaSize; y <= centerY + areaSize; y++) {
            if (x >= 0 &&
                x < decodedImage.width &&
                y >= 0 &&
                y < decodedImage.height) {
              final pixel = decodedImage.getPixel(x, y);
              totalR += pixel.r.toInt();
              totalG += pixel.g.toInt();
              totalB += pixel.b.toInt();
              count++;
            }
          }
        }

        final r = (totalR / count).round();
        final g = (totalG / count).round();
        final b = (totalB / count).round();

        setState(() {
          _detectedColor = Color.fromRGBO(r, g, b, 1);
          _hexValue = '#${r.toRadixString(16).padLeft(2, '0')}'
                  '${g.toRadixString(16).padLeft(2, '0')}'
                  '${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();
          _colorName = _getColorName(r, g, b);
        });
      }
    } catch (e) {
      print('Error detecting color: $e');
    }
  }

  String _getColorName(int r, int g, int b) {
    // Calculate color distances to known colors
    final Map<String, Color> knownColors = {
      // Basic Colors
      'Red': Colors.red,
      'Dark Red': Colors.red[900]!,
      'Light Red': Colors.red[300]!,
      'Green': Colors.green,
      'Dark Green': Colors.green[900]!,
      'Light Green': Colors.green[300]!,
      'Blue': Colors.blue,
      'Dark Blue': Colors.blue[900]!,
      'Light Blue': Colors.blue[300]!,
      'Yellow': Colors.yellow,
      'Dark Yellow': Colors.yellow[900]!,
      'Light Yellow': Colors.yellow[300]!,
      'Purple': Colors.purple,
      'Dark Purple': Colors.purple[900]!,
      'Light Purple': Colors.purple[300]!,
      'Orange': Colors.orange,
      'Dark Orange': Colors.orange[900]!,
      'Light Orange': Colors.orange[300]!,
      'Pink': Colors.pink,
      'Dark Pink': Colors.pink[900]!,
      'Light Pink': Colors.pink[300]!,
      'Brown': Colors.brown,
      'Dark Brown': Colors.brown[900]!,
      'Light Brown': Colors.brown[300]!,

      // Grey Shades
      'Grey': Colors.grey,
      'Dark Grey': Colors.grey[800]!,
      'Medium Grey': Colors.grey[500]!,
      'Light Grey': Colors.grey[300]!,

      // Black & White
      'Black': Colors.black,
      'White': Colors.white,

      // Material Colors
      'Amber': Colors.amber,
      'Dark Amber': Colors.amber[900]!,
      'Light Amber': Colors.amber[300]!,
      'Teal': Colors.teal,
      'Dark Teal': Colors.teal[900]!,
      'Light Teal': Colors.teal[300]!,
      'Indigo': Colors.indigo,
      'Dark Indigo': Colors.indigo[900]!,
      'Light Indigo': Colors.indigo[300]!,
      'Cyan': Colors.cyan,
      'Dark Cyan': Colors.cyan[900]!,
      'Light Cyan': Colors.cyan[300]!,
      'Lime': Colors.lime,
      'Dark Lime': Colors.lime[900]!,
      'Light Lime': Colors.lime[300]!,

      // Additional Colors
      'Deep Purple': Colors.deepPurple,
      'Deep Orange': Colors.deepOrange,
      'Light Green': Colors.lightGreen,
      'Light Blue': Colors.lightBlue,
      'Blue Grey': Colors.blueGrey,

      // Custom Mixed Colors
      'Turquoise': Color(0xFF40E0D0),
      'Maroon': Color(0xFF800000),
      'Navy': Color(0xFF000080),
      'Olive': Color(0xFF808000),
      'Crimson': Color(0xFFDC143C),
      'Forest Green': Color(0xFF228B22),
      'Sky Blue': Color(0xFF87CEEB),
      'Coral': Color(0xFFFF7F50),
      'Magenta': Color(0xFFFF00FF),
      'Gold': Color(0xFFFFD700),
      'Lavender': Color(0xFFE6E6FA),
      'Salmon': Color(0xFFFA8072),
      'Khaki': Color(0xFFF0E68C),
      'Plum': Color(0xFFDDA0DD),
      'Tan': Color(0xFFD2B48C),
      'Orchid': Color(0xFFDA70D6),
      'Slate Blue': Color(0xFF6A5ACD),
      'Royal Blue': Color(0xFF4169E1),
      'Hot Pink': Color(0xFFFF69B4),
      'Sea Green': Color(0xFF2E8B57),
      'Chocolate': Color(0xFFD2691E),
      'Sienna': Color(0xFFA0522D),
      'Steel Blue': Color(0xFF4682B4),
      'Medium Purple': Color(0xFF9370DB),
      'Tomato': Color(0xFFFF6347),
      'Dark Slate Grey': Color(0xFF2F4F4F),
      'Medium Sea Green': Color(0xFF3CB371),
      'Dark Goldenrod': Color(0xFFB8860B),
      'Cadet Blue': Color(0xFF5F9EA0),
      'Indian Red': Color(0xFFCD5C5C),

      // Additional Specific Colors
      'Rose Gold': Color(0xFFB76E79),
      'Mint Green': Color(0xFF98FF98),
      'Powder Blue': Color(0xFFB0E0E6),
      'Burgundy': Color(0xFF800020),
      'Mauve': Color(0xFFE0B0FF),
      'Periwinkle': Color(0xFFCCCCFF),
      'Mustard': Color(0xFFFFDB58),
      'Rust': Color(0xFFB7410E),
      'Azure': Color(0xFF007FFF),
      'Charcoal': Color(0xFF364135),
      'Cream': Color(0xFFFFFDD0),
      'Peacock Blue': Color(0xFF326872),
      'Ruby': Color(0xFFE0115F),
      'Emerald': Color(0xFF50C878),
      'Sapphire': Color(0xFF082567),
      'Pearl': Color(0xFFEAE0C8),
      'Jade': Color(0xFF00A86B),
      'Rose': Color(0xFFFF007F),
      'Berry': Color(0xFF8B0045),
      'Sage': Color(0xFFBCB88A),
      'Copper': Color(0xFFB87333),
      'Bronze': Color(0xFFCD7F32),
      'Silver': Color(0xFFC0C0C0),
      'Platinum': Color(0xFFE5E4E2),

      // Pastel Colors
      'Pastel Pink': Color(0xFFFFD1DC),
      'Pastel Blue': Color(0xFFAEC6CF),
      'Pastel Green': Color(0xFF77DD77),
      'Pastel Yellow': Color(0xFFFFFF99),
      'Pastel Purple': Color(0xFFB39EB5),
      'Pastel Orange': Color(0xFFFFB347),

      // Neon Colors
      'Neon Pink': Color(0xFFFF6EC7),
      'Neon Green': Color(0xFF39FF14),
      'Neon Blue': Color(0xFF1F51FF),
      'Neon Yellow': Color(0xFFFFFF00),
      'Neon Orange': Color(0xFFFF9933),
      'Neon Purple': Color(0xFF9D00FF),

      // Earth Tones
      'Terracotta': Color(0xFFE2725B),
      'Clay': Color(0xFFCB6D51),
      'Sand': Color(0xFFF4A460),
      'Taupe': Color(0xFF483C32),
      'Moss': Color(0xFF8A9A5B),
      'Umber': Color(0xFF635147),

      // Metallic Colors
      'Metallic Gold': Color(0xFFD4AF37),
      'Metallic Silver': Color(0xFFBEC2CB),
      'Metallic Bronze': Color(0xFF614E1A),
      'Metallic Copper': Color(0xFFB87333),

      // Skin Tones
      'Fair': Color(0xFFFFDAB9),
      'Light': Color(0xFFE8BE9D),
      'Medium': Color(0xFFCE9F6F),
      'Tan': Color(0xFFD2B48C),
      'Deep': Color(0xFF8B4513),
      'Dark': Color(0xFF4A3728),

      // Wood Tones
      'Oak': Color(0xFFDEB887),
      'Mahogany': Color(0xFFC04000),
      'Walnut': Color(0xFF773F1A),
      'Pine': Color(0xFFCBA135),
      'Maple': Color(0xFFC86428),
      'Cherry': Color(0xFF600101),

      // Ocean Colors
      'Aquamarine': Color(0xFF7FFFD4),
      'Ocean Blue': Color(0xFF4F42B5),
      'Sea Foam': Color(0xFF98FF98),
      'Deep Sea': Color(0xFF123456),
      'Coral Blue': Color(0xFF5D8AA8),
      'Marine': Color(0xFF000C66)
    };

    String closestColor = "Unknown";
    double minDistance = double.infinity;

    knownColors.forEach((name, color) {
      double distance = _calculateColorDistance(
        r,
        g,
        b,
        color.red,
        color.green,
        color.blue,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColor = name;
      }
    });

    return closestColor;
  }

  double _calculateColorDistance(
    int r1,
    int g1,
    int b1,
    int r2,
    int g2,
    int b2,
  ) {
    return math.sqrt(
        math.pow(r1 - r2, 2) + math.pow(g1 - g2, 2) + math.pow(b1 - b2, 2));
  }

  void _copyHexValue() {
    Clipboard.setData(ClipboardData(text: _hexValue));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Color code $_hexValue copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _colorDetectionTimer?.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Detector'),
        actions: [
          IconButton(
            icon: Icon(
              _currentFlashMode == FlashMode.torch
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),
                      // Crosshair
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'R: ${_detectedColor.red} ',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                          Text(
                            'G: ${_detectedColor.green} ',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 16),
                          ),
                          Text(
                            'B: ${_detectedColor.blue}',
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Color: $_colorName',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _detectedColor,
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _copyHexValue,
                            child: Text(
                              _hexValue,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
