import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:promotionapp/main.dart';

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
            x.company.name.contains(query) ||
            x.company.name.toLowerCase().contains(query)
        );


        if (results.isEmpty) {
          return Center(
              child: Text(
                'No Promotions Found',
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black
                )
              )
          );
        }

        return ListView(
          children: results.map<ListTile>((x) => ListTile(
            title: Text(x.title,
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              close(context, x);
              Navigator.pushNamed(
                context,
                ExtractPromoDetails.routeName,
                arguments: x,
              );
            },
          )).toList()
        );
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


