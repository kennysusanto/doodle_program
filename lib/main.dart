import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'Doodle',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doodle v1.1'),
      ),
      body: Center(
          child: IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(DoodleHandlerRoute());
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 24),
                    ),
                  )),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(SettingsPageRoute());
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: const Text(
                      'Settings',
                      style: TextStyle(fontSize: 24),
                    ),
                  )),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(KeywordsPageRoute());
                  },
                  child: Container(
                      padding: EdgeInsets.all(15),
                      child: const Text(
                        'Show Keywords',
                        style: TextStyle(fontSize: 24),
                      ))),
            )
          ],
        ),
      )),
    );
  }
}
