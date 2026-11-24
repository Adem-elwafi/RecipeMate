import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Retrouve un logo SVG officiel chargé depuis un asset dans un test de widget.
Finder findSvgAsset(String assetPath) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName == assetPath,
  );
}
