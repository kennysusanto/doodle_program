import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:doodle/globals.dart' as globals;

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
    final _keywordsString = await loadKeywordFile();
    _keywords = _keywordsString.split("\n");
    setState(() {});
  }

  Future<String> loadKeywordFile() async {
    return await rootBundle.loadString('assets/keywords.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Keywords'),
        ),
        backgroundColor: globals.bgColor,
        body: Container(
            padding: const EdgeInsets.all(10),
            child: GridView.count(
              childAspectRatio: 1.5,
              crossAxisCount: 4,
              children: List.generate(_keywords.length, (index) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(globals.borderRad),
                      side: BorderSide(color: globals.themeColor)),
                  color: globals.themeColor,
                  key: UniqueKey(),
                  child: InkWell(
                    splashColor: globals.themeColorDarker,
                    borderRadius: BorderRadius.circular(globals.borderRad),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(_keywords[index]),
                        duration: const Duration(milliseconds: 100),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _keywords[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              }),
            )));
  }
}
