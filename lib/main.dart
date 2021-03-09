import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

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
      // floatingActionButton: FloatingActionButton(
      //     child: const Icon(Icons.refresh),
      //     onPressed: () async {
      //       try {
      //         print('I got inside the fab onTap');
      //         var sp = await SharedPreferences.getInstance();

      //         Duration exp = defaultExpirationTime;

      //         var forcedFetch = sp.getBool('RC_CACHE_FORCED_STALE') ?? false;
      //         if (forcedFetch) {
      //           exp = Duration(seconds: 0);
      //           sp.setBool('RC_CACHE_FORCED_STALE', false);
      //         }

      //         print('the used exp is $exp');

      //         await remoteConfig.fetch(expiration: exp);
      //         await remoteConfig.activateFetched();
      //       } on FetchThrottledException catch (exception) {
      //         // Fetch throttled.
      //         print(exception);
      //       } catch (exception) {
      //         print(exception);
      //         print('Unable to fetch remote config. Cached or default values'
      //             ' will be used');
      //       }
      //     }),
    );
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

Future _msgHandler(Map<String, dynamic> message) async {
  var rc = await RemoteConfig.instance;
  if (message['data'].containsKey('CONFIG_STATE')) {
    print('I received a foreground FCM message');
    _fetchRemoteConfig(rc, expiration: Duration(seconds: 0));
  }
}

Future _backgroundMsgHandler(Map<String, dynamic> message) async {
  var rc = await RemoteConfig.instance;
  if (message['data'].containsKey('CONFIG_STATE')) {
    print('I received a background FCM message');
    _fetchRemoteConfig(rc, expiration: Duration(seconds: 0));
  }
}

Future<RemoteConfig> setup() async {
  await Firebase.initializeApp();
  var fbMessaging = FirebaseMessaging();

  await fbMessaging.subscribeToTopic('PUSH_RC');

  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  remoteConfig.setDefaults(<String, dynamic>{
    'welcome': 'John Doe',
    'bgColor': 'red100',
  });

  _fetchRemoteConfig(remoteConfig);

  fbMessaging.configure(
    onMessage: _msgHandler,
    onBackgroundMessage: _backgroundMsgHandler,
  );

  return remoteConfig;
}

_fetchRemoteConfig(RemoteConfig remoteConfig,
    {Duration expiration = defaultExpirationTime}) async {
  try {
    await remoteConfig.fetch(expiration: expiration);
    await remoteConfig.activateFetched();
  } on FetchThrottledException catch (exception) {
    print(exception);
  } catch (exception) {
    print('Unable to fetch remote config. Cached or default values'
        ' will be used');
  }
}
