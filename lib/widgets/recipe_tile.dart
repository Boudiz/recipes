import 'package:flutter/material.dart';

import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/utils/utils.dart';
import 'package:recipes/add_recipe_form.dart';
import 'package:recipes/widgets/recipe_page.dart';

class RecipeTile extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const RecipeTile(
      {super.key,
      required this.recipe,
      required this.onDelete,
      required this.onRestore});

  @override
  State<RecipeTile> createState() => _RecipeTileState();
}

class _RecipeTileState extends State<RecipeTile> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: widget.recipe.deleted
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onPrimaryContainer,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                widget.recipe.name,
                style: theme.textTheme.headlineLarge,
                selectionColor: theme.colorScheme.primary,
              ),
              SizedBox(
                width: 10,
              ),
              GestureDetector(
                onDoubleTap: () {
                  Utils.toggleFavorite(
                    widget.recipe,
                    () => setState(() {
                      widget.recipe.isFavorite = !widget.recipe.isFavorite;
                    }),
                  );
                },
                child: Icon(
                  widget.recipe.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: const Color.fromRGBO(240, 10, 10, 1),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
                tooltip: "Affiche la recette",
                child: const Icon(Icons.expand_more),
              ),
              Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "edit",
                    child: Text(TextConstants.edit),
                  ),
                  PopupMenuItem(
                    value: widget.recipe.deleted ? "restore" : "delete",
                    child: widget.recipe.deleted
                        ? Text("Restaurer")
                        : Text(TextConstants.delete),
                  ),
                ],
                onSelected: (value) async {
                  if (value == "edit") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FormRecipeApp(
                                recipe: widget.recipe,
                              )),
                    );
                  } else if (value == "delete") {
                    bool confirmed =
                        await Utils.showDeleteConfirmationDialog(context);
                    if (confirmed) {
                      widget.onDelete();
                    }
                  } else if (value == "restore") {
                    widget.onRestore();
                  }
                },
              ),
            ]),
            SizedBox(height: 4.0),
            Visibility(
              visible: _isVisible,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RecipePage(recipe: widget.recipe)),
                        );
                      },
                      child: Icon(Icons.open_in_full)),
                  Text(widget.recipe.type.toString()),
                  Text('Ingredients:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var ingredient in widget.recipe.ingredients)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 6.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(ingredient),
                      ],
                    ),

                  /*SizedBox(height: 8.0),
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.recipe.description,
                  ),
                  Text(Utils.dateFormatter.format(widget.recipe.created)),
                  Text(Utils.dateFormatter.format(widget.recipe.lastModified)),
                  Text("id: ${widget.recipe.id}"),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
