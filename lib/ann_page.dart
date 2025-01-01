import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class AnnPage extends StatefulWidget {
  const AnnPage({Key? key}) : super(key: key);

  @override
  _AnnPageState createState() => _AnnPageState();
}

class _AnnPageState extends State<AnnPage> {
  String _result = '';

  Future<Map<String, dynamic>> classifyImage(Uint8List imageBytes) async {
    var uri = Uri.parse('http://127.0.0.1:8000/classify/fashion');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);
      return result;
    } else {
      throw Exception('Failed to classify image');
    }
  }

  Future<void> getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      Uint8List? imageBytes = result.files.single.bytes;

      if (imageBytes != null) {
        try {
          var result = await classifyImage(imageBytes);
          setState(() {
            _result = 'Class: ${result['class']}, Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%';
          });
        } catch (e) {
          setState(() {
            _result = 'Error: $e';
          });
        }
      }
    } else {
      setState(() {
        _result = 'No file selected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANN - Fashion Classification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 20),
            Text(
              'Classification Result: $_result',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
