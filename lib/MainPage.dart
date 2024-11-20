import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './RemoteConnectionPage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _name = "...";

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == true) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 221));  // Adjusted for clarity
      return true;
    }).then((_) {});


    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: Color(0xff2C3E50),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Visibility(
              child: ListTile(
                  title: Text("Device Name : "+_name)),
              visible: _bluetoothState.isEnabled,
            ),
            Visibility(
              child: ListTile(
                  title: const Text('Devices discovery and connection')),
              visible: _bluetoothState.isEnabled,
            ),

            Visibility(  
              visible: _bluetoothState.isEnabled,
              child: ListTile(
                title: ElevatedButton(
                    child: const Text('Explore discovered devices'),
                    onPressed: _bluetoothState.isEnabled
                        ? () async {
                            final BluetoothDevice selectedDevice =
                                await Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (context) {
                              return DiscoveryPage();
                            }));

                            if (selectedDevice != null) {
                              print('Discovery -> selected ' +
                                  selectedDevice.address);
                            } else {
                              print('Discovery -> no device selected');
                            }
                          }
                        : null),
              ),
            ),
            Visibility(
              visible: _bluetoothState.isEnabled,
              child: ListTile(
                title: ElevatedButton(
                  child: const Text('Connect to paired PC to Control'),
                  onPressed: _bluetoothState.isEnabled
                      ? () async {
                          final BluetoothDevice selectedDevice =
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                            return SelectBondedDevicePage(
                                checkAvailability: true);
                          }));

                          if (selectedDevice != null) {
                            print('Connect -> selected ' + selectedDevice.address);
                            _startRemoteConnection(context, selectedDevice);
                          } else {
                            print('Connect -> no device selected');
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startRemoteConnection(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return RemoteConnectionPage(server: server);
    }));
  }
}
