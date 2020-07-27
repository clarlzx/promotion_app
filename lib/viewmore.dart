import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'dart:collection';
import 'package:google_fonts/google_fonts.dart';

class ViewMore {

  final Stream<UnmodifiableListView<Promotion>> promotions;
  final String str;
  ViewMore(this.promotions, this.str);

}

class ViewMoreScreen extends StatelessWidget{

  static const routeName = '/extractArguments';

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    final ViewMore args= ModalRoute.of(context).settings.arguments;

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(9.0),
            ),
            Container(
              child: Align(
                alignment: Alignment(-0.65,0),
                child: Text("All " + args.str + " Deals",
                  style: GoogleFonts.roboto(
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 45,
                    ),
                  )
                )
              )
            ),
            Padding(
              padding: EdgeInsets.all(7.0),
            ),
            StreamBuilder<UnmodifiableListView<Promotion>>(
                stream: args.promotions,
                initialData: UnmodifiableListView<Promotion>([]),
                builder: (context, AsyncSnapshot<UnmodifiableListView<Promotion>> snapshot) {
                  return Column(
                    children: snapshot.data.map((promo) =>
                        GestureDetector(
                          child: Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0)
                              ),
                              color: Colors.white,
                              child: ListTile(
                                  leading: Image(
                                    image: NetworkImage(promo.company.logoURL),
                                  ),
                                  title: Text(promo.title + "\n",
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 17.0,
                                          )
                                      )
                                  ),
                                  subtitle: Text("click to view",
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 15,
                                          )
                                      )
                                  )
                              )
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context,
                                '/promoDetails',
                                arguments: promo
                            );
                          }
                      )
                  ).toList(),
                );
              }
            )
          ],
        )
      )
    );
  }
}