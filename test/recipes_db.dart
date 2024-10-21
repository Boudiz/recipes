import 'package:flutter/widgets.dart';

import 'package:recipes/models/recipe.dart';
import 'package:recipes/utils/db.dart';

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  // Open the database and store the reference.
  final database = RecipesDb.instance;

  var cookiesIngr = [
    'beurre',
    'oeufs',
  ];
  var cookies = Recipe.defaultTimes(
      name: 'Cookies',
      ingredients: cookiesIngr,
      description: 'Do the cookies',
      type: RecipeType.dessert);

  database.insertRecipe(cookies);
  insertNRecipe(database, cookiesIngr, 1000);

  print(await database.getRecipes());
}

void insertNRecipe(RecipesDb database, List<String> ingredients, int n) async {
  for (var i = 0; i < n; i++) {
    var recipe = Recipe.defaultTimes(
        name: 'Test $i',
        ingredients: ingredients,
        description: i.toString(),
        type: RecipeType.dessert);
    await database.insertRecipe(recipe);
  }
}
