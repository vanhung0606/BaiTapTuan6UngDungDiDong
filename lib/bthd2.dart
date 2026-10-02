import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PhotoCaptureApp());
}

class PhotoCaptureApp extends StatelessWidget {
  const PhotoCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Capture & Preview',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const PhotoCaptureHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PhotoCaptureHome extends StatefulWidget {
  const PhotoCaptureHome({super.key});

  @override
  State<PhotoCaptureHome> createState() => _PhotoCaptureHomeState();
}

class _PhotoCaptureHomeState extends State<PhotoCaptureHome> {
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  // Chọn ảnh từ Gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  // Chụp ảnh từ Camera
  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (capturedFile != null) {
        setState(() {
          _imageFile = File(capturedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Lỗi camera: $e');
    }
  }

  // Xem ảnh toàn màn hình
  void _showFullScreenPreview(BuildContext context) {
    if (_imageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImage(
            imageFile: _imageFile!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Capture & Preview'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile == null
                ? const Text(
                    'Chưa có ảnh nào được chọn.',
                  )
                : GestureDetector(
                    onTap: () => _showFullScreenPreview(context),
                    child: Image.file(
                      _imageFile!,
                      height: 300,
                    ),
                  ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: const Text('Chọn ảnh từ Gallery'),
            ),

            ElevatedButton(
              onPressed: _captureImageFromCamera,
              child: const Text('Chụp ảnh từ Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget xem trước toàn màn hình
class FullScreenImage extends StatelessWidget {
  final File imageFile;

  const FullScreenImage({
    super.key,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem trước'),
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}