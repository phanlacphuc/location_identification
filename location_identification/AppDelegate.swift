//
//  AppDelegate.swift
//  location_identification
//
//  Created by Phan Lac Phuc on 11/12/15.
//  Copyright © 2015 cmlab. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var locationManager: CLLocationManager?
    var beaconRegion: CLBeaconRegion?
    var beaconUUID: NSUUID?
    var beaconIdentifier: String?
    var apiURL: String?
    var latitude: Double?
    var longitude: Double?
    var sessionNumber: Int? = 0
    var testNumber: Int? = 0
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            // Use your dict here
            beaconUUID = NSUUID(UUIDString:(dict.valueForKey("Beacon UUID") as! String))
            beaconIdentifier = (dict.valueForKey("Beacon Identifier") as! String)
            apiURL = (dict.valueForKey("API URL") as! String)
        }
        
        //Construct the region
        beaconRegion = CLBeaconRegion(proximityUUID: beaconUUID!, identifier: beaconIdentifier!)
        beaconRegion!.notifyEntryStateOnDisplay = true
        
        locationManager = CLLocationManager()
        
        
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        //the below 2 method can be called without dependence
        locationManager!.startMonitoringForRegion(beaconRegion!)
        
        print("application launched")
        if let options = launchOptions {
            print("options")
            // Do your checking on options here
            let userInfo = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as! UILocalNotification!
            if (userInfo != nil) {
                print("userInfo.count > 0")
            }
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func registerSession() {
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let url = NSURL(string: "server.php?registerSession", relativeToURL: NSURL(string: apiURL!))
        
        let req = NSURLRequest(URL: url!)
        
        print(req)
        //NSURLSessionDownloadTask is retured from session.dataTaskWithRequest
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data, resp, err) in
            print(resp!.URL!)
            print(NSString(data: data!, encoding: NSUTF8StringEncoding))
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                
                if let sessionNumber = json["session_number"] as? Int {
                    print("session number = \(sessionNumber)")
                    self.sessionNumber = sessionNumber
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setInteger(self.sessionNumber!, forKey: "session_number")
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        manager.requestStateForRegion(region)
        print("didStartMonitoringForRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("monitoringDidFailForRegion \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        print("didRangeBeacons in region \(region)")
        
        dispatch_async(dispatch_get_main_queue(),{
            let notificationName = "DidRangeBeacons"
            let userInfo: NSDictionary = NSDictionary(object: beacons, forKey: "beacons")
            NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil, userInfo: userInfo as [NSObject : AnyObject])
        })
        
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let tracking_flag = defaults.boolForKey("tracking_flag")
        if !tracking_flag {
            return
        }
        
        for beacon in beacons {
            if (beacon.rssi != 0 && sessionNumber != 0) {
                let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                let session = NSURLSession(configuration: config)
                
                let defaults = NSUserDefaults.standardUserDefaults()
                testNumber = defaults.integerForKey("test_number")
                
                let paramString = "&ibeacon_major_number=\(beacon.major)&ibeacon_minor_number=\(beacon.minor)&latitude=\(latitude!)&longitude=\(longitude!)&rssi=\(beacon.rssi)&session_number=\(sessionNumber!)&test_number=\(testNumber!)"
                
                let url = NSURL(string: "server.php?postData\(paramString)", relativeToURL: NSURL(string: apiURL!))
                
                let req = NSURLRequest(URL: url!)
                
                //NSURLSessionDownloadTask is retured from session.dataTaskWithRequest
                let task = session.dataTaskWithRequest(req, completionHandler: {
                    (data, resp, err) in
                    print(resp!.URL!)
                    print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                })
                task.resume()
            }
        }

    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if (state == .Inside){
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.startUpdatingLocation()
            print("did enter the region of \(region.identifier)")
            
            registerSession()
            
        }else{
            manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.stopUpdatingLocation()
            print("did exit the region of \(region.identifier)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        latitude = locValue.latitude
        longitude = locValue.longitude
    }
}
