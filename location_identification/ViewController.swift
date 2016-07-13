//
//  ViewController.swift
//  location_identification
//
//  Created by Phan Lac Phuc on 11/12/15.
//  Copyright © 2015 cmlab. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UITableViewController {
    
    private var realDistance : Int = 0
    
    private var nearbyBeacons: Array<CLBeacon> = []
    
    private var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        let notificationName = "DidRangeBeacons"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedDidRangeBeaconsNotification:", name: notificationName, object: nil)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - notification
    
    func handleReceivedDidRangeBeaconsNotification(notification: NSNotification) {
        NSLog("handleReceivedDidRangeBeaconsNotification")
        var userInfo : NSDictionary
        userInfo = notification.userInfo!
        
        nearbyBeacons = userInfo.objectForKey("beacons") as! Array<CLBeacon>
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
extension ViewController{
    
    @IBAction func saveLogClicked() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var tracking_flag = defaults.boolForKey("tracking_flag")
        if (tracking_flag) == true {
            tracking_flag = false
            defaults.setBool(tracking_flag, forKey: "tracking_flag")
            
            let logMessage = "Tracking flag: \(tracking_flag)"
            let alert: UIAlertController = UIAlertController(title: "Change Tracking Flag", message: logMessage, preferredStyle:  UIAlertControllerStyle.Alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:{
                (action: UIAlertAction!) -> Void in
                print("OK")
            })
            
            
            alert.addAction(defaultAction)
            presentViewController(alert, animated: true, completion: nil)
            
        } else {
            
            var myDict: NSDictionary?
            if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
                myDict = NSDictionary(contentsOfFile: path)
            }
            var apiURL : String?
            if let dict = myDict {
                apiURL = (dict.valueForKey("API URL") as! String)
                //apiURL = "http://192.168.2.150:8888/ObjectLocationTrackingApp/web/"
            }
            
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            
            let url = NSURL(string: "server.php?registerTest", relativeToURL: NSURL(string: apiURL!))
            
            let req = NSURLRequest(URL: url!)
            
            print(req)
            //NSURLSessionDownloadTask is retured from session.dataTaskWithRequest
            let task = session.dataTaskWithRequest(req, completionHandler: {
                (data, resp, err) in
                print(resp!.URL!)
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                    
                    if let testNumber = json["test_number"] as? Int {
                        print("test number = \(testNumber)")
                        tracking_flag = true
                        
                        defaults.setBool(tracking_flag, forKey: "tracking_flag")
                        defaults.setInteger(testNumber, forKey: "test_number")
                        
                        
                        let logMessage = "Tracking flag: \(tracking_flag)"
                        let alert: UIAlertController = UIAlertController(title: "Change Tracking Flag", message: logMessage, preferredStyle:  UIAlertControllerStyle.Alert)
                        
                        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:{
                            (action: UIAlertAction!) -> Void in
                            print("OK")
                        })
                        
                        
                        alert.addAction(defaultAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                        
                    }
                } catch {
                    print(error)
                }
            })
            task.resume()

        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Num: \(indexPath.row)")
        print("Value: \(nearbyBeacons[indexPath.row])")
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyBeacons.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell? =
        tableView.dequeueReusableCellWithIdentifier("MyCell") as UITableViewCell!
        if(cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "MyCell")
            cell!.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        let beacon = nearbyBeacons[indexPath.row]
        
        let majorIdLabel = cell!.viewWithTag(1) as! UILabel
        majorIdLabel.text = "Major : \(beacon.major.integerValue)"
        let minorIdLabel = cell!.viewWithTag(2) as! UILabel
        minorIdLabel.text = "Minor: \(beacon.minor.integerValue)"
        let uuidLabel = cell!.viewWithTag(3)as! UILabel
        uuidLabel.text = "UUID: \(beacon.proximityUUID.UUIDString)"
        let rssiLabel = cell!.viewWithTag(4) as! UILabel
        rssiLabel.text = "RSSI: \(beacon.rssi)"
        
        return cell!
        
    }
    
}
