import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RekomendasiWarnaScreen extends StatefulWidget {
  final String userId;

  RekomendasiWarnaScreen({required this.userId});

  @override
  _RekomendasiWarnaScreenState createState() => _RekomendasiWarnaScreenState();
}

class _RekomendasiWarnaScreenState extends State<RekomendasiWarnaScreen> {
  String? selectedMood;
  String? selectedTema;
  String? selectedSuasana;
  String? selectedKontras;
  List<dynamic> recommendedColors = [];

  final TextEditingController paletteNameController = TextEditingController();

  final List<String> moodOptions = [
    'Energik',
    'Tenang',
    'Ceria',
    'Romantis',
    'Serius'
  ];

  final List<String> temaOptions = [
    'Modern',
    'Natural',
    'Vintage',
    'Minimalis',
  ];

  final List<String> suasanaOptions = ['Hangat', 'Dingin', 'Terang', 'Redup'];

  final List<String> kontrasOptions = ['Tinggi', 'Sedang', 'Rendah'];

  @override
  void dispose() {
    paletteNameController.dispose();
    super.dispose();
  }

  Future<void> fetchRekomendasiWarna() async {
    if (paletteNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon masukkan nama palet terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('https://surawal.pythonanywhere.com/rekomendasi');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mood': selectedMood,
        'tema': selectedTema,
        'suasana': selectedSuasana,
        'kontras': selectedKontras,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        recommendedColors = jsonDecode(response.body);
      });
    } else {
      print('Failed to fetch recommendations');
    }
  }

  Future<void> savePaletteToDatabase() async {
    if (paletteNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon masukkan nama palet terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('rekomendasi_warna').add({
      'user_id': widget.userId,
      'palette_name': paletteNameController.text,
      'mood': selectedMood,
      'tema': selectedTema,
      'suasana': selectedSuasana,
      'kontras': selectedKontras,
      'warna': recommendedColors,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Palet berhasil disimpan!'),
        backgroundColor: Colors.green,
      ),
    );

    print("Data rekomendasi warna telah disimpan di Firebase!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rekomendasi Warna", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFfc5c65),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama Palet", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: paletteNameController,
                decoration: InputDecoration(
                  hintText: "Masukkan nama palet",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: 16),
              buildDropdown("Mood", moodOptions, selectedMood, (value) {
                setState(() => selectedMood = value);
              }),
              buildDropdown("Tema", temaOptions, selectedTema, (value) {
                setState(() => selectedTema = value);
              }),
              buildDropdown("Suasana", suasanaOptions, selectedSuasana,
                  (value) {
                setState(() => selectedSuasana = value);
              }),
              buildDropdown("Kontras", kontrasOptions, selectedKontras,
                  (value) {
                setState(() => selectedKontras = value);
              }),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fetchRekomendasiWarna,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text("Dapatkan Rekomendasi Warna"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFfc5c65),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (recommendedColors.isNotEmpty) ...[
                Text("Rekomendasi Warna:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1 / 1.2,
                  ),
                  itemCount: recommendedColors.length,
                  itemBuilder: (context, index) {
                    final color = recommendedColors[index];
                    return GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                                ClipboardData(text: color['Kode Warna']))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Kode warna ${color['Kode Warna']} tersalin ke clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                      color['Kode Warna'].substring(1),
                                      radix: 16) +
                                  0xFF000000),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(color['Nama Warna'],
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center),
                          Text(color['Kode Warna'],
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: savePaletteToDatabase,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text("Save as Palette"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> options,
      String? selectedValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          onChanged: onChanged,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
