//
//  AppleMapController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 03.09.19.
//

import Foundation
import MapKit

public class AppleMapViewFactory: NSObject, FlutterPlatformViewFactory {
    
    var registrar: FlutterPluginRegistrar?
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        super.init()
        self.registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let argsDictionary =  args as! Dictionary<String, Any>
        
        return AppleMapController(withFrame: frame, withRegistrar: registrar!, withargs: argsDictionary ,withId: viewId)
        
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}


public class AppleMapController : NSObject, FlutterPlatformView, MKMapViewDelegate {
    @IBOutlet var mapView: FlutterMapView!
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var annotationController: AnnotationController
    var polylineController: PolylineController
    var initialCameraPosition :Dictionary<String, Any>
    var options :Dictionary<String, Any>
    
    let mapTypes: Array<MKMapType> = [
        MKMapType.standard,
        MKMapType.satellite,
        MKMapType.hybrid,
    ]
    
    let userTrackingModes: Array<MKUserTrackingMode> = [
        MKUserTrackingMode.none,
        MKUserTrackingMode.follow,
        MKUserTrackingMode.followWithHeading,
    ]
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any> ,withId id: Int64) {
        self.registrar = registrar
        channel = FlutterMethodChannel(name: "apple_maps_plugin.luisthein.de/apple_maps_\(id)", binaryMessenger: registrar.messenger())
        self.mapView = FlutterMapView(channel: channel)
        annotationController = AnnotationController(mapView: mapView, channel: channel, registrar: registrar)
        polylineController = PolylineController(mapView: mapView, channel: channel, registrar: registrar)
        initialCameraPosition = args["initialCameraPosition"]! as! Dictionary<String, Any>
        options = args["options"] as! Dictionary<String, Any>
        super.init()
        interpretOptions(options: options)
        mapView.setCenterCoordinate(initialCameraPosition, animated: false)
        if let annotationsToAdd :NSArray = args["annotationsToAdd"] as? NSArray {
            annotationController.annotationsToAdd(annotations: annotationsToAdd)
        }
        if let polylinesToAdd :NSArray = args["polylinesToAdd"] as? NSArray {
            polylineController.addPolylines(polylineData: polylinesToAdd)
        }
        mapView.delegate = self
    }
    
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        channel.invokeMethod("camera#onIdle", arguments: "")
    }
    
    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        channel.invokeMethod("camera#onMoveStarted", arguments: "")
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)  {
        if let annotation :FlutterAnnotation = view.annotation as? FlutterAnnotation  {
            annotationController.onAnnotationClick(annotation: annotation)
        }
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else if let flutterAnnotation = annotation as? FlutterAnnotation {
            return getAnnotationView(annotation: flutterAnnotation)
        }
        return nil
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return polylineController.polylineRenderer(overlay: overlay)
    }
    
    private func interpretOptions(options: Dictionary<String, Any>) {
        if let isCompassEnabled: Bool = options["compassEnabled"] as? Bool {
            if #available(iOS 9.0, *) {
                mapView.showsCompass = isCompassEnabled
            } else {
                // not sure if there's a simple solution
            }
        }
        
        if let mapType: Int = options["mapType"] as? Int {
            mapView.mapType = mapTypes[mapType]
        }
        
        if let trafficEnabled: Bool = options["trafficEnabled"] as? Bool {
            if #available(iOS 9.0, *) {
                mapView.showsTraffic = trafficEnabled
            } else {
                // do nothing
            }
        }
        
        if let rotateGesturesEnabled: Bool = options["rotateGesturesEnabled"] as? Bool {
            mapView.isRotateEnabled = rotateGesturesEnabled
        }
        
        if let scrollGesturesEnabled: Bool = options["scrollGesturesEnabled"] as? Bool {
            mapView.isScrollEnabled = scrollGesturesEnabled
        }
        
        if let pitchGesturesEnabled: Bool = options["pitchGesturesEnabled"] as? Bool {
            mapView.isPitchEnabled = pitchGesturesEnabled
        }
        
        if let zoomGesturesEnabled: Bool = options["zoomGesturesEnabled"] as? Bool{
            mapView.isZoomEnabled = zoomGesturesEnabled
        }
        
        if let myLocationEnabled: Bool = options["myLocationEnabled"] as? Bool {
            mapView.setUserLocation(myLocationEnabled: myLocationEnabled)
        }
        
        if let myLocationButtonEnabled: Bool = options["myLocationButtonEnabled"] as? Bool {
            mapView.mapTrackingButton(isVisible: myLocationButtonEnabled)
        }
        
        if let userTackingMode: Int = options["trackingMode"] as? Int {
            mapView.setUserTrackingMode(userTrackingModes[userTackingMode], animated: false)
        }
        
        if let minMaxZoom: Array<Any> = options["minMaxZoomPreference"] as? Array<Any>{
            if let _minZoom: Double = minMaxZoom[0] as? Double {
                mapView.minZoomLevel = _minZoom
            }
            if let _maxZoom: Double = minMaxZoom[1] as? Double {
                mapView.maxZoomLevel = _maxZoom
            }
        }
    }
    
    private func getAnnotationView(annotation: FlutterAnnotation) -> MKAnnotationView{
        let identifier :String = annotation.id
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        let oldFlutterAnnotation = annotationView?.annotation as? FlutterAnnotation
        
        if annotationView != nil {
            if let _ = oldFlutterAnnotation?.icon as? PinAnnotationIcon,
                let newIcon = annotation.icon as? PinAnnotationIcon,
                let pinAnnotation = annotationView as? MKPinAnnotationView {
                setPinColor(annotationView: pinAnnotation, icon: newIcon)
            } else if let _ = oldFlutterAnnotation?.icon as? CustomAnnotationIcon,
                let newIcon = annotation.icon as? CustomAnnotationIcon {
                annotationView?.image = newIcon.image
                setCenterOffset(annotationView: annotationView!, annotation: annotation, icon: newIcon)
            } else {
                annotationView = createAnnotationView(annotation: annotation)
            }
        } else {
            annotationView = createAnnotationView(annotation: annotation)
        }
        // If annotation is not visible set alpha to 0 and don't let the user interact with it
        if (!annotation.isVisible!) {
            annotationView!.canShowCallout = false
            annotationView!.alpha = CGFloat(0.0)
            annotationView!.isDraggable = false
            return annotationView!
        }
        annotationView!.canShowCallout = true
        annotationView!.alpha = CGFloat(annotation.alpha ?? 1.00)
        annotationView!.isDraggable = annotation.isDraggable ?? false
        
        return annotationView!
    }

    private func createAnnotationView(annotation: FlutterAnnotation) -> MKAnnotationView {
        if let pinIcon = annotation.icon as? PinAnnotationIcon {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotation.id)
            setPinColor(annotationView: pinAnnotationView, icon: pinIcon)
            return pinAnnotationView
        } else if let customIcon = annotation.icon as? CustomAnnotationIcon {
            let customAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.id)
            customAnnotationView.image = customIcon.image
            setCenterOffset(annotationView: customAnnotationView, annotation: annotation, icon: customIcon)
            return customAnnotationView
        } else {
            // this shouldn't happen
            return MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotation.id)
        }
    }
    
    private func setPinColor(annotationView: MKPinAnnotationView, icon: PinAnnotationIcon) {
        switch icon.pinColor {
        case .RED:
            annotationView.pinColor = .red
        case .GREEN:
            annotationView.pinColor = .green
        case .PURPLE:
            annotationView.pinColor = .purple
        case .CUSTOM:
            if #available(iOS 9.0, *), let customColor = icon.customColor {
                annotationView.pinTintColor = customColor
            } else {
                annotationView.pinColor = .red
            }
        }
    }
    
    private func setCenterOffset(annotationView: MKAnnotationView, annotation: FlutterAnnotation, icon: CustomAnnotationIcon) {
        let xOffset = CGFloat(0.5 - annotation.anchor.x) * (icon.image?.size.width ?? 0)
        let yOffset = CGFloat(0.5 - annotation.anchor.y) * (icon.image?.size.height ?? 0)
        annotationView.centerOffset = CGPoint(x: xOffset, y: yOffset)
    }
   
    // Functions used for the mapTrackingButton
    func mapTrackingButton(isVisible visible: Bool){
        if (visible) {
            let image = UIImage(named: "outline_near_me")
            let locationButton = UIButton(type: UIButtonType.custom) as UIButton
            locationButton.tag = 100
            locationButton.layer.cornerRadius = 5
            locationButton.frame = CGRect(origin: CGPoint(x: mapView.bounds.width - 45, y: mapView.bounds.height - 45), size: CGSize(width: 40, height: 40))
            locationButton.setImage(image, for: .normal)
            locationButton.backgroundColor = .white
            locationButton.alpha = 0.8
            locationButton.addTarget(self, action: #selector(centerMapOnUserButtonClicked), for:.touchUpInside)
            mapView.addSubview(locationButton)
        } else {
            if let _locationButton = mapView.viewWithTag(100) {
                _locationButton.removeFromSuperview()
            }
        }
    }
    
    @objc func centerMapOnUserButtonClicked() {
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }

    private func toPositionData(data: Array<Any>, animated: Bool) -> Dictionary<String, Any> {
        var positionData: Dictionary<String, Any> = [:]
        if let update: String = data[0] as? String {
            switch(update) {
            case "newCameraPosition":
                if let _positionData : Dictionary<String, Any> = data[1] as? Dictionary<String, Any> {
                    positionData = _positionData
                }
            case "newLatLng":
                if let _positionData : Array<Any> = data[1] as? Array<Any> {
                    positionData = ["target": _positionData]
                }
            case "newLatLngZoom":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let zoom: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "zoom": zoom]
                }
            case "zoomBy":
                if let zoomBy: Double = data[1] as? Double {
                    mapView.zoomBy(zoomBy: zoomBy, animated: animated)
                }
            case "zoomTo":
                if let zoomTo: Double = data[1] as? Double {
                    mapView.zoomTo(newZoomLevel: zoomTo, animated: animated)
                }
            case "zoomIn":
                mapView.zoomIn(animated: animated)
            case "zoomOut":
                mapView.zoomOut(animated: animated)
            default:
                positionData = [:]
            }
            return positionData
        }
        return [:]
    }
    
    // Setup of the view and MethodChannels
    public func view() -> UIView {
        channel.setMethodCallHandler({(call: FlutterMethodCall, result: FlutterResult) -> Void in
            if let args :Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                switch(call.method) {
                case "annotations#update":
                    if let annotationsToAdd = args["annotationsToAdd"] as? NSArray {
                        self.annotationController.annotationsToAdd(annotations: annotationsToAdd)
                    }
                    if let annotationsToChange = args["annotationsToChange"] as? NSArray {
                        self.annotationController.annotationsToChange(annotations: annotationsToChange)
                    }
                    if let annotationsToDelete = args["annotationIdsToRemove"] as? NSArray {
                        self.annotationController.annotationsIdsToRemove(annotationIds: annotationsToDelete)
                    }
                    result(nil)
                case "polylines#update":
                    if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
                        self.polylineController.addPolylines(polylineData: polylinesToAdd)
                    }
                    if let polylinesToChange: NSArray = args["polylinesToChange"] as? NSArray {
                        self.polylineController.changePolylines(polylineData: polylinesToChange)
                    }
                    if let polylinesToRemove: NSArray = args["polylineIdsToRemove"] as? NSArray {
                        self.polylineController.removePolylines(polylineIds: polylinesToRemove)
                    }
                    result(nil)
                case "map#update":
                    self.interpretOptions(options: args["options"] as! Dictionary<String, Any>)
                    //result(mapView.centerCoordinate) implement result for camera update
                case "camera#animate":
                    let positionData :Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
                    if (!positionData.isEmpty) {
                        self.mapView.setCenterCoordinate(positionData, animated: true)
                    }
                    result(nil)
                case "camera#move":
                    let positionData :Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: false)
                    if (!positionData.isEmpty) {
                        self.mapView.setCenterCoordinate(positionData, animated: false)
                    }
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            } else {
                switch call.method {
                case "map#getVisibleRegion":
                    result(self.mapView.getVisibleRegion())
                case "map#isCompassEnabled":
                    if #available(iOS 9.0, *) {
                        result(self.mapView.showsCompass)
                    } else {
                        result(false)
                    }
                case "map#isPitchGesturesEnabled":
                    result(self.mapView.isPitchEnabled)
                case "map#isScrollGesturesEnabled":
                    result(self.mapView.isScrollEnabled)
                case "map#isZoomGesturesEnabled":
                    result(self.mapView.isZoomEnabled)
                case "map#isRotateGesturesEnabled":
                    result(self.mapView.isRotateEnabled)
                case "map#isMyLocationButtonEnabled":
                    result(self.mapView.isMyLocationButtonShowing ?? false)
                case "map#getMinMaxZoomLevels":
                    result([self.mapView.minZoomLevel, self.mapView.maxZoomLevel])
                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            }
        })
        return mapView
    }
}
