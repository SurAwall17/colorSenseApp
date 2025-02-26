import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detect/c_bf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PaletteScreen extends StatelessWidget {
  final CollectionReference paletteCollection =
      FirebaseFirestore.instance.collection('rekomendasi_warna');

  Color hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      print('Error parsing color: $hexString');
      return Colors.grey;
    }
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  void _copyColorToClipboard(
      BuildContext context, String colorCode, String colorName) {
    Clipboard.setData(ClipboardData(text: colorCode)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode warna $colorName ($colorCode) telah disalin'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _createNewPalette(BuildContext context, String userId) {
    final TextEditingController nameController = TextEditingController();
    List<Color> selectedColors = List.filled(5, Colors.grey);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Buat Palet Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nama Palet'),
                ),
                SizedBox(height: 16),
                ...List.generate(
                    5,
                    (index) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selectedColors[index],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  showAdvancedColorPicker(
                                      context, selectedColors[index], (color) {
                                    setState(() {
                                      selectedColors[index] = color;
                                    });
                                  });
                                },
                                child: Text('Pilih'),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mohon isi nama palet')),
                  );
                  return;
                }

                List<Map<String, String>> warnaList = List.generate(
                  5,
                  (index) => {
                    "Nama Warna": "Warna ${index + 1}",
                    "Kode Warna": colorToHex(selectedColors[index]),
                  },
                );

                paletteCollection.add({
                  'user_id': userId,
                  'palette_name': nameController.text,
                  'timestamp': Timestamp.now(),
                  'warna': warnaList,
                }).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Palet berhasil dibuat')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuat palet')),
                  );
                });
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void showAdvancedColorPicker(BuildContext context, Color currentColor,
      Function(Color) onColorSelected) {
    Color pickerColor = currentColor;
    TextEditingController hexController =
        TextEditingController(text: colorToHex(currentColor).substring(1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Pilih Warna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview warna yang dipilih
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: pickerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                SizedBox(height: 16),

                // Input kode warna
                TextField(
                  controller: hexController,
                  decoration: InputDecoration(
                    labelText: 'Kode Warna',
                    hintText: 'RRGGBB',
                    prefixText: '#',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    try {
                      if (value.length == 6) {
                        final color = hexToColor('#$value');
                        setState(() {
                          pickerColor = color;
                        });
                      }
                    } catch (e) {
                      print('Invalid color code');
                    }
                  },
                ),
                SizedBox(height: 16),

                // Color Picker
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) {
                    setState(() {
                      pickerColor = color;
                      hexController.text = colorToHex(color).substring(1);
                    });
                  },
                  pickerAreaHeightPercent: 0.8,
                  enableAlpha: false,
                  displayThumbColor: true,
                  showLabel: true,
                  paletteType: PaletteType.hsvWithHue,
                  hexInputBar: false, // Mematikan hex input bawaan
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.pop(context);
              },
              child: Text('Pilih'),
            ),
          ],
        ),
      ),
    );
  }

  void showColorPicker(BuildContext context, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Warna'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...Colors.primaries.map((color) => InkWell(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _editPaletteName(
      BuildContext context, String paletteId, String currentName) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Nama Palet'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Nama Baru Palet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              paletteCollection.doc(paletteId).update({
                'palette_name': nameController.text,
              }).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nama palet berhasil diubah')),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengubah nama palet')),
                );
              });
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deletePalette(BuildContext context, String paletteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Palet'),
        content: Text('Apakah Anda yakin ingin menghapus palet ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              paletteCollection.doc(paletteId).delete().then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Palet berhasil dihapus')),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus palet')),
                );
              });
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: userId == null
          ? Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<QuerySnapshot>(
              stream: paletteCollection
                  .where('user_id', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text('Belum ada data warna yang tersimpan'));
                }

                final palettes = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final List<dynamic> warnaList =
                      (data['warna'] ?? []) as List<dynamic>;

                  final colors = warnaList.map((warna) {
                    return {
                      "name": warna["Nama Warna"]?.toString() ?? "",
                      "color": warna["Kode Warna"]?.toString() ?? "#CCCCCC"
                    };
                  }).toList();

                  return {
                    "id": doc.id,
                    "name": data['palette_name'] ?? 'Nama Tidak Diketahui',
                    "timestamp": data['timestamp'] ?? Timestamp.now(),
                    "colors": colors
                  };
                }).toList();

                palettes.sort((a, b) => (b["timestamp"] as Timestamp)
                    .compareTo(a["timestamp"] as Timestamp));

                return ListView.builder(
                  itemCount: palettes.length,
                  itemBuilder: (context, index) {
                    final palette = palettes[index];
                    final colorsList = (palette["colors"] as List?) ?? [];

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    palette["name"] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editPaletteName(
                                        context,
                                        palette["id"] as String,
                                        palette["name"] as String,
                                      );
                                    } else if (value == 'delete') {
                                      _deletePalette(
                                        context,
                                        palette["id"] as String,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Ubah Nama'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20),
                                          SizedBox(width: 8),
                                          Text('Hapus'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: colorsList.map<Widget>((colorData) {
                                    final color = hexToColor(
                                        colorData["color"] as String);
                                    return Expanded(
                                      child: InkWell(
                                        onTap: () => _copyColorToClipboard(
                                          context,
                                          colorData["color"] as String,
                                          colorData["name"] as String,
                                        ),
                                        child: Container(
                                          color: color,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            onPressed: () {
              if (userId != null) {
                _createNewPalette(context, userId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Silakan login terlebih dahulu")),
                );
              }
            },
            child: Icon(Icons.palette),
            backgroundColor: Color(0xFFfc5c65),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RekomendasiWarnaScreen(userId: userId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Silakan login terlebih dahulu")),
                );
              }
            },
            child: Icon(Icons.add),
            backgroundColor: Color(0xFFfc5c65),
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
