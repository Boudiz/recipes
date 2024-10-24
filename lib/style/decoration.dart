import 'package:flutter/material.dart';

InputDecoration inputDecoration({String? hintText}) {
  return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey, width: 1),
      ));
}

BoxDecoration boxTypeDecoration(ThemeData theme, bool isDeleted) {
  return BoxDecoration(
      color: isDeleted
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onPrimaryContainer,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(width: 2, color: theme.colorScheme.onSecondary),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow,
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        )
      ]);
}
