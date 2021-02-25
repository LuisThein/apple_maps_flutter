// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of apple_maps_flutter;

/// Controller for a single AppleMap instance running on the host platform.
class AppleMapController {
  AppleMapController._(
    this.channel,
    CameraPosition initialCameraPosition,
    this._appleMapState,
  ) : assert(channel != null) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<AppleMapController> init(
    int id,
    CameraPosition initialCameraPosition,
    _AppleMapState appleMapState,
  ) async {
    assert(id != null);
    final MethodChannel channel =
        MethodChannel('apple_maps_plugin.luisthein.de/apple_maps_$id');
    // await channel.invokeMethod<void>('map#waitForMap');
    return AppleMapController._(
      channel,
      initialCameraPosition,
      appleMapState,
    );
  }

  @visibleForTesting
  final MethodChannel channel;

  final _AppleMapState _appleMapState;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'camera#onMoveStarted':
        if (_appleMapState.widget.onCameraMoveStarted != null) {
          _appleMapState.widget.onCameraMoveStarted();
        }
        break;
      case 'camera#onMove':
        if (_appleMapState.widget.onCameraMove != null) {
          _appleMapState.widget.onCameraMove(
            CameraPosition.fromMap(call.arguments['position']),
          );
        }
        break;
      case 'camera#onIdle':
        if (_appleMapState.widget.onCameraIdle != null) {
          _appleMapState.widget.onCameraIdle();
        }
        break;
      case 'annotation#onTap':
        _appleMapState.onAnnotationTap(call.arguments['annotationId']);
        break;
      case 'polyline#onTap':
        _appleMapState.onPolylineTap(call.arguments['polylineId']);
        break;
      case 'polygon#onTap':
        _appleMapState.onPolygonTap(call.arguments['polygonId']);
        break;
      case 'circle#onTap':
        _appleMapState.onCircleTap(call.arguments['circleId']);
        break;
      case 'annotation#onDragEnd':
        _appleMapState.onAnnotationDragEnd(call.arguments['annotationId'],
            LatLng._fromJson(call.arguments['position']));
        break;
      case 'infoWindow#onTap':
        _appleMapState.onInfoWindowTap(call.arguments['annotationId']);
        break;
      case 'map#onTap':
        _appleMapState.onTap(LatLng._fromJson(call.arguments['position']));
        break;
      case 'map#onLongPress':
        _appleMapState
            .onLongPress(LatLng._fromJson(call.arguments['position']));
        break;
      default:
        throw MissingPluginException();
    }
  }

  /// Updates configuration options of the map user interface.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMapOptions(Map<String, dynamic> optionsUpdate) async {
    assert(optionsUpdate != null);
    await channel.invokeMethod<void>(
      'map#update',
      <String, dynamic>{
        'options': optionsUpdate,
      },
    );
  }

  /// Updates annotation configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateAnnotations(_AnnotationUpdates annotationUpdates) async {
    assert(annotationUpdates != null);
    await channel.invokeMethod<void>(
      'annotations#update',
      annotationUpdates._toMap(),
    );
  }

  /// Updates polyline configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolylines(_PolylineUpdates polylineUpdates) async {
    assert(polylineUpdates != null);
    await channel.invokeMethod<void>(
      'polylines#update',
      polylineUpdates._toMap(),
    );
  }

  /// Updates polygon configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolygons(_PolygonUpdates polygonUpdates) async {
    assert(polygonUpdates != null);
    await channel.invokeMethod<void>(
      'polygons#update',
      polygonUpdates._toMap(),
    );
  }

  /// Updates circle configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateCircles(_CircleUpdates circleUpdates) async {
    assert(circleUpdates != null);
    await channel.invokeMethod<void>(
      'circles#update',
      circleUpdates._toMap(),
    );
  }

  /// Starts an animated change of the map camera position.
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> animateCamera(CameraUpdate cameraUpdate) async {
    await channel.invokeMethod<void>('camera#animate', <String, dynamic>{
      'cameraUpdate': cameraUpdate._toJson(),
    });
  }

  /// Programmatically show the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> showMarkerInfoWindow(AnnotationId annotationId) {
    assert(annotationId != null);
    return channel.invokeMethod<void>('annotations#showInfoWindow',
        <String, String>{'annotationId': annotationId.value});
  }

  /// Programmatically hide the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> hideMarkerInfoWindow(AnnotationId annotationId) {
    assert(annotationId != null);
    return channel.invokeMethod<void>('annotations#hideInfoWindow',
        <String, String>{'annotationId': annotationId.value});
  }

  /// Returns `true` when the [InfoWindow] is showing, `false` otherwise.
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  Future<bool> isMarkerInfoWindowShown(AnnotationId annotationId) {
    assert(annotationId != null);
    return channel.invokeMethod<bool>('annotations#isInfoWindowShown',
        <String, String>{'annotationId': annotationId.value});
  }

  /// Changes the map camera position.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> moveCamera(CameraUpdate cameraUpdate) async {
    await channel.invokeMethod<void>('camera#move', <String, dynamic>{
      'cameraUpdate': cameraUpdate._toJson(),
    });
  }

  /// Returns the current zoomLevel.
  Future<double> getZoomLevel() async {
    return channel.invokeMethod<double>('camera#getZoomLevel');
  }

  /// Return [LatLngBounds] defining the region that is visible in a map.
  Future<LatLngBounds> getVisibleRegion() async {
    final Map<String, dynamic> latLngBounds =
        await channel.invokeMapMethod<String, dynamic>('map#getVisibleRegion');
    final LatLng southwest = LatLng._fromJson(latLngBounds['southwest']);
    final LatLng northeast = LatLng._fromJson(latLngBounds['northeast']);

    return LatLngBounds(northeast: northeast, southwest: southwest);
  }


  /// A projection is used to translate between on screen location and geographic coordinates.
  /// Screen location is in screen pixels (not display pixels) with respect to the top left corner
  /// of the map, not necessarily of the whole screen.
  Future<Offset> getScreenCoordinate(LatLng latLng) async {
    final point = await channel
        .invokeMapMethod<String, dynamic>(
        'camera#convert', <String, dynamic>{
      'annotation': [latLng.latitude, latLng.longitude]
    });
    if (!point.containsKey('point')) {
      return null;
    }
    final doubles = List<double>.from(point['point']);
    return Offset(doubles.first, doubles.last);
  }
}
