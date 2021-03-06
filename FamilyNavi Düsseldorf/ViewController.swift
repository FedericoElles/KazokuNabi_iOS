//
//  ViewController.swift
//  FamilyNavi Düsseldorf
//
//  Created by Fritz on 10/11/15.
//  Copyright © 2015 Fritz. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UIWebViewDelegate, CLLocationManagerDelegate {
    
    
    let locationManager = CLLocationManager()
    
    
    @IBOutlet weak var homeButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var webview: UIWebView!
    
    
    var jsReady:Bool = false //if webview ready
    var jsBacklog = [String]() //if gps data faster than webview, store commands here
    var geoInitData:Bool = true //if gps data arrives first time
    var geoLastLocation = CLLocation(latitude: 0, longitude: 0)

    
    //update Button status
    func updateButtons(){
        self.backButton.enabled = self.webview.canGoBack;

        let command = "window.location.hash"
        let hash = self.webview.stringByEvaluatingJavaScriptFromString(command)!
        if hash == "" || hash == "#main" {
            self.homeButton.enabled = false
        } else {
            self.homeButton.enabled = true
        }

        print("Current URL\(hash)")

        
    }
    
    //delay execution
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    

    //execute JS command in webview
    func jsExec(command:String){
        if jsReady {
            print(command)
            self.webview.stringByEvaluatingJavaScriptFromString(command)
        } else {
            jsBacklog.append(command)
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backButton.enabled = false
        self.homeButton.enabled = false
        
        // disable scroll out of edge
        webview.scrollView.bounces = false
        
        webview.delegate = self
        
        //GEOLOCATION
        locationManager.delegate = self
        locationManager.desiredAccuracy =  kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        //if location disabled, send to settings
        //via http://stackoverflow.com/questions/30639119/how-check-on-button-tapped-gps-is-enabled-or-not-in-swiftios-if-yes-then-star
        if !CLLocationManager.locationServicesEnabled() {
            UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!);
        }
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
        let url = NSBundle.mainBundle().URLForResource("index", withExtension:"html", subdirectory: "html")
        let requestObj = NSURLRequest(URL: url!);
        webview.loadRequest(requestObj);
        
    }
    
    func webViewDidStartLoad(wv: UIWebView) {
        print("ViewDidStartLoad")
    }
    
    
    func webViewDidFinishLoad(webView: UIWebView)
    {
        print("ViewDidStopLoad")
        updateButtons()
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.URL
        let str = "\(url!)"
        print("open URL: \(url!)")
        let urlArray = str.characters.split{$0 == ":"}.map(String.init)
        if urlArray[0] == "swift" {
            if urlArray[1] == "//ready" {
                print("javascript:ready")
                self.jsReady = true
                if self.jsBacklog.count > 0 {
                    for command in self.jsBacklog {
                        jsExec(command)
                    }
                }
            }
            
            return false
        } else if urlArray[0] == "https" || urlArray[0] == "http" {
            //if external link, open in Safari
            //via http://stackoverflow.com/questions/2532453/force-a-webview-link-to-launch-safari/30648750#30648750

            UIApplication.sharedApplication().openURL(request.URL!)
            return false

        } else {
            delay(0.3) {
                self.updateButtons()
            }
            return true
        }
    }
    
    
    
    //GEOLOCATION
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        var sendLocation = true
        
        //if lsat location, get distance
        if self.geoLastLocation.coordinate.longitude != 0 &&
           self.geoLastLocation.coordinate.latitude != 0 {
            let distance = self.geoLastLocation.distanceFromLocation(location)
            print("Distance \(distance)")
            if distance < 10 {
                sendLocation = false
            }
        }
        
        //save last location
        self.geoLastLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        if sendLocation {
            let action = self.geoInitData ? "positionInitial" : "positionUpdate"
            self.geoInitData = false
            let lng = "\(location.coordinate.longitude)"
            let lat = "\(location.coordinate.latitude)"
            let command = "window._sendLocationData('\(action)', \(lat), \(lng))"
            jsExec(command)
        }
        
        

        
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0] 
                self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            //let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            //let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let street = (containsPlacemark.thoroughfare != nil) ? containsPlacemark.thoroughfare : ""
            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            let command = "window._sendLocationData('placeUpdate', '\(country!)', '\(locality!)', '\(street!)')"
            jsExec(command)
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
        let command = "window._sendLocationData('positionUnavailable')"
        jsExec(command)
    }
    
    //BUTTONS
    
    @IBAction func back(sender: UIBarButtonItem) {
        webview.goBack()
        delay(0.3) {
            self.updateButtons()
        }
    }
    
    //@IBAction func forward(sender: UIBarButtonItem) {
    //    webview.goForward()
    //}
    
    @IBAction func home(sender: UIBarButtonItem) {
         jsExec("window._goHome()")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

