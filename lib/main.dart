import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:promotionapp/calendar.dart';
import 'package:flutter/painting.dart';

//void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Promotions',
      home: MyHomePage(),
      routes: {
        ExtractPromoDetails.routeName: (context) => ExtractPromoDetails(),
      },
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

  Icon customIcon = Icon(Icons.search, color: Colors.white);
  Widget customWidget = Text('View Promotions');

  @override
  Widget build(BuildContext context) {

    GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    Widget mainWidget = AppBar(
      title: customWidget,
      leading: IconButton(
        icon: Icon(
            Icons.filter_list,
            color: Colors.white
        ),
        onPressed: () {
          _scaffoldKey.currentState.openDrawer();
        }
      ),
      actions: <Widget>[
        IconButton(
          onPressed: () {
            setState(() {
              if (this.customIcon.icon == Icons.search) {
                this.customIcon = Icon(Icons.cancel, color: Colors.white);
                this.customWidget = TextField(
                  textInputAction: TextInputAction.go,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                );
              } else {
                this.customIcon = Icon(Icons.search, color: Colors.white);
                this.customWidget = Text('View Promotions');
              }
            });
          },
          icon: customIcon,
        )
      ],
    );


    List<Widget> titles = <Widget>[mainWidget , AppBar(title: Text('Promotion Calendar'))];
    List<Widget> options = <Widget>[_buildBody(context), Calendar()];

    return Scaffold(
      key: _scaffoldKey,
      appBar: titles.elementAt(_selectedIndex),
      body: options.elementAt(_selectedIndex),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header'),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
            ),
            ListTile(
              title: Text('Item 1'),
            ),
            ListTile(
              title: Text('Item 2'),
            )
          ],
        )
      ),
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
      onTap: () {
        Navigator.pushNamed(
          context,
          ExtractPromoDetails.routeName,
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

class Promotion{
  final String title;
  final Company company;
  final String start_date;
  final String end_date;
  DocumentReference reference;

  Promotion(this.title, this.company, this.start_date, this.end_date);

  Promotion.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['title'] != null),
        assert(map['company'] != null),
        assert(map['start_date'] != null),
        assert(map['end_date'] != null),
        title = map['title'],
        company = new Company(map['company']),
        start_date = map['start_date'],
        end_date = map['end_date'];

  Promotion.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

}

class Company {
  final String companyID;
  String name;
  List locations;
  String logoURL;

  Company(companyID) : this.companyID = companyID;

  Future<String> getLogoUrl() async {
    return await Firestore.instance.collection('all_companies').document(this.companyID).get().then((DocumentSnapshot ds) {
      this.name = ds.data["name"];
      this.locations = ds.data["locations"];
      this.logoURL = ds.data["logoURL"];
      return this.logoURL;});
  }

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
                              style: TextStyle(fontSize: 16.0)
                            ),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(fontSize: 16.0)
                              ),
                            )
                          ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          )
        )
      )
    );
  }
}

