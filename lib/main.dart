// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();
  runApp(const MyApp());
}

int count = 0;
int playCount = 0;
String url =
    'https://www.mediacollege.com/downloads/sound-effects/beep/beep-01.wav';
final audioPlayer = AudioPlayer();
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  WidgetsFlutterBinding.ensureInitialized();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    audioPlayer.onPlayerComplete.listen((event) {
      Map<String, dynamic> dataToSend = {'count': count++};

      service.invoke('update', dataToSend);

      // debugPrint(dataToSend.toString());

      audioPlayer.play(UrlSource(url));
    });
    audioPlayer.play(UrlSource(url));
  }

  // service.invoke(
  //   'update',
  //   {
  //     "current_date": DateTime.now().toIso8601String(),
  //   },
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isRunning = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final service = FlutterBackgroundService();
          var isRunning2 = await service.isRunning();

          if (isRunning2) {
            service.invoke("stopService");

            setState(() {
              isRunning2 = false;
              isRunning = false;
            });
          } else {
            FlutterBackgroundService().startService();
            setState(() {
              isRunning2 = true;
              isRunning = true;
            });
          }
        },
        child: Icon(isRunning ? Icons.stop : Icons.play_arrow),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().on('update'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!;
                var device = data["count"];

                String a = device.toString();
                return Column(
                  children: [
                    Text(a),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
