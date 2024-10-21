import 'package:flutter/material.dart';

import 'package:recipes/models/recipe.dart';

class RecipeTypeSelector extends StatefulWidget {
  final void Function(RecipeType) onSelectedValueChanged;
  final RecipeType? initalValue;

  const RecipeTypeSelector(
      {super.key, required this.onSelectedValueChanged, this.initalValue});

  @override
  State<RecipeTypeSelector> createState() => _RecipeTypeSelectorState();
}

class _RecipeTypeSelectorState extends State<RecipeTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RecipeType>(
        value: widget.initalValue,
        decoration: InputDecoration(
            border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey, width: 1),
        )),
        itemHeight: 50,
        items: RecipeType.values.map((RecipeType type) {
          return DropdownMenuItem<RecipeType>(
            value: type,
            child: Text(
              type.toString(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        onChanged: (RecipeType? newType) {
          if (newType != null) {
            widget.onSelectedValueChanged(newType);
          }
        });
  }
}
