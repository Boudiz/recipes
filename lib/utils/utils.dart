import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/utils/db.dart';
import 'package:uuid/uuid.dart';

class Utils {
  static DateFormat dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  static RecipesDb database = RecipesDb.instance;

  static Recipe formToRecipe(
      TextEditingController nameC,
      List<TextEditingController> ingredientsC,
      TextEditingController descriptionC,
      RecipeType recipeType,
      {DateTime? createdDate,
      String? id}) {
    List<String> ingredients = [];

    for (TextEditingController ingredientC in ingredientsC) {
      ingredients.add(ingredientC.text);
    }

    DateTime created = createdDate ?? DateTime.now();

    return Recipe(
      id: id ?? "",
      name: nameC.text,
      ingredients: ingredients,
      description: descriptionC.text,
      type: recipeType,
      created: created,
      lastModified: DateTime.now(),
    );
  }

  static void toggleFavorite(Recipe recipe, Function updateFavoriteState) {
    updateFavoriteState();
    database.updateRecipe(recipe, recipe.id);
  }

  static void insertRecipes(List<Recipe> recipes) async {
    for (Recipe recipe in recipes) {
      await database.insertRecipe(recipe);
    }
  }

  static void deleteRecipes(List<Recipe> recipes) async {
    for (Recipe recipe in recipes) {
      await database.deleteRecipe(recipe.id);
    }
  }

  static int uuidVersion(String string) {
    if (string.isNotEmpty &&
        Uuid.isValidUUID(fromString: string.substring(1))) {
      return (string.substring(0, 1) == "r" && string.length == 37) ? 4 : 1;
    } else {
      return 0;
    }
  }

  static List<String> splitIngredients(String ingredientsString) {
    // Remove bullet points
    ingredientsString = ingredientsString.replaceAll(RegExp(r"^\s*\*\s*"), "");

    // Remove empty lines
    ingredientsString = ingredientsString.replaceAll("\n\n", "\n");
    ingredientsString = ingredientsString.replaceAll("\n\r", "\n");

    List<String> ingredients = ingredientsString.split("\n");
    ingredients = ingredients.where((ingredient) => ingredient != "").toList();

    return ingredients;
  }

  static Future<List<String>> enterAllIngredientsDialog(
      BuildContext context) async {
    Completer<List<String>> ingredientsCompleter = Completer();
    final textFieldController = TextEditingController();
    String text = "";

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              TextConstants.enterIngredients,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            content: TextField(
              controller: textFieldController,
              onChanged: (value) => {text = value},
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(TextConstants.cancel)),
              ElevatedButton(
                onPressed: () {
                  ingredientsCompleter.complete(splitIngredients(text));
                  Navigator.of(context).pop();
                },
                child: Text(TextConstants.ok),
              )
            ],
          );
        });
    return ingredientsCompleter.future;
  }

  static Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    final Completer<bool> result = Completer<bool>();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(''),
            content: Text(TextConstants.deleteConfirmation),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  result.complete(false);
                },
                child: Text(TextConstants.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  result.complete(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(TextConstants.deletedRecipe)),
                  );
                },
                child: Text(TextConstants.delete),
              ),
            ],
          );
        });
    return result.future;
  }
}
