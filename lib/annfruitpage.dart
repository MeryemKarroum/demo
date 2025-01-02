import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnnFruitPage extends StatefulWidget {
  const AnnFruitPage({Key? key}) : super(key: key);

  @override
  _AnnFruitPageState createState() => _AnnFruitPageState();
}

class _AnnFruitPageState extends State<AnnFruitPage> {
  String _result = 'Please upload an image to classify.';
  Uint8List? _imageBytes;

  Future<void> classifyFruit(Uint8List imageBytes) async {
    var uri = Uri.parse('http://127.0.0.1:8000/classify/fruit/ann');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      setState(() {
        _result = 'Class: ${result['class']}, Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%';
      });
    } else {
      setState(() {
        _result = 'Error: Unable to classify the image.';
      });
    }
  }

  Future<void> getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _result = 'Image uploaded. Classifying...';
      });
      if (_imageBytes != null) {
        classifyFruit(_imageBytes!);
      }
    } else {
      setState(() {
        _result = 'No file selected';
        _imageBytes = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANN Fruit Classification'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: getImage,
                child: const Text('Upload Image'),
              ),
              const SizedBox(height: 20),
              if (_imageBytes != null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


