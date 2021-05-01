import 'dart:core';
import 'dart:io' as io;
import 'dart:convert';

import 'config.dart';
import 'harvester.dart';
import 'debug.dart' as Debug;

class Farmer extends Harvester {
  String _status;
  String get status => _status;

  double _balance = 0;
  double get balance => _balance; //hides balance if string

  String _networkSize = "0";
  String get networkSize => _networkSize;

  @override
  ClientType _type = ClientType.Farmer;
  @override
  ClientType get type => _type;

  double filterRatio = 0;
  int totalPlots = 0;

  @override
  Map toJson() => {
        'status': status,
        'balance': balance,
        'networkSize': networkSize,
        'plots': allPlots, //important
        'totalDiskSpace': totalDiskSpace,
        'freeDiskSpace': freeDiskSpace,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
        'lastUpdatedString': lastUpdatedString,
        'type': type.index,
        'filters': filters
      };

  Farmer(Config config, Debug.Log log) : super(config, log) {
    //runs chia farm summary if it is a farmer
    var result = io.Process.runSync(config.cache.binPath, ["farm", "summary"]);
    List<String> lines = result.stdout.toString().replaceAll("\r", "").split('\n');
    try {
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (line.startsWith("Total chia farmed: "))
          _balance =
              (config.showBalance) ? double.parse(line.split('Total chia farmed: ')[1]) : -1.0;
        else if (line.startsWith("Farming status: "))
          _status = line.split("Farming status: ")[1];
        else if (line.startsWith("Estimated network space: "))
          _networkSize = line.split("Estimated network space: ")[1];
      }
    } catch (exception) {
      print("Error parsing Farm info.");
    }
  }

  //Server side function to read farm from json file
  Farmer.fromJson(String json) : super.fromJson(json) {
    var object = jsonDecode(json)[0];

    _status = object['status'];
    _balance = object['balance'];
    _networkSize = object['networkSize'];

    calculateFilterRatio(this);
  }

  //Adds harvester's plots into farm's plots
  void addHarvester(Harvester harvester) {
    allPlots.addAll(harvester.allPlots);

    calculateFilterRatio(harvester);

    filters.addAll(harvester.filters);

    if (harvester.totalDiskSpace == 0 || harvester.freeDiskSpace == 0) supportDiskSpace = false;

    //Adds harvester total and free disk space when merging
    totalDiskSpace += harvester.totalDiskSpace;
    freeDiskSpace += harvester.freeDiskSpace;
  }

  void calculateFilterRatio(Harvester harvester) {
    if (harvester.filters.length > 0) {
      int totalEligiblePlots = 0;
      int totalFilters = harvester.filters.length;

      for (Debug.Filter filter in harvester.filters) totalEligiblePlots += filter.eligiblePlots;

      filterRatio += (totalEligiblePlots / totalFilters) * 512;
      totalPlots += harvester.plots.length;
    }
  }
}
