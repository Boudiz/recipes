import 'package:flutter/material.dart';

class ResearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;

  const ResearchBar({super.key, required this.onSearchChanged});

  @override
  State<ResearchBar> createState() => _ResearchBarState();
}

class _ResearchBarState extends State<ResearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
            hintText: "Search recipes...",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            )),
        onChanged: (text) => widget.onSearchChanged(text),
      ),
    );
  }
}
