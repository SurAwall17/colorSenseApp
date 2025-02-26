import 'package:flutter/material.dart';
import 'detection.dart';
import 'palette.dart';
import 'profile.dart';
import 'login_screen.dart'; // Impor halaman login
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Cek apakah pengguna sudah login atau belum
    if (user != null) {
      // Jika sudah login, tampilkan HomeScreen dengan userId
      return HomeScreen(userId: user.uid);
    } else {
      // Jika belum login, tampilkan LoginScreen
      return LoginScreen();
    }
  }
}

class HomeScreen extends StatefulWidget {
  final String userId; // Menambahkan userId

  HomeScreen({required this.userId}); // Menerima userId sebagai parameter

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _auth = FirebaseAuth.instance;
  String? _email;

  @override
  void initState() {
    super.initState();
    _email = _auth.currentUser?.email; // Mendapatkan email pengguna
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              LoginScreen()), // Navigasi kembali ke LoginScreen
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Logout"),
          content: Text("Apakah Anda yakin ingin logout?"),
          actions: [
            TextButton(
              child: Text("Batal"),
              onPressed: () {
                Navigator.of(context).pop(false); // Tutup dialog tanpa logout
              },
            ),
            TextButton(
              child: Text("Logout"),
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Tutup dialog dan konfirmasi logout
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout(); // Panggil fungsi logout jika dikonfirmasi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ColorSense",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 252, 92, 101),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
            onPressed: _confirmLogout, // Panggil fungsi konfirmasi logout
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Color(0xFFfc5c65),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: "Detection",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: "Palette",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan halaman sesuai tab
  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner Image
              Container(
                height: MediaQuery.of(context).size.height * 0.33,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/banner1.png'), // Ganti dengan path gambar banner Anda
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Ucapan selamat datang
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _email != null
                      ? 'Selamat datang, $_email!'
                      : 'Selamat datang!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      case 1:
        return DetectionScreen();
      case 2:
        return PaletteScreen();
      case 3:
        return ProfileScreen();
      default:
        return Container(); // Mengembalikan widget kosong jika tidak ada tab yang cocok
    }
  }
}
