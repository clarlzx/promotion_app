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
import 'package:intl/intl.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:url_launcher/url_launcher.dart';


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
        MyHomePage.routeName: (BuildContext context) =>
            new MyHomePage(bloc: bloc, userid: userid),
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

  void _showendNotification(String promoid, String title, DateTime date) async {
    await endnotification(promoid, title, date);
  }

  Future<void> endnotification(
      String promoid, String title, DateTime date) async {
//    DateTime datetime = DateTime.now();
    DateTime datetime = date;
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
//    DateTime datetime = DateTime.now().add(new Duration(seconds: 5));
//    DateTime datetime = DateTime.now();

    DateTime datetime = date;
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
        promoid.hashCode + 1,
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
    await flutterLocalNotificationsPlugin.cancel(promoid.hashCode + 1);
  }

  Future onSelectNotification(String payLoad) async {
    Promotion selectedPromo;
    await widget.bloc.promotions.first.then((promotionList) {
      selectedPromo =
          promotionList.firstWhere((promo) => promo.title == payLoad);
    });
    return Navigator.pushNamed(context, '/promoDetails',
        arguments: selectedPromo);
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payLoad) async {
    Promotion selectedPromo;
    await widget.bloc.promotions.first.then((promotionLst) {
      selectedPromo =
          promotionLst.firstWhere((promo) => promo.title == payLoad);
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
  }

  WebScraper webScraper;

  @override
  void initState() {
    super.initState();
    initializing();

    final schedular = NeatPeriodicTaskScheduler(
      interval: Duration(hours: 12),
      name: 'get-data',
      timeout: Duration(minutes: 30),
      task: () async => _getData(),
      minCycle: Duration(seconds: 5),
    );

    schedular.start();
  }

  //web_scrapping
  _getData() async {
    print('started webscraping');

    List<String> all_href = [];

    Map<String, List> typeMap = await getTypeMap();
    Map<String, List<String>> relatedWordsMap = await getRelatedWordsMap();

    webScraper = WebScraper('https://singpromos.com');

    Future<bool> get_href(String path) async {
      int page_num = 1;
      while (await webScraper.loadWebPage(path + '$page_num')) {
        List<Map<String, dynamic>> results = webScraper.getElement(
            'div.tabs1Content > '
            'article.mh-loop-item.clearfix > div.mh-loop-thumb > a ',
            ['href']);
        List<Map<String, dynamic>> next_page = webScraper.getElement(
            'div.tabs1Content > '
            'div.mh-loop-pagination.clearfix > a.next.page-numbers',
            ['title']);

        for (Map<String, dynamic> map in results) {
          String str =
              map['attributes']['href'].split('https://singpromos.com')[1];
          //filter out news
          if (!str.startsWith('/news')) {
            all_href.add(str);
          }
        }

        if (next_page.isNotEmpty) {
          page_num++;
        } else {
          break;
        }
      }
      return true; //to show that it is done
    }

    await get_href("/bydate/ontoday/page/");
    await get_href("/bydate/comingsoon/page/");

    for (String href in all_href) {
      await webScraper.loadWebPage(href);

      String title = webScraper
          .getElement('h1.entry-title', ['title'])[0]['title']
          .toString()
          .trim();
      if (title.contains('/')) {
        String temp = title.split('/')[0];
        for (String str in title.split('/').sublist(1)) {
          temp += " or " + str;
        }
        title = temp;
      }

      //list that contains start date, end date and company, note that some SGPROMO articles do not have this
      List<Map<String, dynamic>> duration_company = webScraper
          .getElement('table.eventDetailsTable < tbody < tr < td', ['title']);

      String start_date = '';
      String end_date = '';
      String company = '';

      if (duration_company.isNotEmpty) {
        List<String> duration_company_str_lst =
            duration_company[0]['title'].split('Location');
        company = duration_company_str_lst[1].trim();
        start_date = convert_date(duration_company_str_lst[0]
            .split('(')[0]
            .split('Starts')[1]
            .trim());
        if (duration_company_str_lst[0].contains('ONE day only')) {
          end_date = start_date;
        } else {
          end_date = convert_date(duration_company_str_lst[0]
              .split('Ends')[1]
              .split('(')[0]
              .trim());
        }
      } else {
        //some SGPROMO articles do not date and location stated
        //those that are empty are assumed to have a from date in the title (else just remove)
        //following code removes things like foodpanda promocodes for the whole month though
        //for now ignoring those with end_dates that are unknown
//        if (title.contains('from')) {
//          start_date = convert_date(title.split('from')[1].trim());
//          end_date = 'UNKNOWN';
//        } else if (title.contains('From')) {
//          start_date = convert_date(title.split('From')[1].trim());
//          if (start_date.contains(')')) {
//            start_date = start_date.split(')')[0].trim();
//          }
//          end_date = 'UNKNOWN';
//        }
      }

      //all promotions are from ongoing n upcoming session, hence no need to
      //remove expired ones, just remove the ones that have unknown end_date
      //exists some promotions with empty company field, will ignore all of this first
      if (start_date != '' && !end_date.contains('UNKNOWN') && company != '') {
        //start adding into database to try first

        //creating Company objects in collection
        await Firestore.instance
            .collection('web_companies')
            .document(company)
            .get()
            .then((docSnapshot) {
          if (docSnapshot.exists) {
            //do nothing
          } else {
            Firestore.instance
                .collection("web_companies")
                .document(company)
                .setData({
              'title': company,
              'logoURL': "https://firebasestorage.googleapis.com/v0/b/"
                  "promotion-918b7.appspot.com/o/defaultImg.png?alt=media"
                  "&token=4e673d46-7b92-4518-ad11-a532fcdfc491"
            });
          }
        }).catchError((error) => print("Got error: $error"));

        //creating Promotion object in collection
        await Firestore.instance
            .collection('web_promotion')
            .document(title)
            .get()
            .then((docSnapshot) {
          if (docSnapshot.exists) {
            //do nothing
          } else {
            List<String> types = [];
            for (String key in relatedWordsMap.keys) {
              for (String relatedWord in relatedWordsMap[key]) {
                if (title.contains(relatedWord)) {
                  types.add(key);
                  for (String parentType in typeMap.keys) {
                    if (!(types.contains(parentType)) &&
                        typeMap[parentType].contains(key)) {
                      types.add(parentType);
                      break;
                    }
                  }
                  break;
                }
              }
            }

            final now = DateTime.now();
            Firestore.instance
                .collection("web_promotion")
                .document(title)
                .setData({
              'title': title,
              'company': company,
              'types': types,
              'clicks': 0,
              'start_date': start_date,
              'end_date': end_date,
              'comments': [],
              'dislikes': 0,
              'likes': 0,
              'dateAdded': Timestamp.fromDate(now)
            });
          }
        }).catchError((error) => print(" Got error: $error"));
      }
    }

    await _updateData(typeMap, relatedWordsMap);

    print("end webscraping process");
  }

  _updateData(Map<String, List> typeMap,
      Map<String, List<String>> relatedWordsMap) async {
    print('undergoing update of database');

    await Firestore.instance
        .collection('web_promotion')
        .getDocuments()
        .then((querySnapshot) {
      final now = DateTime.now();
      querySnapshot.documents.forEach((docSnapshot) async {
        final end_date = DateFormat("d/M/y H:m")
            .parse(docSnapshot.data['end_date'] + ' 23:59');
        //if end_date has ended then remove this document
        if (!(now.isBefore(end_date))) {
          await Firestore.instance
              .collection('web_promotion')
              .document(docSnapshot.data['title'])
              .delete()
              .then((x) {
            print(docSnapshot.data['title'] + " deleted successfully");
          }).catchError((error) => print("Error: " + error));

          FirebaseUser user = await _auth.currentUser();
          //also remove this promotion title from liked, disliked, saved promotions and clickedBefore
          await Firestore.instance
              .collection('all_users')
              .document(user.uid)
              .get()
              .then((userData) {
            List<String> clickedBefore =
                List<String>.from(userData.data['clickedBefore']);
            List<String> disliked_promotions =
                List<String>.from(userData.data['disliked_promotions']);
            List<String> liked_promotions =
                List<String>.from(userData.data['liked_promotions']);
            List<String> saved_promotion =
                List<String>.from(userData.data['saved_promotion']);
            clickedBefore.remove(docSnapshot.data['title']);
            disliked_promotions.remove(docSnapshot.data['title']);
            liked_promotions.remove(docSnapshot.data['title']);
            saved_promotion.remove(docSnapshot.data['title']);
            Firestore.instance
                .collection('all_users')
                .document(user.uid)
                .updateData({
              'clickedBefore': clickedBefore,
              'disliked_promotions': disliked_promotions,
              'liked_promotions': liked_promotions,
              'saved_promotion': saved_promotion
            });
          });
        } else {
          //update tags
          //happens when new tags are added
          List<String> types = List<String>.from(docSnapshot.data['types']);
          for (String key in relatedWordsMap.keys) {
            for (String relatedWord in relatedWordsMap[key]) {
              if (!(types.contains(key)) &&
                  docSnapshot.data['title'].contains(relatedWord)) {
                types.add(key);
                for (String parentType in typeMap.keys) {
                  if (!(types.contains(parentType)) &&
                      typeMap[parentType].contains(key)) {
                    types.add(parentType);
                    break;
                  }
                }
                break;
              }
            }
          }
          Firestore.instance
              .collection("web_promotion")
              .document(docSnapshot.data['title'])
              .updateData({'types': types});
        }
      });
    });
  }

  Future<Map<String, List<String>>> getTypeMap() async {
    Map<String, List<String>> map = new Map<String, List<String>>();
    await Firestore.instance
        .collection('web_type')
        .getDocuments()
        .then((collection) {
      collection.documents.forEach((docSnapshot) {
        if (docSnapshot.data['child_id'] != null) {
          map[docSnapshot.data['title']] =
              List<String>.from(docSnapshot.data['child_id']);
        }
      });
    });
    return map;
  }

  Future<Map<String, List<String>>> getRelatedWordsMap() async {
    Map<String, List<String>> map = new Map<String, List<String>>();
    await Firestore.instance
        .collection('web_type')
        .getDocuments()
        .then((collection) {
      collection.documents.forEach((docSnapshot) {
        if (docSnapshot.data['related_words'] != null) {
          List<String> temp = [];
          for (String str in docSnapshot.data['related_words']) {
            temp.add(convertString.convertUpperCase(str));
            temp.add(convertString.convertLowerCase(str));
            temp.add(convertString.convertCapitalizeFirstWord(str));
            if (str.split(" ").length > 1) {
              temp.add(convertString.convertCapitalizeEachWord(str));
            }
            if (!(temp.contains(str))) {
              temp.add(str);
            }
          }
          map[docSnapshot.data['title']] = temp;
        }
      });
    }).catchError((error) => print("Got error: $error"));
    return map;
  }

  String convert_date(String str) {
    //converting date_str : 9 July 2020 to 09/07/2020
    if (!str.contains("UNKNOWN")) {
      List<String> str_lst = str.split(' ');
      String result = convert_day(str_lst[0]) +
          "/" +
          convert_month(str_lst[1]) +
          "/" +
          str_lst[2];
      return result;
    }
    return str;
  }

  String convert_day(String day_str) {
    if (day_str.length > 1) {
      return day_str;
    } else {
      return "0" + day_str;
    }
  }

  String convert_month(String month_str) {
    //convert from July to 07
    //convert 7 to 07
    if (month_str == "January" || month_str == "Jan" || month_str == "1") {
      return "01";
    } else if (month_str == "February" ||
        month_str == "Feb" ||
        month_str == "2") {
      return "02";
    } else if (month_str == "March" || month_str == "Mar" || month_str == "3") {
      return "03";
    } else if (month_str == "April" || month_str == "Apr" || month_str == "4") {
      return "04";
    } else if (month_str == "May" || month_str == "5") {
      return "05";
    } else if (month_str == "June" || month_str == "Jun" || month_str == "6") {
      return "06";
    } else if (month_str == "July" || month_str == "Jul" || month_str == "7") {
      return "07";
    } else if (month_str == "August" ||
        month_str == "Aug" ||
        month_str == "8") {
      return "08";
    } else if (month_str == "September" ||
        month_str == "Sept" ||
        month_str == "Sep" ||
        month_str == "9") {
      return "09";
    } else if (month_str == "October" || month_str == "Oct") {
      return "10";
    } else if (month_str == "November" || month_str == "Nov") {
      return "11";
    } else if (month_str == "December" || month_str == "Dec") {
      return "12";
    } else {
      return ("Another kind of string was inputted");
    }
  }

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
      backgroundColor: Colors.black,
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
      AppBar(
          title: Text('Promotion Calendar'),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.calendar_today),
            color: Colors.white,
          ))
    ];
    List<Widget> options = <Widget>[
      _buildBody(context),
      Calendar(widget.userid)
    ];

    Future<bool> _onBackPressed() {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(
                  "Do you really want to exit the app?",
                  style: TextStyle(color: Colors.black),
                ),
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
              ));
    }

    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          appBar: titles.elementAt(_selectedIndex),
          body: Center(child: options.elementAt(_selectedIndex)),
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
            backgroundColor: Colors.grey[900],
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
            selectedItemColor: Colors.teal[200],
            unselectedItemColor: Colors.white,
          ),
        ));
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
          child: _buildHotSection(context),
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
                alignment: FractionalOffset(0.09, 0.5),
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
                    .map((child_id) => snapshot.data
                        .toList()
                        .firstWhere((t) => t.title == child_id))
                    .toList();
              } else {
                checkedTypeMap[type.title] = false;
              }
            } catch (e) {
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
        children: checkedDurationMap.keys
            .map((keys) => FilterDurationList(
                title: keys, checkedDurationMap: checkedDurationMap))
            .toList());
  }

//  String _locationMessage =  "";
//  void _getCurrentLocation(Stream<UnmodifiableListView<Promotion>> promoStream) async{
////    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//    List<Placemark> placemark = await Geolocator().placemarkFromAddress('313 Orchard Rd, #01-25 25A, Singapore 238895');
//    setState(() {
//      _locationMessage = "${placemark[0].position.latitude}, ${placemark[0].position.longitude}";
//    });
//  }

  Widget _buildLocationFilter(
      BuildContext context, Map<String, bool> checkedLocationMap) {
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

  Widget _buildHotSection(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Promotion>>(
        stream: widget.bloc.Hotpromotions,
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
        promotion.increaseClicks();
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

  Stream<UnmodifiableListView<Promotion>> get promotions =>
      _promotionsSubject.stream;

  Stream<UnmodifiableListView<Promotion>> get Newpromotions =>
      _NewpromotionsSubject.stream;

  Stream<UnmodifiableListView<Promotion>> get Hotpromotions =>
      _HotpromotionsSubject.stream;

  Stream<UnmodifiableListView<Type>> get typesStream => _typesSubject.stream;

  Stream<UnmodifiableListView<Company>> get companyStream =>
      _companySubject.stream;

  final _promotionsSubject = BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _NewpromotionsSubject =
      BehaviorSubject<UnmodifiableListView<Promotion>>();
  final _HotpromotionsSubject =
      BehaviorSubject<UnmodifiableListView<Promotion>>();
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
    final NewpromotionQShot = await Firestore.instance
        .collection('web_promotion')
        .orderBy('dateAdded', descending: false)
        .getDocuments();
    final HotpromotionQShot = await Firestore.instance
        .collection('web_promotion')
        .orderBy('clicks', descending: true)
        .getDocuments();
    final companyQShot =
        await Firestore.instance.collection('web_companies').getDocuments();
    final typeQShot =
        await Firestore.instance.collection('web_type').getDocuments();

    companyQShot.documents.forEach((doc) {
      List<String> location = [];
      if (doc.data['location'] != null) {
        location = List<String>.from(doc.data['location']);
      }
      _companies[doc.data['title']] =
          Company(doc.data['title'], location, doc.data['logoURL']);
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

    _promotions = promotionQShot.documents.map((doc) {
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
    }).toList();

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
            doc.data['clicks']))
        .toList();

    _Hotpromotions = HotpromotionQShot.documents
        .map((doc) => Promotion(
            doc.data['title'],
            _companies[doc.data['company']],
            doc.data['start_date'],
            doc.data['end_date'],
            doc.data['types'].map((type) => _types[type]).toList(),
            List<String>.from(doc.data['comments']),
            doc.data['dislikes'],
            doc.data['likes'],
            doc.data['clicks']))
        .toList();
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
  int clicks;

  Promotion(this.title, this.company, this.start_date, this.end_date,
      this.types, this.comments, this.dislikes, this.likes, this.clicks);

  void increaseClicks() async {
    final FirebaseUser user = await _auth.currentUser();
    await Firestore.instance
        .collection('all_users')
        .document(user.uid)
        .get()
        .then((docSnapshot) {
      List<String> clickedBefore =
          List<String>.from(docSnapshot.data["clickedBefore"]);
      if (clickedBefore.contains(this.title)) {
        //don't add
      } else {
        this.clicks++;
        Firestore.instance
            .collection('web_promotion')
            .document(this.title)
            .updateData({"clicks": this.clicks});
        clickedBefore.add(this.title);
        Firestore.instance
            .collection('all_users')
            .document(user.uid)
            .updateData({'clickedBefore': clickedBefore});
      }
    });
  }
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
  String url = "";
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
    String promourl = "";
    final snapShot = await Firestore.instance
        .collection('web_promotion')
        .document(args.title)
        .get();
    databaselikes = snapShot.data['likes'];
    databasedislikes = snapShot.data['dislikes'];
    promourl = snapShot.data["href"];
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
    } else if (snapShot2.data['liked_promotions'].contains(args.title)) {
      userliked = true;
    } else if (snapShot2.data['disliked_promotions'].contains(args.title)) {
      userdisliked = true;
    }

    setState(() {
      likes = databaselikes;
      dislikes = databasedislikes;
      liked = userliked;
      disliked = userdisliked;
      url = promourl;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    String userid = widget.userid;

    final Promotion args = ModalRoute.of(context).settings.arguments;

    Future<void> share() async {
      await FlutterShare.share(
        title: args.title,
        text: "Don't miss out on this promotion: " +
            args.title +
            ". For more information, visit " + url + ".",
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
          .collection('web_promotion')
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
      if (startdate.isBefore(enddate)) {
        _MyHomePageState()
            ._showstartNotification(args.title, args.title, startdate);
        _MyHomePageState()
            ._showendNotification(args.title, args.title, enddate);
      } else {
        _MyHomePageState()
            ._showstartNotification(args.title, args.title, startdate);
        _MyHomePageState()
            ._showendNotification(args.title, args.title, enddate);
      }
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
          .collection('web_promotion')
          .document(args.title)
          .updateData({'dislikes': dislikes});
      Firestore.instance
          .collection('web_promotion')
          .document(args.title)
          .updateData({'likes': likes});
    }

    _launchURL() async {
      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: false, forceWebView: false);
      } else {
        throw 'Could not launch $url';
      }
    }

    Color likeiconcolour = Colors.black;
    Color dislikeiconcolour = Colors.black;

    if (liked) {
      likeiconcolour = Colors.teal;
    } else if (disliked) {
      dislikeiconcolour = Colors.teal;
    } else if (!liked) {
      likeiconcolour = Colors.black;
    } else if (!disliked) {
      dislikeiconcolour = Colors.black;
    }

    List<Widget> displaylocations() {
      List<Widget> locations = [];
      if (args.company.location.isEmpty) {
        locations.add(Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "No location data available",
              style: TextStyle(color: Colors.black),
            )));
      } else {
        for (String location in args.company.location) {
          locations.add(Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Center(
                  child: Text(
                "• " + location,
                style: TextStyle(color: Colors.black),
                textAlign: TextAlign.center,
              ))));
        }
        locations.add(Padding(
          padding: EdgeInsets.only(bottom: 20),
        ));
      }
      return locations;
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: <Widget>[
            IconButton(
              //EDIT HERE FOR ADD
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                addpromo();
                Toast.show("Promotion added to calendar", context,
                    duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
              },
            ),
            IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  deletepromo();
                  Toast.show("Promotion deleted from calendar", context,
                      duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
                  Navigator.pushNamed(context, MyHomePage.routeName);
                }),
          ],
        ),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Align(
                    alignment: Alignment.center,
//                child: Container(
//                    width: 350,
                    child: Column(mainAxisSize: MainAxisSize.min, children: <
                        Widget>[
                      Container(
                          padding: EdgeInsets.all(20.0),
                          child: Text(args.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ))),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            args.company.logoURL,
                            height: 330,
                            width: 330,
                          ),
                        ),
                      ),
                      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        IconButton(
                            icon: Icon(Icons.thumb_up, color: likeiconcolour),
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
                            }),
                        Text(
                          likes.toString(),
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 5, width: 10),
                        IconButton(
                          icon:
                              Icon(Icons.thumb_down, color: dislikeiconcolour),
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
                        ),
                        Text(
                          dislikes.toString(),
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 5, width: 10),
                        IconButton(
                          icon: Icon(Icons.comment, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CommentPage(args.title, userid)));
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.black),
                          onPressed: share,
                        ),
                        SizedBox(height: 5, width: 5),
                        IconButton(
                          icon:
                              Icon(Icons.open_in_browser, color: Colors.black),
                          iconSize: 30,
                          onPressed: () {
                            _launchURL();
                          },
                        )
                      ]),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(5),
                            height: 80,
                            width: 175,
                            child: Card(
                              color: Colors.teal,
                              child: Padding(
                                padding: EdgeInsets.only(left: 15, top: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: 19.0, color: Colors.black),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: 'Start Date' + '\n',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(text: args.start_date),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(5),
                            height: 80,
                            width: 175,
                            child: Card(
                              color: Colors.teal,
                              child: Padding(
                                padding: EdgeInsets.only(left: 15, top: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: 19.0, color: Colors.black),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: 'End Date' + '\n',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(text: args.end_date),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(5),
                        height: 80,
                        width: 350,
                        child: Card(
                          color: Colors.teal,
                          child: Padding(
                            padding: EdgeInsets.only(left: 15, top: 8),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    fontSize: 19.0, color: Colors.black),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'Company' + '\n',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextSpan(text: args.company.title),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            left: 5, right: 5, top: 5, bottom: 30),
                        width: 350,
                        child: Card(
                          color: Colors.teal,
                          child: ExpansionTile(
                            title: Text('Locations',
                                style: TextStyle(
                                    fontSize: 19.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            children: displaylocations(),
                          ),
                        ),
                      ),
                    ])))));
  }
}
