import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:promotionapp/calendar.dart';
import 'package:flutter/painting.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Promotions',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
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

  @override

  Icon customIcon = Icon(Icons.search, color: Colors.white);
  Widget customWidget = Align(
      alignment: Alignment(-1.3, 0.0),
      child: Text('View Promotions')
  );
  
  Widget mainWidget = AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.format_list_bulleted,
            color: Colors.white,
          ),
        ),
        title: customWidget,
        actions: <Widget>[
          IconButton(
            icon: customIcon,
          )
        ],
      );
  
  static List<Widget> titles = <Widget>[mainWidget , Text('Promotion Calendar')];

//  Widget customSearchBar = Align(
//    alignment: Alignment(-1.3, 0.0),
//    child: Text('View Promotions'),
//  ); //change title to this

  Widget build(BuildContext context) {
    List<Widget> options = <Widget>[_buildBody(context), Calendar()];
    return Scaffold(
appBar: AppBar(title: titles.elementAt(_selectedIndex)),
      body: _options.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
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
            style: TextStyle(fontSize: 20),
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
            style: TextStyle(fontSize: 20),
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
            style: TextStyle(fontSize: 20),
          ),
        ),
        Container(
          height: 300.0,
          child: _buildSection(context),
        )
      ],
    );
  }

  Widget _buildSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('all_promotions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final promotion = Promotion.fromSnapshot(data);

    return GestureDetector(
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
                  FutureBuilder(
                    future: promotion.company.getLogoUrl(),
                    initialData: "",
                    builder: (BuildContext context, AsyncSnapshot<String> text) {
                      return new Container(
                        height: 140.0,
                        width: 140.0,
                        decoration: new BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(text.data),
                            fit: BoxFit.fill,
                          ),
                        ),
                      );
                    }
                  ),
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

class Promotion {
  final String title;
  final Company company;
  final DocumentReference reference;

  Promotion.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['title'] != null),
        assert(map['company'] != null),
        title = map['title'],
        company = new Company(map['company']);

  Promotion.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Promotion<$title:$company>";
}

class Company {
  final String companyID;

  Company(companyID) : this.companyID = companyID;

  Future<String> getLogoUrl() async {
    return await Firestore.instance.collection('all_companies').document(this.companyID).get().then((DocumentSnapshot ds) {
      return ds.data["logoURL"];});
  }

}
