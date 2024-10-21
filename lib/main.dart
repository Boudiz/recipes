import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipes/models/text_constants.dart';
import 'package:recipes/settings.dart';
import 'package:recipes/style/themes.dart';
import 'package:recipes/widgets/main_menu.dart';
import 'package:recipes/widgets/recipe_list.dart';
import 'package:recipes/add_recipe_form.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => SettingsProvider(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme:
          context.watch<SettingsProvider>().isDarkMode ? darkTheme : lightTheme,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    return Scaffold(
      appBar: AppBar(
        title: Text(TextConstants.title),
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.menu),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      drawer: MenuDrawer(),
      body: RecipeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormRecipeApp()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
