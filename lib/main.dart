import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(SmartTVControlApp());
}

class SmartTVControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart TV Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TVRemoteControl(),
    );
  }
}

class TVRemoteControl extends StatefulWidget {
  @override
  _TVRemoteControlState createState() => _TVRemoteControlState();
}

class _TVRemoteControlState extends State<TVRemoteControl> {
  String? tvIpAddress;
  final int port = 8001; // Replace with the correct port if needed

  @override
  void initState() {
    super.initState();
    discoverTV();
  }

  void discoverTV() async {
    final ssdpMessage = '''
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 1
ST: urn:samsung.com:service:MultiScreenService:1
''';

    final rawDatagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    rawDatagramSocket.broadcastEnabled = true;
    rawDatagramSocket.send(utf8.encode(ssdpMessage), InternetAddress('239.255.255.250'), 1900);

    rawDatagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = rawDatagramSocket.receive();
        if (datagram != null) {
          final response = utf8.decode(datagram.data);
          if (response.contains('LOCATION')) {
            final regex = RegExp(r'LOCATION:\s*(.*)', caseSensitive: false);
            final match = regex.firstMatch(response);
            if (match != null) {
              final location = match.group(1)?.trim();
              final uri = Uri.parse(location!);
              setState(() {
                tvIpAddress = uri.host;
              });
              print("TV found at: $tvIpAddress");
              rawDatagramSocket.close();
            }
          }
        }
      }
    });

    await Future.delayed(Duration(seconds: 5));
    if (tvIpAddress == null) {
      print("TV not found");
      rawDatagramSocket.close();
    }
  }

  Future<void> sendCommand(String command) async {
    if (tvIpAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TV not found')),
      );
      return;
    }

    final url = 'http://$tvIpAddress:$port/api/$command';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'command': command,
      }),
    );

    if (response.statusCode == 200) {
      print('Command sent successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command sent: $command')),
      );
    } else {
      print('Failed to send command');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send command: $command')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart TV Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('power_on') : null,
              child: Text('Power On'),
            ),
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('power_off') : null,
              child: Text('Power Off'),
            ),
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('volume_up') : null,
              child: Text('Volume Up'),
            ),
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('volume_down') : null,
              child: Text('Volume Down'),
            ),
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('mute') : null,
              child: Text('Mute'),
            ),
            ElevatedButton(
              onPressed: tvIpAddress != null ? () => sendCommand('change_channel') : null,
              child: Text('Change Channel'),
            ),
            if (tvIpAddress == null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Searching for TV...'),
              ),
            if (tvIpAddress != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('TV found at $tvIpAddress'),
              ),
          ],
        ),
      ),
    );
  }
}
