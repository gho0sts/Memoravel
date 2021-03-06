//
//  MapViewController.swift
//  Memoravel
//
//  Created by JUNYEONG.YOO on 2/9/17.
//  Copyright © 2017 Boostcamp. All rights reserved.
//

// TODO: keyboard automatically appears when Map view page is showing up

import UIKit
import MapKit

protocol MapViewControllerDelegate {
	func didSelectedLocation(_ placemark: MKPlacemark)
}

class MapViewController: UIViewController {

	let locationManager = CLLocationManager()
	var resultSearchController: UISearchController!
	var searchBar: UISearchBar!
	var selectedPin: MKPlacemark?
	var delegate: MapViewControllerDelegate?
	var cancelButton: UIButton!

	var userInputText: String?
	
	@IBOutlet weak var searchBarContainer: UIView!
	@IBOutlet weak var searchMapView: MKMapView!
	
	override var prefersStatusBarHidden: Bool {
		return (self.navigationController?.isNavigationBarHidden)!
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
		
		// Wire up search result table
		let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
		resultSearchController = UISearchController(searchResultsController: locationSearchTable)
		resultSearchController.delegate = self
		resultSearchController.searchResultsUpdater = locationSearchTable
		
		// Settings for navigation bar
		self.navigationController?.automaticallyAdjustsScrollViewInsets = false
		self.navigationController?.extendedLayoutIncludesOpaqueBars = true
		self.automaticallyAdjustsScrollViewInsets = false
		
		// Settings for search bar
		self.searchBar = resultSearchController!.searchBar
		
		self.searchBarContainer.addSubview(self.searchBar)
		self.searchBar.sizeToFit()
		self.searchBar.placeholder = "Search for a place or address"
		self.searchBar.returnKeyType = .search
		self.searchBar.barTintColor = UIColor.journeyMainColor
		self.searchBar.tintColor = UIColor.journeyLightColor
		self.searchBar.isTranslucent = false
		
		resultSearchController.hidesNavigationBarDuringPresentation = false
		resultSearchController.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		locationSearchTable.mapView = searchMapView
		locationSearchTable.delegate = self
		
		// FIXME: Do not follow user location
		searchMapView.userTrackingMode = .none
    }
	
	// Action when user click cancel button
	@IBAction func cancelSearching(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
}

extension MapViewController : CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			locationManager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//		guard let location = locations.first else { return }
//		let span = MKCoordinateSpanMake(0.05, 0.05)
//		let region = MKCoordinateRegion(center: location.coordinate, span: span)
//		searchMapView.setRegion(region, animated: true)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("error:: \(error)")
	}
}

// MARK: Implement method for HandleMapSearch

extension MapViewController: LocationSearchTableDelegate {
	
	func dropPinZoomIn(_ placemark: MKPlacemark) {
		// If right bar button item is nil then create it
		
		// Cache the pin
		selectedPin = placemark
		
		// Clear existing pins
		searchMapView.removeAnnotations(searchMapView.annotations)
		
		// Create a new annotation
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		
		if let city = placemark.locality, let state = placemark.administrativeArea, let country = placemark.country {
			annotation.subtitle = "\(city) \(state), \(country)"
		}
		
		searchMapView.addAnnotation(annotation)
		searchMapView.selectAnnotation(annotation, animated: true)
		
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(placemark.coordinate, span)
		searchMapView.setRegion(region, animated: true)
		
		// Inactive current search controller
		self.resultSearchController.isActive = false
	}
}

// MARK: - Settings for annotation view

extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		guard !(annotation is MKUserLocation) else { return nil }
		
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		}
		
		pinView?.pinTintColor = UIColor.journeyMainColor
		pinView?.canShowCallout = true
		
		let smallSquare = CGSize(width: 30, height: 30)
		let confirmButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
		confirmButton.setBackgroundImage(#imageLiteral(resourceName: "check"), for: .normal)
		confirmButton.addTarget(self, action: #selector(confirmLocation), for: .touchUpInside)
		pinView?.rightCalloutAccessoryView = confirmButton
		
		return pinView
	}

	func confirmLocation() {		
		if let delegate = self.delegate, let placemark = self.selectedPin {
			delegate.didSelectedLocation(placemark)
			self.dismiss(animated: true, completion: nil)
		}
	}
}

// MARK: - Settings for UISearchController

extension MapViewController: UISearchControllerDelegate {
	
	func willPresentSearchController(_ searchController: UISearchController) {
		UIView.animate(withDuration: 0.5) {
			self.navigationController?.navigationBar.frame.size.height = 0.0
		}
		
		self.navigationController?.isNavigationBarHidden = true
	}
	
	func willDismissSearchController(_ searchController: UISearchController) {
		if let text = searchController.searchBar.text {
			userInputText = text
		}
	}
	
	func didDismissSearchController(_ searchController: UISearchController) {
		if let text = userInputText {
			searchController.searchBar.text = text
		}
		
		UIView.animate(withDuration: 0.5) {
			self.navigationController?.navigationBar.frame.size.height = 44.0
		}
		
		self.navigationController?.isNavigationBarHidden = false
	}
}
