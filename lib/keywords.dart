import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;

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
