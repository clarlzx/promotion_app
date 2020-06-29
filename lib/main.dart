import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:promotionapp/calendar.dart';
import 'package:flutter/painting.dart';
import 'package:rxdart/rxdart.dart';
import 'searchbar.dart';
import 'package:flutter/scheduler.dart';
import 'filter.dart';
import 'filterpage.dart';

class MyApp extends StatelessWidget {
  final PromotionBloc bloc;

  MyApp({Key key, this.bloc}) : super(key: key);

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
      home: MyHomePage(
        bloc: bloc
    ),
      routes: {
        '/promoDetails': (context) => ExtractPromoDetails(),
        '/filterPage': (context) => ExtractFilterPromotion(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {

  final PromotionBloc bloc;

  MyHomePage({Key key, this.bloc}) : super(key: key);

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Icon customIcon = Icon(Icons.search, color: Colors.white);
  Widget customWidget = Text('View Promotions');

  @override
  Widget build(BuildContext context) {

    Widget mainWidget = AppBar(
      title: customWidget,
      actions: <Widget>[
        IconButton(
          onPressed: () {
            showSearch(
                context: context,
                delegate: PromotionSearch(widget.bloc.promotions)
            );
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


    List<Widget> titles = <Widget>[mainWidget , AppBar(title: Text('Promotion Calendar'))];
    List<Widget> options = <Widget>[_buildBody(context), Calendar()];

    return Scaffold(
      appBar: titles.elementAt(_selectedIndex),
      body: options.elementAt(_selectedIndex),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height*0.14,
              child: DrawerHeader(
                child: Text(
                  'Filter Promotions',
                  style: TextStyle(fontSize: 20.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                ),
              )
            ),
            _buildFilter(context),
          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>
        [
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
    return ListView (
      padding: EdgeInsets.all(8.0),
      children: <Widget>[
        Padding (
          padding: EdgeInsets.all(3.0),
        ),
        Container(
          alignment: Alignment(-0.89,0.0),
          child: Text(
            "Hot Deals",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20),
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
          alignment: Alignment(-0.89,0.0),
          child: Text(
            "New Deals",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20
            ),
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
          alignment: Alignment(-0.89,0.0),
          child: Text(
            "All Deals",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20
            ),
          ),
        ),
        Container(
          height: 300.0,
          child: _buildSection(context),
        )
      ],
    );
  }

  Widget _buildFilter(BuildContext context) {

    final Map<String, bool> checkedTypeMap = Map<String,bool>();
    final Map<String, bool> checkedCompanyMap = Map<String, bool>();
    final Map<String, bool> checkedDurationMap = Map<String, bool>();

    return Container(
        height: MediaQuery.of(context).size.height*0.86,
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
                alignment: FractionalOffset(0.09,0.5),
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
                alignment: FractionalOffset(0.09,0.5),
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
                alignment: FractionalOffset(0.09,0.5),
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
              child: Text('Filter',
                style: TextStyle(color: Colors.black),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
            )
          ],
        )
    );
  }

  Widget _buildTypeFilter(BuildContext context, Map<String,bool> checkedTypeMap) {
    return StreamBuilder<UnmodifiableListView<Type>>(
      stream: widget.bloc.typesStream,
      initialData: UnmodifiableListView<Type>([]),
      builder: (context,
          AsyncSnapshot<UnmodifiableListView<Type>> snapshot) {
        HashMap<Type, List<Type>> typeMap = HashMap<Type, List<Type>>();

        //using child_id
        //for now excluding category mains, hence no select all function

        snapshot.data.toList().forEach((type) {
          if (!type.child_id.isEmpty) {
            typeMap[type] = type.child_id.map((child_id) =>
                snapshot.data.toList().firstWhere((t) => t.id == child_id))
                .toList();
          } else {
            checkedTypeMap[type.id] = false;
          }
        });
        return Column(
          children: snapshot.data.toList().map((x) =>
              _buildFilterListItem(x, typeMap, checkedTypeMap)).toList()
        );
      }
    );
  }

  //very inefficient for now, because the hashmap will be repeated across each hashmap item
  Widget _buildFilterListItem(Type type, HashMap<Type, List<Type>> typeMap, Map<String, bool> checkedTypeMap) {
    return FilterList(type: type, typeMap: typeMap, checkedTypeMap: checkedTypeMap);
  }

  Widget _buildCompanyFilter(BuildContext context, Map<String,bool> checkedCompanyMap) {
    return ExpansionTile(
      title: Text('Companies'),
      children: <Widget>[
        StreamBuilder<UnmodifiableListView<Company>>(
            stream: widget.bloc.companyStream,
            initialData: UnmodifiableListView<Company>([]),
            builder: (context, AsyncSnapshot<UnmodifiableListView<Company>> snapshot) {

              snapshot.data.forEach((company) {
                checkedCompanyMap[company.id] = false;
              });

              return Column(
                children: snapshot.data.toList().map((x) =>
                    _buildCompanyFilterListItem(x, checkedCompanyMap)).toList(),
              );
            }
        )
      ],
    );
  }

  Widget _buildCompanyFilterListItem(Company company, Map<String, bool> checkedCompanyMap) {
    return FilterCompanyList(company: company, checkedCompanyMap: checkedCompanyMap);
  }

  Widget _buildDurationFilter(BuildContext context, Map<String, bool> checkedDurationMap) {

    checkedDurationMap['Today'] = false;
    checkedDurationMap['This Week'] = false;

    return ExpansionTile(
      title: Text('Duation'),
      children: checkedDurationMap.keys.map((keys) =>
          FilterDurationList(title: keys, checkedDurationMap: checkedDurationMap)).toList()
    );
  }
        Widget _buildSection(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Promotion>>(
      stream: widget.bloc.promotions,
      initialData: UnmodifiableListView<Promotion>([]),
      builder: (context, snapshot) => ListView(
        scrollDirection: Axis.horizontal,
        children: snapshot.data.map(_buildListItem).toList(),
      )
    );
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
              child: Column(
                  children: <Widget>[
                    Container(
                      height: 140.0,
                      width: 140.0,
                      decoration: new BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(promotion.company.logoURL),
                          fit: BoxFit.fill,
                        )
                      ),
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
                      child: Text(
                        promotion.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black)
                      ),
                    ),
                  ]
              ),
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

  Stream<UnmodifiableListView<Promotion>> get promotions => _promotionsSubject.stream;
  Stream<UnmodifiableListView<Type>> get typesStream => _typesSubject.stream;
  Stream<UnmodifiableListView<Company>> get companyStream => _companySubject.stream;

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
    final promotionQShot = await Firestore.instance.collection('all_promotions').getDocuments();
    final companyQShot = await Firestore.instance.collection('all_companies').getDocuments();
    final typeQShot = await Firestore.instance.collection('all_types').getDocuments();

    companyQShot.documents.forEach((doc) {
      _companies[doc.documentID] = Company(doc.documentID, doc.data['name'], doc.data['locations'], doc.data['logoURL']);
    });

    _companyStream = _companies.values.toList();

    typeQShot.documents.forEach((doc) {
      _types[doc.documentID] = Type(doc.documentID, doc.data['title'], doc.data['child_id']);
      _typesStream.add(Type(doc.documentID, doc.data['title'], doc.data['child_id']));
    });

    _promotions = promotionQShot.documents.map(
            (doc) => Promotion(
            doc.data['title'],
            _companies[doc.data['company']],
            doc.data['start_date'],
            doc.data['end_date'],
            doc.data['item_type'].map((type) => _types[type]).toList())
    ).toList();

  }


}

class Promotion {
  final String title;
  final Company company;
  final String start_date;
  final String end_date;
  final List types;

  Promotion(this.title, this.company, this.start_date, this.end_date, this.types);

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

class ExtractPromoDetails extends StatelessWidget{
  static const routeName = '/extractArguments';

  @override
  Widget build(BuildContext context) {
    final Promotion args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            //EDIT HERE FOR ADD
            icon: Icon(Icons.add,
              color: Colors.white
            )
          ),
          IconButton(
            icon: Icon(Icons.share,
            color: Colors.white
            )
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
                  child: Text(
                    args.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )
                  )
                ),
                Card(
                  elevation: 10.0,
                  child: Container(
                    width: 350,
                    child: Image(
                      image: NetworkImage(args.company.logoURL),
                      fit: BoxFit.fitWidth,
                    )
                  )
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                ),
                Align(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 19.0, color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(text: 'Company: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: args.company.name),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 19.0, color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(text: 'Dates: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: args.start_date + ' - ' + args.end_date),
                          ],
                        ),
                      ),
                      Text(
                        'Locations:',
                        style: TextStyle(fontSize: 19.0, color: Colors.black, fontWeight: FontWeight.bold)
                      ),
                      for (String location in args.company.locations)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "• ",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0)
                            ),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0)
                              ),
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
            )
          )
        )
      )
    );
  }
}

