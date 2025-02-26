import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class KMeansScreen extends StatefulWidget {
  const KMeansScreen({Key? key}) : super(key: key);

  @override
  _KMeansScreenState createState() => _KMeansScreenState();
}

class _KMeansScreenState extends State<KMeansScreen> {
  File? _image;
  Map<String, dynamic>? _colorPercentages;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _analyzeColors();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _analyzeColors() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://surawal.pythonanywhere.com/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      final response = await request.send();
      final responseString = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final colorData = json.decode(responseString.body);
        await _saveToFirebase(_image!, colorData);

        setState(() {
          _colorPercentages = colorData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error analyzing colors: $e');
    }
  }

  Future<void> _saveToFirebase(
      File imageFile, Map<String, dynamic> colorData) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final localPath =
          '${directory.path}/color_analysis_images/${currentUser.uid}';
      final localDirectory = Directory(localPath);

      if (!localDirectory.existsSync()) {
        await localDirectory.create(recursive: true);
      }

      final imageName = '${DateTime.now().toIso8601String()}.jpg';
      final savedImage = await imageFile.copy('$localPath/$imageName');
      final localImagePath = savedImage.path;

      await FirebaseFirestore.instance.collection('hasil_deteksi').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'imagePath': localImagePath,
        'colorPercentages': colorData,
        'analyzedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully saved to local storage and Firestore');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copied to clipboard: $text")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("K-Means Detection"),
        centerTitle: true,
        backgroundColor: const Color(0xFFfc5c65),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Image picker buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfc5c65),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                    ),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfc5c65),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_image == null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text("No image selected"),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_image!),
                ),
              ],
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFfc5c65)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_colorPercentages != null && !_isLoading) ...[
                const Text(
                  "Hasil Deteksi:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._colorPercentages!.entries.map((entry) {
                  final color = Color(
                      int.parse(entry.key.substring(1, 7), radix: 16) +
                          0xFF000000);
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => _copyToClipboard(entry.key),
                        child: Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                            width: 150,
                            decoration: BoxDecoration(
                              color: color, // Warna latar belakang
                              borderRadius: BorderRadius.circular(
                                  2), // Membuat sudut sedikit melengkung
                              border: Border.all(
                                color: Colors.black, // Warna garis pinggir
                                width: 2, // Ketebalan garis pinggir
                              ),
                            ),
                            child: Center(
                              child: Stack(
                                children: [
                                  // Teks dengan garis pinggir (hitam)
                                  Text(
                                    '${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth =
                                            3 // Ketebalan garis pinggir
                                        ..color =
                                            Colors.black, // Warna garis pinggir
                                    ),
                                  ),
                                  // Teks utama (putih)
                                  Text(
                                    '${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Warna utama teks
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ),

                      // Text(
                      //   "Detected Color: ${entry.key}, Percentage: ${(entry.value * 100).toStringAsFixed(1)}%",
                      //   style: const TextStyle(fontSize: 14),
                      // ),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: _buildPieChart(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildBarChart() {
  //   return BarChart(
  //     BarChartData(
  //       barGroups: _colorPercentages!.entries.map((entry) {
  //         final color = Color(
  //             int.parse(entry.key.substring(1, 7), radix: 16) + 0xFF000000);
  //         final double percentage = entry.value * 100;

  //         return BarChartGroupData(
  //           x: _colorPercentages!.keys.toList().indexOf(entry.key),
  //           barRods: [
  //             BarChartRodData(
  //               toY: percentage, // Nilai persentase
  //               color: color,
  //               width: 20, // Lebar batang
  //               borderRadius: BorderRadius.circular(4),
  //               // Menambahkan label persentase di atas batang
  //               backDrawRodData: BackgroundBarChartRodData(
  //                 show: true,
  //                 toY: 100, // Background batang sampai 100%
  //                 color: Colors.grey.withOpacity(0.2),
  //               ),
  //             ),
  //           ],
  //           showingTooltipIndicators: [0], // Tooltip untuk setiap batang
  //         );
  //       }).toList(),
  //       titlesData: FlTitlesData(
  //         leftTitles: AxisTitles(
  //           sideTitles: SideTitles(
  //             showTitles: true,
  //             reservedSize: 40,
  //             getTitlesWidget: (value, meta) {
  //               return Text('${value.toInt()}%',
  //                   style: TextStyle(fontSize: 12));
  //             },
  //           ),
  //         ),
  //         bottomTitles: AxisTitles(
  //           sideTitles: SideTitles(
  //             showTitles: true,
  //             getTitlesWidget: (double value, TitleMeta meta) {
  //               int index = value.toInt();
  //               if (index >= 0 && index < _colorPercentages!.keys.length) {
  //                 return Text(
  //                   _colorPercentages!.keys.elementAt(index),
  //                   style: const TextStyle(fontSize: 10),
  //                 );
  //               }
  //               return Container();
  //             },
  //             reservedSize: 60,
  //           ),
  //         ),
  //       ),
  //       barTouchData: BarTouchData(
  //         enabled: true,
  //         touchTooltipData: BarTouchTooltipData(
  //           tooltipPadding: const EdgeInsets.all(8), // Padding tooltip
  //           tooltipMargin: 8, // Margin dari batang
  //           tooltipBorder: BorderSide(color: Colors.white), // Border tooltip
  //           getTooltipItem: (group, groupIndex, rod, rodIndex) {
  //             return BarTooltipItem(
  //               '${rod.toY.toStringAsFixed(2)}%', // Menampilkan persentase dengan 2 desimal
  //               const TextStyle(color: Colors.white, fontSize: 14),
  //             );
  //           },
  //         ),
  //       ),

  //       borderData: FlBorderData(show: false),
  //       gridData: FlGridData(show: true), // Menampilkan grid garis bantu
  //     ),
  //   );
  // }
  Widget _buildPieChart() {
    final List<PieChartSectionData> pieChartData =
        _colorPercentages!.entries.map((entry) {
      final color =
          Color(int.parse(entry.key.substring(1, 7), radix: 16) + 0xFF000000);
      return PieChartSectionData(
        color: color,
        value: entry.value * 100,
        // title: '${(entry.value * 100).toStringAsFixed(1)}%',
        title: '',
        radius: 50,
        borderSide: BorderSide(
          color: Colors.black, // Warna garis pinggir
          width: 2, // Ketebalan garis pinggir
        ),
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartData,
        borderData: FlBorderData(show: false),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
//metode deteksi menggunakan palette_generator
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:palette_generator/palette_generator.dart';

// class KMeansScreen extends StatefulWidget {
//   const KMeansScreen({Key? key}) : super(key: key);

//   @override
//   _KMeansScreenState createState() => _KMeansScreenState();
// }

// class _KMeansScreenState extends State<KMeansScreen> {
//   File? _image;
//   Map<String, dynamic>? _colorPercentages;
//   bool _isLoading = false;
//   final ImagePicker _picker = ImagePicker();

//   String _colorToHex(Color color) {
//     return '#${color.value.toRadixString(16).substring(2)}';
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(source: source);
//       if (pickedFile != null) {
//         setState(() {
//           _image = File(pickedFile.path);
//         });
//         if (source == ImageSource.camera) {
//           await _analyzePalette();
//         } else {
//           await _analyzeColors();
//         }
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }

//   Future<void> _analyzePalette() async {
//     if (_image == null) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final imageProvider = FileImage(_image!);
//       final PaletteGenerator paletteGenerator =
//           await PaletteGenerator.fromImageProvider(
//         imageProvider,
//         maximumColorCount: 5, // Adjust this number for more or fewer colors
//       );

//       Map<String, dynamic> colorData = {};
//       int totalPopulation = 0;

//       // Get all palette colors with their populations
//       List<PaletteColor> paletteColors = [];

//       // Add dominant and other significant colors
//       if (paletteGenerator.dominantColor != null) {
//         paletteColors.add(paletteGenerator.dominantColor!);
//       }
//       paletteColors.addAll(paletteGenerator.paletteColors);

//       // Calculate total population
//       for (var paletteColor in paletteColors) {
//         totalPopulation += paletteColor.population;
//       }

//       // Convert colors to percentages
//       for (var paletteColor in paletteColors) {
//         String hexColor = _colorToHex(paletteColor.color);
//         double percentage = totalPopulation > 0
//             ? paletteColor.population / totalPopulation
//             : 0.0;
//         colorData[hexColor] = percentage;
//       }

//       await _saveToFirebase(_image!, colorData);

//       setState(() {
//         _colorPercentages = colorData;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('Error analyzing palette: $e');
//     }
//   }

//   // Keep the existing _analyzeColors() method for gallery images
//   Future<void> _analyzeColors() async {
//     if (_image == null) return;

//     setState(() {
//       _isLoading = true;
//     });

//     final request = http.MultipartRequest(
//       'POST',
//       Uri.parse('http://192.168.1.5:5000/analyze'),
//     );
//     request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

//     try {
//       final response = await request.send();
//       final responseString = await http.Response.fromStream(response);

//       if (response.statusCode == 200) {
//         final colorData = json.decode(responseString.body);
//         await _saveToFirebase(_image!, colorData);

//         setState(() {
//           _colorPercentages = colorData;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         print('Error: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('Error analyzing colors: $e');
//     }
//   }

//   Future<void> _saveToFirebase(
//       File imageFile, Map<String, dynamic> colorData) async {
//     try {
//       User? currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         print('No user logged in');
//         return;
//       }

//       final directory = await getApplicationDocumentsDirectory();
//       final localPath =
//           '${directory.path}/color_analysis_images/${currentUser.uid}';
//       final localDirectory = Directory(localPath);

//       if (!localDirectory.existsSync()) {
//         await localDirectory.create(recursive: true);
//       }

//       final imageName = '${DateTime.now().toIso8601String()}.jpg';
//       final savedImage = await imageFile.copy('$localPath/$imageName');
//       final localImagePath = savedImage.path;

//       await FirebaseFirestore.instance.collection('hasil_deteksi').add({
//         'userId': currentUser.uid,
//         'userEmail': currentUser.email,
//         'imagePath': localImagePath,
//         'colorPercentages': colorData,
//         'analyzedAt': FieldValue.serverTimestamp(),
//       });

//       print('Successfully saved to local storage and Firestore');
//     } catch (e) {
//       print('Error saving to local storage: $e');
//     }
//   }

//   void _copyToClipboard(String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Copied to clipboard: $text")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("K-Means Detection"),
//         centerTitle: true,
//         backgroundColor: const Color(0xFFfc5c65),
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () => _pickImage(ImageSource.camera),
//                     icon: const Icon(
//                       Icons.camera_alt,
//                       color: Colors.white,
//                     ),
//                     label: const Text('Camera'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFfc5c65),
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () => _pickImage(ImageSource.gallery),
//                     icon: const Icon(
//                       Icons.photo_library,
//                       color: Colors.white,
//                     ),
//                     label: const Text('Gallery'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFfc5c65),
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               if (_image == null) ...[
//                 Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Center(
//                     child: Text("No image selected"),
//                   ),
//                 ),
//               ] else ...[
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: Image.file(_image!),
//                 ),
//               ],
//               const SizedBox(height: 20),
//               if (_isLoading) ...[
//                 const Center(
//                   child: CircularProgressIndicator(
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Color(0xFFfc5c65)),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//               if (_colorPercentages != null && !_isLoading) ...[
//                 const Text(
//                   "Hasil Deteksi:",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 ..._colorPercentages!.entries.map((entry) {
//                   final color = Color(
//                       int.parse(entry.key.substring(1, 7), radix: 16) +
//                           0xFF000000);
//                   return Column(
//                     children: [
//                       GestureDetector(
//                         onTap: () => _copyToClipboard(entry.key),
//                         child: Container(
//                           padding: const EdgeInsets.all(8.0),
//                           margin: const EdgeInsets.symmetric(vertical: 5.0),
//                           decoration: BoxDecoration(
//                             color: color,
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                           child: Text(
//                             '${entry.key} - ${(entry.value * 100).toStringAsFixed(1)}%',
//                             style: const TextStyle(
//                                 color: Colors.white, fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   height: 300,
//                   child: _buildPieChart(),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPieChart() {
//     final List<PieChartSectionData> pieChartData =
//         _colorPercentages!.entries.map((entry) {
//       final color =
//           Color(int.parse(entry.key.substring(1, 7), radix: 16) + 0xFF000000);
//       return PieChartSectionData(
//         color: color,
//         value: entry.value * 100,
//         title: '${(entry.value * 100).toStringAsFixed(1)}%',
//         radius: 50,
//         titleStyle: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       );
//     }).toList();

//     return PieChart(
//       PieChartData(
//         sections: pieChartData,
//         borderData: FlBorderData(show: false),
//         centerSpaceRadius: 40,
//         sectionsSpace: 2,
//       ),
//     );
//   }
// }
}
