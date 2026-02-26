
import 'dart:convert';

import 'package:flutter_map_arcgis_example/models/wind_direction.dart';

import '../models/wind_speed.dart';
import 'fire_management_api.dart';

const windspeedunit = 'windspeed_unit';

class WeatherApi {

// get whether wind data
// valid minutes values are windspeed_10m, windspeed_80m, windspeed_120m, windspeed_180m
// from https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&hourly=temperature_2m
Future<WindSpeed> getWindSpeedData({latitude = 0.0, longitude = 0.0, minutes = 10}) async {
    final params = {'latitude': '$latitude', 'longitude': '$longitude', 'hourly': 'windspeed_${minutes}m' };
    var response = await client.get(Uri.https('api.open-meteo.com', 'v1/forecast', params));
    final windspeed = json.decode(response.body);
    return WindSpeed.fromJson(windspeed);
  }

  // get whether's wind direction data
  // valid minutes values are 10m, 80m, 120m, 180m
  // from https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&hourly=temperature_2m
  Future<WindDirection> getWindDirectionData({latitude = 0.0, longitude = 0.0, minutes = 10}) async {
    final params = {'latitude': latitude.toString(), 'longitude': longitude.toString(), 'hourly': 'winddirection_${minutes}m' };
    var response = await client.get(Uri.https('api.open-meteo.com', 'v1/forecast', params));
    return WindDirection.fromJson(json.decode(response.body));
  }
}