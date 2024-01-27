import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickImageExample extends StatefulWidget {
  const PickImageExample({Key? key}) : super(key: key);

  @override
  State<PickImageExample> createState() => _PickImageExampleState();
}

class _PickImageExampleState extends State<PickImageExample> {
  bool isImageSelected = false;
  File? imageFile;

  _pickImagefromGallery() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          imageFile = File(pickedImage.path);
          isImageSelected = true;
        });
      } else {
        print('User didnt pick any image.');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 59, 59, 59),
      appBar: AppBar(
        title: const Text('Image Picker Example'),
      ),
      body: Center(
        child: Column(
          children: [
            MaterialButton(
                color: Colors.blue,
                child: const Text("Pick Image from Gallery",
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _pickImagefromGallery();
                }),
            MaterialButton(
                color: Colors.blue,
                child: const Text("Pick Image from Camera",
                    style: TextStyle(color: Colors.white)),
                onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
