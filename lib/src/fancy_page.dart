import 'package:fancy_on_boarding/src/page_model.dart';
import 'package:flutter/material.dart';

import 'fancy_image.dart';

class FancyPage extends StatelessWidget {
  final PageModel model;
  final double percentVisible;

  FancyPage({
    this.model,
    this.percentVisible = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: double.infinity,
        color: model.color,
        child: Opacity(
          opacity: percentVisible,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (model.heroImagePath != null)
              Transform(
                transform: Matrix4.translationValues(0.0, 50.0 * (1.0 - percentVisible), 0.0),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 25.0),
                  child: FancyImage(
                    image: model.heroImagePath,
                    width: 200,
                    height: 200,
                    color: model.heroImageColor,
                  ),
                ),
              ),
            if (model.title != null)
              Transform(
                transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
                child: Padding(padding: EdgeInsets.only(top: 10.0, bottom: 10.0), child: model.title),
              ),
            Transform(
              transform: Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
              child: Padding(
                padding: EdgeInsets.only(bottom: 75.0),
                child: _getBody(context, constraints),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _getBody(BuildContext context, BoxConstraints constraints) {
    return SizedBox(
      height: constraints.maxHeight - 75,
      child: model.buildBody(context),
    );
  }
}
