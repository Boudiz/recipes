import 'package:flutter/material.dart';
import 'package:recipes/utils/api_calls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipes/main.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/utils/db.dart';
import 'package:recipes/utils/utils.dart';
import 'package:tuple/tuple.dart';

class SyncPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syncronisation')),
      body: SyncPage(),
    );
  }
}

class SyncPage extends StatefulWidget {
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late DateTime lastSyncTimestamp;
  RecipesDb database = RecipesDb.instance;

  bool _isLoading = false;
  Map<String, int> _apiCallStatuses = {
    'fetch': 0,
    'archived': 0,
    'new': 0,
    'modified': 0,
    'conflicting': 0,
  };

  Future<void> _loadLastSyncTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTimestamp = prefs.getString('lastSyncTimestamp');
    if (storedTimestamp != null) {
      lastSyncTimestamp = DateTime.parse(storedTimestamp);
    } else {
      lastSyncTimestamp = DateTime(2000);
    }
  }

  Future<void> _saveLastSyncTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'lastSyncTimestamp', lastSyncTimestamp.toIso8601String());
  }

  void _updateDatabase() async {
    setState(() {
      _isLoading = true;
      _apiCallStatuses = {
        'fetch': 0,
        'archived': 0,
        'new': 0,
        'modified': 0,
        'conflicting': 0,
      }; // Reset statuses
    });

    List<Recipe> localRecipes =
        await database.getRecipes(lastModified: lastSyncTimestamp);
    List<Recipe> deletedRecipes =
        localRecipes.where((recipe) => recipe.deleted).toList();
    List<Recipe> newRecipes = localRecipes
        .where((recipe) =>
            recipe.created.isAfter(lastSyncTimestamp) && !recipe.deleted)
        .toList();
    List<Recipe> modifiedRecipes = localRecipes
        .where((recipe) =>
            recipe.created.isBefore(lastSyncTimestamp) &&
            recipe.lastModified.isAfter(lastSyncTimestamp) &&
            !recipe.deleted)
        .toList();

    // Fetch the ip from config file
    ApiCall.loadConfigIp();

    // New recipes on the server
    final Tuple2<int, List<Recipe>> response =
        await ApiCall.fetchRecipes(lastSyncTimestamp);

    _apiCallStatuses['fetch'] = response.item1;

    final Tuple2<int, List<Recipe>> archivedResponse =
        await ApiCall.fetchRecipes(lastSyncTimestamp, isArchived: 'true');

    _apiCallStatuses['archived'] = archivedResponse.item1;

    if (_apiCallStatuses['fetch'] == 200 &&
        _apiCallStatuses['archived'] == 200) {
      List<Recipe> serverRecipes = response.item2;
      List<Recipe> archivedRecipes = archivedResponse.item2;

      // Recipes modified in local and on the server
      List<Recipe> conflictingRecipes = modifiedRecipes
          .where((localRecipe) => serverRecipes.any((serverRecipe) =>
              serverRecipe.id == localRecipe.id &&
              serverRecipe.created.isAtSameMomentAs(localRecipe.created) &&
              serverRecipe.lastModified != localRecipe.lastModified))
          .toList();

      // Send new local recipes to the server
      _apiCallStatuses['new'] = await ApiCall.sendRecipes(newRecipes);

      // Send updated local recipes that where not modified on the server
      _apiCallStatuses['modified'] = await ApiCall.updateRecipes(modifiedRecipes
          .where((recipe) => !conflictingRecipes.contains(recipe))
          .toList());

      // Insert new recipes from the server that where not modified locally
      Utils.insertRecipes(serverRecipes
          .where((recipe) => !conflictingRecipes.contains(recipe))
          .toList());

      // Delete archived recipes on local database
      Utils.deleteRecipes(archivedRecipes);

      // Send deleted recipes to the server and delete them locally
      await ApiCall.deleteRecipes(deletedRecipes);
      Utils.deleteRecipes(deletedRecipes);

      // Resolve the conflicting recipes and update both local and server
      _apiCallStatuses['conflicting'] =
          await _resolveConflicts(conflictingRecipes, serverRecipes);
    }

    setState(() {
      if (_apiCallStatuses['fetch'] == 200 &&
          _apiCallStatuses['archived'] == 200 &&
          _apiCallStatuses['new'] == 201 &&
          _apiCallStatuses['modified'] == 200 &&
          _apiCallStatuses['conflicting'] == 201) {
        lastSyncTimestamp = DateTime.now();
        _saveLastSyncTimestamp();
      }
      _isLoading = false;
    });
  }

  Future<int> _resolveConflicts(
      List<Recipe> conflictingRecipes, List<Recipe> serverRecipes) async {
    int status = 201;

    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
            future: _loadLastSyncTimestamp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                    'Error loading last sync timestamp: ${snapshot.error}');
              } else {
                return Text(
                    "Dernière syncronisation: ${Utils.dateFormatter.format(lastSyncTimestamp)}");
              }
            }),
        ElevatedButton(onPressed: _updateDatabase, child: const Text('Sync')),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
          child: const Text('Return'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Données reçues du serveur"),
            _buildDot(
              color: _getStatusColor(_apiCallStatuses['fetch']),
              text: "Fetched Recipes",
              isLoading: _isLoading,
            ),
            SizedBox(height: 10),
            _buildDot(
              color: _getStatusColor(_apiCallStatuses['archived']),
              text: "Archived Recipes",
              isLoading: _isLoading,
            ),
            SizedBox(height: 10),
            Text("Données envoyées au serveur"),
            _buildDot(
              color: _getStatusColor(_apiCallStatuses['new']),
              text: "New Recipes",
              isLoading: _isLoading,
            ),
            SizedBox(height: 10),
            _buildDot(
              color: _getStatusColor(_apiCallStatuses['modified']),
              text: "Modified Recipes",
              isLoading: _isLoading,
            ),
            SizedBox(height: 10),
            _buildDot(
              color: _getStatusColor(_apiCallStatuses['conflicting']),
              text: "Conflicting Recipes",
              isLoading: _isLoading,
            ),
          ],
        ),
      ],
    );
  }
}

Color _getStatusColor(int? status) {
  switch (status) {
    case 0:
      return Colors.grey;
    case 200:
    case 201:
      return Colors.green;
    default:
      return Colors.red;
  }
}

Widget _buildDot(
    {required Color color, String? text, required bool isLoading}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text ?? ""),
      (isLoading && color == Colors.grey)
          ? CircularProgressIndicator(
              strokeWidth: 3,
            )
          : Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
    ],
  );
}
