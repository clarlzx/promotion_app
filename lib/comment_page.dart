import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:promotionapp/main.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:toast/toast.dart';
import 'package:timeago/timeago.dart' as tAgo;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

String currentuserid;
String currenturl;

class Comment extends StatelessWidget {
  final String url;
  final String promotitle;
  final String userid;
  final String comment;
  final Timestamp timestamp;

  SlidableController slidableController = SlidableController();

  Comment(
      {this.url, this.promotitle, this.userid, this.comment, this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot documentSnapshot) {
    return Comment(
      promotitle: documentSnapshot['promotitle'],
      userid: documentSnapshot['userid'],
      comment: documentSnapshot['comment'],
      timestamp: documentSnapshot['timestamp'],
      url: documentSnapshot['url'],
    );
  }

  deletecomment() {
    Firestore.instance
        .collection("web_promotion")
        .document(promotitle)
        .collection("comments")
        .where("comment", isEqualTo: comment)
        .where("userid", isEqualTo: userid)
        .where("timestamp", isEqualTo: timestamp)
        .getDocuments()
        .then((snapshot) {
      snapshot.documents.first.reference.delete();
    });
  }

  Widget commentwithdelete() {
    print(url);
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Card(
              child: Slidable(
                actionPane: SlidableDrawerActionPane(),
                secondaryActions: <Widget>[
                  IconSlideAction(
                    caption: "Delete",
                    icon: Icons.delete,
                    color: Colors.green[700],
                    onTap: () {
                      deletecomment();
                    },
                  )
                ],
                child: ListTile(
                  leading: CircleAvatar(radius: 30.0, backgroundImage: NetworkImage(url)),
                  title: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: userid + "\n",
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[600])),
                        TextSpan(
                            text: comment,
                            style:
                                TextStyle(fontSize: 16.0, color: Colors.black)),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    tAgo.format(timestamp.toDate()),
                    style: TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget commentwithoutdelete() {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Card(
              child: ListTile(
                title: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text: userid + "\n",
                          style: TextStyle(
                              fontSize: 14.0, color: Colors.grey[600])),
                      TextSpan(
                          text: comment,
                          style:
                              TextStyle(fontSize: 16.0, color: Colors.black)),
                    ],
                  ),
                ),
                subtitle: Text(
                  tAgo.format(timestamp.toDate()),
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userid == currentuserid) {
      return commentwithdelete();
    } else {
      return commentwithoutdelete();
    }
  }
}

class CommentPage extends StatefulWidget {
  String promotitle;
  String userid;

  CommentPage(String promotitle, String userid) {
    this.promotitle = promotitle;
    this.userid = userid;
  }

  @override
  CommentPageState createState() => new CommentPageState(promotitle, userid);
}

class CommentPageState extends State<CommentPage> {
  final filter = ProfanityFilter();
  String promotitle;
  String userid;

  CommentPageState(String promotitle, String userid) {
    this.promotitle = promotitle;
    this.userid = userid;
  }

  displayComments() {
    print("current user:" + currentuserid);
    return StreamBuilder(
      stream: Firestore.instance
          .collection("web_promotion")
          .document(promotitle)
          .collection("comments")
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return CircularProgressIndicator();
        }
        List<Comment> comments = [];
        dataSnapshot.data.documents.forEach((document) {
          comments.add(Comment.fromDocument(document));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  saveComment(String comment) {
    Firestore.instance
        .collection("web_promotion")
        .document(promotitle)
        .collection("comments")
        .add({
      "promotitle": promotitle,
      "userid": currentuserid,
      "comment": comment,
      "timestamp": DateTime.now(),
      "url": currenturl,
    });
//    commentTextEditingController.clear();
  }

  getcurrentuser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser user = await auth.currentUser();
    String username = user.displayName;
    String url = user.photoUrl;
    setState(() {
      if (username.contains(" ")) {
        currentuserid = username.substring(0, username.indexOf(" "));
        currenturl = url;
      } else {
        currentuserid = username;
        currenturl = url;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getcurrentuser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title: Text("Comments"), backgroundColor: Colors.black,),
      body: Column(
        children: <Widget>[
          Expanded(child: displayComments()),
          Divider(),
          TextField(
              onSubmitted: (String comment) {
                if (filter.checkStringForProfanity(comment)) {
                  Toast.show(
                      "Please make sure your comment does not contain any profanities.",
                      context,
                      duration: Toast.LENGTH_LONG,
                      gravity: Toast.BOTTOM);
                } else {
                  saveComment(comment);
                }
              },
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(20.0),
                hintText: "Add comment here",
                hintStyle: TextStyle(color: Colors.grey),
              ))
        ],
      ),
    );
  }
}
