import 'dart:collection';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class PromotionFilter{

  final Stream<UnmodifiableListView<Promotion>> promotions;
  final Map<String,bool> checkedTypeMap;
  final Map<String, bool> checkedCompanyMap;
  final Map<String, bool> checkedDurationMap;
  final Map<String, bool> checkedLocationMap;

  PromotionFilter(this.promotions, this.checkedTypeMap, this.checkedCompanyMap, this.checkedDurationMap, this.checkedLocationMap);

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

          var result = snapshot.data.toList();

          if (args.checkedTypeMap.values.contains(true)){
            result = result.where((promo) => typeFilter(promo, args.checkedTypeMap)).toList();
          }

          if (args.checkedCompanyMap.values.contains(true)) {
            result = result.where((promo) => companyFilter(promo, args.checkedCompanyMap)).toList();
          }

          if (args.checkedDurationMap.values.contains(true)){
            result = result.where((promo) => durationFilter(promo, args.checkedDurationMap)).toList();
          }

          if (result.isEmpty) {
            return Center(
              child: Text(
                'No Promotions Found',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0
                ),
              )
            );
          }

          Future _getLocation() async{
            List<Promotion> near_me = [];
            Position curr_position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

            for (Promotion promo in result) {
              for (String location in promo.company.location) {
                List<Placemark> placemark = await Geolocator().placemarkFromAddress(location);
                Position temp_position = placemark[0].position;
                double distance = await Geolocator().distanceBetween(curr_position.latitude,
                    curr_position.longitude, temp_position.latitude, temp_position.longitude);
                if (distance <= 3500) { //distance in metres
                  near_me.add(promo);
                  break;
                }
              }
            }
            return near_me;
          }

          if (args.checkedLocationMap.values.first) {
            return FutureBuilder(
              future: _getLocation(),
              builder: (context, snapshot){
                if (snapshot.hasData) {
                  if (snapshot.data.toList().isEmpty) {
                    return Center(
                        child: Text(
                          'No Promotions Found',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0
                          ),
                        )
                    );
                  } else {
                    return ListView(
                        children: snapshot.data.map<ListTile>((promotion) =>
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
                } else if (snapshot.hasError) {
                  return Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                  );
                } else {
                  return Center(
                    child: SizedBox(
                      child: CircularProgressIndicator(),
                      width: 60,
                      height: 60,
                    )
                  );
                }
              }
            );
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

  bool typeFilter(Promotion promo, Map<String, bool> checkedTypeMap) {
    for (String key in checkedTypeMap.keys) {
      if (checkedTypeMap[key] && promo.types.map((t) => t.title).contains(key)) {
          return true;
      }
    }
    return false;
  }

  bool companyFilter(Promotion promo, Map<String, bool> checkedCompanyMap) {
    for (String key in checkedCompanyMap.keys) {
      if (checkedCompanyMap[key] && promo.company.title == key) {
        return true;
      }
    }
    return false;
  }

  bool durationFilter(Promotion promo, Map<String, bool> checkedDurationMap) {
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final start_date = DateFormat("d/M/y").parse(promo.start_date);
    final end_date = DateFormat("d/M/y H:m").parse(promo.end_date + ' 23:59');

    bool promotionOnToday(DateTime today) {
      if ((today.isAfter(start_date) && today.isBefore(end_date))
          || today.isAtSameMomentAs(start_date)
          || today.isAtSameMomentAs(end_date)) {
        return true;
      }
      return false;
    }

    if (checkedDurationMap['Today']) {
      if (promotionOnToday(now)){
        return true;
      }
    }

    if (checkedDurationMap['This Week']) {
      final now_string = now.day.toString() + "/" + now.month.toString() + "/" + now.year.toString();
      final days_to_start_week = now.weekday - 1;
      final days_to_end_week = 7 - now.weekday;
      final start_week = DateFormat("d/M/y").parse(now_string).subtract(Duration(days: days_to_start_week));
      final end_week = DateFormat("d/M/y H:m").parse(now_string + " 23:59").add(Duration(days: days_to_end_week));
      var current = start_week;
      while (!current.isAfter(end_week)) {
        if (promotionOnToday(current)) {
          return true;
        }
        current = current.add(Duration(days: 1));
      }
    }

    return false;

  }



}