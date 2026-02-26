import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/viirs.dart';

final client = http.Client();
class FireManagementApi {

/// Get Viirs Satelites data
// https://firms.modaps.eosdis.nasa.gov/api/country/csv/5110d95cb1457ffe923b31aeb9f4ef29/VIIRS_NOAA20_NRT/TUR/10/2023-10-07
Future<Iterable<Viirs>> getViirData({String token = '5110d95cb1457ffe923b31aeb9f4ef29', String countryCode = 'TUR', timeRange = 10, date = '2023-10-07'}) async {
    var response = await client.post(Uri.https('firms.modaps.eosdis.nasa.gov', 'api/country/csv/$token/VIIRS_NOAA20_NRT/$countryCode/$timeRange/$date'), body: {});
    const ls = LineSplitter();
    List<String> ln = ls.convert(response.body);
    final headers = ln[0].split(',');
    final map = ln.sublist(1).map((e) => Map<String, dynamic>.fromIterables(headers, e.split(',')));
    return ViirsFromJson(map);
  }
}