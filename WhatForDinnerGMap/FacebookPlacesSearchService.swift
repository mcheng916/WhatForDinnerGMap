//
//  FacebookPlacesSearchService.swift
//  FacebookPlacesSearch
//
//  Created by Denny Tsai on 2017/04/13.
//  Copyright © 2017 Denny Tsai. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class Place {
    
    let name: String
    let rating: Double
    let location: CLLocationCoordinate2D
    let address: String?
    let mapItem: MKMapItem
    let pictureURL: URL?
    
    init(jsonObject: [String: Any]) {
        name = jsonObject["name"] as! String
        rating = jsonObject["overall_star_rating"] as! Double
        
        let locationObject = jsonObject["location"] as! [String: Any]
        
        location = CLLocationCoordinate2D(latitude: locationObject["latitude"] as! Double, longitude: locationObject["longitude"] as! Double)
        
        address = locationObject["street"] as? String
        mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location))
        
        if let pictureObject = (jsonObject["picture"] as! [String: Any])["data"] as? [String: Any], let pictureURLString = pictureObject["url"] as? String {
            pictureURL = URL(string: pictureURLString)!
        } else {
            pictureURL = nil
        }
    }
    
}

class FacebookPlacesSearchService {

    private static let apiUrlString = "https://graph.facebook.com/v2.8/search"
    private static var accessToken = ""
        
    class func setAccessToken(_ token: String) {
        FacebookPlacesSearchService.accessToken = token
    }
    
    func searchForRestaurants(with location: CLLocationCoordinate2D, distance: Double, completionHandler: @escaping ([Place]?, Error?) -> Void) {
        let url = URL(string: "\(FacebookPlacesSearchService.apiUrlString)?q=restaurant&type=place&center=\(location.latitude),\(location.longitude)&distance=\(Int(distance * 1000))&fields=location,name,overall_star_rating,picture.type(large)&limit=60&access_token=\(FacebookPlacesSearchService.accessToken)")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let responseJson = json as? [String: Any], let results = responseJson["data"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil)
                }
                
                return
            }
            
            let places = results.map { Place(jsonObject: $0) }
            completionHandler(places, nil)
        }
        
        task.resume()
    }
    
}
