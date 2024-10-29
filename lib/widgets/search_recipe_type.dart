import 'package:flutter/material.dart';
import 'package:recipes/models/recipe.dart';

class SearchRecipeType extends StatefulWidget {
  final void Function(List<RecipeType>) onSelectedTypeChanged;
  final void Function(bool) onSelectedFavoriteChanged;

  final List<RecipeType> initalTypeValues;
  final bool initialFavorite;

  const SearchRecipeType(
      {super.key,
      required this.onSelectedTypeChanged,
      required this.initalTypeValues,
      required this.onSelectedFavoriteChanged,
      required this.initialFavorite});

  @override
  State<SearchRecipeType> createState() => _SearchRecipeTypeState();
}

class _SearchRecipeTypeState extends State<SearchRecipeType> {
  late List<RecipeType> _selectedRecipeType = [];
  bool _selectedFavorite = false;

  @override
  void initState() {
    super.initState();
    _selectedRecipeType = widget.initalTypeValues;
    _selectedFavorite = widget.initialFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedFavorite = !_selectedFavorite;
              widget.onSelectedFavoriteChanged(_selectedFavorite);
            });
          },
          child: Icon(
            _selectedFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.red,
            size: 35,
          ),
        ),
        SizedBox(
          width: 12,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              children: [
                ..._selectedRecipeType,
                ...RecipeType.values
                    .where((type) => !_selectedRecipeType.contains(type))
              ].map((type) {
                return ChoiceChip(
                  label: Text(
                    type.name,
                    selectionColor: Theme.of(context).colorScheme.primary,
                    style: TextStyle(fontSize: 20),
                  ),
                  selected: _selectedRecipeType.contains(type),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRecipeType.add(type);
                      } else {
                        _selectedRecipeType.remove(type);
                      }
                      widget.onSelectedTypeChanged(_selectedRecipeType);
                    });
                  },
                  elevation: 2,
                  pressElevation: 5,
                  labelPadding: EdgeInsets.all(2),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
