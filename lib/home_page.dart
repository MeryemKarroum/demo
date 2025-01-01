import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';  // Import file_picker
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';  // Import to handle byte data
import 'ann_page.dart';
import 'rnn_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _extractName(String? email) {
    if (email == null || !email.contains('@')) return 'User';
    return email.split('@')[0];
  }

  String _result = '';

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
    // Use file_picker to pick files instead of image_picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      // Get the byte data of the selected image
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
    final user = FirebaseAuth.instance.currentUser;
    final userName = _extractName(user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      userName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('CNN - Fruit Classification'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Choose Image Source'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              getImage();
                              Navigator.pop(context);
                            },
                            child: const Text('Choose Image'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('ANN'),
              onTap: () {
               Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnnPage()),
              );
              },
            ),
            ListTile(
              leading: const Icon(Icons.loop),
              title: const Text('RNN'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement RNN functionality
                 Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RnnPage()),
              );
              },
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('LSTM'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement LSTM functionality
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality for a main feature of your app
              },
              child: const Text('Start Using App'),
            ),
            const SizedBox(height: 20),
            Text(
              'Classification Result: $_result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
