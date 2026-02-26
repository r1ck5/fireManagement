import 'package:flutter/material.dart';
import 'package:flutter_map_arcgis_example/Routes.dart';
import 'package:flutter_map_arcgis_example/mainBindings.dart';
import 'package:flutter_map_arcgis_example/screens/mainScreen.dart';
import 'package:get/get_navigation/get_navigation.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: MainScreen(),
      initialBinding: MainBinding(),
      getPages: Routes.getPages,
    );
  }
}
