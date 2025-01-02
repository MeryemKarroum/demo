import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class AnnPage extends StatefulWidget {
  const AnnPage({Key? key}) : super(key: key);

  @override
  _AnnPageState createState() => _AnnPageState();
}

class _AnnPageState extends State<AnnPage> {
  String _result = '';
  Uint8List? _imageBytes;
  String? _imagePath;

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
      setState(() {
        _result = 'Processing...';
      });

      if (result.files.single.bytes != null) {
        // Web platform
        setState(() {
          _imageBytes = result.files.single.bytes;
          _imagePath = null;
        });
      } else if (result.files.single.path != null) {
        // Mobile platform
        setState(() {
          _imagePath = result.files.single.path;
          _imageBytes = null;
        });
      }

      try {
        Uint8List imageBytes;
        if (_imageBytes != null) {
          imageBytes = _imageBytes!;
        } else if (_imagePath != null) {
          imageBytes = await File(_imagePath!).readAsBytes();
        } else {
          throw Exception('No image data available');
        }

        var classificationResult = await classifyImage(imageBytes);
        setState(() {
          _result = 'Class: ${classificationResult['class']}, Confidence: ${(classificationResult['confidence'] * 100).toStringAsFixed(2)}%';
        });
      } catch (e) {
        setState(() {
          _result = 'Error: $e';
        });
      }
    } else {
      setState(() {
        _result = 'No file selected';
        _imageBytes = null;
        _imagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANN - Fashion Classification'),
      ),
      body: SingleChildScrollView(
        child: Center(
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
                if (_imageBytes != null || _imagePath != null)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Classification Result:',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _result,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


  