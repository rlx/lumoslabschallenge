//
//  ViewController.swift
//  Lumoslabschallenge
//
//  Created by Lior Rudnik on 12/3/16.
//  Copyright © 2016 Lior Rudnik. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController , CLLocationManagerDelegate{
    var locMan:CLLocationManager? = CLLocationManager()
    var mapView:GMSMapView? = nil
    var currentLocation:CLLocation? = nil
    var placesMan:GMSPlacesClient? = nil
    
    //MARK: - create and configre map
    func createMap(camera:GMSCameraPosition)
    {
        DispatchQueue.main.async {
            self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            self.mapView!.isMyLocationEnabled = true
            self.view = self.mapView!
            DispatchQueue.global().async {
                self.obtainPlacesNearCurrentUserLocation()
            }
        }
    }
    func setupMap()
    {
        if let loc = currentLocation {
            let camera = GMSCameraPosition.camera(withLatitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, zoom: 12.0)
            if (self.mapView == nil) {
                createMap(camera: camera)
            }
            else {
                DispatchQueue.main.async {
                    self.mapView!.camera = camera
                }
            }
        }
    }
    func updateMapLocation(loc:CLLocation) {
        print("location updated to \(loc)")
        currentLocation = loc
        self.setupMap()
    }
    //MARK: - alert
    func showAlertNoAction(title:String, description:String) {
        let alert = UIAlertController.init(title: title, message: description, preferredStyle: .alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: - location authorization
    func setupLocationAuthorization() {
        let state = CLLocationManager.authorizationStatus()
        switch state {
        case .restricted, .denied:
            showAlertNoAction(title: "Restricted/Denied", description: "Location services are restricted (Parental control?) or Denied.\nThis App cannot work without it, sorry.")
        case .notDetermined:
            print("No authorization: \(state)")
            locMan?.requestWhenInUseAuthorization()
        default:
            print("We have already authorization for location services")
            break
        }
    }
    //MARK: - view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        placesMan = GMSPlacesClient.shared()
        if (locMan == nil)
        {
            locMan = CLLocationManager()
        }
        setupLocationAuthorization()
        locMan?.delegate = self
        // assuming location is enabled and working (otherwise an alert would have been displayed)
        locMan?.desiredAccuracy = kCLLocationAccuracyKilometer
        locMan?.requestLocation() // this will generate one location update which will drive the map configuration.
    }

    //MARK: - memory
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self.mapView = nil
        self.locMan = nil
        self.currentLocation = nil
    }
    //MARK: - location callbacks
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        DispatchQueue.global().async {
            self.updateMapLocation(loc: locations.first!)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed to obtain location with Error: \(error)")
    }
    
    //MARK: - places - bad API results (dont use)
    // This SDK API does not work well - it doesnt respect the location!
    // Leaving it for reference. The work around is to use the places web service (nearbysearch)
    func obtainPlacesAutoCompleteInMapVisibleRegion() {
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        filter.country = "US" // limit to US otherwise we receive from other countries (bug in the API?)
        DispatchQueue.main.async {
            // this must run on main thread
            let visibleRegion = self.mapView!.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
            // unfortunetly this API doesnt use the bounds as expected so we receive places outside of the area we requestd!
            self.placesMan?.autocompleteQuery("Italian restaurant", bounds: bounds, filter: filter, callback: {(results, error) -> Void in
                if let error = error {
                    print("Autocomplete error \(error)")
                    return
                }
                if let rslts = results {
                    for result in rslts {
                        self.placesMan!.lookUpPlaceID(result.placeID!, callback: { (place:GMSPlace?, error:Error?) in
                            print("details for \(place?.name):\(place) ")
                            if let p = place {
                                self.createAMarkerOnTheMapFor(place: p)
                            }
                            else {
                                print("error while retreiving place info: \(error)")
                            }
                        })
                    }
                }
            })
        }
    }
    //MARK: - Marker setup
    func translatePriceLevelToStr(pLevel:GMSPlacesPriceLevel) ->String
    {
        switch (pLevel) {
        case .cheap:
            return "cheap"
        case .expensive:
            return "expensive"
        case .high:
            return "high"
        case .medium:
            return "medium"
        case .free:
            return "free"
        default:
            return "unknown"
        }
    }
    func translateOpenStatus(openStatus:GMSPlacesOpenNowStatus) -> String {
        switch openStatus {
        case .no:
            return "No"
        case .yes:
            return "Yes"
        default:
            return "Unknown"
        }
    }
    func createAMarkerOnTheMapFor(place:GMSPlace) {
        // interacting with the map view, lets do it on main thread
        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        let openNow = translateOpenStatus(openStatus: place.openNowStatus)
        let phone = (place.phoneNumber != nil) ? place.phoneNumber! : "(no phone)"
        let address = (place.formattedAddress != nil) ? place.formattedAddress!: "(no address)"
        let rating = place.rating
        let priceLevel = self.translatePriceLevelToStr(pLevel: place.priceLevel)
            
        marker.snippet = "Open:\(openNow) , \(phone)\n\(address)\nrating:\(rating), price level:\(priceLevel)"
        marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.5)
        DispatchQueue.main.async {
            marker.map = self.mapView
        }
    }
    //MARK: - places web API
    func buildMapAPIURL() -> String? {
        let searchTerm = "Italian restaurant"
        var urlString:String? = nil
        let radiusMeters = 5000
        // make sure we have current location (otherwise the urlString will be nil
        if let coordinate = currentLocation?.coordinate {
            urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?keyword=\(searchTerm)&type=restaurant&location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radiusMeters)&key=AIzaSyA-RfcEPpzIuiBoiBpM3Y55RZMaLOXvIhE".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            print("URL: \(urlString!)")
        }
        return urlString
    }
    func obtainPlacesNearCurrentUserLocation() {
        // we call the nearby search WEB service instead of the ios SDK
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let urlString = buildMapAPIURL()
        // if we have a valid URL object (urlString was not nil)
        if let url = URL(string: urlString!) {
            // create a network data task to retrieve the result
            let task = session.dataTask(with: url) {(data:Data?, response:URLResponse?, error:Error?) in
                if ((error == nil) && (data != nil)) {
                    //parse the results JSON string
                    if let d = try? JSONSerialization.jsonObject(with: data!)  {
                        // if we made it thus far, lets go over the data and create markers on the map for it
                        DispatchQueue.global().async {
                            self.processPlaceWebAPIResponseData(data: d as! Dictionary<String, AnyObject>)
                        }
                    }
                }
                else {
                    print("received error: \(error) \ndata: \(data)")
                }
            }
            // dont forget the "run" the task
            task.resume()
        }
        else {
            print("bad url object (encoding issues with the urlString?)")
        }
    }
    
    let RESULTS = "results"
    let PLACE_ID_KEY = "place_id"
    
    func processPlaceWebAPIResponseData(data:Dictionary<String,AnyObject>) {
        if let resultsData:Array<AnyObject> = data[RESULTS] as? Array<AnyObject> {
            for placeInfo in resultsData{
                // inside the array we have dictionaries..
                if let placeID:String = placeInfo[PLACE_ID_KEY] as? String {
                    // now that we extracted the place id, lets get the details
                    self.placesMan!.lookUpPlaceID(placeID , callback: { (place:GMSPlace?, error:Error?) in
                        if let p = place {
                            // finally create the actual marker and attach to the map
                            self.createAMarkerOnTheMapFor(place: p)
                        }
                        else {
                            print("error while retreiving place info: \(error)")
                        }
                    })
                }
            }
        }
    }
}

