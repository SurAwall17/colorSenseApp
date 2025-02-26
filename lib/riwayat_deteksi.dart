import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class DetectionHistoryScreen extends StatelessWidget {
  // Function to parse color from hex string
  Color _parseColor(String hexColor) {
    try {
      // Remove '#' if present
      hexColor = hexColor.replaceAll('#', '');
      // Add FF for opacity if 6 digits
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Return a default color if parsing fails
      return Colors.grey;
    }
  }

  // Function to delete detection record
  Future<void> _deleteDetection(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('hasil_deteksi')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Riwayat deteksi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus riwayat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Riwayat Deteksi'),
        ),
        body: Center(
          child: Text(
            'Silakan login untuk melihat riwayat deteksi.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Deteksi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hasil_deteksi')
            .where('userId', isEqualTo: currentUser.uid)
            // .orderBy('analyzedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Tidak ada riwayat deteksi untuk akun ini.'),
            );
          }

          final detectionData = snapshot.data!.docs;

          return ListView.builder(
            itemCount: detectionData.length,
            itemBuilder: (context, index) {
              final doc = detectionData[index];
              final data = doc.data() as Map<String, dynamic>;
              final imagePath = data['imagePath'] as String?;
              final colorPercentages =
                  data['colorPercentages'] as Map<String, dynamic>;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    color: Colors.red,
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Konfirmasi'),
                          content: Text(
                              'Apakah Anda yakin ingin menghapus riwayat deteksi ini?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Hapus'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteDetection(context, doc.id);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                image: imagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(imagePath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imagePath == null
                                  ? Icon(Icons.image_not_supported, size: 40)
                                  : null,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(
                                    (data['analyzedAt'] as Timestamp).toDate(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var entry in colorPercentages.entries)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                      text: entry.key),
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Kode warna ${entry.key} telah disalin!',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                margin:
                                                    EdgeInsets.only(right: 12),
                                                decoration: BoxDecoration(
                                                  color: _parseColor(entry.key),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: Colors.black12),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Konfirmasi'),
                                    content: Text(
                                        'Apakah Anda yakin ingin menghapus riwayat deteksi ini?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text('Hapus'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                _deleteDetection(context, doc.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
