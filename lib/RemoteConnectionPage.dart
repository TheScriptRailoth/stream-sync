import 'dart:async';
import 'dart:typed_data';
import 'package:control_pad_plus/views/joystick_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'package:ionicons/ionicons.dart  ';

class RemoteConnectionPage extends StatefulWidget {
  final BluetoothDevice server;

  const RemoteConnectionPage({required this.server});

  @override
  _RemoteConnectionPageState createState() => new _RemoteConnectionPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _RemoteConnectionPageState extends State<RemoteConnectionPage> {

  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;

  late StreamSubscription<Uint8List>? _streamSubscription;

  List<_Message> messages = [];
  String _messageBuffer = '';
  String _previousText = '';
  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;

  // bool get isConnected => _streamSubscription != null;
  bool isConnected = false;
  bool doubleTapped = false;
  bool _condition = true;
  bool _isJoystick = false;
  double dx = 0.0;
  double dy = 0.0;

  bool isGyroOn = false;

  bool _onHold = false;

  @override
  void initState() {
    super.initState();
    textEditingController.addListener(_onTextChanged);
    prevFocalPoint = Offset.zero;
    prevScale = 0.0;

    accelerometerEvents.listen((event) {

      if (isGyroOn) {
        // print(event);
        _sendMessage('*#*Offset(${event.x * -1}, ${event.y * -1})*@*');
      }
    });
    if (widget.server.isConnected) {
      isConnected = true;
      isConnecting = false;
    }
    // gyroscopeEvents.listen((event) {
    //   if (isOn) {
    // print(event);
    // _sendMessage('*#*Offset(${event.x*100}, ${event.y*100})*@*');
    //   }
    // });
    // RawKeyboard.instance
    //     .addListener((rawKeyEvent) => handleKeyListener(rawKeyEvent));

    connectToBluetooth();
  }

  // handleKeyListener(RawKeyEvent rawKeyEvent) {
  //   // print("Event runtimeType is ${rawKeyEvent.runtimeType}");
  //   if (rawKeyEvent.runtimeType.toString() == 'RawKeyDownEvent') {
  //     print('***********************************' +rawKeyEvent.physicalKey.debugName);
  //     RawKeyEventDataAndroid data = rawKeyEvent.data as RawKeyEventDataAndroid;
  //     String _keyCode;
  //     _keyCode = data.keyCode.toString();
  //   }
  // }

  void handleKeyListener(RawKeyEvent rawKeyEvent) {
    // Check if the event is a key down event
    if (rawKeyEvent.runtimeType.toString() == 'RawKeyDownEvent') {
      String debugName = rawKeyEvent.physicalKey.debugName ?? "Unknown Key";
      print('***********************************' + debugName);

      RawKeyEventDataAndroid data = rawKeyEvent.data as RawKeyEventDataAndroid;

      String keyCode = data.keyCode?.toString() ?? "Unknown KeyCode";
      print('Key Code: $keyCode');
    }
  }


  late BluetoothConnection _bluetoothConnection;

  connectToBluetooth() async {
    if (!isConnected) {
      _bluetoothConnection =
      await BluetoothConnection.toAddress(widget.server.address);

      isConnecting = false;
      this._bluetoothConnection = _bluetoothConnection;
      // Subscribe for incoming data after connecting
      _streamSubscription = _bluetoothConnection.input!.listen(_onDataReceived);
      setState(() {
        isConnected = true;
        /* Update for `isConnecting`, since depends on `_streamSubscription` */
      });

      // Subscribe for remote disconnection
      _streamSubscription?.onDone(() {
        print('we got disconnected by remote!');
        _streamSubscription = null;
        setState(() {
          isConnected = false;
          /* Update for `isConnected`, since is depends on `_streamSubscription` */
        });
      });
    }
    // BluetoothConnection.toAddress(widget.server.address)
    //     .then((_bluetoothConnection) {
    //   // @TODO ? shouldn't be done via `.listen()`?
    //
    // });
  }

  @override
  void dispose() {
    if (isConnected) {
      _streamSubscription?.cancel();
      print('we are disconnecting locally!');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                    (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(isConnecting
              ? 'Connecting to ${widget.server.name}...'
              : isConnected
              ? 'Connected with ${widget.server.name}'
              : 'Disconnected'),
          centerTitle: true,
          backgroundColor: const Color(0xff00416a),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Ionicons.refresh_circle_outline,
                color: Colors.white,
              ),
              onPressed: () => close(),
            ),
            IconButton(
              icon: const Icon(Ionicons.close_circle_outline,
                    color: Colors.white),
              onPressed: isConnected ? null : () => connectToBluetooth(),
            ),
          ],
        ),
        body: SafeArea(
            child: Column(children: <Widget>[
              _isJoystick
                  ? Container(
                color: Colors.white,
                child: JoystickView(
                  interval: Duration(
                    milliseconds: 50,
                  ),
                  onDirectionChanged: (degrees, distance) =>
                      directionChanged(degrees, distance),
                ),
              )
                  : Flexible(
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (dragUpdate) => zoom(dragUpdate),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                        child: Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * (1 / 6),
                          height: MediaQuery
                              .of(context)
                              .size
                              .height - 40,
                          // color: Colors.red,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              _buildCircularButton(
                  icon: Ionicons.volume_mute,
                  onPressed: () => muteVolume(),
                ),
                _buildCircularButton(
                  icon: Ionicons.volume_low,
                  onPressed: () => decreaseVol(),
                ),
                _buildCircularButton(
                  icon: Ionicons.volume_high,
                  onPressed: () => increaseVol(),
                ),
                _buildCircularButton(
                  icon: Icons.zoom_in,
                  onPressed: () => zoomIn(),
                ),
                _buildCircularButton(
                  icon: Icons.zoom_out,
                  onPressed: () => zoomOut(),
                ),
              ],
          ),
        ),
      ),
                    ),

                          //     Container(
                          //       height: MediaQuery.of(context).size.height*(1/12),
                          //       width: MediaQuery.sizeOf(context).width * (1/6),
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(10.0),
                          //         gradient: LinearGradient(
                          //           begin: Alignment.bottomRight,
                          //           end: Alignment.topLeft,
                          //           stops: [0.1, 0.5, 0.7, 0.9],
                          //           colors: [
                          //             Color.fromARGB(255, 238, 112, 2),
                          //             Color.fromARGB(220, 238, 112, 2),
                          //             Color.fromARGB(200, 238, 112, 2),
                          //             Color.fromARGB(150, 238, 112, 2),
                          //           ],
                          //         ),
                          //       ),
                          //       child: GestureDetector(
                          //         // onHold: () =>
                          //         //     zoom(DragUpdateDetails(
                          //         //         delta: Offset(0.0, -1.0),
                          //         //         globalPosition: Offset(0, 0))),
                          //         // holdTimeout: Duration(milliseconds: 200),
                          //         // enableHapticFeedback: true,
                          //         child: IconButton(
                          //           onPressed: ()=> increaseVol(),
                          //           icon: Icon(
                          //             Icons.volume_up_outlined,
                          //             color: Colors.white,
                          //           ),
                          //           iconSize: 50,
                          //         ),
                          //       ),
                          //     ),
                          //     Container(
                          //       height: MediaQuery.of(context).size.height*(1/12),
                          //       width: MediaQuery.sizeOf(context).width * (1/6),
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(10.0),
                          //         gradient: LinearGradient(
                          //           begin: Alignment.bottomRight,
                          //           end: Alignment.topLeft,
                          //           stops: [0.1, 0.5, 0.7, 0.9],
                          //           colors: [
                          //             Color.fromARGB(255, 238, 112, 2),
                          //             Color.fromARGB(220, 238, 112, 2),
                          //             Color.fromARGB(200, 238, 112, 2),
                          //             Color.fromARGB(150, 238, 112, 2),
                          //           ],
                          //         ),
                          //       ),
                          //       child: GestureDetector(
                          //         // onHold: () =>
                          //         //     zoom(DragUpdateDetails(
                          //         //         delta: Offset(0.0, -1.0),
                          //         //         globalPosition: Offset(0, 0))),
                          //         // holdTimeout: Duration(milliseconds: 200),
                          //         // enableHapticFeedback: true,
                          //         child: IconButton(
                          //           onPressed: ()=> decreaseVol(),
                          //           icon: const Icon(
                          //             Icons.volume_down_outlined,
                          //             color: Colors.white,
                          //           ),
                          //           iconSize: 50,
                          //         ),
                          //       ),
                          //     ),
                          //     Container(
                          //       height: MediaQuery.of(context).size.height*(1/12),
                          //       width: MediaQuery.sizeOf(context).width * (1/6),
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(10.0),
                          //         gradient: const LinearGradient(
                          //           begin: Alignment.bottomRight,
                          //           end: Alignment.topLeft,
                          //           stops: [0.1, 0.5, 0.7, 0.9],
                          //           colors: [
                          //             Color.fromARGB(255, 238, 112, 2),
                          //             Color.fromARGB(220, 238, 112, 2),
                          //             Color.fromARGB(200, 238, 112, 2),
                          //             Color.fromARGB(150, 238, 112, 2),
                          //           ],
                          //         ),
                          //       ),
                          //       child: GestureDetector(
                          //         // onHold: () =>
                          //         //     zoom(DragUpdateDetails(
                          //         //         delta: Offset(0.0, -1.0),
                          //         //         globalPosition: Offset(0, 0))),
                          //         // holdTimeout: Duration(milliseconds: 200),
                          //         // enableHapticFeedback: true,
                          //         child: IconButton(
                          //           onPressed: ()=> muteVolume(),
                          //           icon: const Icon(
                          //             Icons.volume_off,
                          //             color: Colors.white,
                          //             size: 24,
                          //           ),
                          //           iconSize: 50,
                          //         ),
                          //       ),
                          //     ),

                          //     Container(
                          //       height: MediaQuery.of(context).size.height*(1/12),
                          //       width: MediaQuery.sizeOf(context).width * (1/6),
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(10.0),
                          //         gradient: const LinearGradient(
                          //           begin: Alignment.bottomRight,
                          //           end: Alignment.topLeft,
                          //           stops: [0.1, 0.5, 0.7, 0.9],
                          //           colors: [
                          //             Color.fromARGB(255, 238, 112, 2),
                          //             Color.fromARGB(220, 238, 112, 2),
                          //             Color.fromARGB(200, 238, 112, 2),
                          //             Color.fromARGB(150, 238, 112, 2),
                          //           ],
                          //         ),
                          //       ),
                          //       child: HoldDetector(
                          //         onHold: () {

                          //         },
                          //         //     zoom(DragUpdateDetails(
                          //         //         delta: Offset(0.0, -1.0),
                          //         //         globalPosition: Offset(0, 0))),
                          //         // holdTimeout: Duration(milliseconds: 200),
                          //         // enableHapticFeedback: true,
                          //         child: IconButton(
                          //           onPressed: () =>  zoomIn(),

                          //           // onPressed: () =>
                          //           //     zoom(DragUpdateDetails(
                          //           //         delta: Offset(0.0, -1.0),
                          //           //         globalPosition: Offset(0, 0))),
                          //           icon: Icon(
                          //             Icons.zoom_in,
                          //             color: Colors.white,
                          //           ),
                          //           iconSize: 50,
                          //         ),
                          //       ),
                          //     ),

                          //     Container(

                          //       height: MediaQuery.of(context).size.height*(1/12),
                          //       width: MediaQuery.sizeOf(context).width * (1/6),
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(10.0),
                          //         gradient: LinearGradient(
                          //           begin: Alignment.bottomRight,
                          //           end: Alignment.topLeft,
                          //           stops: [0.1, 0.5, 0.7, 0.9],
                          //           colors: [
                          //             Color.fromARGB(255, 238, 112, 2),
                          //             Color.fromARGB(220, 238, 112, 2),
                          //             Color.fromARGB(200, 238, 112, 2),
                          //             Color.fromARGB(150, 238, 112, 2),
                          //           ],
                          //         ),
                          //       ),


                          //       child: HoldDetector(
                          //         onHold: () {},
                          //         //     zoom(DragUpdateDetails(
                          //         //         delta: Offset(0.0, 1.0),
                          //         //         globalPosition: Offset(0, 0))),
                          //         // holdTimeout: Duration(milliseconds: 200),
                          //         //enableHapticFeedback: true,
                          //         child: IconButton(
                          //         onPressed: () => zoomOut(),
                          //           // onPressed: () =>
                          //           //     zoom(DragUpdateDetails(
                          //           //         delta: Offset(0.0, 1.0),
                          //           //         globalPosition: Offset(0, 0))),
                          //           icon: Icon(
                          //             Icons.zoom_out,
                          //             color: Colors.white,
                          //           ),
                          //           iconSize: 50,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // Align(
                          //   alignment: Alignment.center,
                          //   child: RotatedBox(
                          //     quarterTurns: 3,
                          //     child: Text(
                          //       'ZOOM',
                          //       style: TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 50,
                          //       ),
                          //     ),
                          //   ),
                          // ),



                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(10.0),
                    //         gradient: LinearGradient(
                    //           begin: Alignment.bottomRight,
                    //           end: Alignment.topLeft,
                    //           stops: [0.1, 0.5, 0.7, 0.9],
                    //           colors: [
                    //             Color.fromARGB(255, 238, 112, 2),
                    //             Color.fromARGB(220, 238, 112, 2),
                    //             Color.fromARGB(200, 238, 112, 2),
                    //             Color.fromARGB(150, 238, 112, 2),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    Expanded(
              child:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    isGyroOn
                        ? HoldDetector(
                      onHold: () =>
                          setState(() {
                            _onHold = true;
                          }),
                      onCancel: () =>
                          setState(() {
                            _onHold = false;
                          }),
                      onTap: () => leftClickMouse(),
                      holdTimeout: Duration(milliseconds: 200),
                      enableHapticFeedback: true,
                      child: TouchArea(
                        dx: dx,
                        dy: dy,
                      ),
                    )
                        : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => leftClickMouse(),
                      onDoubleTap: () =>
                      {
                        doubleTapped = true,
                        print('Double Tapped'),
                      },
                      // onPanUpdate: (dragUpdate) => onPan(dragUpdate),
                      onScaleUpdate: _condition
                          ? (dragUpdate) => onScale(dragUpdate)
                          : null,
                      onScaleEnd: (scaleEndDetails) => onScaleEnd(),
                      child: TouchArea(
                        dx: dx,
                        dy: dy,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (dragUpdate) =>
                          scroll(dragUpdate),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                        child: Container(
                          width:
                          MediaQuery
                              .of(context)
                              .size
                              .width * (1 / 6) - 2,
                          height: MediaQuery
                              .of(context)
                              .size
                              .height - 40,
                          decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomRight,
                                  end: Alignment.topLeft,
                                  stops: [0.1, 0.5, 0.7, 0.9],
                                  colors: [
                                    Color.fromARGB(255, 238, 112, 2),
                                    Color.fromARGB(220, 238, 112, 2),
                                    Color.fromARGB(200, 238, 112, 2),
                                    Color.fromARGB(150, 238, 112, 2),
                                    // Color.fromARGB(150, 2, 130, 238),
                                    // Color.fromARGB(220, 2, 130, 238),
                                    // Color.fromARGB(255, 2, 130, 238),
                                    // Color.fromARGB(220, 2, 130, 238),
                                    // Color.fromARGB(150, 2, 130, 238),
                                  ],
                                ),
                              ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              HoldDetector(
                                onHold: () =>
                                    scroll(DragUpdateDetails(
                                        delta: Offset(0.0, -1.0),
                                        globalPosition: Offset(0, 0))),
                                holdTimeout: Duration(milliseconds: 200),
                                enableHapticFeedback: true,
                                child: IconButton(
                                  onPressed: () =>
                                      scroll(DragUpdateDetails(
                                          delta: Offset(0.0, -1.0),
                                          globalPosition: Offset(0, 0))),
                                  icon: Icon(
                                    Ionicons.caret_up_outline,
                                        color: Colors.white,
                                  ),
                                  iconSize: 20,
                                ),
                              ),
                              HoldDetector(
                                onHold: () =>
                                    scroll(DragUpdateDetails(
                                        delta: Offset(0.0, 1.0),
                                        globalPosition: Offset(0, 0))),
                                holdTimeout: Duration(milliseconds: 200),
                                enableHapticFeedback: true,
                                child: IconButton(
                                  onPressed: () =>
                                      scroll(DragUpdateDetails(
                                          delta: Offset(0.0, 1.0),
                                          globalPosition: Offset(0, 0))),
                                  icon: Icon(
                                    Ionicons.caret_down_outline,
                                        color: Colors.white,
                                  ),
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ), // child: Align(
                          //   alignment: Alignment.center,
                          //   child: RotatedBox(
                          //     quarterTurns: 3,
                          //     child: Text(
                          //       'SCROLL',
                          //       style: TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 50,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Flexible(
              //   child: ListView(
              //     padding: const EdgeInsets.all(12.0),
              //     controller: listScrollController,
              //     children: list
              //   )
              // ),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                          Ionicons.arrow_back,
                          color: Color(0xff00416a),
                        ),
                    iconSize: (MediaQuery
                        .of(context)
                        .size
                        .width / 5) - 16,
                    onPressed: isConnected ? () => present() : null,
                    tooltip: 'Back',
                  ),
                  IconButton(
                    icon: const Icon(
                          Ionicons.backspace,
                          color: Color(0xff00416a),
                        ),
                    iconSize: (MediaQuery
                        .of(context)
                        .size
                        .width / 5) - 16,
                    onPressed: isConnected ? () => presentCurrent() : null,
                    tooltip: 'Backspace',
                  ),
                  IconButton(
                    icon: const Icon(
                          Ionicons.return_up_back,
                          color: Color(0xff00416a),
                        ),
                    iconSize: (MediaQuery
                        .of(context)
                        .size
                        .width / 5) - 16,
                    onPressed: isConnected ? () => goLeft() : null,
                    tooltip: 'Next',
                  ),
                  IconButton(
                    icon: const Icon(Ionicons.return_up_forward,
                            color: Color(0xff00416a)),
                    iconSize: (MediaQuery
                        .of(context)
                        .size
                        .width / 5) - 16,
                    onPressed: isConnected ? () => goRight() : null,
                    tooltip: 'Previous',
                  ),
                  IconButton(
                    icon: const Icon(
                          Ionicons.close,
                          color: Color(0xff00416a),
                        ),
                    iconSize: (MediaQuery
                        .of(context)
                        .size
                        .width / 5) - 16,
                    onPressed: isConnected ? () => exit() : null,
                    tooltip: 'Exit',
                  ),
                ],
              ),
              // Row(
              //   children: <Widget>[
              //     SwitchListTile(
              //         onChanged: (isOn) => accelerometerControl(isOn), value: false)
              //   ],
              // ),

              // SwitchListTile(
              //     title: Text('Gyro'),
              //     onChanged: (isOn) => accelerometerControl(isOn),
              //     value: isGyroOn),
              Row(children: <Widget>[
                Flexible(
                    child: Container(
                        margin: const EdgeInsets.only(left: 16.0),
                        child: TextField(
                          style: const TextStyle(fontSize: 15.0),
                          controller: textEditingController,

                          decoration: InputDecoration.collapsed(
                            hintText: (isConnecting
                                ? 'Wait until connected...'
                                : isConnected
                                ? 'Type on PC...'
                                : 'Bluetooth got disconnected'),
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                          onSubmitted:submit ,
                          enabled: isConnected,
                        ))),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Ionicons.send),
                      onPressed: isConnected
                          ? () => _sendStringToType(textEditingController.text)
                          : null),
                ),
              ])
            ]
            )
            )
            ]
            )
            )
            );      
  }
// @override
  Widget _buildCircularButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      height: MediaQuery.of(context).size.height * (1 / 12),
      width: MediaQuery.of(context).size.width * (1 / 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent,
            offset: const Offset(
              5.0,
              5.0,
            ),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ), //BoxShadow
          BoxShadow(
            color: Colors.white,
            offset: const Offset(0.0, 0.0),
            blurRadius: 0.0,
            spreadRadius: 0.0,
          ), //BoxShadow
        ],
        gradient: const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          stops: [0.1, 0.5, 0.7, 0.9],
          colors: [
            Color.fromARGB(255, 238, 112, 2),
            Color.fromARGB(220, 238, 112, 2),
            Color.fromARGB(200, 238, 112, 2),
            Color.fromARGB(150, 238, 112, 2),
          ],
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 30,
      ),
    );
  }
  void close() {
    if (isConnected) {
      _streamSubscription = null;
      _bluetoothConnection.finish();
      setState(() {
        isConnected = false;
        /* Update for `isConnected`, since is depends on `_streamSubscription` */
      });
      // FlutterBluetoothSerial.instance.disconnect();
      // _streamSubscription.cancel();
      // _streamSubscription = null;
      print('we are disconnecting locally!');
      // isConnected = false;
      // setState(() {});
    }
  }

  void zoomIn(){
    _sendMessage("#*ZOOMIN@*");
  }

  void zoomOut(){
    _sendMessage("#*ZOOMOUT@*");
  }
  void present() {
    _sendMessage("#enter#@");
  }

  void submit(String value) {
    _sendMessage("#enter#@");
    textEditingController.clear();
  }
  void exit() {
    _sendMessage("*#*esc*@*");
  }

  void presentCurrent() {
    _sendMessage("#BACKSPACE#@");
  }

  void goRight() {
    _sendMessage("*#*RIGHT*@*");
  }

  void goLeft() {
    _sendMessage("*#*LEFT*@*");
  }
  
  void muteVolume(){
    _sendMessage("#mute#@");
  }

  void increaseVol(){
    _sendMessage("#increasevol#@");
  }

  void decreaseVol(){
    _sendMessage("#decreasevol#@");
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      // \r\n
      setState(() {
        messages.add(_Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index)));
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) {
    if (text != null && text.isNotEmpty) {
      text = text.trim();
      if (text.length > 0) {
        //textEditingController.clear();
        _bluetoothConnection.output.add(ascii.encode(text + "\r\n"));
      }
    }
  }

  directionChanged(double degrees, double distance) {
    print(degrees.toString() + " " + distance.toString());
    _sendMessage(
        "*#*JOYSTICK" + degrees.toString() + " " + distance.toString() + "*@*");
  }

  bool _leftClick = false;
  bool _dragEnabled = false;

  leftClickMouse() {
    print("Left Click");
    _sendMessage("*#*LC*@*");
  }

  onPan(DragUpdateDetails dragUpdate) {
    // dragUpdate.delta
    print("Cordinates:${dragUpdate.delta}");
    // _sendMessage("*#*LC*@*");
  }

  scroll(DragUpdateDetails dragUpdate) {
    _sendMessage("*#*SCROLL${dragUpdate.delta.dy.toString()}*@*");
    print(dragUpdate);
  }

  zoom(DragUpdateDetails dragUpdate) {
    _sendMessage("#*ZOOM${dragUpdate.delta.dy.toString()}*@*");
    print(dragUpdate);
  }

  onScale(ScaleUpdateDetails dragUpdate) {
    setState(() => _condition = false);

    if (dragUpdate.scale != 1) {
      if (prevScale == 0) {
        prevScale = dragUpdate.scale;
        setState(() => _condition = true);
        return;
      }
      print("${dragUpdate.scale - prevScale}");
      _sendMessage("*#*ZOOM${dragUpdate.scale - prevScale}*@*");
      prevScale = dragUpdate.scale;
      setState(() => _condition = true);
      return;
    }

    if (prevFocalPoint == Offset.zero) {
      prevFocalPoint = dragUpdate.focalPoint;
      setState(() => _condition = true);
      return;
    }

    // Adjust the focal point calculations to be relative to the previous focal point
    double deltaX = dragUpdate.focalPoint.dx - prevFocalPoint.dx;
    double deltaY = dragUpdate.focalPoint.dy - prevFocalPoint.dy;

    setState(() {
      dx += deltaX / MediaQuery.of(context).size.width; // Normalize the delta
      dy += deltaY / MediaQuery.of(context).size.height; // Normalize the delta
    });

    _dragEnabled = _leftClick;
    _sendMessage(
        "*#*${(_leftClick ? 'DRAG' : '') +
            Offset(deltaX, deltaY).toString()}*@*");

    prevFocalPoint = dragUpdate.focalPoint;
    setState(() => _condition = true);
  }

  onScaleEnd() {
    if (_dragEnabled) {
      _sendMessage("*#*DRAGENDED*@*");
    }
    //_sendMessage(_dragEnabled ? "*#*DRAGENDED*@*" : null);
    _dragEnabled = false;
    _leftClick = false;
    prevFocalPoint = Offset(0, 0);
    doubleTapped = false;
    prevScale = 0;
    setState(() {
      dx = 0;
      dy = 0;
    });
  }

  late Offset prevFocalPoint;
  late double prevScale;

  _sendStringToType(String text) {
    String _finalText = text[text.length -1];
    _sendMessage("*#*TYPE$_finalText*@*");
  }

  void accelerometerControl(bool isOn) {
    setState(() {
      this.isGyroOn = isOn;
    });
  }

  void _onTextChanged() {
    String currentText = textEditingController.text;
    print(currentText);
    if (_previousText.length > currentText.length) {
      print("Backspace pressed!");
      _onBackspacePressed();
    }
    else{
      _sendStringToType(currentText);
    }
    _previousText = currentText;
  }

  void _onBackspacePressed() {
    presentCurrent();
  }
}

class TouchArea extends StatelessWidget {
  TouchArea({required this.dx, required this.dy});
  final double dx, dy;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width * (4 / 6) - 16,
        height: MediaQuery.of(context).size.height - 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: SweepGradient(
            center: Alignment(dx, dy),
            tileMode: TileMode.repeated,
            colors: [
              Color.fromARGB(150, 2, 130, 238),
              Color.fromARGB(220, 2, 130, 238),
              Color.fromARGB(255, 2, 130, 238),
              Color.fromARGB(220, 2, 130, 238),
              Color.fromARGB(150, 2, 130, 238),
            ],
          ),
        ),
      ),
    );
  }
}

