//
//  ViewController.swift
//  FamilyNavi Düsseldorf
//
//  Created by Fritz on 10/11/15.
//  Copyright © 2015 Fritz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view, typically from a nib.
        let url = NSBundle.mainBundle().URLForResource("index", withExtension:"html", subdirectory: "html")
        //let url = NSURL (string: "http://www.apple.com");
        let requestObj = NSURLRequest(URL: url!);
        webview.loadRequest(requestObj);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

