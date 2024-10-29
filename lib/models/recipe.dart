import 'dart:convert';

import 'package:recipes/utils/utils.dart';

/*class Ingredient {
  final String name;
  final double quantity;
  final String unit;

  const Ingredient({
    required this.name,
    required this.quantity,
    this.unit = "",
  });

  @override
  String toString() {
    return '{name: $name, quantity: $quantity $unit}';
  }

  // Convert Ingredient into a Map, keys must correspond to the names of the columns in SQlite
  Map<String, Object?> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  // Create Ingredient object from a Map
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      quantity: map['quantity'],
      unit: map['unit'],
    );
  }

  // Convert a List of Ingredient to JSON string
  static String encode(List<Ingredient> ingredients) {
    return json
        .encode(ingredients.map((ingredient) => ingredient.toMap()).toList());
  }

  //Decode a JSON string into List of Ingredient
  static List<Ingredient> decode(String ingredients) {
    return (json.decode(ingredients) as List<dynamic>)
        .map<Ingredient>((item) => Ingredient.fromMap(item))
        .toList();
  }
}
*/

enum RecipeType {
  entree,
  plat,
  dessert,
  cocktail,
  na;

  @override
  String toString() {
    switch (this) {
      case RecipeType.entree:
        return 'Entrée';
      case RecipeType.plat:
        return 'Plat';
      case RecipeType.dessert:
        return 'Dessert';
      case RecipeType.cocktail:
        return 'Cocktail';
      case RecipeType.na:
        return 'N/A';
      default:
        return 'NOT DEFINED';
    }
  }

  static const Map<int, RecipeType> _recipeTypeMap = {
    0: RecipeType.entree,
    1: RecipeType.plat,
    2: RecipeType.dessert,
    3: RecipeType.cocktail,
    4: RecipeType.na,
  };

  static RecipeType fromInt(int value) {
    return _recipeTypeMap[value] ?? RecipeType.na;
  }
}

class Recipe {
  String id;
  final String name;
  final List<String> ingredients;
  final String description;
  final RecipeType type;
  bool isFavorite;

  // Metadata
  final DateTime created;
  DateTime lastModified;
  bool deleted;

  Recipe.defaultTimes({
    this.id = "",
    required this.name,
    required this.ingredients,
    required this.description,
    required this.type,
    this.isFavorite = false,
    this.deleted = false,
  })  : created = DateTime.now(),
        lastModified = DateTime.now();

  Recipe({
    this.id = "",
    required this.name,
    required this.ingredients,
    required this.description,
    required this.type,
    this.isFavorite = false,
    this.deleted = false,
    required this.created,
    required this.lastModified,
  });

  // Convert Recipe into a Map, keys must correspond to the names of the columns in SQlite
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'ingredients': jsonEncode(ingredients),
      'description': description,
      'type': type.index,
      'favorite': isFavorite ? 1 : 0,
      'created': Utils.dateFormatter.format(created),
      'lastModified': Utils.dateFormatter.format(lastModified),
      'deleted': deleted ? 1 : 0,
    };
  }

  // Convert Recipe into a Map compatible with API call
  Map<String, Object?> toApiMap() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'description': description,
      'type': type.index,
      'isFavorite': isFavorite,
      'created': created.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      ingredients: List<String>.from(jsonDecode(map['ingredients'])),
      description: map['description'],
      type: RecipeType.fromInt(map['type']),
      isFavorite: map['favorite'] == 1,
      created: Utils.dateFormatter.parse(map['created']),
      lastModified: Utils.dateFormatter.parse(map['lastModified']),
      deleted: map['deleted'] == 1,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
        id: json['id'],
        name: json['name'],
        ingredients: List<String>.from(json['ingredients']),
        description: json['description'],
        isFavorite: json['isFavorite'] ?? 1 == 1,
        type: RecipeType.fromInt(json['type']),
        created: Utils.dateFormatter.parse(json['created']),
        lastModified: Utils.dateFormatter.parse(json['lastModified']));
  }

  @override
  String toString() {
    return 'Recipe{${deleted ? "DELETED " : ""}name: $name, ingredients: $ingredients, description: $description, type: $type, ${isFavorite ? "favorite," : ""} created: $created, lastModified: $lastModified}';
  }

  String toBeautifulString() {
    return 'Recette  ${deleted ? "DELETED " : ""}: \n name: $name\n ingredients: $ingredients\n description: $description\n type: $type\n ${isFavorite ? "favorite," : ""}';
  }

  bool isSimilarTo(Recipe other) {
    return id == other.id &&
        name == other.name &&
        type == other.type &&
        ingredients == other.ingredients &&
        description == other.description;
  }
}
