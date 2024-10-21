import 'package:flutter/material.dart';

import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/utils/utils.dart';
import 'package:recipes/utils/db.dart';
import 'package:recipes/widgets/recipe_type.dart';

import 'main.dart';

class FormRecipeApp extends StatelessWidget {
  final Recipe? recipe;

  const FormRecipeApp({super.key, this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(TextConstants.formTitle)),
      body: FormRecipe(
        recipe: recipe,
      ),
    );
  }
}

class FormRecipe extends StatefulWidget {
  final Recipe? recipe;

  const FormRecipe({super.key, this.recipe});

  @override
  State<FormRecipe> createState() => _FormRecipeState();
}

class _FormRecipeState extends State<FormRecipe> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Open the database and store the reference.
  final database = RecipesDb.instance;

  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _ingredientController = [
    TextEditingController()
  ];
  final TextEditingController _descriptionController = TextEditingController();
  RecipeType? _selectedRecipeType;

  late List<Widget> _ingredientFields = [
    TextFormField(
      decoration: InputDecoration(labelText: 'Ingrédient 1'),
      textInputAction: TextInputAction.next,
      controller: _ingredientController[0],
    )
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.name;
      _selectedRecipeType = widget.recipe!.type;
      _descriptionController.text = widget.recipe!.description;
      List<String> ingredients = widget.recipe!.ingredients;
      final int size = ingredients.length - 1;
      for (var i = 0; i < size; i++) {
        _ingredientController[i].text = ingredients[i];
        _addIngredientField();
      }
      _ingredientController[size].text = ingredients[size];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _ingredientController) {
      controller.dispose();
    }
    _descriptionController.dispose();
    super.dispose();
  }

  // Method to add an ingredient
  void _addIngredientField() {
    final int ingredientSize = _ingredientFields.length;
    _ingredientController.add(TextEditingController());
    setState(() {
      _ingredientFields.add(TextFormField(
        decoration: InputDecoration(
            labelText: "${TextConstants.ingredient} ${ingredientSize + 1}"),
        textInputAction: TextInputAction.next,
        controller: _ingredientController[ingredientSize],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return TextConstants.ingredientValidator;
          }
          return null;
        },
      ));
    });
  }

  // Method to remove last ingredient
  void _removeIngredientField() {
    if (_ingredientFields.length > 1) {
      setState(() {
        _ingredientFields.removeLast();
        _ingredientController.removeLast();
      });
    }
  }

  void _onRecipeTypeSelected(RecipeType selectedType) {
    setState(() {
      _selectedRecipeType = selectedType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  hintText: TextConstants.hintRecipeName,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return TextConstants.nameValidator;
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                controller: _nameController,
              ),
              RecipeTypeSelector(
                onSelectedValueChanged: _onRecipeTypeSelected,
                initalValue: _selectedRecipeType,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${TextConstants.ingredient}s"),
                  ElevatedButton(
                    onPressed: _addIngredientField,
                    child: Icon(Icons.add),
                  ),
                  ElevatedButton(
                    onPressed: _removeIngredientField,
                    child: Icon(Icons.remove),
                  ),
                  ElevatedButton.icon(
                      onPressed: () async {
                        List<String> ingredients =
                            await Utils.enterAllIngredientsDialog(context);

                        int firstEmpty = _ingredientController
                            .indexWhere((controller) => controller.text == "");

                        int newFields;
                        if (firstEmpty == -1) {
                          newFields = ingredients.length;
                          firstEmpty = _ingredientController.length;
                        } else {
                          newFields = ingredients.length - firstEmpty;
                        }

                        setState(() {
                          for (int i = 0; i < newFields; i++) {
                            _addIngredientField();
                          }
                          for (int i = 0; i < ingredients.length; i++) {
                            _ingredientController[firstEmpty + i].text =
                                ingredients[i];
                          }
                        });
                      },
                      label: Icon(Icons.alarm)),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredientFields.length,
                itemBuilder: (context, index) => _ingredientFields[index],
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: TextConstants.hintRecipeDescription,
                ),
                textInputAction: TextInputAction.newline,
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Validate will return true if the form is valid.
                        if (_formKey.currentState!.validate()) {
                          if (widget.recipe == null) {
                            Recipe recipe = Utils.formToRecipe(
                              _nameController,
                              _ingredientController,
                              _descriptionController,
                              _selectedRecipeType!,
                            );
                            database.insertRecipe(recipe);
                          } else {
                            Recipe recipe = Utils.formToRecipe(
                                _nameController,
                                _ingredientController,
                                _descriptionController,
                                _selectedRecipeType!,
                                createdDate: widget.recipe?.created,
                                id: widget.recipe!.id);
                            database.updateRecipe(recipe, widget.recipe!.id);
                          }

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()));

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Recette ${_nameController.text} ${widget.recipe == null ? 'ajoutée' : 'modifiée'}')),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
