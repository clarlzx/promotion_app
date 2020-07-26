import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<String> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
  await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final AuthResult authResult = await _auth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  await Firestore.instance.collection('all_users').document(user.uid).get()
      .then((docSnapshot) async {
        if (!docSnapshot.exists) {
          await Firestore.instance.collection('all_users').document(user.uid).setData({
            'clickedBefore' : [],
            'disliked_promotions' : [],
            'liked_promotions': [],
            'saved_promotion': []
          });
        }
  });

  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  return user.uid;
}

void signOutGoogle() async{
  await googleSignIn.signOut();

  print("User Sign Out");
}