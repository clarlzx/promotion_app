import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:promotionapp/calendar.dart';
import 'package:flutter/painting.dart';
import 'package:rxdart/rxdart.dart';
import 'searchbar.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'filter.dart';
import 'filterpage.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:promotionapp/comment_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:toast/toast.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class MyApp extends StatelessWidget {
  final PromotionBloc bloc;
  final String userid;

  MyApp({Key key, this.bloc, this.userid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Promotions',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],

        // Define the default font family
        // fontFamily: 'Roboto',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
      ),
      home: MyHomePage(bloc: bloc, userid: userid),
      routes: {
        '/promoDetails': (context) => ExtractPromoDetails(userid),
        '/filterPage': (context) => ExtractFilterPromotion(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final PromotionBloc bloc;
  final String userid;

  MyHomePage({Key key, this.bloc, this.userid}) : super(key: key);

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings androidInitializationSettings;
  IOSInitializationSettings iosInitializationSettings;
  InitializationSettings initializationSettings;

  void _showstartNotification(
      String promoid, String title, DateTime date) async {
    await startnotification(promoid, title, date);
  }

  void _showendNotification(
      String promoid, String title, DateTime date) async {
    await endnotification(promoid, title, date);
  }

  Future<void> endnotification(
      String promoid, String title, DateTime date) async {
    DateTime datetime = date.add(new Duration(hours: 22, minutes: 10));
    print(datetime.toString());
    AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        'Channel_ID', 'Channel_title', 'Channel_body',
        priority: Priority.High,
        importance: Importance.Max,
        ticker: 'ticker');
    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
    NotificationDetails(androidNotificationDetails, iosNotificationDetails);
    await flutterLocalNotificationsPlugin.schedule(
        promoid.hashCode,
        "Last day for this awesome promotion!",
        title,
        datetime,
        notificationDetails,
        payload: promoid);
  }

  Future<void> startnotification(
      String promoid, String title, DateTime date) async {
    DateTime datetime = date.add(new Duration(hours: 22, minutes: 10));
    print(datetime.toString());
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'Channel_ID', 'Channel_title', 'Channel_body',
            priority: Priority.High,
            importance: Importance.Max,
            ticker: 'ticker');
    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(androidNotificationDetails, iosNotificationDetails);
    await flutterLocalNotificationsPlugin.schedule(
        promoid.hashCode,
        "Don't miss this awesome promotion!",
        title,
        datetime,
        notificationDetails,
        payload: promoid);
  }

  void _deleteNotification(String promoid) async {
    await deletenotification(promoid);
  }

  Future<void> deletenotification(String promoid) async {
    await flutterLocalNotificationsPlugin.cancel(promoid.hashCode);
  }

  Future onSelectNotification(String payLoad) async {
    final DocumentSnapshot ds = await Firestore.instance
        .collection('all_promotions')
        .document(payLoad)
        .get();
    final DocumentSnapshot ds1 = await Firestore.instance
        .collection('all_companies')
        .document(ds.data['company'])
        .get();
    if (payLoad != null) {
      print(payLoad);
    }
    await Navigator.pushNamed(context, '/promoDetails',
        arguments: new Promotion(
            ds.data['title'],
            new Company(ds1.data['company'], ds1.data['name'],
                ds1.data['locations'], ds1.data['logoURL']),
            ds.data['start_date'],
            ds.data['end_date'],
            ds.data['item_type'],
            payLoad));
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payLoad) async {
    final DocumentSnapshot ds = await Firestore.instance
        .collection('all_promotions')
        .document(payLoad)
        .get();
    final DocumentSnapshot ds1 = await Firestore.instance
        .collection('all_companies')
        .document(ds.data['company'])
        .get();
    return showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pushNamed(context, '/promoDetails',
                          arguments: new Promotion(
                              ds.data['title'],
                              new Company(ds1.data['company'], ds1.data['name'],
                                  ds1.data['locations'], ds1.data['logoURL']),
                              ds.data['start_date'],
                              ds.data['end_date'],
                              ds.data['item_type'],
                              payLoad));
                    },
                    child: Text("okay"))
              ],
            ));
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Icon customIcon = Icon(Icons.search, color: Colors.white);
  Widget customWidget = Text('View Promotions');

  @override
  void initState() {
    super.initState();
    initializing();
  }

  void initializing() async {
    androidInitializationSettings = AndroidInitializationSettings('app_icon');
    iosInitializationSettings = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = InitializationSettings(
        androidInitializationSettings, iosInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  @override
  Widget build(BuildContext context) {
    Widget mainWidget = AppBar(
      title: customWidget,
      actions: <Widget>[
        IconButton(
          onPressed: () {
            showSearch(
                context: context,
                delegate: PromotionSearch(widget.bloc.promotions));
//FOR A SEARCH BAR THAT DOES NOT NAVIGATE TO A NEW PAGE
//            setState(() {
//              if (this.customIcon.icon == Icons.search) {
//                this.customIcon = Icon(Icons.cancel, color: Colors.white);
//                this.customWidget = TextField(
//                  style: TextStyle(color: Colors.white),
//                  decoration: new InputDecoration(
//                    border: InputBorder.none,
//                    hintText: 'Search...',
//                    hintStyle: TextStyle(
//                        fontSize: 18.0,
//                        color: Colors.white60
//                    ),
//                  ),
//                );
//              } else {
//                this.customIcon = Icon(Icons.search, color: Colors.white);
//                this.customWidget = Text('View Promotions');
//              }
//            });
          },
          icon: customIcon,
        )
      ],
    );

    List<Widget> titles = <Widget>[
      mainWidget,
      AppBar(title: Text('Promotion Calendar'))
    ];
    List<Widget> options = <Widget>[
      _buildBody(context),
      Calendar(widget.userid)
    ];

    return Scaffold(
      appBar: titles.elementAt(_selectedIndex),
      body: options.elementAt(_selectedIndex),
      drawer: Drawer(
          child: ListView(
        children: <Widget>[
          Container(
              height: MediaQuery.of(context).size.height * 0.14,
              child: DrawerHeader(
                child: Text(
                  'Filter Promotions',
                  style: TextStyle(fontSize: 20.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                ),
              )),
          _buildFilter(context),
        ],
      )),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            title: Text('Calendar'),
          )
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey[900],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO: get actual snapshot from Cloud Firestore
    return ListView(
      padding: EdgeInsets.all(8.0),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(3.0),
        ),
        Container(
          alignment: Alignment(-0.89, 0.0),
          child: Text(
            "Hot Deals",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        Container(
          height: 200.0,
          child: _buildSection(context),
        ),
        Padding(
          padding: EdgeInsets.all(10.0),
        ),
        Container(
          alignment: Alignment(-0.89, 0.0),
          child: Text(
            "New Deals",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        Container(
          height: 200.0,
          child: _buildSection(context),
        ),
        Padding(
          padding: EdgeInsets.all(10.0),
        ),
        Container(
          alignment: Alignment(-0.89, 0.0),
          child: Text(
            "All Deals",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        Container(
          height: 200.0,
          child: _buildSection(context),
        )
      ],
    );
  }

  Widget _buildFilter(BuildContext context) {
    final Map<String, bool> checkedTypeMap = Map<String, bool>();
    final Map<String, bool> checkedCompanyMap = Map<String, bool>();
    final Map<String, bool> checkedDurationMap = Map<String, bool>();

    return Container(
        height: MediaQuery.of(context).size.height * 0.86,
        child: ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
//                border: Border.all(color: Colors.grey),
              ),
              height: 50.0,
              child: Align(
                alignment: FractionalOffset(0.09, 0.5),
                child: Text(
                  'BY CATEGORY',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            _buildTypeFilter(context, checkedTypeMap),
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Container(
              color: Colors.grey[800],
              height: 50.0,
              child: Align(
                alignment: FractionalOffset(0.09, 0.5),
                child: Text(
                  'BY COMPANY',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            _buildCompanyFilter(context, checkedCompanyMap),
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Container(
              color: Colors.grey[800],
              height: 50.0,
              child: Align(
                alignment: FractionalOffset(0.09, 0.5),
                child: Text(
                  'BY DURATION',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            _buildDurationFilter(context, checkedDurationMap),
            RaisedButton(
              color: Colors.teal[200],
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/filterPage',
                  arguments: PromotionFilter(
                    widget.bloc.promotions,
                    checkedTypeMap,
                    checkedCompanyMap,
                    checkedDurationMap,
                  ),
                );
              },
              child: Text(
                'Filter',
                style: TextStyle(color: Colors.black),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
            )
          ],
        ));
  }

  Widget _buildTypeFilter(
      BuildContext context, Map<String, bool> checkedTypeMap) {
    return StreamBuilder<UnmodifiableListView<Type>>(
        stream: widget.bloc.typesStream,
        initialData: UnmodifiableListView<Type>([]),
        builder: (context, AsyncSnapshot<UnmodifiableListView<Type>> snapshot) {
          HashMap<Type, List<Type>> typeMap = HashMap<Type, List<Type>>();

          //using child_id
          //for now excluding category mains, hence no select all function

          snapshot.data.toList().forEach((type) {
            if (!type.child_id.isEmpty) {
              typeMap[type] = type.child_id
                  .map((child_id) => snapshot.data
                      .toList()
                      .firstWhere((t) => t.id == child_id))
                  .toList();
            } else {
              checkedTypeMap[type.id] = false;
            }
          });
          return Column(
              children: snapshot.data
                  .toList()
                  .map((x) => _buildFilterListItem(x, typeMap, checkedTypeMap))
                  .toList());
        });
  }

  //very inefficient for now, because the hashmap will be repeated across each hashmap item
  Widget _buildFilterListItem(Type type, HashMap<Type, List<Type>> typeMap,
      Map<String, bool> checkedTypeMap) {
    return FilterList(
        type: type, typeMap: typeMap, checkedTypeMap: checkedTypeMap);
  }

  Widget _buildCompanyFilter(
      BuildContext context, Map<String, bool> checkedCompanyMap) {
    return ExpansionTile(
      title: Text('Companies'),
      children: <Widget>[
        StreamBuilder<UnmodifiableListView<Company>>(
            stream: widget.bloc.companyStream,
            initialData: UnmodifiableListView<Company>([]),
            builder: (context,
                AsyncSnapshot<UnmodifiableListView<Company>> snapshot) {
              snapshot.data.forEach((company) {
                checkedCompanyMap[company.id] = false;
              });

              return Column(
                children: snapshot.data
                    .toList()
                    .map((x) =>
                        _buildCompanyFilterListItem(x, checkedCompanyMap))
                    .toList(),
              );
            })
      ],
    );
  }

  Widget _buildCompanyFilterListItem(
      Company company, Map<String, bool> checkedCompanyMap) {
    return FilterCompanyList(
        company: company, checkedCompanyMap: checkedCompanyMap);
  }

  Widget _buildDurationFilter(
      BuildContext context, Map<String, bool> checkedDurationMap) {
    checkedDurationMap['Today'] = false;
    checkedDurationMap['This Week'] = false;

    return ExpansionTile(
        title: Text('Duation'),
        children: checkedDurationMap.keys
            .map((keys) => FilterDurationList(
                title: keys, checkedDurationMap: checkedDurationMap))
            .toList());
  }

  Widget _buildSection(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Promotion>>(
        stream: widget.bloc.promotions,
        initialData: UnmodifiableListView<Promotion>([]),
        builder: (context, snapshot) => ListView(
              scrollDirection: Axis.horizontal,
              children: snapshot.data.map(_buildListItem).toList(),
            ));
  }

//  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
//    return ListView(
//      scrollDirection: Axis.horizontal,
//      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
//    );
//  }

  Widget _buildListItem(Promotion promotion) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/promoDetails',
          arguments: promotion,
        );
      },
      child: Padding(
        key: ValueKey(promotion.title),
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 8.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Container(
              width: 140.0,
              height: 183.0,
              child: Column(children: <Widget>[
                Container(
                  height: 140.0,
                  width: 140.0,
                  decoration: new BoxDecoration(
                      image: DecorationImage(
                    image: NetworkImage(promotion.company.logoURL),
                    fit: BoxFit.fill,
                  )),
                ),
//                  FutureBuilder(
//                    future: promotion.company.getLogoUrl(),
//                    initialData: "",
//                    builder: (BuildContext context, AsyncSnapshot<String> text) {
//                      return new Container(
//                        height: 140.0,
//                        width: 140.0,
//                        decoration: new BoxDecoration(
//                          image: DecorationImage(
//                            image: NetworkImage(text.data),
//                            fit: BoxFit.fill,
//                          ),
//                        ),
//                      );
//                    }
//                  ),
                Padding(
                  padding: EdgeInsets.all(3.0),
                ),
                Container(
                  width: 100.0,
                  child: Text(promotion.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

//class Promotion{
//  final String title;
//  final Company company;
//  final String start_date;
//  final String end_date;
//  DocumentReference reference;
//
//  Promotion(this.title, this.company, this.start_date, this.end_date);
//
//  Promotion.fromMap(Map<String, dynamic> map, {this.reference})
//      : assert(map['title'] != null),
//        assert(map['company'] != null),
//        assert(map['start_date'] != null),
//        assert(map['end_date'] != null),
//        title = map['title'],
//        company = new Company(map['company']),
//        start_date = map['start_date'],
//        end_date = map['end_date'];
//
//  Promotion.fromSnapshot(DocumentSnapshot snapshot)
//      : this.fromMap(snapshot.data, reference: snapshot.reference);
//
//}

class PromotionBloc {
  //hashMaps,since only for these 2 classes do their id matter
  var _companies = HashMap<String, Company>();
  var _types = HashMap<String, Type>();

  //sorted HashMap, where each type links to their child

  //promotions
  var _promotions = <Promotion>[];

  var _typesStream = <Type>[];
  var _companyStream = <Company>[];

  Stream<UnmodifiableListView<Promotion>> get promotions =>
      _promotionsSubject.stream;

  Stream<UnmodifiableListView<Type>> get typesStream => _typesSubject.stream;

  Stream<UnmodifiableListView<Company>> get companyStream =>
      _companySubject.stream;

  final _promotionsSubject = BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _typesSubject = BehaviorSubject<UnmodifiableListView<Type>>();
  final _companySubject = BehaviorSubject<UnmodifiableListView<Company>>();

  PromotionBloc() {
    _updatePromotions().then((_) {
      _promotionsSubject.add(UnmodifiableListView(_promotions));
      _typesSubject.add(UnmodifiableListView(_typesStream));
      _companySubject.add(UnmodifiableListView(_companyStream));
    });
  }

  Future<Null> _updatePromotions() async {
    final promotionQShot =
        await Firestore.instance.collection('all_promotions').getDocuments();
    final companyQShot =
        await Firestore.instance.collection('all_companies').getDocuments();
    final typeQShot =
        await Firestore.instance.collection('all_types').getDocuments();

    companyQShot.documents.forEach((doc) {
      _companies[doc.documentID] = Company(doc.documentID, doc.data['name'],
          doc.data['locations'], doc.data['logoURL']);
    });

    _companyStream = _companies.values.toList();

    typeQShot.documents.forEach((doc) {
      _types[doc.documentID] =
          Type(doc.documentID, doc.data['title'], doc.data['child_id']);
      _typesStream
          .add(Type(doc.documentID, doc.data['title'], doc.data['child_id']));
    });

    _promotions = promotionQShot.documents
        .map((doc) => Promotion(
            doc.data['title'],
            _companies[doc.data['company']],
            doc.data['start_date'],
            doc.data['end_date'],
            doc.data['item_type'].map((type) => _types[type]).toList(),
            doc.documentID))
        .toList();
  }
}

class Promotion {
  final String title;
  final Company company;
  final String start_date;
  final String end_date;
  final List types;
  final String promoid;

  Promotion(this.title, this.company, this.start_date, this.end_date,
      this.types, this.promoid);
}

class Company {
  final String id;
  final String name;
  final List locations;
  final String logoURL;

  Company(this.id, this.name, this.locations, this.logoURL);

//  Future<String> getLogoUrl() async {
//    return await Firestore.instance.collection('all_companies').document(this.companyID).get().then((DocumentSnapshot ds) {
//      this.name = ds.data["name"];
//      this.locations = ds.data["locations"];
//      this.logoURL = ds.data["logoURL"];
//      return this.logoURL;});
//  }

}

class Type {
  final String id;
  final String title;
  final List child_id;

  Type(this.id, this.title, this.child_id);
}

class ExtractPromoDetails extends StatefulWidget {
  static const routeName = '/extractArguments';
  String userid;

  ExtractPromoDetails(String userid) {
    this.userid = userid;
  }

  @override
  ExtractPromoDetailsState createState() =>
      new ExtractPromoDetailsState(userid);
}

class ExtractPromoDetailsState extends State<ExtractPromoDetails> {
  String userid;

  ExtractPromoDetailsState(String userid) {
    this.userid = userid;
  }

  int likes = 0;
  int dislikes = 0;
  bool liked = false;
  bool disliked = false;
  static var args;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        args = ModalRoute.of(context).settings.arguments;
      });
      findstufffromdatabase(args);
    });
  }

  // Find if user liked/disliked promo, number of likes/dislikes
  void findstufffromdatabase(args) async {
    int databaselikes = 0;
    int databasedislikes = 0;
    bool userliked = false;
    bool userdisliked = false;
    final snapShot = await Firestore.instance
        .collection('all_promotions')
        .document(args.promoid)
        .get();
    databaselikes = snapShot.data['likes'];
    databasedislikes = snapShot.data['dislikes'];
    final snapShot2 =
        await Firestore.instance.collection('all_users').document(userid).get();
    if (snapShot2 == null || !snapShot2.exists) {
      Firestore.instance
          .collection("all_users")
          .document(userid)
          .setData({'liked_promotions': []});
      Firestore.instance
          .collection('all_users')
          .document(userid)
          .setData({'disliked_promotions': []});
    } else if (snapShot2.data['liked_promotions'].contains(args.promoid)) {
      userliked = true;
    } else if (snapShot2.data['disliked_promotions'].contains(args.promoid)) {
      userdisliked = true;
    }

    setState(() {
      likes = databaselikes;
      dislikes = databasedislikes;
      liked = userliked;
      disliked = userdisliked;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    String userid = widget.userid;

    final Promotion args = ModalRoute.of(context).settings.arguments;

    Future<void> share() async {
      String locations = '';
      for (String location in args.company.locations) {
        locations += location + '; ';
      }
      await FlutterShare.share(
        title: args.title,
        text: "Don't miss out on this promotion: " +
            args.title +
            ' from ' +
            args.start_date +
            ' to ' +
            args.end_date +
            ' at these locations: ' +
            locations,
//          linkUrl: 'https://flutter.dev/',
//          chooserTitle: 'Example Chooser Title'
      );
    }

    // Adding a promotion
    // Check if userid is in database, if it is not, add userid
    // Add promotion id
    void addpromo() async {
      List<DateTime> dates = new List();
      final snapShot = await Firestore.instance
          .collection('all_users')
          .document(userid)
          .get();
      // If userid does not exist
      if (snapShot == null || !snapShot.exists) {
        Firestore.instance.collection("all_users").document(userid).setData({
          'saved_promotion': [args.promoid]
        });
      } else {
        // If userid exists
        Firestore.instance.collection('all_users').document(userid).updateData({
          'saved_promotion': FieldValue.arrayUnion([args.promoid])
        });
      }
      final DocumentSnapshot ds = await Firestore.instance
          .collection('all_promotions')
          .document(args.promoid)
          .get();
      String promostart = ds.data['start_date'];
      String promoend = ds.data['end_date'];
      DateTime startdate = new DateTime(
          int.parse(promostart.substring(6)),
          int.parse(promostart.substring(3, 5)),
          int.parse(promostart.substring(0, 2)));
      DateTime enddate = new DateTime(
          int.parse(promoend.substring(6)),
          int.parse(promoend.substring(3, 5)),
          int.parse(promoend.substring(0, 2)));
      _MyHomePageState()
          ._showstartNotification(args.promoid, args.title, startdate);
      _MyHomePageState()
          ._showendNotification(args.promoid, args.title, enddate);
    }

    // Deleting a promotion
    void deletepromo() async {
      Firestore.instance.collection("all_users").document(userid).updateData({
        'saved_promotion': FieldValue.arrayRemove([args.promoid])
      });
      _MyHomePageState()._deleteNotification(args.promoid);
    }

    void updatepromo() async {
      if (liked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayRemove([args.promoid])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayUnion([args.promoid])
        });
      } else if (disliked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayRemove([args.promoid])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayUnion([args.promoid])
        });
      } else if (!liked && !disliked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayRemove([args.promoid])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayRemove([args.promoid])
        });
      }
      Firestore.instance
          .collection('all_promotions')
          .document(args.promoid)
          .updateData({'dislikes': dislikes});
      Firestore.instance
          .collection('all_promotions')
          .document(args.promoid)
          .updateData({'likes': likes});
    }

    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              //EDIT HERE FOR ADD
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                addpromo();
                Toast.show("Promotion added to calendar", context, duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
              },
            ),
            IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  deletepromo();
                  Toast.show("Promotion deleted from calendar", context, duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
                }),
            Column(children: <Widget>[
              Expanded(
                  child: IconButton(
                      icon: Icon(Icons.thumb_up, color: Colors.white),
                      onPressed: () {
                        if (!liked && !disliked) {
                          setState(() {
                            likes++;
                          });
                          liked = true;
                        } else if (liked) {
                          setState(() {
                            likes--;
                          });
                          liked = false;
                        } else if (!liked && disliked) {
                          setState(() {
                            likes++;
                            dislikes--;
                          });
                          liked = true;
                          disliked = false;
                        }
                        updatepromo();
                      })),
              Text(likes.toString())
            ]),
            Column(children: <Widget>[
              Expanded(
                  child: IconButton(
                icon: Icon(Icons.thumb_down, color: Colors.white),
                onPressed: () {
                  if (!disliked && !liked) {
                    setState(() {
                      dislikes++;
                    });
                    disliked = true;
                  } else if (disliked) {
                    setState(() {
                      dislikes--;
                    });
                    disliked = false;
                  } else if (!disliked && liked) {
                    setState(() {
                      dislikes++;
                      likes--;
                    });
                    liked = false;
                    disliked = true;
                  }
                  updatepromo();
                },
              )),
              Text(dislikes.toString())
            ]),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                setState(() {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CommentPage(args.promoid)));
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: share,
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Align(
                alignment: Alignment.center,
                child: Container(
                    width: 350,
                    child: Column(
                      children: <Widget>[
                        Container(
                            padding: EdgeInsets.all(10.0),
                            child: Text(args.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ))),
                        Card(
                            elevation: 10.0,
                            child: Container(
                                width: 350,
                                child: Image(
                                  image: NetworkImage(args.company.logoURL),
                                  fit: BoxFit.fitWidth,
                                ))),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                        ),
                        Align(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 19.0, color: Colors.black),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: 'Company: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: args.company.name),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 19.0, color: Colors.black),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: 'Dates: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(
                                        text: args.start_date +
                                            ' - ' +
                                            args.end_date),
                                  ],
                                ),
                              ),
                              Text('Locations:',
                                  style: TextStyle(
                                      fontSize: 19.0,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              for (String location in args.company.locations)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text("• ",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.0)),
                                    Expanded(
                                      child: Text(location,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16.0)),
                                    )
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20.0),
                        )
                      ],
                    )))));
  }
}
