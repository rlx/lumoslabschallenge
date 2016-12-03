//
//  ViewController.swift
//  Lumoslabschallenge
//
//  Created by Lior Rudnik on 12/3/16.
//  Copyright © 2016 Lior Rudnik. All rights reserved.
//

import UIKit
import GoogleMaps


class ViewController: UIViewController , CLLocationManagerDelegate{
    let locMan = CLLocationManager()
    var mapView:GMSMapView? = nil
    var currentLocation:CLLocation? = nil
    
    func setupMap()
    {
        if let loc = currentLocation {
            let camera = GMSCameraPosition.camera(withLatitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, zoom: 12.0)
            if (self.mapView == nil)
            {
                self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            }
            else {
                self.mapView?.camera = camera
            }
            mapView!.isMyLocationEnabled = true
            view = mapView
        }
    }
    func updateMapLocation(loc:CLLocation) {
        print("location updated to \(loc)")
        currentLocation = loc
        DispatchQueue.main.async {
            self.setupMap()
        }
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
            locMan.requestWhenInUseAuthorization()
        default:
            print("We have already authorization for location services")
            break
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLocationAuthorization()
        self.locMan.delegate = self
        // assuming location is enabled and working (otherwise an alert would have been displayed)
        self.locMan.startUpdatingLocation() // this will generate at least one location update which will drive the map configuration.
    }

    //MARK: - memory
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - location update delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locMan.stopUpdatingLocation()
        DispatchQueue.main.async {
            self.updateMapLocation(loc: locations.first!)
        }
    }

}

