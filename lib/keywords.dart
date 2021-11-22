import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class KeywordsPage extends StatefulWidget {
  const KeywordsPage({Key? key}) : super(key: key);

  @override
  _KeywordsPageState createState() => _KeywordsPageState();
}

class _KeywordsPageState extends State<KeywordsPage> {
  List _keywords = [];

  @override
  void initState() {
    super.initState();
    loadKeywords();
  }

  void loadKeywords() async {
// load keywords and h5 model
    final _downloadsFolder = await getExternalStorageDirectory();
    File _keywordsFile = File(_downloadsFolder!.path + '/keywords.txt');
    Stream<String> lines3 = _keywordsFile
        .openRead()
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(LineSplitter()); // Convert stream to individual lines.
    try {
      await for (var line in lines3) {
        // print('$line: ${line.length} characters');
        _keywords.add(line);
      }
      print('File is now closed.');
    } catch (e) {
      print('Error: $e');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
                itemCount: _keywords.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(_keywords[index]),
                          duration: const Duration(milliseconds: 100),
                        ));
                      },
                      child: Card(
                        key: UniqueKey(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(_keywords[index]),
                        ),
                      ));
                })));
  }
}
