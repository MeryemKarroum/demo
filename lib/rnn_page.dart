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
  bool _isLoading = false;
  List<List<String>> _csvData = [];

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
      var errorData = await response.stream.bytesToString();
      throw Exception('Failed to predict with RNN: $errorData');
    }
  }

  List<List<String>> parseCsv(String csvContent) {
    List<List<String>> result = [];
    List<String> rows = csvContent.split('\n');
    for (String row in rows) {
      if (row.trim().isNotEmpty) {
        List<String> cells = row.split(',').map((cell) => cell.trim()).toList();
        result.add(cells);
      }
    }
    return result;
  }

  Future<void> getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      List<int>? fileBytes = result.files.single.bytes;

      if (fileBytes != null) {
        String csvContent = utf8.decode(fileBytes);
        _csvData = parseCsv(csvContent);

        setState(() {
          _isLoading = true;
          _result = '';
        });

        try {
          var prediction = await predictRnn(fileBytes);
          setState(() {
            _result = 'Predicted Value: ${prediction['predicted_value']}';
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
        _csvData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RNN - Time Series Prediction'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : getFile,
                child: const Text('Upload CSV File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _result.isNotEmpty ? _result : 'Awaiting Prediction...',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 20),
              if (_csvData.isNotEmpty) ...[
                Text(
                  'CSV Data',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                CsvDataTable(data: _csvData),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CsvDataTable extends StatelessWidget {
  final List<List<String>> data;

  const CsvDataTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: data[0].map((header) => DataColumn(label: Text(header))).toList(),
          rows: data.skip(1).map((row) {
            return DataRow(
              cells: row.map((cell) => DataCell(Text(cell))).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

