import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final darkGray = const Color(0xFF232323);
final bulbOnColor = const Color(0xFFFFE12C);
final bulbOffColor = const Color(0xFFC1C1C1);
final animationDuration = const Duration(milliseconds: 500);

class SmartHomeControl extends StatefulWidget {
  const SmartHomeControl({super.key});

  @override
  State<SmartHomeControl> createState() => _SmartHomeControlState();
}

class _SmartHomeControlState extends State<SmartHomeControl> {

  bool isSwitched = false;
  var _isSwitchOn = false;
  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final String picoIp = "192.168.153.229";
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

    return Scaffold(
      body: Stack(
        children: <Widget>[
          LampHangerRope(screenWidth: screenWidth, screenHeight: screenHeight, color: darkGray),
          LEDBulb(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            onColor: bulbOnColor,
            offColor: bulbOffColor,
            isSwitchOn: _isSwitchOn,
          ),
          Lamp(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            color: darkGray,
            isSwitchOn: _isSwitchOn,
            gradientColor: bulbOnColor,
            animationDuration: animationDuration,
          ),
          LampSwitch(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            toggleOnColor: bulbOnColor,
            toggleOffColor: bulbOffColor,
            color: darkGray,
            isSwitchOn: _isSwitchOn,
            onTap: () {
              setState(() {
                _isSwitchOn = !_isSwitchOn;
              });
              sendRequest(_isSwitchOn ? "true" : "false");
            },
            animationDuration: animationDuration,
          ),
          LampSwitchRope(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            color: darkGray,
            isSwitchOn: _isSwitchOn,
            animationDuration: animationDuration,
          ),
          RoomName(
            screenWidth: screenWidth,
            screenHeight: screenWidth,
            color: darkGray,
            roomName: "Switch",
          ),
        ],
      ),
    );


  }
}

class LampHangerRope extends StatelessWidget {
  final double screenWidth, screenHeight;
  final Color color;

  const LampHangerRope({required this.screenWidth, required this.screenHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenWidth * 0.2,
      child: Container(
        color: color,
        width: 15,
        height: screenHeight * 0.15,
      ),
    );
  }
}

class RoomName extends StatelessWidget {
  final double screenWidth, screenHeight;
  final Color color;
  final String roomName;

  const RoomName({ required this.screenWidth, required this.screenHeight, required this.color, required this.roomName}) ;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: screenHeight * 0.25,
      width: screenWidth,
      child: Center(
        child: Transform.rotate(
          angle: -1.58,
          child: Text(
            roomName.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class LampSwitchRope extends StatelessWidget {
  final double screenWidth, screenHeight;
  final Color color;
  final bool isSwitchOn;
  final Duration animationDuration;

  const LampSwitchRope({required this.screenWidth, required this.screenHeight, required this.color, required this.isSwitchOn, required this.animationDuration});


  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: animationDuration,
      top: screenHeight * 0.4,
      bottom: screenHeight * (isSwitchOn ? 0.34 : 0.38),
      width: 2,
      right: screenWidth * 0.5 - 1,
      child: Container(
        color: color,
      ),
    );
  }
}

class LEDBulb extends StatelessWidget {
  final double screenWidth, screenHeight;
  final Color  onColor, offColor;
  final bool isSwitchOn;
  final Duration animationDuration = const Duration(milliseconds: 4000);

  const LEDBulb(
      {required this.screenWidth, required this.screenHeight, required this.onColor, required this.offColor, required this.isSwitchOn});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenWidth * 0.1,
      top: screenHeight * 0.35,
      child: AnimatedContainer(
        duration: animationDuration,
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSwitchOn ? onColor : offColor,
        ),
      ),
    );
  }
}

class LampSwitch extends StatelessWidget {
  final Function onTap;
  final bool isSwitchOn;
  final Color toggleOnColor, toggleOffColor, color;
  final screenWidth, screenHeight;
  final Duration animationDuration;

  const LampSwitch({

    required this.onTap,
    required this.isSwitchOn,
    this.screenWidth,
    this.screenHeight,
    required this.animationDuration,
    required this.toggleOnColor,
    required this.toggleOffColor,
    required this.color,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: screenHeight * 0.31,
      width: 30,
      left: screenWidth * 0.5 - 15,
      child: GestureDetector(
        onTap : ()=> onTap(),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: animationDuration,
              width: 30,
              height: 70,
              decoration: BoxDecoration(
                color: isSwitchOn ? bulbOnColor : bulbOffColor,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            AnimatedPositioned(
              duration: animationDuration,
              left: 0,
              right: 0,
              top: isSwitchOn ? 42 : 4,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Lamp extends StatelessWidget {
  final double screenWidth, screenHeight;
  final Color color, gradientColor;
  final bool isSwitchOn;
  final Duration animationDuration;

  const Lamp({
    required this.screenWidth,
    required this.screenHeight,
    required this.color,
    required this.isSwitchOn,
    required this.gradientColor,
    required this.animationDuration,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -screenWidth * 0.95,
      top: screenHeight * 0.15,
      width: screenWidth * 2.1,
      child: ClipPath(
        clipper: TrapezoidClipper(),
        child: Column(
          children: <Widget>[
            Container(
              height: screenHeight * 0.25,
              color: color,
            ),
            AnimatedContainer(
              duration: animationDuration,
              height: screenHeight * 0.75,
              decoration: BoxDecoration(
                gradient: isSwitchOn
                    ? LinearGradient(
                  colors: [gradientColor.withOpacity(0.4), gradientColor.withOpacity(0.01)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(size.width * 0.3, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.7, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}