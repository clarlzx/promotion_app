import 'package:flutter/cupertino.dart';

class convertString {

  static String convertUpperCase(String str) {
    return str.toUpperCase();
  }

  static String convertLowerCase(String str) {
    return str.toLowerCase();
  }

  //except the first word, rest will be small letters
  static String convertCapitalizeFirstWord(String str) {
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  static String convertCapitalizeEachWord(String str) {
    String temp = "";
    for (String s in str.split(" ")) {
      temp += convertCapitalizeFirstWord(s) + " ";
    }
    return temp.trim();
  }

}