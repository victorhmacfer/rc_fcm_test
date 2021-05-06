import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Remote Config Example',
      home: FutureBuilder<RemoteConfig>(
        future: setup(),
        builder: (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
          return snapshot.hasData
              ? WelcomeWidget(remoteConfig: snapshot.data)
              : Scaffold(
                  body: Center(
                  child: CircularProgressIndicator(),
                ));
        },
      )));
}

const defaultExpirationTime = Duration(minutes: 12, seconds: 10);
const now = Duration(seconds: 0);

class WelcomeWidget extends AnimatedWidget {
  WelcomeWidget({this.remoteConfig}) : super(listenable: remoteConfig);

  final RemoteConfig remoteConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Config Example'),
      ),
      body: Container(
          alignment: Alignment.center,
          color: _bgColor(remoteConfig.getString('bgColor')),
          child: Text(
            'Welcome, ${remoteConfig.getString('welcome')}',
            style: TextStyle(fontSize: 20),
          )),
    );
  }
}

Future<RemoteConfig> setup() async {
  final storage = FlutterSecureStorage();

  await Firebase.initializeApp();
  final fbMessaging = FirebaseMessaging.instance;

  await fbMessaging.subscribeToTopic('PUSH_RC');

  FirebaseMessaging.onMessage.listen(_foregroundHandler);
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  remoteConfig.setDefaults(<String, dynamic>{
    'welcome': 'John Doe',
    'bgColor': 'red100',
  });

  final shouldFetchOnStartup =
      (await storage.read(key: 'RC_CACHE_FORCED_STALE')) == 'true';

  if (shouldFetchOnStartup) {
    await _fetchRemoteConfig(remoteConfig, storage, expiration: now);
  }

  await _fetchRemoteConfig(remoteConfig, storage);

  await remoteConfig.activateFetched();

  return remoteConfig;
}

Future _fetchRemoteConfig(RemoteConfig remoteConfig, FlutterSecureStorage storage,
    {Duration expiration = defaultExpirationTime}) async {
  try {
    await remoteConfig.fetch(expiration: expiration);
    await remoteConfig.activateFetched();
    storage.write(key: 'RC_CACHE_FORCED_STALE', value: 'false');
  } on FetchThrottledException catch (exception) {
    print(exception);
  } catch (exception) {
    print('Unable to fetch remote config. Cached or default values'
        ' will be used');
  }
}

Color _bgColor(String remoteConfigBgColor) {
  if (remoteConfigBgColor == 'red100') {
    return Colors.red[100];
  } else if (remoteConfigBgColor == 'blue100') {
    return Colors.blue[100];
  } else if (remoteConfigBgColor == 'green100') {
    return Colors.green[100];
  }
  return Colors.white;
}

Future _foregroundHandler(RemoteMessage msg) async {
  print('I received a FOREGROUND FCM message');

  final storage = FlutterSecureStorage();

  if (msg.data.containsKey('CONFIG_STATE')) {
    final before = await storage.read(key: 'RC_CACHE_FORCED_STALE');

    print('before.. the value is $before');

    await storage.write(key: 'RC_CACHE_FORCED_STALE', value: 'true');

    final after = await storage.read(key: 'RC_CACHE_FORCED_STALE');

    print('after.. the value is $after');
  }
}

Future<void> _bgHandler(RemoteMessage msg) async {
  print('I received a BACKGROUND FCM message');

  final storage = FlutterSecureStorage();

  if (msg.data.containsKey('CONFIG_STATE')) {
    final before = await storage.read(key: 'RC_CACHE_FORCED_STALE');

    print('before do BG.. the value is $before');

    await storage.write(key: 'RC_CACHE_FORCED_STALE', value: 'true');

    final after = await storage.read(key: 'RC_CACHE_FORCED_STALE');

    print('after do BG.. the value is $after');
  }
}
