import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:promotionapp/home.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:toast/toast.dart';

class CommentPage extends StatefulWidget {
  String promoid;

  CommentPage(String promoid) {
    this.promoid = promoid;
  }

  @override
  CommentPageState createState() => new CommentPageState(promoid);
}

class CommentPageState extends State<CommentPage> {
  final filter = ProfanityFilter();
  String promoid;

  CommentPageState(String promoid) {
    this.promoid = promoid;
  }

  List<String> comments = [];

  @override
  void initState() {
    super.initState();
    findcomments();
  }

  void findcomments() async {
    List<String> currcomments = new List();
    final DocumentSnapshot snapShot = await Firestore.instance
        .collection('all_promotions')
        .document(promoid)
        .get();
    for (int i = 0; i < snapShot.data['comments'].length; i++) {
      currcomments.add(snapShot.data['comments'][i]);
    }
    setState(() {
      comments = currcomments;
      print(comments);
    });
  }

  void addcomment(String comment) {
      setState(() {
        comments.add(comment);
      });
  }

  Widget _buildcommentlist() {
    return ListView.builder(itemBuilder: (context, index) {
      if (index < comments.length) {
        return _buildcommentitem(comments[index]);
      }
    });
  }

  Widget _buildcommentitem(String comment) {
    return Card(
      child: ListTile(
        title: Text(
          comment,
          style: TextStyle(color: Colors.black),
        ),
      ),
      color: Colors.white,
    );
  }

  void addtodatabase(String comment) async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('all_promotions')
        .document(promoid).get();
    List l1 = ds.data['comments'];
    l1.add(comment);
    Firestore.instance
        .collection('all_promotions')
        .document(promoid)
        .updateData({
      'comments': l1
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: new AppBar(
          title: Text('Comments'),
        ),
        body: Column(children: <Widget>[
          Expanded(child: _buildcommentlist()),
          TextField(
            onSubmitted: (String comment) {
              if (filter.checkStringForProfanity(comment)) {
                Toast.show("Please make sure your comment does not contain any profanities.", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
              }
              else {
                addtodatabase(comment);
                addcomment(comment);
              }
            },
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(20.0),
              hintText: "Add comment here",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          )
        ]));
  }
}
