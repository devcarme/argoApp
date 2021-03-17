import 'package:flutter/material.dart';
import 'package:Argo/pages/userpreference.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:scidart/numdart.dart';

class Wmo extends StatefulWidget {
  @override
  _WmoState createState() => new _WmoState();
}

class _WmoState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    //Get wmo clicked from page context
    Map datapassed = ModalRoute.of(context).settings.arguments;

    List position = datapassed['position'];
    Map wmodata = datapassed['data'];

    List actionList;
    if (datapassed['from'] == 'home') {
      actionList = <Widget>[
        //TRAJ icon to acess trajectory from a profile
        IconButton(
            icon: Icon(Icons.grain),
            onPressed: () {
              Navigator.pushNamed(context, '/search_result',
                  arguments: wmodata['platformCode'].toString());
            }),
        //For the heart icon, we use a future builder because we're gonna load fleet list
        //from user preferencies and compare our wmo to this list
        FutureBuilder<List<String>>(
            // get the wmofleetlist, saved in the user preferences
            future: SharedPreferencesHelper.getwmofleet(),
            initialData: List<String>(),
            builder:
                (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              //Here we call the build function with our fleet list and clicked wmo in input
              return snapshot.hasData
                  ? _buildIcon(
                      snapshot.data, wmodata['platformCode'].toString())
                  : Container();
            }),
      ];
    } else {
      actionList = <Widget>[
        FutureBuilder<List<String>>(
            // get the wmofleetlist, saved in the user preferences
            future: SharedPreferencesHelper.getwmofleet(),
            initialData: List<String>(),
            builder:
                (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              //Here we call the build function with our fleet list and clicked wmo in input
              return snapshot.hasData
                  ? _buildIcon(
                      snapshot.data, wmodata['platformCode'].toString())
                  : Container();
            }),
      ];
    }

    //Lets build the page
    return Scaffold(
        appBar: AppBar(
            title:
                SelectableText("WMO : " + wmodata['platformCode'].toString()),
            actions: actionList),
        body: // Then we build the reste of the page with wmo info
            Center(
                child: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            Container(
                height: 170,
                child: FutureBuilder<List>(
                    // retrieve data
                    future: _retrievemetadata(
                        wmodata['platformCode'].toString(),
                        wmodata['cvNumber'].toString()),
                    initialData: ["", "", "", 0, 0, 0, ""],
                    builder:
                        (BuildContext context, AsyncSnapshot<List> snapshot) {
                      //Here we call the build function
                      return snapshot.hasData
                          ? _buildMeta(snapshot.data)
                          : Container();
                    })),
            // and the charts
            Container(
                height: (MediaQuery.of(context).size.height) - 270,
                child: new RotatedBox(
                    quarterTurns: 1,
                    child: FutureBuilder<List<List<double>>>(
                        // retrieve data
                        future: _retrievedata(
                            wmodata['platformCode'].toString(),
                            wmodata['cvNumber'].toString()),
                        initialData: [
                          [0.0, 1000.0, 2000.0],
                          [1.0, 1.0, 1.0]
                        ],
                        builder: (BuildContext context,
                            AsyncSnapshot<List<List<double>>> snapshot) {
                          //Here we call the build function
                          return snapshot.hasData
                              ? _buildChart(snapshot.data)
                              : Container();
                        })))
          ],
        )));
  }

  Widget _buildMeta(metalist) {
    return ListView(padding: const EdgeInsets.all(8), children: <Widget>[
      Container(
        height: 40,
        color: Colors.red[200],
        child: Center(
            child: SelectableText(
                'PI name : ' + metalist[0] + ' (' + metalist[1] + ')')),
      ),
      Container(
        height: 40,
        color: Colors.amber[200],
        child: Center(
            child: SelectableText('Cycle number : ' +
                metalist[3].toString() +
                '  (' +
                metalist[4].toStringAsFixed(2) +
                '/' +
                metalist[5].toStringAsFixed(2) +
                ')')),
      ),
      Container(
        height: 40,
        color: Colors.cyan[200],
        child: Center(child: SelectableText('Float type : ' + metalist[2])),
      ),
      Container(
        height: 40,
        color: Colors.green[200],
        child: Center(child: SelectableText('Profile date : ' + metalist[6])),
      ),
      Container(
        height: 20,
        color: Colors.white,
        child: Center(child: Text('')),
      )
    ]);
  }

  Widget _buildChart(points) {
    //var lims = getLims(points);
    //int step = (lims[1] / 6).ceil();

    final List<charts.Series<List, double>> seriesList = [
      new charts.Series<List, double>(
        id: 'Temp [°C]',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (meas, _) => meas[0],
        measureFn: (meas, _) => meas[1],
        data: points,
      ),
      new charts.Series<List, double>(
        id: 'Psal [psu]',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (meas, _) => meas[0],
        measureFn: (meas, _) => meas[2],
        data: points,
      )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId')
    ];

    return new charts.LineChart(seriesList,
        animate: false,
        behaviors: [new charts.SeriesLegend()],
        primaryMeasureAxis: new charts.NumericAxisSpec(
            tickProviderSpec: new charts.BasicNumericTickProviderSpec(
                zeroBound: false, desiredTickCount: 5)),
        secondaryMeasureAxis: new charts.NumericAxisSpec(
            tickProviderSpec: new charts.BasicNumericTickProviderSpec(
                zeroBound: false, desiredTickCount: 5)));
  }

  //This is the function that builds the favorite icon with wmo and fleet list iin input
  Widget _buildIcon(List<String> wmolist, String wmo) {
    if (wmolist.contains(wmo)) {
      return IconButton(
          icon: Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            wmolist.remove(wmo);
            await SharedPreferencesHelper.setwmofleet(wmolist);
            setState(() {});
          });
    } else {
      return IconButton(
          icon: Icon(Icons.favorite, color: Colors.white),
          onPressed: () async {
            wmolist.add(wmo);
            await SharedPreferencesHelper.setwmofleet(wmolist);
            setState(() {});
          });
    }
  }
}

Future<List<List<double>>> _retrievedata(wmo, cycle) async {
  String stringJson;
  var jsonData;

  //This is based on erddap ifremer server
  var urll =
      'http://www.ifremer.fr/erddap/tabledap/ArgoFloats.json?pres%2Ctemp%2Cpsal&platform_number=%22' +
          wmo +
          '%22&cycle_number=' +
          cycle +
          '&orderBy(%22pres%22)';
  //print(urll);
  var client = http.Client();
  try {
    //CALLING makeRequest with await to wait for the answer
    var response = await client.get(urll);
    stringJson = response.body;

    jsonData = json.decode(stringJson);
    List<List<double>> bigList = [];

    for (var e in jsonData['table']['rows']) {
      List<double> smallList = [];
      for (var j in e) {
        smallList.add(j.toDouble());
      }
      bigList.add(smallList);
    }
    return bigList;
  } on Exception catch (ex) {
    print('Erddap error: $ex');
    return [
      [0.0, 1000.0, 2000.0],
      [1.0, 1.0, 1.0]
    ];
  } finally {
    client.close();
  }
}

Future<List> _retrievemetadata(wmo, cycle) async {
  String stringJson;
  var jsonData;

  //This is based on erddap ifremer server
  var urll =
      'http://www.ifremer.fr/erddap/tabledap/ArgoFloats.json?pi_name%2Cdata_center%2Cplatform_type%2Ccycle_number%2Clongitude%2Clatitude%2Ctime&platform_number=%22' +
          wmo +
          '%22&cycle_number=' +
          cycle;
  //print(urll);
  var client = http.Client();
  try {
    //CALLING makeRequest with await to wait for the answer
    var response = await client.get(urll);
    stringJson = response.body;
    jsonData = json.decode(stringJson);
    return jsonData['table']['rows'][0];
  } on Exception catch (ex) {
    print('Erddap error: $ex');
    return [
      "unavailable",
      "unavailable",
      "unavailable",
      0,
      0,
      0,
      "unavailable"
    ];
  } finally {
    client.close();
  }
}

List<double> getLims(List<List<double>> points) {
  var lims = [0.0, 10.0, 1000.0, 0.0, 1000.0, 0.0];

  for (var i = 0; i < points.length; i++) {
    //PRES
    //if (points[i][0] < lims[0]) {
    //  lims[0] = points[i][0];
    //}
    if (points[i][0] > lims[1]) {
      lims[1] = points[i][0];
    }
    //TEMP
    if (points[i][1] < lims[2]) {
      lims[2] = points[i][1];
    }
    if (points[i][1] > lims[3]) {
      lims[3] = points[i][1];
    }
    //PSAL
    if (points[i][2] < lims[4]) {
      lims[4] = points[i][2];
    }
    if (points[i][2] > lims[5]) {
      lims[5] = points[i][2];
    }
  }
  return lims;
}
