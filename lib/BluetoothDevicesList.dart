import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devicesList = [];
  Map<String, StreamSubscription<ConnectionStateUpdate>> _connectionSubscriptions = {};
  DiscoveredDevice? _connectedDevice;


  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    _ble.scanForDevices(withServices: []).listen((device) {
      setState(() {
        if (!_devicesList.any((element) => element.id == device.id)) {
          _devicesList.add(device);
        }
      });
    }, onError: (error) {
      print('Error occurred while scanning: $error');
    });
  }

  void connectToDevice(DiscoveredDevice device) {
    final connectionStream = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        setState(() {
          _connectedDevice = device;
        });
      } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          if (_connectedDevice?.id == device.id) {
            _connectedDevice = null;
          }
        });
      }
    }, onError: (error) {
      print('Failed to connect: $error');
    });

    _connectionSubscriptions[device.id] = connectionStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: ListView.builder(
        itemCount: _devicesList.length,
        itemBuilder: (context, index) {
          final device = _devicesList[index];
          return ListTile(
            title: Text(device.name ?? 'Unknown Device'),
            subtitle: Text(device.id),
            onTap: () => connectToDevice(device),
            trailing: _connectedDevice?.id == device.id ? Icon(Icons.link) : null,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Disconnect from all devices
    _connectionSubscriptions.forEach((key, subscription) {
      subscription.cancel();
     // _ble.disconnectDevice(id: key);
    });
    super.dispose();
  }
}