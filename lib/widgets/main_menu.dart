import 'package:flutter/material.dart';
import 'package:recipes/add_recipe_form.dart';
import 'package:recipes/settings.dart';
import 'package:recipes/sync_page.dart';

class MenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text('Menu'),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Ajouter une recette'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FormRecipeApp()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text('Syncronisation'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SyncPageApp()),
              ).then((_) => Navigator.pop(context));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              ).then((_) => Navigator.pop(context));
            },
          ),
          // Add more menu items as needed
        ],
      ),
    );
  }
}
