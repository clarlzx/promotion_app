import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:promotionapp/home.dart';
import 'package:google_fonts/google_fonts.dart';

class Calendar extends StatelessWidget {
  String userid;

  Calendar(String userid) {
    this.userid = userid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyHomePage(userid),
    );
  }
}

//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Table Calendar Demo',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//      ),
//      home: MyHomePage(title: 'Table Calendar Demo'),
//    );
//  }
//}

class MyHomePage extends StatefulWidget {
  MyHomePage(String userid) {
    this.userid = userid;
  }

  String userid;

//  MyHomePage({Key key, this.title}) : super(key: key);
//
//  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Map<DateTime, List> _events = {};
  List _selectedEvents;
  AnimationController _animationController;
  CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    final _selectedDay = new DateTime.now();

    String userid = widget.userid;
    List savedpromotitles;
    String promostart;
    String promoend;

    // First search for all promotions saved by user
    void search() async {
      Map<DateTime, List> aneventmap = {};
      final DocumentSnapshot snapShot = await Firestore.instance
          .collection('all_users')
          .document(userid)
          .get();
      savedpromotitles = snapShot.data['saved_promotion'];
      // For every promo get the title, start and end dates and add into map
      for (int i = 0; i < savedpromotitles.length; i++) {
        String promotitle = savedpromotitles[i];
        final DocumentSnapshot ds = await Firestore.instance
            .collection('web_promotion')
            .document(promotitle)
            .get();
        if (ds.exists && ds != null) {
          promostart = ds.data['start_date'];
          promoend = ds.data['end_date'];
          // If promotion within one month
          if (promostart.substring(3, 5) == promoend.substring(3, 5)) {
            // Check if there are existing promos on the day
            DateTime date = new DateTime(
                int.parse(promostart.substring(6)),
                int.parse(promostart.substring(3, 5)),
                int.parse(promostart.substring(0, 2)));
            for (int i = 0;
            i <=
                (int.parse(promoend.substring(0, 2)) -
                    int.parse(promostart.substring(0, 2)));
            i++) {
              if (aneventmap.containsKey(date.add(new Duration(days: i)))) {
                aneventmap[date.add(new Duration(days: i))].add(promotitle);
              } else {
                aneventmap[date.add(new Duration(days: i))] = [promotitle];
              }
            }
          } else {
            DateTime startdate = new DateTime(
                int.parse(promostart.substring(6)),
                int.parse(promostart.substring(3, 5)),
                int.parse(promostart.substring(0, 2)));
            DateTime enddate = new DateTime(
                int.parse(promoend.substring(6)),
                int.parse(promoend.substring(3, 5)),
                int.parse(promoend.substring(0, 2)));
            while (!startdate.isAfter(enddate)) {
              if (aneventmap.containsKey(startdate)) {
                aneventmap[startdate].add(promotitle);
              } else {
                aneventmap[startdate] = [promotitle];
              }
              startdate = startdate.add(new Duration(days: 1));
            }
          }
        }
      }
      setState(() {
        _events = aneventmap;
      });
    }

    search();

    _selectedEvents = _events[_selectedDay] ?? [];
    _calendarController = CalendarController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime day, List events) {
    print('CALLBACK: _onDaySelected');
    setState(() {
      _selectedEvents = events;
    });
  }

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    print('CALLBACK: _onVisibleDaysChanged');
  }

  void _onCalendarCreated(
      DateTime first, DateTime last, CalendarFormat format) {
    print('CALLBACK: _onCalendarCreated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(
//        title: Text(widget.title),
//      ),
      backgroundColor: Colors.grey[800],
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          // Switch out 2 lines below to play with TableCalendar's settings
          //-----------------------
          _buildTableCalendar(),
          // _buildTableCalendarWithBuilders(),
          const SizedBox(height: 8.0),
          const SizedBox(height: 8.0),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  // Simple TableCalendar configuration (using Styles)
  Widget _buildTableCalendar() {
    return TableCalendar(
      calendarController: _calendarController,
      events: _events,
//      holidays: _holidays,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        selectedColor: Colors.teal,
        todayColor: Colors.teal[300],
        markersColor: Colors.white,
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.teal[200]),
        weekdayStyle: TextStyle().copyWith(color: Colors.white),
        selectedStyle: TextStyle().copyWith(color: Colors.white),
        todayStyle: TextStyle().copyWith(color: Colors.white),
      ),
      headerStyle: HeaderStyle(
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        titleTextStyle:
            TextStyle().copyWith(color: Colors.white, fontSize: 17.0),
        formatButtonTextStyle:
            TextStyle().copyWith(color: Colors.black, fontSize: 15.0),
        formatButtonDecoration: BoxDecoration(
          color: Colors.teal[100],
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle().copyWith(color: Colors.white),
        weekendStyle: TextStyle().copyWith(color: Colors.teal[200]),
      ),
      onDaySelected: _onDaySelected,
      onVisibleDaysChanged: _onVisibleDaysChanged,
      onCalendarCreated: _onCalendarCreated,
    );
  }

  Widget _buildEventList() {
    Future<DocumentSnapshot> mappingfunc(event) async {
      DocumentSnapshot promo = await Firestore.instance
          .collection('web_promotion')
          .document(event)
          .get();
      return promo;
    }

    Future<DocumentSnapshot> mappingfunc2(company) async {
      DocumentSnapshot comp = await Firestore.instance
          .collection('web_companies')
          .document(company)
          .get();
      return comp;
    }

    return ListView(
      padding: EdgeInsets.only(left: 20, right: 20),
      children: _selectedEvents.map((event) {
        return Container(
          decoration: BoxDecoration(
            //color: Colors.lightGreen[100],
            //border: Border.all(width: 0.8),
            //borderRadius: BorderRadius.circular(12.0),
          ),
          //margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            ),
            child: ListTile(
              contentPadding: EdgeInsets.only(top: 6, bottom: 6, left: 10, right: 10),
            title: Center(
        child: Text(event, style: GoogleFonts.roboto(
        textStyle: TextStyle(color: Colors.grey[900]), fontSize: 15, fontWeight: FontWeight.w300
        ), textAlign: TextAlign.center,)),
//                style: TextStyle(color: Colors.grey[900], fontSize: 15), textAlign: TextAlign.center,)),
            onTap: () {
              mappingfunc(event).then((DocumentSnapshot promotion) {
                mappingfunc2(promotion.data['company'])
                    .then((DocumentSnapshot company) {
                      List<String> location = [];
                      if (company.data['location'] != null) {
                        location = List<String>.from(company.data['location']);
                      }
                      // ExtractPromoDetails.routeName
                  Navigator.pushNamed(context, '/promoDetails',
                      arguments: new Promotion(
                          event,
                          new Company(
                              company.data['title'],
                              location,
                              company.data['logoURL']),
                          promotion.data['start_date'],
                          promotion.data['end_date'],
                          promotion.data['types'],
                          List<String>.from(promotion.data['comments']),
                          promotion.data['dislikes'],
                          promotion.data['likes'],
                          promotion.data['clicks']
                      ));
                });
              });
              print('$event tapped!');
            },
          ),
            color: Colors.teal[100],
        ),);
      }).toList(),
    );
  }
}
