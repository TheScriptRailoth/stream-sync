import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_sync/MainPage.dart';
import 'package:stream_sync/smartHomeTest.dart';

import 'SmartHomeControl.dart';
class Optionpage extends StatefulWidget {
  const Optionpage({super.key});

  @override
  State<Optionpage> createState() => _OptionpageState();
}

class _OptionpageState extends State<Optionpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: Color(0xff2C3E50),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10), // Adds spacing between buttons
              height: 60,
              width: 220,
              child: ElevatedButton(
                child: Row(
                  children: [
                    Text(
                      'Connect to PC',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 20,),
                    Icon(Icons.computer)
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return MainPage();
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10), // Adds spacing between buttons
              height: 60,
              width: 270,
              child: ElevatedButton(
                child: Row(
                  children: [
                    Text(
                      'Smart Home Control',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 20,),
                    Icon(Icons.settings_remote)
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SmartHomeControl();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
