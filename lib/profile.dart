import 'dart:io';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, '${user!.uid}_profile.jpg');
  }

  Future<void> _loadProfileImage() async {
    try {
      if (user != null) {
        final imagePath = await _localPath;
        final imageFile = File(imagePath);

        if (await imageFile.exists()) {
          setState(() {
            _profileImage = imageFile;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get path for new image
      final String imagePath = await _localPath;

      // Delete existing file if it exists
      final existingFile = File(imagePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Copy new image to app directory
      final File newImage = await File(image.path).copy(imagePath);

      // Verify the file was created successfully
      if (await newImage.exists()) {
        // Update state
        setState(() {
          _profileImage = newImage;
        });

        // Close loading indicator
        if (context.mounted) {
          Navigator.pop(context);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile picture updated successfully')),
          );
        }
      } else {
        throw Exception('Failed to save image file');
      }
    } catch (e) {
      print('Error updating profile picture: $e');

      // Close loading indicator if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changePassword(BuildContext context) {
    final TextEditingController emailController =
        TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: emailController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Password reset link has been sent to your email.'),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and User Info
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xFFfc5c65),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFfc5c65),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _changeProfilePicture,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                user?.email ?? 'Email Not Available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Settings Section
            const Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              leading: const Icon(Icons.lock, color: Color(0xFFfc5c65)),
              title: const Text("Change Password"),
              onTap: () => _changePassword(context),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              leading: const Icon(Icons.exit_to_app, color: Color(0xFFfc5c65)),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
