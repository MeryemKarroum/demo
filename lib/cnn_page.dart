import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class CnnPage extends StatefulWidget {
  const CnnPage({Key? key}) : super(key: key);

  @override
  _CnnPageState createState() => _CnnPageState();
}

class _CnnPageState extends State<CnnPage> {
  String _result = '';
  bool _isLoading = false;
  Uint8List? _imageBytes;

  Future<Map<String, dynamic>> classifyImage(Uint8List imageBytes) async {
    var uri = Uri.parse('http://127.0.0.1:8000/classify/fruit');
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
        setState(() {
          _isLoading = true;
          _imageBytes = imageBytes;
          _result = '';
        });

        try {
          var result = await classifyImage(imageBytes);
          setState(() {
            _result = 'Class: ${result['class']}, Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%';
          });
        } catch (e) {
          setState(() {
            _result = 'Error: $e';
          });
        } finally {
          setState(() {
            _isLoading = false;
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
        title: const Text('CNN - Fruit Classification'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : getImage,
                child: const Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              if (_imageBytes != null) ...[
                Text(
                  'Uploaded Image',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, // Take up available width
                  height: 250, // Limit the height of the image
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain, // Maintain aspect ratio and fit the container
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _result.isNotEmpty ? _result : 'Awaiting Classification...',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
