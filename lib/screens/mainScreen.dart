import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_arcgis/flutter_map_arcgis.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_arcgis_example/controllers/alarm_ctrl.dart';
import 'package:flutter_map_arcgis_example/controllers/report_ctrl.dart';
import 'package:flutter_map_arcgis_example/widgets/alarm_Widget.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';
import '../Image_Paths.dart';
import '../Routes.dart';
import '../api/fire_management_api.dart';
import '../api/weather_api.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // final map = Get.find<AirMapController>();
  final wheatherApi = Get.find<WeatherApi>();
  final mapController = MapController();
  final spots = <Marker>[];
  final windSpeeds = <Marker>[];
  final windDirections = <Marker>[];
  StreamSubscription<MapEvent>? mapSub;
  
  double zoom = 10;

  @override
  void dispose() {
    mapSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    getViirData();

    // subscribe to map events
    mapSub = mapController.mapEventStream.debounceTime(Duration(milliseconds: 600)).listen((event) async {
      zoom = mapController.zoom ?? 10;
      final ws = await wheatherApi.getWindSpeedData(latitude: event.center.latitude, longitude: event.center.longitude);
      windSpeeds.add(Marker(
        point: LatLng(ws.latitude ??0, ws.longitude ??0),
        width: 80,
        height: 80,
        builder: (context) => Icon(Icons.air)),
      );

      final wd = await wheatherApi.getWindDirectionData(latitude: event.center.latitude, longitude: event.center.longitude);
      windDirections.add(Marker(
        point: LatLng((wd.latitude ??0) +0.05, (wd.longitude ??0) + 0.05),
        width: 80,
        height: 80,
        builder: (context) => Icon(Icons.arrow_forward)),
      );
    });

    // get wind speed and direction when map is ready
    mapController.onReady.then((value) async {
     zoom = mapController.zoom ?? 10;
      final ws = await wheatherApi.getWindSpeedData(latitude: mapController.center.latitude, longitude: mapController.center.longitude);
      windSpeeds.add(Marker(
        point: LatLng(ws.latitude ??0, ws.longitude ??0),
        width: 80,
        height: 80,
        builder: (context) => Icon(Icons.air)),
      );

      final wd = await wheatherApi.getWindDirectionData(latitude: mapController.center.latitude, longitude: mapController.center.longitude);
      windDirections.add(Marker(
        point: LatLng((wd.latitude ??0) +0.05, (wd.longitude ??0) + 0.05),
        width: 80,
        height: 80,
        builder: (context) => Icon(Icons.arrow_forward)),
      );
    });
  }



  getViirData() async {
    final data = await FireManagementApi().getViirData();
    spots.addAll(data.map((i) =>
      Marker(
        point: LatLng(i.latitude, i.longitude),
        width: 80,
        height: 80,
        builder: (context) => Container(
          color: Color.fromARGB(0, 256 ~/(i.brightTi4 - 273.15), 0, 0),
          height: i.scan,
          width: i.track,
          child: Icon(Icons.local_fire_department)),
    )));
  }

    List<Marker> _createEllipse(LatLng center, double latRadius, double lngRadius) {
    final int steps = 36; // The number of points to define the ellipse
    List<Marker> ellipseMarkers = [];

    for (int i = 0; i < steps; i++) {
      double theta = (i / steps) * (2 * 3.14159265358979323846);
      double lat = center.latitude + latRadius * (3.14159265358979323846 / 180) * cos(theta);
      double lng = center.longitude + lngRadius * (3.14159265358979323846 / 180) * sin(theta);

      ellipseMarkers.add(
        Marker(
          width: 10.0,
          height: 10.0,
          point: LatLng(lat, lng),
          builder: (context) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return ellipseMarkers;
  }


  double baseSize = 80.0;

  double getZoomScaledSize(double baseSize) {
    return baseSize * zoom * 0.15; // Adjust this formula as needed.
  }

  @override
  Widget build(BuildContext context) {


    AlarmController alarm_controller = Get.find<AlarmController>();
    ReportController reportController = Get.find<ReportController>();
    // TODO: implement build
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(title: Text('FireRanger')
          ),
          floatingActionButton: IconButton(onPressed: () => alarm_controller.isAlarm.value = true, icon: Icon(Icons.alarm)),
          body: Obx((() {

             if (alarm_controller.isAlarm.value) {
    Future.delayed(Duration.zero, () => 
      Get.defaultDialog(content: AlarmWidget())
           );
          }
             return Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        alarm_controller.isAlarm.value ? AlarmWidget()
                        : 
                        SizedBox(),
                      ],
                    ), 
                    Flexible(
                      child:
                     FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      center: LatLng(37.07916541977954, 35.369805781605216),
                      zoom: 14.0,
                      plugins: [EsriPlugin()],

                    ),
                    layers: [
                      TileLayerOptions(
                        urlTemplate:
                        'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                      ),

                      // fire spots
                      MarkerLayerOptions(
                        markers: spots,
                      ),

                      // wind speed
                      MarkerLayerOptions(
                        markers: windSpeeds,
                      ),

                      // wind direction
                      MarkerLayerOptions(
                        markers: windDirections,
                      ),
                      //Bisher Fake Markers
                      // MarkerLayerOptions(
                      //   markers: reportController.bisherMarkers.value,
                      // ),
                      OverlayImageLayerOptions(overlayImages: [
                      OverlayImage(bounds: LatLngBounds(LatLng(37.084003, 35.361670), LatLng(37.081041, 35.357764)),
                        imageProvider: Image.asset(ImagePaths.shelterIcon).image)
                      ]),
                      // danger zone
                      OverlayImageLayerOptions(overlayImages: [
                        OverlayImage(bounds: LatLngBounds(LatLng(37.07916541977954, 35.369805781605216), LatLng(37.071673, 35.380400)), imageProvider: Image.asset('assets/images/fireSVG.png').image)
                      ])


                      // MarkerLayerOptions(
                      //   markers: _createEllipse(initialPosition(), 0.1, 0.05),
                      // ),
                    ],
                  )
                    ),
                    TextButton(onPressed: () => Get.toNamed(Routes.reportingScreen), child: Text("Report")
                    
                    ),
                  ],
                ),
              ),
             );
          }
            ),
          ),
        ),
    );
  }

  LatLng initialPosition() => LatLng(37.084003, 35.361670);
}