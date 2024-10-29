import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipes/models/constants.dart';
import 'dart:async';

import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/settings.dart';
import 'package:recipes/utils/db.dart';
import 'package:recipes/widgets/recipe_tile.dart';
import 'package:recipes/widgets/search_recipe_type.dart';

class RecipeList extends StatefulWidget {
  final String searchText;

  const RecipeList({super.key, this.searchText = ""});

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  RecipesDb database = RecipesDb.instance;
  late List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();
  List<RecipeType> _selectedRecipeType = [];
  bool _selectedFavorite = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchText;
    _fetchRecipes();
  }

  Timer? _debounceTimer;
  final _debounceDuration = Duration(milliseconds: Constants.debounceTime);
  void debounce(void Function() callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, callback);
  }

  Future<List<Recipe>> _fetchRecipes() async {
    return await database.getRecipes();
  }

  void _searchRecipes(String searchTerm) {
    setState(() {
      _searchText = searchTerm.toLowerCase();
      _filteredRecipes =
          _recipes.where((recipe) => _filtering(recipe, _searchText)).toList();
    });
  }

  bool _filtering(Recipe recipe, String searchTerm) {
    // If we want to show only favorite, and the recipe is not a favorite do not show
    if (_selectedFavorite && !recipe.isFavorite) {
      return false;
    }

    // Normalize search term
    final String searchText = searchTerm.toLowerCase();
    return (_selectedRecipeType.isEmpty ||
            _selectedRecipeType.contains(recipe.type)) &&
        (recipe.name.toLowerCase().contains(searchText) ||
            recipe.ingredients.any(
                (ingredient) => ingredient.toLowerCase().contains(searchText)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>>(
        future: _fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(TextConstants.noRecipe));
          } else {
            bool showDeleted = context.watch<SettingsProvider>().showDeleted;
            if (showDeleted) {
              _recipes = snapshot.data!;
            } else {
              _recipes =
                  snapshot.data!.where((recipe) => !recipe.deleted).toList();
            }
            _filteredRecipes = _recipes
                .where((recipe) => _filtering(recipe, _searchText))
                .toList();

            // If the initial item count is not updated to _filteredRecipes length
            // update it automatically
            int size = _listKey.currentState?.widget.initialItemCount ??
                _filteredRecipes.length;

            if (_filteredRecipes.length > size) {
              for (int i = size; i < _filteredRecipes.length; i++) {
                _listKey.currentState?.insertItem(i);
              }
            } else if (_filteredRecipes.length < size) {
              for (int i = _filteredRecipes.length; i < size; i++) {
                _listKey.currentState
                    ?.removeItem(i, (context, animation) => Container());
              }
            }

            return Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: TextConstants.searchRecipes,
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (text) => debounce(() => _searchRecipes(text)),
                  controller: _searchController,
                ),
                SizedBox(height: 8),
                SearchRecipeType(
                  onSelectedTypeChanged: _onRecipeTypeSelected,
                  initalTypeValues: _selectedRecipeType,
                  onSelectedFavoriteChanged: _onFavoriteSelected,
                  initialFavorite: _selectedFavorite,
                ),
                Visibility(
                    visible: _filteredRecipes.isEmpty,
                    child: Expanded(
                      child: Center(
                          child: Text('No recipe found for "$_searchText"')),
                    )),
                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _filteredRecipes.length,
                    itemBuilder: (context, index, animation) {
                      return _buildTile(index, animation);
                    },
                    padding: EdgeInsets.only(bottom: 60),
                  ),
                ),
                SizedBox(
                  height: 14,
                ),
              ],
            );
          }
        });
  }

  Widget _buildTile(int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: RecipeTile(
        recipe: _filteredRecipes[index],
        onDelete: () => removeItem(index),
        onRestore: () => restoreItem(index),
      ),
    );
  }

  void removeItem(int index) {
    if (index >= 0 && index < _filteredRecipes.length) {
      setState(() {
        _filteredRecipes[index].deleted = true;
      });

      database.setDeleteRecipe(_filteredRecipes[index]);
    }
  }

  void restoreItem(int index) {
    if (index >= 0 && index < _filteredRecipes.length) {
      setState(() {
        _filteredRecipes[index].deleted = false;
      });

      database.restoreRecipe(_filteredRecipes[index]);
    }
  }

  void _onRecipeTypeSelected(List<RecipeType> selectedTypes) {
    setState(() {
      _selectedRecipeType = selectedTypes;
      _searchRecipes(_searchText);
    });
  }

  void _onFavoriteSelected(bool favorite) {
    setState(() {
      _selectedFavorite = favorite;
      _searchRecipes(_searchText);
    });
  }
}
