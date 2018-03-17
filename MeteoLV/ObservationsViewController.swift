//
//  ObservationsViewController.swift
//  MeteoLV
//
//  Created by Kristaps Grinbergs on 18/02/2018.
//  Copyright © 2018 fassko. All rights reserved.
//

import UIKit
import MapKit
import MeteoLVProvider

class ObservationsViewController: UIViewController {
  
  /// Meteo data provider
  let meteoDataProvider = MeteoLVProvider()

  /// Map view
  @IBOutlet weak var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let centerCoordinate = CLLocationCoordinate2D(latitude: 56.8800000, longitude: 24.6061111)
    let region = MKCoordinateRegionMakeWithDistance(centerCoordinate, 200000, 500000)
    mapView.setRegion(region, animated: false)
    
    loadObservations()
    loadLatvianRoadsObservations()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "station", let station = sender as? Station,
      let stationViewController = segue.destination as? StationViewController {
      stationViewController.station = station
    } else if segue.identifier == "roadStation", let station = sender as? LatvianRoadsStation,
      let stationViewController = segue.destination as? RoadStationTableViewController {
      stationViewController.station = station
    }
  }
  
  @IBAction func refreshObservations(_ sender: Any) {
    self.mapView.removeAnnotations(self.mapView.annotations)
    loadObservations()
    loadLatvianRoadsObservations()
  }
  
  /**
    Load observations
  */
  fileprivate func loadObservations() {
    meteoDataProvider.observations { result in
      switch result {
      case let .success(stations):
        let annoations = stations.map { station -> StationAnnotation in
          let annotation = StationAnnotation(station: station)
          annotation.coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
          annotation.title = station.name
          annotation.subtitle = station.temperature
          annotation.accessibilityLabel = station.name
          annotation.accessibilityIdentifier = station.name
          
          return annotation
        }
        
        DispatchQueue.main.async {
          self.mapView.addAnnotations(annoations)
        }
      case let .failure(error):
        print(error)
      }
    }
  }
  
  /**
   Load Latvian roads observation
  */
  fileprivate func loadLatvianRoadsObservations() {
    meteoDataProvider.latvianRoadsObservations { result in
      switch result {
      case let .success(stations):
        let annoations = stations.map { station -> RoadsStationAnnotation in
          let annotation = RoadsStationAnnotation(station: station)
          annotation.coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
          annotation.title = station.name
          annotation.subtitle = station.temperature
          annotation.accessibilityLabel = station.name
          annotation.accessibilityIdentifier = station.name
          
          return annotation
        }
        
        DispatchQueue.main.async {
          self.mapView.addAnnotations(annoations)
        }
      case let .failure(error):
        print(error)
      }
    }
  }
}

// MARK: - MapView delegate methods
extension ObservationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "marker"
    var view: MKMarkerAnnotationView
    
    if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
      as? MKMarkerAnnotationView {
      dequeuedView.annotation = annotation
      view = dequeuedView
      view.displayPriority = .required
    } else {
      view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      view.canShowCallout = true
      view.animatesWhenAdded = true
      view.calloutOffset = CGPoint(x: -5, y: 5)
      view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
      view.displayPriority = .required
    }
    
    return view
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
               calloutAccessoryControlTapped control: UIControl) {
    
    if let station = view.annotation as? StationAnnotation {
      performSegue(withIdentifier: "station", sender: station.station)
      mapView.deselectAnnotation(view.annotation, animated: true)
    } else if let station = view.annotation as? RoadsStationAnnotation, station.station.weatherData.count > 0 {
      performSegue(withIdentifier: "roadStation", sender: station.station)
      mapView.deselectAnnotation(view.annotation, animated: true)
    }
  }
}
