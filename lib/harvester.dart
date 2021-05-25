import 'dart:core';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import 'package:chiabot/plot.dart';
import 'package:chiabot/config.dart';
import 'package:chiabot/harvester/plots.dart';
import 'package:chiabot/harvester/diskspace.dart';
import 'package:chiabot/debug.dart' as Debug;
import 'package:chiabot/harvester/filters.dart';
import 'package:chiabot/farmer.dart';

import 'package:chiabot/extensions/swarpm.dart';

final log = Logger('Harvester');

class Harvester with HarvesterDiskSpace, HarvesterPlots, HarvesterFilters {
  Config _config;

  String _name;
  String get name => _getName();

  String _currency = 'USD';
  String get currency => _currency.toUpperCase();

  // pubspec.yaml version
  String _version = '';
  String get version => _version;

  List<String> _plotDests = []; //plot destination paths

  final String id = Uuid().v4();

  //Timestamp to when the farm was last parsed
  DateTime _lastUpdated;
  DateTime get lastUpdated => _lastUpdated;

  String _lastUpdatedString = "1971-01-01";
  String get lastUpdatedString => _lastUpdatedString;

  //Farmer or Harvester
  ClientType _type = ClientType.Harvester;
  ClientType get type => _type;

  SwarPM _swarPM;
  SwarPM get swarPM => _swarPM;

  Map toJson() => {
        'name': _name,
        'currency': currency,
        'plots': allPlots, //important
        'totalDiskSpace': totalDiskSpace,
        'freeDiskSpace': freeDiskSpace,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
        'lastUpdatedString': lastUpdatedString,
        'type': type.index,
        'numberFilters': numberFilters,
        'eligiblePlots': eligiblePlots,
        'proofsFound': proofsFound,
        'totalPlots': totalPlots,
        'missedChallenges': missedChallenges,
        'maxTime': maxTime,
        'minTime': minTime,
        'avgTime': avgTime,
        'medianTime': medianTime,
        'stdDeviation': stdDeviation,
        'filterCategories': filterCategories,
        "swarPM": swarPM,
        'version': version
      };

  Harvester(Config config, Debug.Log log, [String version = '']) {
    _version = version;
    _config = config;
    _name = config.name; //loads name from config
    _currency = config.currency; // loads currency from config

    allPlots = config.cache.plots; //loads plots from cache

    _lastUpdated = DateTime.now();
    _lastUpdatedString = dateToString(_lastUpdated);

    loadFilters(log);

    //loads swar plot manager config if defined by user
    if (config.swarPath != "") _swarPM = SwarPM(config.swarPath);
  }

  Harvester.fromJson(String json) {
    allPlots = [];

    var object = jsonDecode(json)[0];

    //loads name from json file
    if (object['name'] != null) _name = object['name'];

    //loads currency from json file
    if (object['currency'] != null) _currency = object['currency'];

    //loads version from json
    if (object['version'] != null) _version = object['version'];

    for (int i = 0; i < object['plots'].length; i++) {
      allPlots.add(Plot.fromJson(object['plots'][i]));
    }

    //check harvester/filters.dart
    loadFiltersStatsJson(object, plots.length);

    if (object['totalDiskSpace'] != null && object['freeDiskSpace'] != null) {
      totalDiskSpace = object['totalDiskSpace'];
      freeDiskSpace = object['freeDiskSpace'];

      //if one of these values is 0 then it will assume that something went wrong in parsing disk space
      //or the client was outdated
      if (totalDiskSpace == 0 || freeDiskSpace == 0) supportDiskSpace = false;
    } else
      supportDiskSpace = false;

    _lastUpdated = DateTime.fromMillisecondsSinceEpoch(object['lastUpdated']);

    if (object['lastUpdatedString'] != null)
      _lastUpdatedString = object['lastUpdatedString'];

    if (object['swarPM'] != null) _swarPM = SwarPM.fromJson(object['swarPM']);

    _type = ClientType.values[object['type']];
  }

  Future<void> init(String chiaConfigPath) async {
    //LOADS CHIA CONFIG FILE AND PARSES PLOT DIRECTORIES
    _plotDests = listPlotDest(chiaConfigPath);

    listPlots(_plotDests, _config);

    filterDuplicates(); //removes plots with duplicate ids

    _lastUpdated = DateTime.now();

    await getDiskSpace(_plotDests);
  }

  //clears plots ids before sending info to server
  /*void clearIDs() {
    for (int i = 0; i < allPlots.length; i++) allPlots[i].clearID();
  }*/

  String _getName() {
    String name = '';

    if (_name != null)
      name = _name;
    else if (this is Farmer)
      name = "Farmer";
    else
      name = "Harvester";

    return name;
  }
}
