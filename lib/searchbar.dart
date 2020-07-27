import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:promotionapp/home.dart';
import 'package:google_fonts/google_fonts.dart';

//acts similarly to app bar, with actions and leading, etc.
class PromotionSearch extends SearchDelegate<Promotion> {

  final Stream<UnmodifiableListView<Promotion>> promotions;

  PromotionSearch(this.promotions);

  @override
  String get searchFieldLabel => 'Search...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
      ),
    ];
  }

  @override
  //leading gadget
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    return StreamBuilder<UnmodifiableListView<Promotion>>(
      stream: promotions,
      builder: (context, AsyncSnapshot<UnmodifiableListView<Promotion>> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Text('No Data!',
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final results = snapshot.data.where((x) =>
            x.title.toLowerCase().contains(query) ||
            x.title.contains(query) ||
            x.types.map((types) => types.title.toLowerCase()).toList().contains(query) ||
            x.types.map((types) => types.title).toList().contains(query) ||
            startsWith(x.types.map((types) => types.title).toList(), query) ||
            startsWith(x.types.map((types) => types.title.toLowerCase()).toList(), query) ||
            x.company.title.contains(query) ||
            x.company.title.toLowerCase().contains(query)
        );


        if (results.isEmpty) {
          return Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.teal[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Image(
                    image: AssetImage("assets/kinda_filled_beaver.png")
                  )
                ),
                Text(
                    'No Promotions Found',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(color: Colors.grey[850]),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    )
                )
              ],
            )
          );
        }

        return Container(
            color: Colors.teal[100],
            child: GridView.count(
                crossAxisCount: 2,
                padding: EdgeInsets.all(12.0),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: results.map<Card>((x) => Card(
//                  shadowColor: Colors.grey[300],
//                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(15),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        child: Stack(
                            children: <Widget>[
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15.0),
                                        image: DecorationImage(
                                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7),
                                              BlendMode.dstATop),
                                          image: NetworkImage(
                                            x.company.logoURL,
                                          ),
                                          alignment: Alignment.topCenter,
                                        ),
                                      )
                                  )
                              ),
                              Align(
                                  alignment: Alignment.topLeft.add(Alignment(0.5,0.3)),
                                  child: SizedBox(
                                    width: 130,
                                    height: 100,
                                    child: Text(
                                        x.title,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(color: Colors.grey[850]),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 21,
                                        )
                                    ),
                                  )
                              ),
                            ]),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/promoDetails',
                            arguments: x,
                          );
                        },
                      ),
                    ),
                  ),
                )
                ).toList()
            ));
      },
    );
  }

  bool startsWith(List list, String query) {
    bool isSubString = false;
    list.forEach((item) => {
      if (item.toString().startsWith(query)) {
        isSubString = true
      }
    });
    return isSubString;
  }

}


