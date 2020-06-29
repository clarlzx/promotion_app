import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; //used to add time lag for checkbox button
import 'main.dart';

class FilterList extends StatefulWidget {

  FilterList({Key key, @required this.type, this.typeMap, this.checkedTypeMap}): super(key: key);

  final HashMap<Type, List<Type>> typeMap;
  final Type type;
  final Map<String,bool> checkedTypeMap;

  @override
  State createState() => _FilterState();

}

class _FilterState extends State<FilterList> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (!widget.type.child_id.isEmpty) {
      return ExpansionTile(
        title: Text(widget.type.title),
        children: <Widget>[
          for (Type childType in widget.typeMap[widget.type])
            CheckboxListTile(
              title: Text(childType.title, style: TextStyle()),
              value: widget.checkedTypeMap[childType.id],
              onChanged: (val) {
                setState(() {
                  widget.checkedTypeMap[childType.id] = val;
                });
              },
            )
        ],
      );
    } else {
      return Container(
        height: 0.0,
        width: 0.0,
      );
    }
  }
}

class FilterCompanyList extends StatefulWidget {

  FilterCompanyList({Key key, @required this.company, this.checkedCompanyMap}): super(key: key);

  final Company company;
  final Map<String, bool> checkedCompanyMap;

  @override
  State createState() => _FilterCompanyState();

}

class _FilterCompanyState extends State<FilterCompanyList> {

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.company.name),
      value: widget.checkedCompanyMap[widget.company.id],
      onChanged: (newValue) {
        setState(() {
          widget.checkedCompanyMap[widget.company.id] = newValue;
        });
      },
    );
  }
}

class FilterDurationList extends StatefulWidget {

  FilterDurationList({Key key, @required this.title, this.checkedDurationMap}): super(key: key);

  final String title;
  final Map<String, bool> checkedDurationMap;

  @override
  State createState() => _FilterDurationState();

}

class _FilterDurationState extends State<FilterDurationList> {

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.title),
      value: widget.checkedDurationMap[widget.title],
      onChanged: (newValue) {
        setState(() {
          widget.checkedDurationMap[widget.title] = newValue;
        });
      },
    );
  }
}