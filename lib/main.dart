import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foreground_test2/event_service.dart';
import 'package:foreground_test2/foreground_service.dart';
import 'package:foreground_test2/my_shared_preferences.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await MySharedPreferences.init();
  await ForegroundService.init();
  runApp(const MyHome());
}

class MyHome extends StatefulWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  Widget build(BuildContext context) {
     return const MaterialApp(
       home: Scaffold(
         body: Main(),
       ),
     );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<Main> {
  static const dataChannel = EventChannel('foreground/event');

  static Stream<String> get dataStream {
    return dataChannel.receiveBroadcastStream().cast();
  }

  @override
  void dispose() {
    EventService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Expanded(child: SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    await ForegroundService.setEnabled(true);
                  },
                  child: const Text('포그라운드 서비스 활성화'),
                ),
                TextButton(
                  onPressed: () {
                    EventService.instance.start();
                  },
                  child: const Text('서비스 시작'),
                ),
                TextButton(
                  onPressed: () async {
                    EventService.instance.stop();
                    await MySharedPreferences.setServiceEnabled(false);
                    await ForegroundService.stopService();
                  },
                  child: const Text('서비스 종료'),
                ),
              ],
            ),
          ),),
          Expanded(
            flex: 5,
            child: SizedBox(
            child: StreamBuilder(
              stream: dataStream,
              builder: (context, snapshot) {
                if(snapshot.hasData) {
                  return Center(child: Text('${snapshot.data}'));
                } else {
                  return const Center(child: Text('no data'));
                }
              },
            ),
          ),),
        ],
      )
    );
  }
}