// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of apple_maps_flutter;

class AnnotationColor {
  const AnnotationColor._(this._json);

  /// The platform red annotation color
  static const red = AnnotationColor._(['red']);
  /// The platform green annotation color
  static const green = AnnotationColor._(['purple']);
  /// The platform purple annotation color
  static const purple = AnnotationColor._(['green']);
  /// A custom annotation color
  ///
  /// Only supported since iOS 9
  static AnnotationColor custom(Color color) => AnnotationColor._(['custom', color.value]);

  final dynamic _json;
  dynamic _toJson() => _json;
}

/// Defines a bitmap image. For a annotation, this class can be used to set the
/// image of the annotation icon. For a ground overlay, it can be used to set the
/// image to place on the surface of the earth.
class BitmapDescriptor {
  const BitmapDescriptor._(this._json);

  /// Creates a BitmapDescriptor that refers to the default annotation image.
  static const BitmapDescriptor defaultAnnotation =
      BitmapDescriptor._(<dynamic>['defaultAnnotation']);

  /// Creates a BitmapDescriptor that refers to a colorization of the default
  /// annotation image. For convenience, there is a predefined set of hue values.
  /// See e.g. [hueYellow].
  static BitmapDescriptor defaultAnnotationWithColor(AnnotationColor color) {
    assert(color != null);
    return BitmapDescriptor._(<dynamic>['defaultAnnotation', color._toJson()]);
  }

  /// Creates a [BitmapDescriptor] from an asset image.
  ///
  /// Asset images in flutter are stored per:
  /// https://flutter.dev/docs/development/ui/assets-and-images#declaring-resolution-aware-image-assets
  /// This method takes into consideration various asset resolutions
  /// and scales the images to the right resolution depending on the dpi.
  static Future<BitmapDescriptor> fromAssetImage(
    ImageConfiguration configuration,
    String assetName, {
    AssetBundle bundle,
    String package,
  }) async {
    if (configuration.devicePixelRatio != null) {
      return BitmapDescriptor._(<dynamic>[
        'fromAssetImage',
        assetName,
        configuration.devicePixelRatio,
      ]);
    }
    final AssetImage assetImage =
        AssetImage(assetName, package: package, bundle: bundle);
    final AssetBundleImageKey assetBundleImageKey =
        await assetImage.obtainKey(configuration);
    return BitmapDescriptor._(<dynamic>[
      'fromAssetImage',
      assetBundleImageKey.name,
      assetBundleImageKey.scale,
    ]);
  }

  final dynamic _json;

  dynamic _toJson() => _json;
}
