//
//  ViewController.swift
//  FamilyNavi Düsseldorf
//
//  Created by Fritz on 10/11/15.
//  Copyright © 2015 Fritz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {
    
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    
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
                let result = self.webview.stringByEvaluatingJavaScriptFromString("window._sendLocationData('positionInitial', 51.249, 6.77576)")
                print(result)
            }
            return false
        } else {
            return true
        }
    }
    
    //BUTTONS
    
    @IBAction func back(sender: UIBarButtonItem) {
        webview.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webview.goForward()
    }
    
    @IBAction func home(sender: UIBarButtonItem) {
        let url = NSBundle.mainBundle().URLForResource("index", withExtension:"html", subdirectory: "html")
        let request = NSURLRequest(URL:url!)
        webview.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

