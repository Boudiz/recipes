import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:recipes/utils/db.dart';
import 'package:recipes/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:recipes/utils/utils.dart';
import 'package:tuple/tuple.dart';

class ApiCall {
  static late String _uri;

  static Future<void> loadConfigIp() async {
    final jsonString = await rootBundle.loadString('assets/config.json');
    Map<String, dynamic> config = jsonDecode(jsonString);
    _uri = config['ip'];
  }

  static Future<Tuple2<int, List<Recipe>>> fetchRecipes(
      DateTime lastSyncTimestamp,
      {String? isArchived}) async {
    List<Recipe> recipes = [];
    Map<String, dynamic> params = {
      'last_sync_timestamp': Utils.dateFormatter.format(lastSyncTimestamp),
      'is_archived': isArchived,
    };
    final response =
        await http.get(Uri.parse(_uri).replace(queryParameters: params));
    if (response.statusCode == 200) {
      final List<dynamic> datas = jsonDecode(response.body);
      recipes = datas.map((recipeJson) => Recipe.fromJson(recipeJson)).toList();

      return Tuple2(response.statusCode, recipes);
    }

    return Tuple2(404, []);
  }

  static Future<int> sendRecipes(List<Recipe> recipeList) async {
    int status = 201;
    if (recipeList.isEmpty) {
      return status;
    }

    final db = RecipesDb.instance;
    for (Recipe recipe in recipeList) {
      final response = await http.post(Uri.parse(_uri),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(recipe.toApiMap()));
      if (response.statusCode != 201 || response.body == "") {
        status = response.statusCode;
      } else {
        // Update the local id with the id given by the server
        final String serverId = jsonDecode(response.body)['id'];
        db.updateItemWithServerId(recipe.id, serverId);

        final String serverLastModified =
            jsonDecode(response.body)['lastModified'];
        db.updateItemWithServerLastModified(serverId, serverLastModified);
      }
    }
    return status;
  }

  static Future<int> updateRecipes(List<Recipe> recipeList) async {
    int status = 200;
    if (recipeList.isEmpty) {
      return status;
    }

    final db = RecipesDb.instance;
    for (Recipe recipe in recipeList) {
      final response = await http.put(Uri.parse('$_uri/${recipe.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(recipe.toApiMap()));
      if (response.statusCode != 200) {
        status = response.statusCode;
      } else {
        final String serverLastModified =
            jsonDecode(response.body)['lastModified'];
        db.updateItemWithServerLastModified(recipe.id, serverLastModified);
      }
    }
    return status;
  }

  static Future<int> deleteRecipes(List<Recipe> recipeList) async {
    int status = 200;
    if (recipeList.isEmpty) {
      return status;
    }

    for (Recipe recipe in recipeList) {
      final response = await http.delete(Uri.parse('$_uri/${recipe.id}'));
      if (response.statusCode != 200) {
        status = response.statusCode;
      }
    }
    return status;
  }
}
