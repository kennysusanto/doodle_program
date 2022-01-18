import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'routes.dart';
import 'package:doodle/globals.dart' as globals;
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          primarySwatch: createMaterialColor(globals.themeColor),
          fontFamily: 'Roboto'),
      home: const MainMenu(),
    );
  }
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  UserCredential? _currentUser;
  String pappName = '';
  String ppackageName = '';
  String pversion = '';
  String pbuildNumber = '';
  // late FirebaseApp fbapp;

  @override
  void initState() {
    super.initState();
    initFirebase();
    initGoogleSignIn();
    checkInternet();
    loadAppInfo();
  }

  void initFirebase() async {
    bool exists = false;
    String firebaseAppName = 'fb_main';
    for (FirebaseApp fba in Firebase.apps) {
      if (fba.name == firebaseAppName) {
        exists = true;
      }
    }
    if (!exists) {
      await Firebase.initializeApp(
          name: firebaseAppName,
          // options: DefaultFirebaseOptions.currentPlatform);
          options: globals.firebaseConfig);
    } else {
      Firebase.app(firebaseAppName);
    }
  }

  void initGoogleSignIn() async {
    // FirebaseAuth auth = FirebaseAuth.instanceFor(app: fbapp);
    _currentUser = await signInWithGoogle();
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_currentUser!.user!.email!),
      duration: const Duration(milliseconds: 100),
    ));
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: [
      // 'email',
      // 'https://www.googleapis.com/auth/contacts.readonly',
      // 'https://www.googleapis.com/auth/user.emails.read'
    ]).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  void checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // print('connected');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Internet connection established!'),
          duration: Duration(milliseconds: 1000),
        ));
      }
    } on SocketException catch (_) {
      // print('not connected');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No internet connection detected!'),
        duration: Duration(milliseconds: 1000),
      ));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Some features may not appear correctly...'),
        duration: Duration(milliseconds: 1000),
      ));
    }
  }

  void loadAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      pappName = packageInfo.appName;
      ppackageName = packageInfo.packageName;
      pversion = packageInfo.version;
      pbuildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globals.bgColor,
      appBar: AppBar(
        title: Text('$pappName v$pversion'),
      ),
      body: Center(
          child: IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              child: ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(globals.borderRad),
                              side: BorderSide(color: globals.themeColor)))),
                  onPressed: () {
                    if (_currentUser != null) {
                      Navigator.of(context).push(DoodleHandlerRoute(
                          userEmail: _currentUser!.user!.email!));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please log in'),
                        duration: Duration(seconds: 1),
                      ));
                      initGoogleSignIn();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(globals.buttonPad),
                    child: Text(
                      'New Game',
                      style: TextStyle(fontSize: globals.buttonFontSize),
                    ),
                  )),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(globals.borderRad),
                              side: BorderSide(color: globals.themeColor)))),
                  onPressed: () {
                    Navigator.of(context).push(SettingsPageRoute());
                  },
                  child: Container(
                    padding: EdgeInsets.all(globals.buttonPad),
                    child: Text(
                      'Settings',
                      style: TextStyle(fontSize: globals.buttonFontSize),
                    ),
                  )),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(globals.borderRad),
                              side: BorderSide(color: globals.themeColor)))),
                  onPressed: () {
                    Navigator.of(context).push(KeywordsPageRoute());
                  },
                  child: Container(
                      padding: EdgeInsets.all(globals.buttonPad),
                      child: Text(
                        'Show Keywords',
                        style: TextStyle(fontSize: globals.buttonFontSize),
                      ))),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(globals.borderRad),
                              side: BorderSide(color: globals.themeColor)))),
                  onPressed: () {
                    if (_currentUser != null) {
                      Navigator.of(context).push(PreviousDoodlesRoute(
                          userEmail: _currentUser!.user!.email!));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please log in'),
                        duration: Duration(seconds: 1),
                      ));
                      initGoogleSignIn();
                    }
                  },
                  child: Container(
                      padding: EdgeInsets.all(globals.buttonPad),
                      child: Text(
                        'Previous Doodles',
                        style: TextStyle(fontSize: globals.buttonFontSize),
                      ))),
            ),
            Container(
                margin: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentUser != null
                          ? 'logged in as: ${_currentUser!.user!.email}'
                          : 'Please log in',
                      style: const TextStyle(fontSize: 8),
                    ),
                    OutlinedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(globals.borderRad),
                              side: BorderSide(
                                color: globals.themeColor,
                              ),
                            )),
                            side: MaterialStateProperty.all(
                                BorderSide(color: globals.themeColor))),
                        onPressed: () async {
                          if (_currentUser != null) {
                            // _currentUser!.user!.delete();
                            await FirebaseAuth.instance.signOut();
                            GoogleSignIn().disconnect();
                            _currentUser = null;
                            setState(() {});
                          } else {
                            initGoogleSignIn();
                          }
                        },
                        child: Text(_currentUser != null ? 'Logout' : 'Login'))
                  ],
                ))
          ],
        ),
      )),
    );
  }
}
