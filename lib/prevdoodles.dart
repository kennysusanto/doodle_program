import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:doodle/globals.dart' as globals;
import 'dart:convert';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'firebase_options.dart';

class PreviousDoodlesPage extends StatefulWidget {
  final String userEmail;
  const PreviousDoodlesPage({Key? key, required this.userEmail})
      : super(key: key);

  @override
  _PreviousDoodlesPageState createState() => _PreviousDoodlesPageState();
}

class _PreviousDoodlesPageState extends State<PreviousDoodlesPage> {
  late FirebaseDatabase database;
  String _content = '';
  List _doodleMaster = [];

  @override
  void initState() {
    super.initState();
    initFirebaseConn();
  }

  void initFirebaseConn() async {
    bool exists = false;
    String firebaseAppName = 'fb_prevdoodle';
    for (FirebaseApp fba in Firebase.apps) {
      if (fba.name == firebaseAppName) {
        exists = true;
      }
    }
    if (!exists) {
      FirebaseApp fbapp = await Firebase.initializeApp(
          name: firebaseAppName,
          options: DefaultFirebaseOptions.currentPlatform);
      // print('$b ${b.name} ${b.options}');
      database = FirebaseDatabase.instanceFor(app: fbapp);
    } else {
      FirebaseApp fbapp = Firebase.app(firebaseAppName);
      database = FirebaseDatabase.instanceFor(app: fbapp);
    }

    DatabaseReference ref = database.ref('doodleMaster');
    Query query = ref.orderByChild('user_email').equalTo(widget.userEmail);
    // DatabaseEvent event = await ref.once();
    DatabaseEvent event = await query.once();
    setState(() {
      _content = event.snapshot.value.toString();
      // var jsonContent = jsonDecode(_content);
      for (DataSnapshot d in event.snapshot.children) {
        String datetime = d.child('datetime').value.toString();
        String userEmail = d.child('user_email').value.toString();
        String doodles = d.child('doodles').value.toString();
        Map<String, dynamic> j = jsonDecode(
            '{"user_email": "$userEmail", "datetime": "$datetime", "doodles": $doodles}');
        // var json = jsonDecode(d.value.toString());
        _doodleMaster.add(j);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Data fetched: ${_doodleMaster.length.toString()}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Previous Doodles'),
        ),
        backgroundColor: globals.bgColor,
        // body list view
        body: Container(
          margin: const EdgeInsets.all(8),
          child: StaggeredGridView.countBuilder(
              crossAxisCount: 4,
              itemCount: _doodleMaster.length,
              itemBuilder: (context, i) {
                var match = _doodleMaster[i];
                return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(globals.borderRad),
                        side: BorderSide(color: globals.themeColor)),
                    color: globals.themeColor,
                    child: InkWell(
                        splashColor: globals.themeColorDarker,
                        borderRadius: BorderRadius.circular(globals.borderRad),
                        onTap: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(''),
                            duration: Duration(milliseconds: 100),
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(match['user_email']),
                              Text(match['datetime']),
                              Text(match['doodles'].length.toString()),
                              Column(
                                children: List.generate(match['doodles'].length,
                                    (index) {
                                  var child = match['doodles'][index];
                                  return Text('${child['keyword']}');
                                }),
                              )
                            ],
                          ),
                        )));
              },
              staggeredTileBuilder: (i) => const StaggeredTile.fit(1)),
        ));
  }
}
