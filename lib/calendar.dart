import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:promotionapp/main.dart';

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
  Map<String, String> anothereventlist = {};

  @override
  void initState() {
    super.initState();
    final _selectedDay = new DateTime.now();

    String userid = widget.userid;
    List savedpromoids;
    String promotitle;
    String promostart;
    String promoend;

    // First search for all promotions saved by user
    void search() async {
      Map<String, String> eventlist = {};
      final DocumentSnapshot snapShot = await Firestore.instance
          .collection('all_users')
          .document(userid)
          .get();
      savedpromoids = snapShot.data['saved_promotion'];
      // For every promo get the title, start and end dates and add into map
      for (int i = 0; i < savedpromoids.length; i++) {
        String promoid = savedpromoids[i];
        final DocumentSnapshot ds = await Firestore.instance
            .collection('all_promotions')
            .document(promoid)
            .get();
        promotitle = ds.data['title'];
        promostart = ds.data['start_date'];
        promoend = ds.data['end_date'];
        eventlist[savedpromoids[i]] = promotitle;

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
            if (_events.containsKey(date.add(new Duration(days: i)))) {
              _events[date.add(new Duration(days: i))].add(promoid);
            } else {
              _events[date.add(new Duration(days: i))] = [promoid];
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
            if (_events.containsKey(startdate)) {
              _events[startdate].add(promoid);
            } else {
              _events[startdate] = [promoid];
            }
            startdate = startdate.add(new Duration(days: 1));
          }
        }
      }
      setState(() {
        anothereventlist = eventlist;
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
        selectedColor: Colors.deepOrange[400],
        todayColor: Colors.deepOrange[200],
        markersColor: Colors.brown[700],
        outsideDaysVisible: false,
        weekdayStyle: TextStyle().copyWith(color: Colors.black),
      ),
      headerStyle: HeaderStyle(
        titleTextStyle:
            TextStyle().copyWith(color: Colors.black, fontSize: 17.0),
        formatButtonTextStyle:
            TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
        formatButtonDecoration: BoxDecoration(
          color: Colors.deepOrange[400],
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      onDaySelected: _onDaySelected,
      onVisibleDaysChanged: _onVisibleDaysChanged,
      onCalendarCreated: _onCalendarCreated,
    );
  }

  // More advanced TableCalendar configuration (using Builders & Styles)
  Widget _buildTableCalendarWithBuilders() {
    return TableCalendar(
      locale: 'pl_PL',
      calendarController: _calendarController,
      events: _events,
//      holidays: _holidays,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: '',
        CalendarFormat.week: '',
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.blue[800]),
        holidayStyle: TextStyle().copyWith(color: Colors.blue[800]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, _) {
          return FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(_animationController),
            child: Container(
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.only(top: 5.0, left: 6.0),
              color: Colors.deepOrange[300],
              width: 100,
              height: 100,
              child: Text(
                '${date.day}',
                style: TextStyle().copyWith(fontSize: 16.0),
              ),
            ),
          );
        },
        todayDayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            padding: const EdgeInsets.only(top: 5.0, left: 6.0),
            color: Colors.amber[400],
            width: 100,
            height: 100,
            child: Text(
              '${date.day}',
              style: TextStyle().copyWith(fontSize: 16.0),
            ),
          );
        },
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];

          if (events.isNotEmpty) {
            children.add(
              Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              ),
            );
          }

          if (holidays.isNotEmpty) {
            children.add(
              Positioned(
                right: -2,
                top: -2,
                child: _buildHolidaysMarker(),
              ),
            );
          }

          return children;
        },
      ),
      onDaySelected: (date, events) {
        _onDaySelected(date, events);
        _animationController.forward(from: 0.0);
      },
      onVisibleDaysChanged: _onVisibleDaysChanged,
      onCalendarCreated: _onCalendarCreated,
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: _calendarController.isSelected(date)
            ? Colors.brown[500]
            : _calendarController.isToday(date)
                ? Colors.brown[300]
                : Colors.blue[400],
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHolidaysMarker() {
    return Icon(
      Icons.add_box,
      size: 20.0,
      color: Colors.blueGrey[800],
    );
  }

  Widget _buildEventList() {

    Future<DocumentSnapshot> mappingfunc(event) async {
      DocumentSnapshot promo = await Firestore.instance
          .collection('all_promotions')
          .document(event)
          .get();
      return promo;
    }

    Future<DocumentSnapshot> mappingfunc2(company) async {
      DocumentSnapshot comp = await Firestore.instance
          .collection('all_companies')
          .document(company)
          .get();
      return comp;
    }

    return ListView(
      children: _selectedEvents.map((event) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(width: 0.8),
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(anothereventlist[event],
                style: TextStyle(color: Colors.black)),
            onTap: () {
              mappingfunc(event).then((DocumentSnapshot promotion) {
                mappingfunc2(promotion.data['company'])
                    .then((DocumentSnapshot company) {

                      // ExtractPromoDetails.routeName
                  Navigator.pushNamed(context, '/promoDetails',
                      arguments: new Promotion(
                          event,
                          new Company(
                              company.data['title'],
                              company.data['location'],
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
        );
      }).toList(),
    );
  }
}
