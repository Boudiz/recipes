import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/utils/api_calls.dart';
import 'package:recipes/utils/db.dart';
import 'package:recipes/utils/utils.dart';

RecipesDb database = RecipesDb.instance;

Future<int> _updateDbsAndServer(Recipe recipe, int choice) async {
  Completer<int> status = Completer();

  if (choice == 0) {
    // Keep the local version
    status.complete(await ApiCall.updateRecipes([recipe]));
  } else if (choice == 1) {
    // Keep the server version
    try {
      database.updateRecipe(recipe, recipe.id);
      status.complete(200);
    } catch (e) {
      status.complete(400);
    }
  }

  return status.future;
}

Future<int> resolveConflicts(List<Recipe> conflictingRecipes,
    List<Recipe> serverRecipes, BuildContext context) async {
  int status = 0;

  ThemeData theme = Theme.of(context);
  // Iterate through conflicting recipes
  for (final conflictingRecipe in conflictingRecipes) {
    // Find the corresponding server recipe based on ID
    final serverRecipe = serverRecipes.firstWhere(
      (recipe) => recipe.id == conflictingRecipe.id,
      orElse: () {
        return conflictingRecipe;
      },
    );

    // If a corresponding server recipe was found, show a dialog to let the user choose
    if (!serverRecipe.isSimilarTo(conflictingRecipe)) {
      final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Conflict: Recipe ${conflictingRecipe.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TextConstants.localVersion,
                  style: theme.textTheme.headlineMedium,
                ),
                Text(conflictingRecipe.toBeautifulString()),
                SizedBox(height: 16),
                Text(TextConstants.serverVersion,
                    style: theme.textTheme.headlineMedium),
                Text(serverRecipe.toBeautifulString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: Text(TextConstants.keepLocalVersion),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: Text(TextConstants.keepServerVersion),
            ),
          ],
        ),
      );

      // Update the resolved recipe map based on the user's choice
      if (result != null) {
        int localStatus = await _updateDbsAndServer(
            result == 0 ? conflictingRecipe : serverRecipe, result);
        status = (status > 300) ? status : localStatus;
      } else {
        // Handle if the user close the windows without making a choice
        return 400;
      }
    } else if (serverRecipe != conflictingRecipe) {
      // When only some timestamp differ
      database.updateItemWithServerLastModified(conflictingRecipe.id,
          Utils.dateFormatter.format(serverRecipe.lastModified));
    }
  }

  // Return the count of resolved conflicts
  return status;
}
