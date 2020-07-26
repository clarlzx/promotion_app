import 'package:flutter/material.dart';
import 'package:promotionapp/searchbar.dart';
import 'package:promotionapp/sign_in.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override

  Future<bool> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Do you really want to exit the app?", style: TextStyle(color: Colors.black),),
          actions: <Widget>[
            FlatButton(
              child: Text("No", style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.pop(context, false),
            ),
            FlatButton(
              child: Text("Yes", style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.pop(context, true),
            )
          ],
        )
    );
  }

  Widget build(BuildContext context) {
    return WillPopScope(
    onWillPop: _onBackPressed,
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(image: AssetImage("assets/officialLogo.png"), height: 360.0), //will be where our official logo will be
                SizedBox(height: 20),
                _signInButton(),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {
        signInWithGoogle().then((String userid) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) {
                return MyApp(bloc: PromotionBloc(), userid: userid);
              },
            ),
          );
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/google_logo.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
