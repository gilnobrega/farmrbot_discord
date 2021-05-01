import 'dart:core';
import 'dart:io' as io;

import 'package:yaml/yaml.dart';
import 'package:path/path.dart';

import '../plot.dart';
import '../config.dart';

class HarvesterPlots {
  //Private list with complete and incomplete plots
  List<Plot> allPlots;

  //Returns list of complete plots
  List<Plot> get plots => allPlots.where((plot) => plot.complete).toList();
  //Returns list of incomplete plots
  List<Plot> get incompletePlots => allPlots.where((plot) => !plot.complete).toList();

  //Parses chia's config.yaml and finds plot destionation paths
  List<String> listPlotDest(String chiaConfigPath) {
    String configPath = chiaConfigPath + "config.yaml";

    var configYaml = loadYaml(io.File(configPath).readAsStringSync().replaceAll("!!set", ""));

    List<String> pathsUnfiltered = ylistToStringlist(configYaml['harvester']['plot_directories']);

    //Filters duplicate paths
    List<String> pathsFiltered = [];

    for (int i = 0; i < pathsUnfiltered.length; i++) {
      io.Directory dir = io.Directory(pathsUnfiltered[i]);

      if (dir.existsSync()) {
        bool isEmpty =
            dir.listSync().where((file) => extension(file.path) == ".plot").toList().length == 0;

        //Adds plot dest if it contains at least one .plot file
        if (!isEmpty) pathsFiltered.add(dir.absolute.path);
      }
    }

    return pathsFiltered.toSet().toList();
  }

//makes a list of available plots in all plot destination paths
  void listPlots(List<String> paths, Config config) async {
    List<Plot> newplots = [];

    for (int i = 0; i < paths.length; i++) {
      var path = paths[i];

      io.Directory dir = new io.Directory(path);

      await dir.list(recursive: false).forEach((file) {
        //Checks if file extension is .plot
        if (extension(file.path) == ".plot") {
          String id = basenameWithoutExtension(file.path).split('-').last;

          bool inCache = allPlots.any((cachedPlot) => cachedPlot.id == id);
          bool duplicate = newplots.any((plot) => plot.id == id);

          //If plot id it is in cache then adds old plot information (timestamps, etc.)
          if (inCache && !duplicate)
            newplots.add(allPlots.firstWhere((cachedPlot) => cachedPlot.id == id));
          //Adds plot if it's not in cache already
          else if (!duplicate) {
            //print("Found new plot " + id); // UNCOMMENT FOR DEBUGGING PLOT CACHE
            Plot plot = new Plot(file);
            newplots.add(plot);
          }
        }
      });
    }

    allPlots = newplots;

    config.cache.savePlots(allPlots);
  }

  void filterDuplicates([bool client = true]) {
    final idslist = allPlots.map((plot) => plot.id);
    final idsSet = idslist.toSet();
    final difference = idslist.length - idsSet.length;

    //Removes plots with same ids!
    allPlots.retainWhere((x) => idsSet.remove(x.id));

    //Counts how many plots were filtered
    if (client && difference > 0) print("Warning: filtering ${difference} duplicated plots!");
  }

  //makes an id based on end and start timestamps for the last plot, necessary to call notifications webhook
  String lastPlotID() {
    Plot last = lastPlot(plots); //last completed plot

    return last.id;
  }

  void sortPlots() {
    allPlots.sort(
        (plot1, plot2) => (plot1.begin.compareTo(plot2.begin))); //Sorts plots from oldest to newest
  }
}

//Converts a YAML List to a String list
//Used to parse chia's config.yaml
List<String> ylistToStringlist(YamlList input) {
  List<String> output = [];
  for (int i = 0; i < input.length; i++) {
    output.add(input[i].toString());
  }
  return output;
}
