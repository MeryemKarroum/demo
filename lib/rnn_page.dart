import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RnnPage extends StatefulWidget {
  const RnnPage({Key? key}) : super(key: key);

  @override
  _RnnPageState createState() => _RnnPageState();
}

class _RnnPageState extends State<RnnPage> {
  String _result = '';

  Future<Map<String, dynamic>> predictRnn(List<int> fileBytes) async {
    var uri = Uri.parse('http://127.0.0.1:8000/predict/rnn');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: 'data.csv'));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);
      return result;
    } else {
      throw Exception('Failed to predict with RNN');
    }
  }

  Future<void> getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      List<int>? fileBytes = result.files.single.bytes;

      if (fileBytes != null) {
        try {
          var result = await predictRnn(fileBytes);
          setState(() {
            _result = 'Predicted Value: ${result['predicted_value'].toStringAsFixed(2)}';
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
        title: const Text('RNN - Time Series Prediction'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getFile,
              child: const Text('Upload CSV File'),
            ),
            const SizedBox(height: 20),
            Text(
              'Prediction Result: $_result',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

