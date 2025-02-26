// program ini untuk menampilkan gambar dari lokal storage, dan data lainnya ditampilkan dari firebase

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detect/realtime.dart';
import 'riwayat_deteksi.dart';
import 'detect/k_means.dart';

class DetectionScreen extends StatefulWidget {
  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  late List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      final availableCams = await availableCameras();
      if (mounted) {
        setState(() {
          cameras = availableCams;
        });
      }
    } catch (e) {
      print('Error fetching cameras: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tombol Deteksi Realtime
            _buildStyledButton(
              context,
              label: "Realtime",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ColorDetectorApp(camera: cameras.first)),
                );
              },
              icon: Icons.camera_alt,
              buttonColor: Colors.blueAccent,
            ),

            SizedBox(height: 20),
            // Tombol K-Means (via Kamera)
            _buildStyledButton(
              context,
              label: "K-Means",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KMeansScreen()),
                );
              },
              icon: Icons.camera,
              buttonColor: Colors.green,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetectionHistoryScreen()),
          );
        },
        child: Icon(Icons.history),
        backgroundColor: Color(0xFFfc5c65),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Fungsi untuk membangun tombol dengan styling (sama seperti sebelumnya)
  Widget _buildStyledButton(BuildContext context,
      {required String label,
      required VoidCallback onPressed,
      required IconData icon,
      required Color buttonColor}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
        label: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 10,
        ),
      ),
    );
  }
}
