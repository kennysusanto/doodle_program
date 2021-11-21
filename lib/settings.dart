import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String roundsValue = globals.numRounds.toString();
  String timerValue = globals.timerTime.toString();
  String downloadFolderPath = '/storage/emulated/0/Download/';
  // Directory dir = Directory('/storage/emulated/0/Download');

  final String _fileUrlKeywords =
      "https://github.com/kennysusanto/doodle/raw/main/keywords.txt";
  final String _fileUrlH5Model =
      "https://github.com/kennysusanto/doodle/raw/main/my_h5_model.h5";
  final String _fileUrlTfliteModel =
      "https://github.com/kennysusanto/doodle/raw/main/my_tflite_model.tflite";
  // final String _fileUrlLabel = "https://github.com/kennysusanto/doodle/raw/main/labels.txt";
  final String _fileUrlLabel =
      "https://raw.githubusercontent.com/kennysusanto/doodle/main/labels.txt";

  final String _fileUrlLabel2 =
      "https://raw.githubusercontent.com/kennysusanto/doodle/main/labels2.txt";

  String _progress = "-";

  // Future<Directory?> _getDownloadDirectory() async {
  //   if (Platform.isAndroid) {
  //     return await DownloadsPathProvider.downloadsDirectory;
  //   }

  //   // in this example we are using only Android and iOS so I can assume
  //   // that you are not trying it for other platforms and the if statement
  //   // for iOS is unnecessary

  //   // iOS directory visible to user
  //   // return await getApplicationDocumentsDirectory();
  // }

  // Future<String> _getPathToDownload() async {
  //   return ExtStorage.getExternalStoragePublicDirectory(
  //       ExtStorage.DIRECTORY_DOWNLOADS);
  // }

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      setState(() {
        _progress = 'Downloading ${id.toString()} ... ${progress.toString()}';
      });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  void _download2(String url) async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      print('Starting download $url');
      final externalDir = await getExternalStorageDirectory();

      final id = await FlutterDownloader.enqueue(
        url: url,
        savedDir: externalDir!.path,
        showNotification: true,
        openFileFromNotification: true,
      );
      // print('Downloading $id...');
    } else {
      print('Permission Denied');
    }
  }

  // Future<bool> _requestPermissions() async {
  //   var permission = Permission.storage;
  //   if (await permission.isDenied) {
  //     await permission.request();
  //   }
  //   return permission.isGranted;
  // }

  // Future<void> _download() async {
  //   // final dir = await _getPathToDownload();
  //   Directory dir = Directory('/storage/emulated/0/Download');
  //   final isPermissionStatusGranted = await _requestPermissions();

  //   if (isPermissionStatusGranted) {
  //     final savePath = path.join(dir.path, _fileName);
  //     await _startDownload(savePath);
  //   } else {
  //     // handle the scenario when user declines the permissions
  //   }
  // }

  // final Dio _dio = Dio();

  // Future<void> _startDownload(String savePath) async {
  //   Map<String, dynamic> result = {
  //     'isSuccess': false,
  //     'filePath': null,
  //     'error': null,
  //   };

  //   try {
  //     final result = await InternetAddress.lookup('example.com');
  //     if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
  //       print('connected');
  //     }
  //   } on SocketException catch (_) {
  //     print('not connected');
  //   }

  //   try {
  //     print("DOWNLOADING");
  //     final response = await _dio.download(_fileUrl, savePath,
  //         onReceiveProgress: _onReceiveProgress);
  //     result['isSuccess'] = response.statusCode == 200;
  //     result['filePath'] = savePath;
  //   } catch (ex) {
  //     result['error'] = ex.toString();
  //   } finally {
  //     print(result);
  //     // await _showNotification(result);
  //   }
  // }

  // void _onReceiveProgress(int received, int total) {
  //   if (total != -1) {
  //     setState(() {
  //       _progress = (received / total * 100).toStringAsFixed(0) + "%";
  //       print(_progress);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Rounds:'),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: DropdownButton<String>(
                  value: roundsValue,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 16,
                  onChanged: (String? newValue) {
                    setState(() {
                      roundsValue = newValue!;
                    });
                  },
                  items: <String>['3', '5', '7']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Timer:'),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: DropdownButton<String>(
                  value: timerValue,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 16,
                  onChanged: (String? newValue) {
                    setState(() {
                      timerValue = newValue!;
                    });
                  },
                  items: <String>['10', '20', '30', '40', '50', '60']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // ElevatedButton(
          //   onPressed: () async {
          //     final taskIdKeywords = await FlutterDownloader.enqueue(
          //       url:
          //           'https://github.com/kennysusanto/doodle/raw/main/keywords.txt',
          //       savedDir: downloadFolderPath,
          //       showNotification:
          //           true, // show download progress in status bar (for Android)
          //       openFileFromNotification:
          //           false, // click on notification to open downloaded file (for Android)
          //     );

          //     final taskIdAIModel = await FlutterDownloader.enqueue(
          //       url:
          //           'https://github.com/kennysusanto/doodle/raw/main/my_h5_model.h5',
          //       savedDir: downloadFolderPath,
          //       showNotification:
          //           true, // show download progress in status bar (for Android)
          //       openFileFromNotification:
          //           false, // click on notification to open downloa ded file (for Android)
          //     );
          //   },
          //   child: Text('Update AI Model & Keywords'),
          // ),
          ElevatedButton(
            onPressed: () async {
              //_download();
              _download2(_fileUrlKeywords);
              _download2(_fileUrlH5Model);
              _download2(_fileUrlTfliteModel);
              _download2(_fileUrlLabel);
              _download2(_fileUrlLabel2);
            },
            child: Text('Update AI Model & Keywords'),
          ),
          Text(_progress),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel')),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        roundsValue = '3';
                        timerValue = '20';
                      });
                    },
                    child: Text('Reset')),
              ),
              Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  child: ElevatedButton(
                      onPressed: () {
                        switch (roundsValue) {
                          case '3':
                            globals.numRounds = 3;
                            break;
                          case '5':
                            globals.numRounds = 5;
                            break;
                          case '7':
                            globals.numRounds = 7;
                            break;
                        }

                        switch (timerValue) {
                          case '10':
                            globals.timerTime = 10;
                            break;
                          case '20':
                            globals.timerTime = 20;
                            break;
                          case '30':
                            globals.timerTime = 30;
                            break;
                          case '40':
                            globals.timerTime = 40;
                            break;
                          case '50':
                            globals.timerTime = 50;
                            break;
                          case '60':
                            globals.timerTime = 60;
                            break;
                        }

                        Navigator.of(context).pop();
                      },
                      child: Text('Save'))),
            ],
          )
        ],
      ),
    ));
  }
}
