import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class LedController extends StatefulWidget {
  @override
  _LedControllerState createState() => _LedControllerState();
}

class _LedControllerState extends State<LedController> {
  final String picoIp = "192.168.153.229"; // Replace with your Raspberry Pi Pico IP
  String status = "Unknown";

  Future<void> sendRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('http://$picoIp/$endpoint'));
      if (response.statusCode == 200) {
        setState(() {
          status = response.body;
        });
      } else {
        setState(() {
          status = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LED Controller'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LED Status: $status',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendRequest("lighton"),
              child: Text("Turn On LED"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => sendRequest("lightoff"),
              child: Text("Turn Off LED"),
            ),
          ],
        ),
      ),
    );
  }
}
