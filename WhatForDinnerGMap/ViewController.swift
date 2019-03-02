//
//  ViewController.swift
//  WhatForLunch
//
//  Created by Denny Tsai on 2017/04/17.
//  Copyright © 2017 Denny Tsai. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    

    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var travelTimeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var distanceToResLabel: UILabel!
    
    //only create location manager when getCurrentLocation is run, use ! coz its easier
    //and we can for sure create one in that function
    var locationManager:CLLocationManager!
    var isGettingLocation = false
    var searchService: FacebookPlacesSearchService!
    let okAction = UIAlertAction(title: "Okay", style: .default) { (UIAlertAction) in
    }
    
    
    
//    override func loadView() {
//        //https://developers.google.com/maps/documentation/ios-sdk/map-with-marker
//        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
//        let gMapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//        // Creates a marker in the center of the map.
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
//        marker.title = "Sydney"
//        marker.snippet = "Australia"
//        marker.map = gMapView
//        mapView = gMapView
//    }

    
    
    @IBAction func sliderValueChange(_ sender: Any) {
        let roundedValue = round(distanceSlider.value * 10) / 10
        //now slider can only slide to ceratin position like 0.1, 0.2 etc
        distanceSlider.value = roundedValue
        distanceLabel.text = "\(distanceSlider.value) km"
    }
    
    
    @IBAction func chowTapped(_ sender: Any) {
        getCurrentLocation()
    }
    
    
    
    //it doesnt need to be put in front of searchTapped
    func getCurrentLocation (){
        print("To get current location")
        let status = CLLocationManager.authorizationStatus()
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.delegate = self
        }
        //CLAuthorizationStatus   enum CLAuthorizationStatus : Int32
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        //you dont know when the below function would extract the GPS location
        isGettingLocation = true
        locationManager.requestLocation()
        //you dont know how long it would take
        print("GPS locate okay?")
    }

    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isGettingLocation {
            isGettingLocation = false
            print("GPS locate okay!")
            debugPrint(locations)
            let location = locations.first!
            searchForRestaurant(with: location, distance: distanceSlider.value)
        }else{
            print ("ok I know lah!")
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isGettingLocation = false
        print ("GPS error")
        debugPrint(error)
        //GPS alert error, error window is shown
        let gpsAlert = UIAlertController(title: "Error", message: "GPS error", preferredStyle: .alert)
        gpsAlert.addAction(self.okAction)
        self.present(gpsAlert, animated: true, completion: nil)
    }
    
    
    
    func searchForRestaurant(with location: CLLocation, distance: Float){
        print("Looking for resaturant sergeant!")
        if searchService == nil {
            searchService = FacebookPlacesSearchService()
        }
        searchService.searchForRestaurants(with: location.coordinate, distance: Double(distance)) { places, error in
            if let places = places {
                if places.count == 0 {
                    //if there is no restaurant found, error window is shown
                    let noRestaurantAlert = UIAlertController(title: "Error", message: "No restaurant was found", preferredStyle: .alert)
                    noRestaurantAlert.addAction(self.okAction)
                    self.present(noRestaurantAlert, animated: true, completion: nil)
                }else{
                    let randomIndex = Int(arc4random_uniform(UInt32(places.count)))
                    let place = places[randomIndex]
                    debugPrint(place.name, place.rating, place.location)
                    //since its inside closure, need to add self.
                    self.calculateDirections(from: location, to: place)
                }
            }
        }
    }
    
    //The following is preferred way to run closure, and this is original way to run with MKDirection
    func calculateDirections (from currentLocation: CLLocation, to place: Place){
        print("Now planning the route!")
        //since the drawing can only be done in main thread
        //http://stackoverflow.com/questions/30206983/gmsthreadexception-occur-when-displaying-gmsmarkers-on-ios-simulator
        DispatchQueue.main.async() {
            let camera = GMSCameraPosition.camera(withTarget: place.location, zoom: 14)
            self.mapView.animate(to: camera)
            let marker = GMSMarker(position: place.location)
            marker.snippet = "\(place.name)"
            self.mapView.clear()
            marker.map = self.mapView
            debugPrint(Error.self)
            
            self.restaurantLabel.text = place.name
            self.ratingLabel.text = "Rating: \(place.rating)"
            let orgCoordinate = currentLocation.coordinate
            let destCoordinate = place.location

            let distanceInMeters = GMSGeometryDistance(orgCoordinate, destCoordinate)
            self.distanceToResLabel.text = "\(round(distanceInMeters)) m"
            self.travelTimeLabel.text = "\(Int(round(distanceInMeters/1.4/60))) min"
            self.addressLabel.text = place.address
            
            //display Picture
            let picURL = place.pictureURL!
            //when the pic is those chars at the end, then there is no pic on FB
//            if picURL.substringFromIndex(picURL.endIndex.advancedBy(-8)) != "5986F1DA" {
            debugPrint(picURL)
            let data = try? Data(contentsOf: picURL)
            //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            self.restaurantImageView.image = UIImage(data: data!)
        }
    }
    
            //add path and fit the whole path in one mapview
            //http://stackoverflow.com/questions/37831776/how-to-draw-a-route-between-two-markers-in-google-maps-swift
//            let path = GMSMutablePath()
//            path.add(currentLocation.coordinate)
//            path.add(place.location)
//            let routePolyline = GMSPolyline(path: path)
//            routePolyline.map = self.mapView
//            var bounds = GMSCoordinateBounds()
//            for index in 1...path.count() {
//                bounds = bounds.includingCoordinate(path.coordinate(at: index))
//            }
//            self.mapView.animate(with: GMSCameraUpdate.fit(bounds))
//            let rectangle = GMSPolyline(path: path)
//            rectangle.map = self.mapView
            
            
            //https://developers.google.com/maps/documentation/directions/
            //draw the route btw two places on GMS MAPview
            //http://stackoverflow.com/questions/22550849/drawing-route-between-two-places-on-gmsmapview-in-ios
            //use the web api as follows
            //https://maps.googleapis.com/maps/api/directions/outputFormat?parameters
            //The following request returns driving directions from Toronto, Ontario to Montreal, Quebec.
            //https://maps.googleapis.com/maps/api/directions/json?origin=Toronto&destination=Montreal&key=YOUR_API_KEY
            //mode = walking
//            let origin = "\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)"
//            let destination = "\(place.location.latitude),\(place.location.longitude)"
//            let directionAPI = "https://maps.googleapis.com/maps/api/directions/json?"
//            let key = "AIzaSyCyei8Ky7Ei9UQ3YFC9iPPfZMelM1TgL9c"
    
}















