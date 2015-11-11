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
    
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    let locationManager = CLLocationManager()
    
    
    @IBOutlet weak var webview: UIWebView!
    
    func loadPage(){

        
        //let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        delay(3.0) {
            // do stuff

        }

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable scroll out of edge
        webview.scrollView.bounces = false
        
        webview.delegate = self
        
        //GEOLOCATION
        locationManager.delegate = self
        locationManager.desiredAccuracy =  kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
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
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.URL
        let str = "\(url!)"
        let urlArray = str.characters.split{$0 == ":"}.map(String.init)
        if urlArray[0] == "swift" {
            if urlArray[1] == "//ready" {
                print("javascript:ready")
                //let result = self.webview.stringByEvaluatingJavaScriptFromString("window._sendLocationData('positionInitial', 51.249, 6.77576)")
                //print(result)
            }
            
            //if external link, open in Safari
            //via http://stackoverflow.com/questions/2532453/force-a-webview-link-to-launch-safari/30648750#30648750
            if navigationType == UIWebViewNavigationType.LinkClicked {
                UIApplication.sharedApplication().openURL(request.URL!)
                return false
            } else {
                return true
            }
            
            //return false
        } else {
            return true
        }
    }
    
    
    
    //GEOLOCATION
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        
        let action = locations.count == 1 ? "positionInitial" : "positionUpdate"
        let lng = "\(location.coordinate.longitude)"
        let lat = "\(location.coordinate.latitude)"
        let command = "window._sendLocationData('\(action)', \(lat), \(lng))"
        print (command)
        self.webview.stringByEvaluatingJavaScriptFromString(command)
        
        

        
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
            print(command)
            self.webview.stringByEvaluatingJavaScriptFromString(command)
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
        let command = "window._sendLocationData('positionUnavailable')"
        print(command)
        self.webview.stringByEvaluatingJavaScriptFromString(command)
    }
    
    //BUTTONS
    
    @IBAction func back(sender: UIBarButtonItem) {
        webview.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webview.goForward()
    }
    
    @IBAction func home(sender: UIBarButtonItem) {
         self.webview.stringByEvaluatingJavaScriptFromString("window._goHome()")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

