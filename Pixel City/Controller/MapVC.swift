//
//  ViewController.swift
//  Pixel City
//
//  Created by Raghav Vashisht on 25/08/17.
//  Copyright © 2017 Raghav Vashisht. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import MapKit
import CoreLocation

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    var locationManager = CLLocationManager()
    let authStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var screenSize = UIScreen.main.bounds
    var spinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imgUrlArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        pullUpView.addSubview(collectionView!)
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
        
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
        
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - (spinner?.frame.width)!, y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
        
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - (120) , y: 175, width: 240, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
        collectionView?.addSubview(progressLabel!)
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "dropablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLabel()
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DropablePin(coordinate: touchCoordinate, identifier: "dropablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
        retrieveUrls(forAnnotation: annotation) { (true) in
            print(self.imgUrlArray)
        }
        
        
    }
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DropablePin, handler: @escaping (_ status: Bool) -> ()) {
        imgUrlArray = []
        let url = flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, numberOfPhotos: 40)
        print(url)
        Alamofire.request(url).responseJSON { (response) in
            if response.result.error == nil {
                guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
                let photosDict = json["photos"] as! Dictionary<String, AnyObject>
                let photosDictionary = photosDict["photo"] as! [Dictionary<String,AnyObject>]
                for photo in photosDictionary {
                    let postURL = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imgUrlArray.append(postURL)
                }
                handler(true)
                
            }
        }
    }
    
    
    
}

extension MapVC:CLLocationManagerDelegate {
    func configureLocationServices() {
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // number of items in array
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell
        return cell!
    }
    
    
    
    
}



