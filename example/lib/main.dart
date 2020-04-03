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
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    final String token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzQwN2YyYmZlYmFiMmIzNTA2ZjU2Y2Y0MGYwYzVmZWRlLTE1ODU5MDkwNTQiLCJncmFudHMiOnsiaWRlbnRpdHkiOiJjMzI3OWY5My0yZmVmLTQyYjUtYTE5Yy1jOWYzYTZkM2FjMTIiLCJjaGF0Ijp7InNlcnZpY2Vfc2lkIjoiSVM2NmY0ODQzODE2MTk0NmU5YTcwYzQ0ODYyMDhiYjg5MSJ9fSwiaWF0IjoxNTg1OTA5MDU0LCJleHAiOjE1ODU5MTI2NTQsImlzcyI6IlNLNDA3ZjJiZmViYWIyYjM1MDZmNTZjZjQwZjBjNWZlZGUiLCJzdWIiOiJBQzY2YWI0MzM5YzE3ODY0NDk4MjNkYTE4YzE3ZWQxNTgwIn0.nHbE8-hXEhRETApBYozahVmcwDx9jI0JLiBGqsfetPo';
    try {
      print('Before initialize');
      await FlutterTwilioChat.initialize(token: token);
      print('After initialize');
      setState(() {
        initialized = true;
      });
    } catch (err) {
      print('Error: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: initialized
            ? Center(
                child: RaisedButton(
                  child: Text('Send poke'),
                  onPressed: () {
                    FlutterTwilioChat.sendSimpleMessage(
                      channelId: '3fe2d1bb-75a8-4b0f-8f2e-b715e452660c',
                      messageText: 'Poke',
                    );
                  },
                ),
              )
            : Center(
                child: Text('Initializing...'),
              ),
      ),
    );
  }
}
