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
    
    func createMap(camera:GMSCameraPosition)
    {
        DispatchQueue.main.async {
            self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            self.mapView!.isMyLocationEnabled = true
            self.view = self.mapView!
            DispatchQueue.global().async {
                self.obtainPlacesInMapVisibleRegion()
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
    
    func showAlertNoAction(title:String, description:String) {
        let alert = UIAlertController.init(title: title, message: description, preferredStyle: .alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
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
    //MARK: places
    // This SDK API does not work well - it doesnt respect the location!
    // Leaving it for reference. The work around is to use this web service: https://maps.googleapis.com/maps/api/place/nearbysearch/json?input=italiam%20restaurant&types=establishment&location=32.0833,34.804469&radius=50&key=AIzaSyA-RfcEPpzIuiBoiBpM3Y55RZMaLOXvIhE
    
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
    func createAMarkerOnTheMapFor(place:GMSPlace) {
        // interacting with the map view, lets do it on main thread
        DispatchQueue.main.async {
            let marker = GMSMarker(position: place.coordinate)
            marker.title = place.name
            marker.snippet = place.description
            marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.map = self.mapView
        }
    }

    func obtainPlacesNearCurrentUserLocation() {
        // we call the nearby search WEB service
        NSURLRequest.
        //parse the results JSON string
        
    }
    let PLACE_ID_KEY = "place_id"
    
    func createMarkerForMapSearchNearbyResults(data:Dictionary<String,>) {
        let placeID = data[PLACE_ID_KEY]
        self.placesMan!.lookUpPlaceID(placeID!, callback: { (place:GMSPlace?, error:Error?) in
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

