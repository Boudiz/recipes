import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recipes/main.dart';
import 'package:recipes/models/recipe.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecipePage extends StatefulWidget {
  final Recipe recipe;

  const RecipePage({super.key, required this.recipe});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  bool _isLocked = false;

  void _updateRotationAndScreenLock() {
    if (_isLocked) {
      _unlockRotationAndScreen();
    } else {
      _lockRotationAndScreen();
    }

    _isLocked = !_isLocked;
  }

  void _lockRotationAndScreen() {
    // Lock the screen to the current orientation
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    if (currentOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } else if (currentOrientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }

    // Prevent the screen from going to sleep
    WakelockPlus.enable();
  }

  void _unlockRotationAndScreen() {
    // Unlock screen rotation
    SystemChrome.setPreferredOrientations(List.empty());

    // Allow the screen to enter sleep mode
    WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<dynamic>(
      onPopInvokedWithResult: (didPop, result) {
        _unlockRotationAndScreen();
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: () => {
                      setState(() {
                        _updateRotationAndScreenLock();
                      })
                    },
                    child: Icon(
                      _isLocked ? Icons.lock : Icons.lock_open,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    widget.recipe.name,
                    style: theme.textTheme.headlineLarge,
                  ),
                  Divider(
                    height: 40,
                    thickness: 2,
                    indent: 30,
                    endIndent: 30,
                  ),
                  Text(
                    "${TextConstants.ingredient}s :",
                    style: theme.textTheme.headlineSmall,
                  ),
                  SizedBox(height: 12),
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
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  Divider(
                    height: 40,
                    thickness: 2,
                    indent: 30,
                    endIndent: 30,
                  ),
                  Text(
                    "Description :",
                    style: theme.textTheme.headlineSmall,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(widget.recipe.description),
                  SizedBox(height: 55),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            _unlockRotationAndScreen();
          },
          child: Icon(
            Icons.home,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
