//
//  ViewController.swift
//  ruch01
//
//  Created by Yolankyi SERHII on 7/7/19.
//  Copyright © 2019 Yolankyi SERHII. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

var firstlatitude: Double? = 0.0
var firstlongitude: Double? = 0.0
var secondlatitude: Double? = 0.0
var secondlongitude: Double? = 0.0
var checkLocation = false
var typeSeatchWay = MKDirections.Request().transportType
var flagFirstcClick = true
var flagSecondClick = true
var flagFirstSecondClick = false

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate{
    
    @IBOutlet weak var map: MKMapView!
    @IBAction func searchButtom(_ sender: UIBarButtonItem) {
        flagFirstcClick = true
        flagSecondClick = true
        flagFirstSecondClick = false
        self.map.removeOverlays(self.map!.overlays)
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //Ignoring user
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Activity Indicator
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        //Hide search bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //Create the search request
        
        let searcRequewst = MKLocalSearch.Request()
        searcRequewst.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searcRequewst)
        activeSearch.start(completionHandler: { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
                self.showToast(message: "Unknown address!")
            } else {
                //Remove anootations
                let annotations = self.map.annotations
                self.map.removeAnnotations(annotations)

                //Getting data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude

                //Create annotation
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.map.addAnnotation(annotation)
                
                //Zoomingin om annotation
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                let rigion = MKCoordinateRegion(center: coordinate, span: span)
                self.map.setRegion(rigion, animated: true)
                checkLocation = false
            }
        })
    }
    
    @IBOutlet weak var firstLocation: UITextField!
    @IBOutlet weak var secondLocation: UITextField!
    
    func searchOneWay(loc: UITextField, flag: Int) {
        
        let searcRequewstf = MKLocalSearch.Request()
        searcRequewstf.naturalLanguageQuery = loc.text
        let activeSearchf = MKLocalSearch(request: searcRequewstf)
        activeSearchf.start(completionHandler: { (response, error) in
            
            if response == nil {
                self.showToast(message: "Unknown address!")
            } else {
                
                let annotations = self.map.annotations
                self.map.removeAnnotations(annotations)

                if flag == 1 {
                    firstlatitude = response?.boundingRegion.center.latitude
                    firstlongitude = response?.boundingRegion.center.longitude
                } else if flag == 2 {
                    secondlatitude = response?.boundingRegion.center.latitude
                    secondlongitude = response?.boundingRegion.center.longitude
                    self.drowWay()
                }
            }
        })
    }
    
   func drowWay() {
        let sourceLocation = CLLocationCoordinate2D(latitude: firstlatitude!, longitude: firstlongitude!)
        let destinationLocation = CLLocationCoordinate2D(latitude: secondlatitude!, longitude: secondlongitude!)
    
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
    
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
    
        let sourceAnnotation = MKPointAnnotation()
            sourceAnnotation.title = "Times Square"
    
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
    
    
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "Empire State Building"
    
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
    
        self.map.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
    
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = typeSeatchWay
    
        let directions = MKDirections(request: directionRequest)
    
        directions.calculate(completionHandler: {
        (response, error) -> Void in
        
        guard let response = response else {
            if let error = error {
            print("Error: \(error)")
        }
            return
        }
            let route = response.routes[0]
            self.map.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        })
    }
    
    @IBAction func searchWay(_ sender: UIButton) {
        checkLocation = false
        flagFirstcClick = true
        flagSecondClick = true
        flagFirstSecondClick = false
        self.map.removeOverlays(self.map!.overlays)
        self.searchOneWay(loc: self.firstLocation, flag: 1)
        self.searchOneWay(loc: self.secondLocation, flag: 2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        renderer.lineWidth = 4.0
        return renderer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        typeSeatchWay = .automobile
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        locationManager.requestAlwaysAuthorization()
        map.showsUserLocation = true
        map.mapType = .standard
        
        let imageWay = UIImage(named: "car")
        let intendImageWay = imageWay?.withRenderingMode(.alwaysTemplate)
        Car.setImage(intendImageWay, for: .normal)
        Car.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        let imageLocation = UIImage(named: "Location")
        let intendImageLocation = imageLocation?.withRenderingMode(.alwaysTemplate)
        MyLocalFirstItem.setImage(intendImageLocation, for: .normal)
        MyLocalFirstItem.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        MyLocalSecondItem.setImage(intendImageLocation, for: .normal)
        MyLocalSecondItem.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        let point = sender.location(in: map)
        let coordinate = map.convert(point, toCoordinateFrom: map)
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in
                // Place details
                guard let placeMark = placemarks?.first else { return }
                // Country
                if flagFirstcClick {
                    if let country = placeMark.country {
                        self.firstLocation.text = country
                    }
                    // City
                    if let city = placeMark.subAdministrativeArea {
                        self.firstLocation.text = city
                    }
                    // Location name
                    if let street = placeMark.thoroughfare {
                        self.firstLocation.text = street
                    }
                    flagFirstcClick = false
                    flagSecondClick = true
                    flagFirstSecondClick = false
                }
                if flagSecondClick && flagFirstSecondClick {
                    if let country = placeMark.country {
                        self.secondLocation.text = country
                    }
                    // City
                    if let city = placeMark.subAdministrativeArea {
                        self.secondLocation.text = city
                    }
                    // Location name
                    if let street = placeMark.thoroughfare {
                        self.secondLocation.text = street
                    }
                    flagSecondClick = false
                    flagFirstcClick = true
                }
                flagFirstSecondClick = true
        })
    }

    @IBAction func onClickSegment(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex  {
        case 0:
            map.mapType = .standard
        case 1:
            map.mapType = .satellite
        case 2:
            map.mapType = .hybrid
        default:
            map.mapType = .standard
        }
    }
    
    var locationManager = CLLocationManager()
    
    func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-250, width: 150, height: 35))
        
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {
            (isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    @IBAction func omClickGeo(_ sender: UIBarButtonItem) {
        flagFirstcClick = true
        flagSecondClick = true
        flagFirstSecondClick = false
        self.map.removeOverlays(self.map!.overlays)
        if !checkLocation {
            showToast(message: "Starting location!")
            locationManager.startUpdatingLocation()
            checkLocation = true
        }
        else {
            
            showToast(message: "Stop location!")
            locationManager.stopUpdatingLocation()
            checkLocation = false
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        if checkLocation {
            let regionRadius: CLLocationDistance = 1000
            let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            map.setRegion(coordinateRegion, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        if checkLocation {
            let location = locations[0]
            let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            centerMapOnLocation(location: CLLocation(latitude : myLocation.latitude, longitude : myLocation.longitude))

        }
    }
    
    @IBOutlet weak var MyLocalFirstItem: UIButton!
    @IBOutlet weak var MyLocalSecondItem: UIButton!
    
    @IBAction func myLocalFirst(_ sender: UIButton) {
        firstLocation.text = "My location"
        flagFirstcClick = false
        flagSecondClick = true
        flagFirstSecondClick = true
    }
    @IBAction func myLocalSecond(_ sender: UIButton) {
        secondLocation.text = "My location"
        flagSecondClick = false
        flagFirstcClick = true
    }
    
    @IBOutlet weak var Bus: UIButton!
    @IBOutlet weak var Walking: UIButton!
    @IBOutlet weak var Car: UIButton!
    
    func onOfCollor(_ name: String) {
        if name != "Bus" {
            let imageWalking = UIImage(named: "Bus")
            let intendImageWalking = imageWalking?.withRenderingMode(.alwaysTemplate)
            Bus.setImage(intendImageWalking, for: .normal)
            Bus.tintColor = UIColor.black
        }
        if name != "car" {
            let imageCar = UIImage(named: "car")
            let intendImageCar = imageCar?.withRenderingMode(.alwaysTemplate)
            Car.setImage(intendImageCar, for: .normal)
            Car.tintColor = UIColor.black
            }
        if name != "walking" {
            let imagePlane = UIImage(named: "walking")
            let intendImagePlane = imagePlane?.withRenderingMode(.alwaysTemplate)
            Walking.setImage(intendImagePlane, for: .normal)
            Walking.tintColor = UIColor.black
        }
    }
    
    
    @IBAction func plane(_ sender: UIButton) {
        onOfCollor("Bus")
        let image = UIImage(named: "Bus")
        let intendImage = image?.withRenderingMode(.alwaysTemplate)
        sender.setImage(intendImage, for: .normal)
        sender.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        typeSeatchWay = .transit
    }
    @IBAction func walking(_ sender: UIButton) {
        onOfCollor("walking")
        let image = UIImage(named: "walking")
        let intendImage = image?.withRenderingMode(.alwaysTemplate)
        sender.setImage(intendImage, for: .normal)
        sender.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        typeSeatchWay = .walking
    }
    @IBAction func car(_ sender: UIButton) {
        onOfCollor("car")
        let image = UIImage(named: "car")
        let intendImage = image?.withRenderingMode(.alwaysTemplate)
        sender.setImage(intendImage, for: .normal)
        sender.tintColor = UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        typeSeatchWay = .automobile
    }
}
