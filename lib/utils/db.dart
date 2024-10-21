import 'dart:async';

import 'package:path/path.dart';
import 'package:recipes/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:recipes/models/recipe.dart';

class RecipesDb {
  // Singleton pattern to ensure there's only one instance of the database
  static final RecipesDb instance = RecipesDb._init();
  static Database? _database;

  RecipesDb._init();

  // Open the database (or create it if it doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('recipes_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE recipes(id STRING PRIMARY KEY, name TEXT, ingredients TEXT, description TEXT, created TEXT, type INTEGER, favorite INTEGER, lastModified TEXT, deleted INTEGER)');
      },
    );
  }

  // Retrieve all the recipes in the db
  // If lastModified is precised, it retrieve the recipes that have been modified after lastModified
  Future<List<Recipe>> getRecipes({DateTime? lastModified}) async {
    final db = await database;
    final List<Map<String, Object?>> recipeMaps;
    if (lastModified == null) {
      recipeMaps = await db.query('recipes');
    } else {
      recipeMaps = await db.query('recipes',
          where: 'lastModified >= ?',
          whereArgs: [Utils.dateFormatter.format(lastModified)]);
    }
    return List.generate(recipeMaps.length, (i) {
      return Recipe.fromMap(recipeMaps[i]);
    });
  }

  // Insert a new recipe
  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;

    if (Utils.uuidVersion(recipe.id) == 0) {
      recipe.id = const Uuid().v1();
    }

    await db.insert('recipes', recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Update an existing recipe (based on id)
  Future<void> updateRecipe(Recipe recipe, String id) async {
    final db = await database;

    await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateItemWithServerId(
      String temporaryId, String serverId) async {
    final db = await database;
    final int temporaryIdVersion = Utils.uuidVersion(temporaryId);
    final int serverIdVersion = Utils.uuidVersion(serverId);
    if (temporaryIdVersion != 4 && serverIdVersion == 4) {
      await db.update('recipes', {'id': serverId},
          where: 'id = ?', whereArgs: [temporaryId]);
    }
  }

  Future<void> updateItemWithServerLastModified(
      String id, String lastModified) async {
    final db = await database;
    await db.update('recipes', {'lastModified': lastModified},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDeleteRecipe(Recipe recipe) async {
    recipe.deleted = true;
    recipe.lastModified = DateTime.now();
    updateRecipe(recipe, recipe.id);
  }

  Future<void> restoreRecipe(Recipe recipe) async {
    recipe.deleted = false;
    recipe.lastModified = DateTime.now();
    updateRecipe(recipe, recipe.id);
  }

  // Delete a recipe using its id
  Future<void> deleteRecipe(String id) async {
    final db = await database;

    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
