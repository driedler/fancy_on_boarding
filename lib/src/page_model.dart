import 'package:flutter/material.dart';

class PageModel {
  final Color color;
  final String heroImagePath;
  final Color heroImageColor;
  final Widget title;
  final Widget body;
  final String iconImagePath;
  final Icon icon;

  PageModel({
    this.body,
    this.color,
    this.heroImagePath,
    this.heroImageColor,
    this.title,   
    this.iconImagePath,
    this.icon,
  })  :  assert(
            (iconImagePath != null && icon == null) ||
                (iconImagePath == null && icon != null),
            'Cannot provide both icon, iconImagePath');

  Widget buildBody(BuildContext context) {
    return this.body;
  }
}
