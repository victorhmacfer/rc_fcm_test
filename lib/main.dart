import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Remote Config Example',
      home: FutureBuilder<RemoteConfig>(
        future: setupRemoteConfig(),
        builder: (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
          return snapshot.hasData
              ? WelcomeWidget(remoteConfig: snapshot.data)
              : Container();
        },
      )));
}

class WelcomeWidget extends AnimatedWidget {
  WelcomeWidget({this.remoteConfig}) : super(listenable: remoteConfig);

  final RemoteConfig remoteConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Config Example'),
      ),
      body: Center(
          child: Text(
        'Welcome, ${remoteConfig.getString('welcome')}',
        style: TextStyle(fontSize: 20),
      )),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () async {
            try {
              // Using default duration to force fetching from remote server.
              await remoteConfig.fetch(expiration: const Duration(seconds: 0));
              await remoteConfig.activateFetched();
            } on FetchThrottledException catch (exception) {
              // Fetch throttled.
              print(exception);
            } catch (exception) {
              print(
                  'Unable to fetch remote config. Cached or default values will be '
                  'used');
            }
          }),
    );
  }
}

Future<RemoteConfig> setupRemoteConfig() async {
  await Firebase.initializeApp();
  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  // Allow a fetch every millisecond. Default is 12 hours.
  remoteConfig
      .setConfigSettings(RemoteConfigSettings(minimumFetchIntervalMillis: 1));
  remoteConfig.setDefaults(<String, dynamic>{
    'welcome': 'John Doe',
    'hello': 'default hello',
  });
  return remoteConfig;
}
