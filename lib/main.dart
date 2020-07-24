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
import 'package:web_scraper/web_scraper.dart';
import 'dart:io';
import 'convertString.dart';

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
        MyHomePage.routeName: (BuildContext context) => new MyHomePage(bloc: bloc, userid: userid),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final PromotionBloc bloc;
  final String userid;

  MyHomePage({Key key, this.bloc, this.userid}) : super(key: key);

  static String routeName = "/MyHomePage";

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
    //just want to get promotion for this
    Promotion selectedPromo;
    widget.bloc.promotions.first.then((promotionList) {
      selectedPromo = promotionList.firstWhere((promo) => promo.title == payLoad);
    });
    return Navigator.pushNamed(context, '/promoDetails',
      arguments: selectedPromo
    );
//    final DocumentSnapshot ds = await Firestore.instance
//        .collection('all_promotions')
//        .document(payLoad)
//        .get();
//    final DocumentSnapshot ds1 = await Firestore.instance
//        .collection('all_companies')
//        .document(ds.data['company'])
//        .get();
//    if (payLoad != null) {
//      print(payLoad);
//    }
//    await Navigator.pushNamed(context, '/promoDetails',
//        arguments: new Promotion(
//            ds.data['title'],
//            new Company(ds1.data['company'], ds1.data['name'],
//                ds1.data['locations'], ds1.data['logoURL']),
//            ds.data['start_date'],
//            ds.data['end_date'],
//            ds.data['item_type'],
//            payLoad));
  }

  Future onDidReceiveLocalNotification(int id, String title, String body, String payLoad) async {

    Promotion selectedPromo;
    widget.bloc.promotions.first.then((promotionLst) {
      selectedPromo = promotionLst.firstWhere((promo) => promo.title == payLoad);
    });

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
                      arguments: selectedPromo);
                },
                child: Text("okay"))
          ],
        ));

//    final DocumentSnapshot ds = await Firestore.instance
//        .collection('all_promotions')
//        .document(payLoad)
//        .get();
//    final DocumentSnapshot ds1 = await Firestore.instance
//        .collection('all_companies')
//        .document(ds.data['company'])
//        .get();
//
//    return showDialog(
//        context: context,
//        builder: (BuildContext context) => CupertinoAlertDialog(
//              title: Text(title),
//              content: Text(body),
//              actions: [
//                CupertinoDialogAction(
//                    isDefaultAction: true,
//                    onPressed: () {
//                      Navigator.pushNamed(context, '/promoDetails',
//                          arguments: new Promotion(
//                              ds.data['title'],
//                              new Company(ds1.data['company'], ds1.data['name'],
//                                  ds1.data['locations'], ds1.data['logoURL']),
//                              ds.data['start_date'],
//                              ds.data['end_date'],
//                              ds.data['item_type'],
//                              payLoad));
//                    },
//                    child: Text("okay"))
//              ],
//            ));
  }

  WebScraper webScraper;
  bool loaded = true; //change to false
  String popNum;

  @override
  void initState() {
    super.initState();
//    _getData();
    initializing();
  }

//  _getData() async {
//    List<String> all_href = []; //probably need to set as a global variable later
//    //with widget.bloc = promotionBloc
//
//    webScraper = WebScraper('https://singpromos.com');
//
//    Future<bool> get_href(String path) async{
//      int page_num = 1;
//      while (await webScraper.loadWebPage (path + '$page_num')) {
//        List<Map<String, dynamic>> results = webScraper.getElement('div.tabs1Content > '
//        'article.mh-loop-item.clearfix > div.mh-loop-thumb > a ', ['href']);
//        List<Map<String, dynamic>> next_page = webScraper.getElement('div.tabs1Content > '
//        'div.mh-loop-pagination.clearfix > a.next.page-numbers', ['title']);
//
//        for (Map<String, dynamic> map in results) {
//          String str = map['attributes']['href'].split('https://singpromos.com')[1];
//          //filter out news
//          if (!str.startsWith('/news')) {
//          all_href.add(str);
//          }
//        }
//
//        if (next_page.isNotEmpty) {
//          page_num++;
//        } else {
//          break;
//        }
//      }
//      return true; //to show that it is done
//    }
//
//    await get_href("/bydate/ontoday/page/");
//    if (await get_href("/bydate/comingsoon/page/")) {
////      setState(() {
////        loaded = true;
////      });
//    }
//
//    for (String href in all_href) {
//      await webScraper.loadWebPage(href);
//
//      String title = webScraper.getElement('h1.entry-title', ['title'])[0]['title'].toString().trim();
//      if (title.contains('/')) {
//        String temp = title.split('/')[0];
//        for (String str in title.split('/').sublist(1)) {
//          temp += " or " + str;
//        }
//        title = temp;
//      }
//
//
//      //list that contains start date, end date and company, note that some SGPROMO articles do not have this
//      List<Map<String, dynamic>> duration_company = webScraper.getElement('table.eventDetailsTable < tbody < tr < td', ['title']);
//
//      String start_date = '';
//      String end_date = '';
//      String company = '';
//
//      if (duration_company.isNotEmpty) {
//        List<String> duration_company_str_lst = duration_company[0]['title'].split('Location');
//        company = duration_company_str_lst[1].trim();
//        start_date = convert_date(duration_company_str_lst[0].split('(')[0].split('Starts')[1].trim());
//        if (duration_company_str_lst[0].contains('ONE day only')) {
//          end_date = start_date;
//        } else {
//          end_date = convert_date(duration_company_str_lst[0].split('Ends')[1].split('(')[0].trim());
//        }
//      } else {
//        //some SGPROMO articles do not date and location stated
//        //those that are empty are assumed to have a from date in the title (else just remove)
//        //following code removes things like foodpanda promocodes for the whole month though
//        //for now ignoring those with end_dates that are unknown
////        if (title.contains('from')) {
////          start_date = convert_date(title.split('from')[1].trim());
////          end_date = 'UNKNOWN';
////        } else if (title.contains('From')) {
////          start_date = convert_date(title.split('From')[1].trim());
////          if (start_date.contains(')')) {
////            start_date = start_date.split(')')[0].trim();
////          }
////          end_date = 'UNKNOWN';
////        }
//      }
//
//      Map<String, List> typeMap = await getTypeMap();
//      Map<String, List<String>> relatedWordsMap = await getRelatedWordsMap();
//
//      //all promotions are from ongoing n upcoming session, hence no need to
//      //remove expired ones, just remove the ones that have unknown end_date
//      //exists some promotions with empty company field, will ignore all of this first
//      if (start_date != '' && !end_date.contains('UNKNOWN') && company != '') {
//        //start adding into database to try first
//
//        //creating Company objects in collection
//        await Firestore.instance.collection('web_companies')
//            .document(company)
//            .get()
//            .then(
//                (docSnapshot) {
//              if (docSnapshot.exists) {
//                //do nothing
//              } else {
//                Firestore.instance.collection("web_companies").document(
//                  company).setData({
//                  'title': company,
//                  'logoURL': "https://firebasestorage.googleapis.com/v0/b/"
//                      "promotion-918b7.appspot.com/o/defaultImg.png?alt=media"
//                      "&token=4e673d46-7b92-4518-ad11-a532fcdfc491"
//                });
//              }
//            }
//        ).catchError((error) => print("Got error: $error"));
//
//
//        //creating Promotion object in collection
//        await Firestore.instance.collection('web_promotion')
//            .document(title)
//            .get()
//            .then(
//                (docSnapshot) {
//              if (docSnapshot.exists) {
//                //update happens here
//                //happens when new tags are added
//                List<String> types = List<String>.from(docSnapshot.data['types']);
//                for (String key in relatedWordsMap.keys) {
//                  for (String relatedWord in relatedWordsMap[key]) {
//                    if (!(types.contains(relatedWord) && title.contains(relatedWord))) {
//                      types.add(key);
//                      for (String parentType in typeMap.keys) {
//                        if (!(types.contains(parentType)) &&
//                            typeMap[parentType].contains(key)) {
//                          types.add(parentType);
//                          break;
//                        }
//                      }
//                      break;
//                    }
//                  }
//                }
//                Firestore.instance.collection("web_promotion").document(
//                  title
//                ).updateData({'types': types});
//              } else {
//                List<String> types = [];
//                for (String key in relatedWordsMap.keys) {
//                  for (String relatedWord in relatedWordsMap[key]) {
//                    if (title.contains(relatedWord)) {
//                      types.add(key);
//                      for (String parentType in typeMap.keys) {
//                        if (!(types.contains(parentType)) &&
//                            typeMap[parentType].contains(key)) {
//                          types.add(parentType);
//                          break;
//                        }
//                      }
//                      break;
//                    }
//                  }
//                }
//
//                Firestore.instance.collection("web_promotion").document(
//                  title
//                ).setData({'title': title, 'company': company, 'types': types,
//                  'clicks': 0, 'start_date': start_date, 'end_date': end_date,
//                  'comments': [], 'dislikes': 0, 'likes' : 0
//                });
//              }
//            }
//        ).catchError((error) => print(" Got error: $error"));
//
//      }
//    }
//
//    setState(() {
//      loaded = true;
//    });
//
//  }
//
//  Future<Map<String, List<String>>> getTypeMap() async {
//    Map<String, List<String>> map = new Map<String, List<String>>();
//    await Firestore.instance.collection('web_type')
//      .getDocuments()
//      .then(
//        (collection) {
//          collection.documents.forEach(
//            (docSnapshot) {
//              if (docSnapshot.data['child_id'] != null) {
//                map[docSnapshot.data['title']] = List<String>.from(docSnapshot.data['child_id']);
//              }
//            }
//          );
//        }
//    );
//    return map;
//  }
//
//  Future<Map<String, List<String>>> getRelatedWordsMap() async{
//    Map<String, List<String>> map = new Map<String, List<String>>();
//    await Firestore.instance.collection('web_type')
//        .getDocuments()
//        .then(
//          (collection) {
//            collection.documents.forEach(
//              (docSnapshot) {
//                if (docSnapshot.data['related_words'] != null) {
//                  List<String> temp = [];
//                  for (String str in docSnapshot.data['related_words']) {
//                    temp.add(convertString.convertUpperCase(str));
//                    temp.add(convertString.convertLowerCase(str));
//                    temp.add(convertString.convertCapitalizeFirstWord(str));
//                    if (str.split(" ").length > 1) {
//                      temp.add(convertString.convertCapitalizeEachWord(str));
//                    }
//                    if (!(temp.contains(str))) {
//                      temp.add(str);
//                    }
//                  }
//                  map[docSnapshot.data['title']] = temp;
//                }
//              }
//            );
//          }
//        ).catchError((error) => print("Got error: $error"));
//    return map;
//  }
//
//  String convert_date(String str) {
//    //converting date_str : 11 July 2020 to 11/07/2020
//    if (!str.contains("UNKNOWN")) {
//      List<String> str_lst = str.split(' ');
//      String result = str_lst[0] + "/" + convert_month(str_lst[1]) + "/" +
//          str_lst[2];
//      return result;
//    }
//    return str;
//  }
//
//  String convert_month(String month_str) {
//    //convert from July to 07
//    if (month_str == "January" || month_str == "Jan") {
//      return "01";
//    } else if (month_str == "February" || month_str == "Feb") {
//      return "02";
//    } else if (month_str == "March" || month_str == "Mar") {
//      return "03";
//    } else if (month_str == "April" || month_str == "Apr") {
//      return "04";
//    } else if (month_str == "May") {
//      return "05";
//    } else if (month_str == "June" || month_str == "Jun") {
//      return "06";
//    } else if (month_str == "July" || month_str == "Jul") {
//      return "07";
//    } else if (month_str == "August" || month_str == "Aug") {
//      return "08";
//    } else if (month_str == "September" || month_str == "Sept" || month_str == "Sep") {
//      return "09";
//    } else if (month_str == "October" || month_str == "Oct") {
//      return "10";
//    } else if (month_str == "November" || month_str == "Nov") {
//      return "11";
//    } else if (month_str == "December" || month_str == "Dec") {
//      return "12";
//    } else {
//      return ("Another kind of string was inputted");
//    }
//  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Icon customIcon = Icon(Icons.search, color: Colors.white);
  Widget customWidget = Text('View Promotions');


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
          },
          icon: customIcon,
        )
      ],
    );

    List<Widget> titles = <Widget>[
      mainWidget,
      AppBar(title: Text('Promotion Calendar'),
        leading: IconButton(
          icon: Icon(Icons.calendar_today),
          color: Colors.white,)
      )
    ];
    List<Widget> options = <Widget>[
      _buildBody(context),
      Calendar(widget.userid)
    ];

    return Scaffold(
      appBar: titles.elementAt(_selectedIndex),
      body: Center(
        child: (loaded) ? options.elementAt(_selectedIndex)
            : CircularProgressIndicator(),
      ),
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
          child: _buildNewSection(context),
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
    final Map<String, bool> checkedLocationMap = Map<String, bool>();

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
            Container(
              color: Colors.grey[800],
              height: 50.0,
              child: Align(
                alignment: FractionalOffset(0.09,0.5),
                child: Text(
                  'BY LOCATION',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            _buildLocationFilter(context, checkedLocationMap),
//            Text(_locationMessage),
            RaisedButton(
              color: Colors.teal[200],
              onPressed: () {
//                _getCurrentLocation(widget.bloc.promotions);

                Navigator.pushNamed(
                  context,
                  '/filterPage',
                  arguments: PromotionFilter(
                    widget.bloc.promotions,
                    checkedTypeMap,
                    checkedCompanyMap,
                    checkedDurationMap,
                    checkedLocationMap,
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
            try {
              if (!type.child_id.isEmpty) {
                typeMap[type] = type.child_id
                    .map((child_id) =>
                    snapshot.data
                        .toList()
                        .firstWhere((t) => t.title == child_id))
                    .toList();
              } else {
                checkedTypeMap[type.title] = false;
              }
            } catch (e){
              print(type.title);
              print(e);
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
                checkedCompanyMap[company.title] = false;
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
      title: Text('Duration'),
      children: checkedDurationMap.keys.map((keys) =>
          FilterDurationList(title: keys, checkedDurationMap: checkedDurationMap)).toList()
    );
  }

//  String _locationMessage =  "";
//  void _getCurrentLocation(Stream<UnmodifiableListView<Promotion>> promoStream) async{
////    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//    List<Placemark> placemark = await Geolocator().placemarkFromAddress('313 Orchard Rd, #01-25 25A, Singapore 238895');
//    setState(() {
//      _locationMessage = "${placemark[0].position.latitude}, ${placemark[0].position.longitude}";
//    });
//  }

  Widget _buildLocationFilter (BuildContext context, Map<String, bool> checkedLocationMap) {

    checkedLocationMap['Near Me'] = false;

    return ExpansionTile(
      title: Text('Location'),
      children: <Widget>[
        FilterLocation(checkedLocationMap: checkedLocationMap),
      ],
    );
  }

  Widget _buildNewSection(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Promotion>>(
        stream: widget.bloc.Newpromotions,
        initialData: UnmodifiableListView<Promotion>([]),
        builder: (context, snapshot) => ListView(
          scrollDirection: Axis.horizontal,
          children: snapshot.data.map(_buildListItem).toList(),
        ));
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

class PromotionBloc {
  //hashMaps,since only for these 2 classes do their id matter
  var _companies = HashMap<String, Company>();
  var _types = HashMap<String, Type>();

  //sorted HashMap, where each type links to their child

  //promotions
  var _promotions = <Promotion>[];
  var _Newpromotions = <Promotion>[];
  var _Hotpromotions = <Promotion>[];

  var _typesStream = <Type>[];
  var _companyStream = <Company>[];

  Stream<UnmodifiableListView<Promotion>> get promotions => _promotionsSubject.stream;
  Stream<UnmodifiableListView<Promotion>> get Newpromotions => _NewpromotionsSubject.stream;
  Stream<UnmodifiableListView<Promotion>> get Hotpromotions => _HotpromotionsSubject.stream;
  Stream<UnmodifiableListView<Type>> get typesStream => _typesSubject.stream;
  Stream<UnmodifiableListView<Company>> get companyStream => _companySubject.stream;

  final _promotionsSubject = BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _NewpromotionsSubject = BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _HotpromotionsSubject = BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _typesSubject = BehaviorSubject<UnmodifiableListView<Type>>();
  final _companySubject = BehaviorSubject<UnmodifiableListView<Company>>();

  PromotionBloc() {
    _updatePromotions().then((_) {
      _promotionsSubject.add(UnmodifiableListView(_promotions));
      _NewpromotionsSubject.add(UnmodifiableListView(_Newpromotions));
      _HotpromotionsSubject.add(UnmodifiableListView(_Hotpromotions));
      _typesSubject.add(UnmodifiableListView(_typesStream));
      _companySubject.add(UnmodifiableListView(_companyStream));
    });
  }

  Future<Null> _updatePromotions() async {

    final promotionQShot =
        await Firestore.instance.collection('web_promotion').getDocuments();
    final NewpromotionQShot =
      await Firestore.instance.collection('web_promotion').orderBy('start_date', descending: true).getDocuments();
    final companyQShot =
        await Firestore.instance.collection('web_companies').getDocuments();
    final typeQShot =
        await Firestore.instance.collection('web_type').getDocuments();

    companyQShot.documents.forEach((doc) {
      List<String> location = [];
      if (doc.data['location'] != null) {
        location = List<String>.from(doc.data['location']);
      }
      _companies[doc.data['title']] = Company(doc.data['title'],
          location, doc.data['logoURL']);
    });

    _companyStream = _companies.values.toList();

    typeQShot.documents.forEach((doc) {
      List<String> related_words = [];
      List<String> child_id = [];
      if (doc.data['child_id'] != null) {
        child_id = List<String>.from(doc.data['child_id']);
      } else {
        related_words = List<String>.from(doc.data['related_words']);
      }
      _types[doc.data['title']] =
          Type(doc.data['title'], child_id, related_words);
    });

    _typesStream = _types.values.toList();

    _promotions = promotionQShot.documents
        .map((doc) {
          List types = [];
          if (doc.data['types'].isNotEmpty) {
            types = doc.data['types'].map((type) => _types[type]).toList();
          }
          return Promotion(
          doc.data['title'],
          _companies[doc.data['company']],
          doc.data['start_date'],
          doc.data['end_date'],
          types,
          List<String>.from(doc.data['comments']),
          doc.data['dislikes'],
          doc.data['likes'],
          doc.data['clicks']);
        }
    ).toList();

    _Newpromotions = NewpromotionQShot.documents
        .map((doc) => Promotion(
        doc.data['title'],
        _companies[doc.data['company']],
        doc.data['start_date'],
        doc.data['end_date'],
        doc.data['types'].map((type) => _types[type]).toList(),
        List<String>.from(doc.data['comments']),
        doc.data['dislikes'],
        doc.data['likes'],
        doc.data['clicks']
    )).toList();

  }

}

class Promotion {
  final String title;
  final Company company;
  final String start_date;
  final String end_date;
  final List types;
  final List<String> comments;
  final int dislikes;
  final int likes;
  final int clicks;

  Promotion(this.title, this.company, this.start_date, this.end_date,
      this.types, this.comments, this.dislikes, this.likes, this.clicks);
}

class Company {
  final String title;
  final List<String> location;
  final String logoURL;

  Company(this.title, this.location, this.logoURL);
}

class Type {
  final String title;
  final List<String> child_id;
  final List<String> related_words;

  Type(this.title, this.child_id, this.related_words);
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
      for (String location in args.company.location) {
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
          'saved_promotion': [args.title]
        });
      } else {
        // If userid exists
        Firestore.instance.collection('all_users').document(userid).updateData({
          'saved_promotion': FieldValue.arrayUnion([args.title])
        });
      }
      final DocumentSnapshot ds = await Firestore.instance
          .collection('all_promotions')
          .document(args.title)
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
          ._showstartNotification(args.title, args.title, startdate);
      _MyHomePageState()
          ._showendNotification(args.title, args.title, enddate);
    }

    // Deleting a promotion
    void deletepromo() async {
      Firestore.instance.collection("all_users").document(userid).updateData({
        'saved_promotion': FieldValue.arrayRemove([args.title])
      });
      _MyHomePageState()._deleteNotification(args.title);
    }

    void updatepromo() async {
      if (liked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayRemove([args.title])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayUnion([args.title])
        });
      } else if (disliked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayRemove([args.title])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayUnion([args.title])
        });
      } else if (!liked && !disliked) {
        Firestore.instance.collection('all_users').document(userid).updateData({
          'liked_promotions': FieldValue.arrayRemove([args.title])
        });
        Firestore.instance.collection('all_users').document(userid).updateData({
          'disliked_promotions': FieldValue.arrayRemove([args.title])
        });
      }
      Firestore.instance
          .collection('all_promotions')
          .document(args.title)
          .updateData({'dislikes': dislikes});
      Firestore.instance
          .collection('all_promotions')
          .document(args.title)
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
                  Navigator.pushNamed(context, MyHomePage.routeName);

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
                          builder: (context) => CommentPage(args.title)));
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
                                    TextSpan(text: args.company.title),
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
                              for (String location in args.company.location)
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
