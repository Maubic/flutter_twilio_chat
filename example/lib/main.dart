import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_twilio_chat/flutter_twilio_chat.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _text = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    final String token = '';
    try {
      print('Before initialize');
      await FlutterTwilioChat.initialize(token: token);
      print('After initialize');
    } catch (err) {
      print('Error: $err');
    }
    //setState(() {
    //_platformVersion = platformVersion;
    //});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('$_text'),
        ),
      ),
    );
  }
}
