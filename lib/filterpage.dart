import 'dart:collection';
import 'package:flutter/material.dart';
import 'main.dart';

class PromotionFilter{

  final Stream<UnmodifiableListView<Promotion>> promotions;
  final Map<String,bool> checkedTypeMap;
  final Map<String, bool> checkedCompanyMap;
  final Map<String, bool> checkedDurationMap;

  PromotionFilter(this.promotions, this.checkedTypeMap, this.checkedCompanyMap, this.checkedDurationMap);

}

class ExtractFilterPromotion extends StatelessWidget {

  static const filterRouteName ='/extractArguments';


  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    final PromotionFilter args = ModalRoute.of(context).settings.arguments;

    //doing as AND function for now
    //if all false, count as all inclusive

    return Scaffold(
      appBar: AppBar(
      ),
      body: StreamBuilder<UnmodifiableListView<Promotion>>(
        stream: args.promotions,
        builder: (context, AsyncSnapshot<UnmodifiableListView<Promotion>> snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: Text('No Data'),
            );
          }

          List result = snapshot.data.toList();
          if (args.checkedTypeMap.values.contains(true)){
            //need to filter due to the presence of at least one true
          }

          return ListView(
            children: result.map<ListTile>((promotion) =>
              ListTile(
                  title: Text(promotion.title,
                      style: TextStyle(color: Colors.black)
                  ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/promoDetails',
                    arguments: promotion,
                  );
                },
                )).toList()
          );
        }
      )
    );
  }
}