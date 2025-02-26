import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'register_screen.dart'; // Impor halaman RegisterScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>(); // Untuk validasi form

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (userCredential.user != null) {
          // Mendapatkan userId setelah login berhasil
          String userId = userCredential.user!.uid;

          // Redirect ke HomeScreen dengan membawa userId
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(userId: userId), // Meneruskan userId ke HomeScreen
            ),
          );
        }
      } catch (e) {
        // Menangani error login
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFfc5c65),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Menambahkan form key untuk validasi
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Color(0xFFfc5c65)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                          r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Input Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Color(0xFFfc5c65)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password should be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Tombol Login
              ElevatedButton(
                onPressed: _login,
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white, // Set the text color to white here
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFfc5c65),
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Tautan ke RegisterScreen jika belum punya akun
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Belum punya akun? ",
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Daftar di sini",
                        style: TextStyle(
                            color: Color(0xFFfc5c65),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
