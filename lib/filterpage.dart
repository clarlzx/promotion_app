import 'dart:collection';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class PromotionFilter{

  final Stream<UnmodifiableListView<Promotion>> promotions;
  final Map<String,bool> checkedTypeMap;
  final Map<String, bool> checkedCompanyMap;
  final Map<String, bool> checkedDurationMap;
  final Map<String, bool> checkedLocationMap;
  final Stream<UnmodifiableListView<Company>> companies;

  PromotionFilter(this.promotions, this.checkedTypeMap, this.checkedCompanyMap,
      this.checkedDurationMap, this.checkedLocationMap, this.companies);

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

          Future _getLocation() async{
            List<Promotion> near_me = [];
            List<String> near_companies = [];
            List<String> alrcheckedCompanies = [];
            Position curr_position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

            List<Company> companiesList = await args.companies.first.then((companyLst) {
              return companyLst;
            });

            for (Promotion promo in result) {
              if (alrcheckedCompanies.contains(promo.company.title)) {
                if (near_companies.contains(promo.company.title)) {
                  near_me.add(promo);
                }
              } else {
                for (String location in promo.company.location) {
                  alrcheckedCompanies.add(promo.company.title);
                  List<Placemark> placemark = await Geolocator()
                      .placemarkFromAddress(location);
                  Position temp_position = placemark[0].position;
                  double distance = await Geolocator().distanceBetween(
                      curr_position.latitude,
                      curr_position.longitude, temp_position.latitude,
                      temp_position.longitude);
                  if (distance <= 3500) {
                    near_companies.add(
                        promo.company.title); //distance in metres
                    near_me.add(promo);
                    break;
                  }
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
                  } else {
                    return Container(
                        color: Colors.teal[100],
                        child: GridView.count(
                            crossAxisCount: 2,
                            padding: EdgeInsets.all(12.0),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: snapshot.data.map<Card>((x) => Card(
//                              shadowColor: Colors.grey[300],
//                              elevation: 5.0,
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
                  }
                } else if (snapshot.hasError) {
                  print(snapshot.error);
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
                            'Sorry an error has occurred',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(color: Colors.grey[850]),
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            )
                          )
                        ],
                      )
                  );
                } else {
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
                              'Please wait while\nwe retrieve the promotions',
                              style: GoogleFonts.roboto(
                                textStyle: TextStyle(color: Colors.grey[850]),
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                          ),
                          CircularProgressIndicator(
                          ),
                        ],
                      )
                  );
                }
              }
            );
          }

          return Container(
              color: Colors.teal[100],
              child: GridView.count(
                  crossAxisCount: 2,
                  padding: EdgeInsets.all(12.0),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: result.map<Card>((x) => Card(
//                    shadowColor: Colors.grey[300],
//                    elevation: 5.0,
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
    final now = DateTime.now();
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