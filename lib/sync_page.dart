import 'package:flutter/material.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/utils/api_calls.dart';
import 'package:recipes/utils/conflicting_recipes.dart';
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
      appBar: AppBar(title: Text(TextConstants.syncTitle)),
      body: SyncPage(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        },
        child: Icon(
          Icons.home,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
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
    // Reset statuses
    setState(() {
      _isLoading = true;
      _apiCallStatuses = {
        'fetch': 0,
        'archived': 0,
        'new': 0,
        'modified': 0,
        'conflicting': 0,
      };
    });

    // Fetch recipes from local database
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
    await ApiCall.loadConfigIp();

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
          await resolveConflicts(conflictingRecipes, serverRecipes, context);
    }

    setState(() {
      if (_areApiCallSuccesful(_apiCallStatuses)) {
        lastSyncTimestamp = DateTime.now();
        _saveLastSyncTimestamp();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      children: [
        FutureBuilder(
            future: _loadLastSyncTimestamp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                    "${TextConstants.errorLastSync}: ${snapshot.error}");
              } else {
                return Text(
                    "${TextConstants.lastSync}: ${Utils.dateFormatter.format(lastSyncTimestamp)}");
              }
            }),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _updateDatabase,
          child: Text(TextConstants.syncTitle),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              Divider(
                height: 40,
                thickness: 2,
                indent: 30,
                endIndent: 30,
              ),
              Text(
                TextConstants.dataFromServer,
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: 10),
              _buildDot(
                color: _getStatusColor(_apiCallStatuses['fetch']),
                text: TextConstants.fetchedRecipes,
                isLoading: _isLoading,
              ),
              _buildDot(
                color: _getStatusColor(_apiCallStatuses['archived']),
                text: TextConstants.archivedRecipes,
                isLoading: _isLoading,
              ),
              Divider(
                height: 40,
                thickness: 2,
                indent: 30,
                endIndent: 30,
              ),
              Text(TextConstants.dataSendToServer,
                  style: theme.textTheme.headlineSmall),
              SizedBox(height: 10),
              _buildDot(
                color: _getStatusColor(_apiCallStatuses['new']),
                text: TextConstants.newRecipes,
                isLoading: _isLoading,
              ),
              _buildDot(
                color: _getStatusColor(_apiCallStatuses['modified']),
                text: TextConstants.modifiedRecipes,
                isLoading: _isLoading,
              ),
              _buildDot(
                color: _getStatusColor(_apiCallStatuses['conflicting']),
                text: TextConstants.conflictingRecipes,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _areApiCallSuccesful(Map<String, int> apiCallStatuses) {
  return apiCallStatuses.values.every((status) => status < 300);
}

Color _getStatusColor(int? status) {
  if (status == null || status > 300) {
    return Colors.red;
  }
  if (status >= 200) {
    return Colors.green;
  }
  return Colors.grey;
}

Widget _buildDot(
    {required Color color, String? text, required bool isLoading}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text ?? ""),
      Spacer(),
      (isLoading && color == Colors.grey)
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
      SizedBox(
        width: 50,
      ),
    ],
  );
}
