import 'package:flutter/material.dart';
import 'package:stream_sync/BluetoothDevicesList.dart';

class DeviceScreen extends StatelessWidget {
  //final BluetoothDevice device;

  //DeviceScreen({required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text(device.name),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            /*ElevatedButton(
              child: Text("Send Data"),
              onPressed: () => sendDataToDevice(),
            ),*/
          ],
        ),
      ),
    );
  }

 /* void sendDataToDevice() async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // Assumes you know the service and characteristic UUIDs
      var targetCharacteristic = service.characteristics.firstWhere(
              (c) => c.uuid.toString() == "your-characteristic-uuid-here",
          orElse: () => null);
      if (targetCharacteristic != null) {
        device.writeCharacteristic(targetCharacteristic, [0x12, 0x34],
            type: CharacteristicWriteType.withoutResponse);
      }
    });
  }*/
}
