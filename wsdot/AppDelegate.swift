//
//  AppDelegate.swift
//  wsdot
//
//  Copyright (c) 2016 Washington State Department of Transportation
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>
//

import UIKit
import Firebase
import GoogleMobileAds
import UserNotifications
import GoogleMaps
import RealmSwift
import Realm
import EasyTipView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    var newDB: Bool = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let theme = Theme(rawValue: EventStore.getActiveEventThemeId()) ?? .defaultTheme
        ThemeManager.applyTheme(theme: theme)
        migrateRealm()
        CachesStore.initCacheItem()
        
        GMSServices.provideAPIKey(ApiKeys.getGoogleAPIKey())
        FirebaseApp.configure()
        
        application.registerForRemoteNotifications()
        
        MobileAds.shared.start(completionHandler: nil)
        // print(GADMobileAds.sharedInstance().sdkVersion)
        // GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "9c3a9dd6ec9e8078003e5d4f8c885944" ]
        
        // EasyTipView Setup
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = UIColor(hue:0.46, saturation:0.99, brightness:0.6, alpha:1)
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top

        // Make these preferences global for all future EasyTipViews
        EasyTipView.globalPreferences = preferences
        
        // Reset Warning each time app starts
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasSeenWarning)
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self
        }
        
        FerryRealmStore.flushOldData()
        CamerasStore.flushOldData()
        TravelTimesStore.flushOldData()
        HighwayAlertsStore.flushOldData()
        NotificationsStore.flushOldData()
        TollRateSignsStore.flushOldData()
        TollRateTableStore.flushOldData()
        BorderWaitStore.flushOldData()
        BridgeAlertsStore.flushOldData()
        
        NSSetUncaughtExceptionHandler { exception in
           print(exception)
           print(exception.callStackSymbols)
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        FerryRealmStore.flushOldData()
        CamerasStore.flushOldData()
        TravelTimesStore.flushOldData()
        HighwayAlertsStore.flushOldData()
        NotificationsStore.flushOldData()
        TollRateSignsStore.flushOldData()
        TollRateTableStore.flushOldData()
        BorderWaitStore.flushOldData()
        BridgeAlertsStore.flushOldData()
    }
    
    // MARK: Push Notifications
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

        // ensure topic subs are always in sync with what we have stored on the client.
        for topic in NotificationsStore.getTopics() {
            if topic.subscribed {
                Messaging.messaging().subscribe(toTopic: topic.topic)
            } else {
                Messaging.messaging().unsubscribe(fromTopic: topic.topic)
            }
        }
    }
    
    // catches notifications while app is in foreground and displays
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
       
        // Display the notificaion.
        completionHandler(UNNotificationPresentationOptions.alert)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("didReceiveRemoteNotification w/ completionHandler.")

        Messaging.messaging().appDidReceiveMessage(userInfo)
            if let alertType = userInfo["type"] as? String {
                if alertType == "ferry_alert" {
                    MyAnalytics.event(category: "Notification", action: "Message Opened" , label: "Ferry Alert")
                    if let routeIdString = userInfo["route_id"] as? String {
                        if let routeId = Int(routeIdString){
                            launchFerriesAlertScreen(routeId: routeId)
                        }
                    }
                } else if alertType == "highway_alert" {
                    MyAnalytics.event(category: "Notification", action: "Message Opened" , label: "Traffic Alert")
                    if let alertIdString = userInfo["alert_id"] as? String, let latString = userInfo["lat"] as? String, let longString = userInfo["long"] as? String    {
                        if let alertId = Int(alertIdString), let lat = Double(latString), let long = Double(longString) {
                            launchTrafficAlertDetailsScreen(alertId: alertId, latitude: lat, longitude: long)
                        }
                    }
                } else if alertType == "bridge_alert" {
                    MyAnalytics.event(category: "Notification", action: "Message Opened" , label: "Bridge Alert")
                if let alertIdString = userInfo["alert_id"] as? String {
                    if let alertId = Int(alertIdString) {
                        launchBridgeAlertsViewControllerScreen(alertId: alertId)
                    }
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // unused - old method from before bridge alerts had their own section
    func launchTrafficAlertDetailsScreenWithNoAlert(
        title: String, description: String, latitude: Double, longitude: Double) {
        
        let trafficMapStoryboard: UIStoryboard = UIStoryboard(name: "TrafficMap", bundle: nil)
        
        // Set up nav and vc stack
        let trafficMapNav = trafficMapStoryboard.instantiateViewController(withIdentifier: "TrafficMapNav") as! UINavigationController
        let trafficMap = trafficMapStoryboard.instantiateViewController(withIdentifier: "TrafficMapViewController") as! TrafficMapViewController
        
        let HighwayAlertStoryboard: UIStoryboard = UIStoryboard(name: "HighwayAlert", bundle: nil)
        
        let highwayAlertDetails = HighwayAlertStoryboard.instantiateViewController(withIdentifier: "HighwayAlertViewController") as! HighwayAlertViewController
  
        highwayAlertDetails.fromPush = true
        highwayAlertDetails.hasAlert = false
        highwayAlertDetails.pushLat = latitude
        highwayAlertDetails.pushLong = longitude
        highwayAlertDetails.title = title
        highwayAlertDetails.pushMessage = description
        
        // assign vc stack to new nav controller
        trafficMapNav.setViewControllers([trafficMap, highwayAlertDetails], animated: false)

        setNavController(newNavigationController: trafficMapNav)
    }
    
    func launchTrafficAlertDetailsScreen(alertId: Int, latitude: Double, longitude: Double){

        let trafficMapStoryboard: UIStoryboard = UIStoryboard(name: "TrafficMap", bundle: nil)
        
        // Set up nav and vc stack
        let trafficMapNav = trafficMapStoryboard.instantiateViewController(withIdentifier: "TrafficMapNav") as! UINavigationController
        let trafficMap = trafficMapStoryboard.instantiateViewController(withIdentifier: "TrafficMapViewController") as! TrafficMapViewController
        
        let HighwayAlertStoryboard: UIStoryboard = UIStoryboard(name: "HighwayAlert", bundle: nil)
        
        let highwayAlertDetails = HighwayAlertStoryboard.instantiateViewController(withIdentifier: "HighwayAlertViewController") as! HighwayAlertViewController
  
        highwayAlertDetails.alertId = alertId
        highwayAlertDetails.fromPush = true
        highwayAlertDetails.pushLat = latitude
        highwayAlertDetails.pushLong = longitude
        
        // assign vc stack to new nav controller
        trafficMapNav.setViewControllers([trafficMap, highwayAlertDetails], animated: false)

        setNavController(newNavigationController: trafficMapNav)
    
    }

    func launchFerriesAlertScreen(routeId: Int) {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Ferries", bundle: nil)
        
        // Set up nav and vc stack
        let ferriesNav = mainStoryboard.instantiateViewController(withIdentifier: "FerriesNav") as! UINavigationController
        
        let ferrySchedules = mainStoryboard.instantiateViewController(withIdentifier: "RouteSchedulesViewController") as! RouteSchedulesViewController
        
        let ferrySailings = mainStoryboard.instantiateViewController(withIdentifier: "RouteDeparturesViewController") as! RouteDeparturesViewController
        
        ferrySailings.routeId = routeId
        
        let ferryAlerts = mainStoryboard.instantiateViewController(withIdentifier: "RouteAlertsViewController") as! RouteAlertsViewController
  
        ferryAlerts.routeId = routeId
        
        // assign vc stack to new nav controller
        ferriesNav.setViewControllers([ferrySchedules, ferrySailings, ferryAlerts], animated: false)

        setNavController(newNavigationController: ferriesNav)

    }
    
    func launchBridgeAlertsViewControllerScreen(alertId: Int){
        let bridgeAlertsStoryboard: UIStoryboard = UIStoryboard(name: "BridgeAlerts", bundle: nil)

        // Set up nav and vc stack
        let bridgesNav = bridgeAlertsStoryboard.instantiateViewController(withIdentifier: "BridgesNav") as! UINavigationController
        let bridgeAlertsVC = bridgeAlertsStoryboard.instantiateViewController(withIdentifier: "BridgeAlertsViewController") as! BridgeAlertsTableViewController
        
        let bridgeAlertDetails = bridgeAlertsStoryboard.instantiateViewController(withIdentifier: "BridgeAlertDetailViewController") as! BridgeAlertDetailViewController

        // Set up nav and vc stack
        bridgeAlertDetails.alertId = alertId
        bridgeAlertDetails.fromPush = true
        
        // assign vc stack to new nav controller
        bridgesNav.setViewControllers([bridgeAlertsVC, bridgeAlertDetails], animated: false)

        setNavController(newNavigationController: bridgesNav)

    }
    
    func setNavController(newNavigationController: UINavigationController){
        // get the main split view, check how VCs are currently displayed
        let rootViewController = self.window!.rootViewController as! UISplitViewController
        if (rootViewController.isCollapsed) {
            // Only one vc displayed, pop current stack and assign new vc stack
            let nav = rootViewController.viewControllers[0] as! UINavigationController
            nav.popToRootViewController(animated: false)
            nav.pushViewController(newNavigationController, animated: true)
            
            print("1")
        
        } else {
            // Master/Detail displayed, swap out the current detail view with the new stack of view controllers.
            newNavigationController.viewControllers[0].navigationItem.leftBarButtonItem = rootViewController.displayModeButtonItem
            newNavigationController.viewControllers[0].navigationItem.leftItemsSupplementBackButton = true
            rootViewController.showDetailViewController(newNavigationController, sender: self)
            
            print("2")
            
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        // When schema version is unsupported notify users.
        if (newDB) {
            let alertController = UIAlertController(title: "Thank you for updating the WSDOT app", message: "This version of the app requires a new database to work correctly. All user settings have been reset. We apologize for any inconvenience.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in }
            alertController.addAction(okAction)
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            
            UserDefaults.standard.set("on", forKey: UserDefaultsKeys.trafficLayer)
            UserDefaults.standard.set("on", forKey: UserDefaultsKeys.alerts)
            UserDefaults.standard.set("on", forKey: UserDefaultsKeys.restAreas)
            UserDefaults.standard.set("on", forKey: UserDefaultsKeys.cameras)
            UserDefaults.standard.set("on", forKey: UserDefaultsKeys.shouldCluster)
            UserDefaults.standard.set("system", forKey: UserDefaultsKeys.mapStyle)
            
            newDB = false

        }
        
    }
    
    // MARK: Realm
    func migrateRealm(){
        
        // Check Realm schema version.
        let configCheck = Realm.Configuration()
        
        do {
            
            let fileUrl = try schemaVersionAtURL(configCheck.fileURL!)
            print("schema version \(fileUrl)")
            
        } catch let error as Realm.Error where error.code == .unsupportedFileFormatVersion {
            
            // Clear database when schema version is unsupported.
            try? FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
            newDB = true
            print(error)

        } catch {
            
            print(error)
            
        }
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 16,

            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    // The enumerateObjects(ofType:_:) method iterates
                    // over every MountainPassItem object stored in the Realm file
                    migration.enumerateObjects(ofType: MountainPassItem.className()) { oldObject, newObject in
                        // pull the camera ids from the old field and place it into the new
                        let oldCameras = oldObject!["cameras"] as! List<DynamicObject>
                        let passCameraIds = newObject!["cameraIds"] as! List<DynamicObject>
                        for camera in oldCameras {
                            let newPassCameraId = migration.create(PassCameraIDItem.className())
                            newPassCameraId["cameraId"] = camera["cameraId"] as! Int
                            passCameraIds.append(newPassCameraId)
                        }
                    }
                }
                
                if (oldSchemaVersion < 2) {
                    // The enumerateObjects(ofType:_:) method iterates
                    // over every TravelTime object stored in the Realm file
                    migration.enumerateObjects(ofType: TravelTimeItem.className()) { oldObject, newObject in
                        // Add start/end lat/long to travel times
                        newObject!["startLatitude"] = 0.0
                        newObject!["endLatitude"] = 0.0
                        newObject!["startLongitude"] = 0.0
                        newObject!["endLongitude"] = 0.0
                    }
                }
                
                if (oldSchemaVersion < 3) {
                   migration.deleteData(forType: TravelTimeItemGroup.className())
                   migration.deleteData(forType: TravelTimeItem.className())
                   migration.deleteData(forType: CacheItem.className())
                }
                
                if (oldSchemaVersion < 4) {
                    migration.enumerateObjects(ofType: CacheItem.className()) { oldObject, newObject in
                        newObject!["notificationsLastUpdate"] = Date(timeIntervalSince1970: 0)
                    }
                }
                
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: CacheItem.className()) { oldObject, newObject in
                        newObject!["tollRatesLastUpdate"] = Date(timeIntervalSince1970: 0)
                    }
                }
                
                /*
                    Adds milepost and direction fields.
                    Clears cache times to force refresh
                */
                if (oldSchemaVersion < 6) {
                    migration.enumerateObjects(ofType: CameraItem.className()) { oldObject, newObject in
                        newObject!["milepost"] = -1
                        newObject!["direction"] = ""
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /*
                    Adds favorite field to borderwaits.
                    Clears cache times to force refresh
                */
                if (oldSchemaVersion < 7) {
                    migration.enumerateObjects(ofType: BorderWaitItem.className()) { oldObject, newObject in
                        newObject!["selected"] = false
                        newObject!["delete"] = false
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /*
                    Adds cameraId and tavelTimeId field to my route item.
                    Clears cache times to force refresh
                */
                if (oldSchemaVersion < 8) {
                    migration.enumerateObjects(ofType: MyRouteItem.className()) { oldObject, newObject in
                        newObject!["cameraIds"] = List<Int>()
                        newObject!["foundCameras"] = false
                        newObject!["travelTimeIds"] = List<Int>()
                        newObject!["foundTravelTimes"] = false
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /*
                   tollTableItem added and cache item for toll table data
                */
                if (oldSchemaVersion < 9) {
                    migration.enumerateObjects(ofType: CacheItem.className()) { oldObject, newObject in
                        newObject!["staticTollRatesLastUpdate"] = Date(timeIntervalSince1970: 0)
                    }
                }
                
                /*
                    BridgeAlertItem added and cache item for bridge alert date
                 */
                if (oldSchemaVersion < 10) {
                    migration.enumerateObjects(ofType: CacheItem.className()) { oldObject, newObject in
                        newObject!["bridgeAlertsLastUpdate"] = Date(timeIntervalSince1970: 0)
                    }
                }
                
                /*
                    Adds WSDOT traffic map data from https://wsdot.com/travel/real-time/service/api/Alerts
                    Clears cache times to force refresh
                */
                if (oldSchemaVersion < 11) {
                    migration.enumerateObjects(ofType: HighwayAlertItem.className()) { oldObject, newObject in
                        newObject!["roadName"] = ""
                        newObject!["eventCategoryTypeDescription"] = ""
                        newObject!["travelCenterPriorityId"] = 0                        
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /*
                 Adds eventCategoryType and midpoint alert data to HighwayAlertItems
                 Clears cache times to force refresh
                 */
                if (oldSchemaVersion < 12) {
                    migration.enumerateObjects(ofType: HighwayAlertItem.className()) { oldObject, newObject in
                        newObject!["eventCategoryType"] = ""
                        newObject!["displayLatitude"] = 0.0
                        newObject!["displayLongitude"] = 0.0
                    }
                    migration.deleteData(forType: CacheItem.className())
            }
                /* Adds status field to bridge alert item.
                 Clears cache times to force refresh
                 */
                if (oldSchemaVersion < 13) {
                    migration.enumerateObjects(ofType: BridgeAlertItem.className()) { oldObject, newObject in
                        newObject!["status"] = ""
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /* Adds title field to travel time item.
                 Clears travel time and cache data
                 */
                if (oldSchemaVersion < 14) {
                    migration.enumerateObjects(ofType: TravelTimeItem.className()) { oldObject, newObject in
                        newObject!["title"] = ""
                        newObject!["hovCurrentTime"] = 0
                    }
                    migration.deleteData(forType: TravelTimeItem.className())
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /* Adds delete field to travel time item.
                 Clears cache to force refresh
                 */
                if (oldSchemaVersion < 15) {
                    migration.enumerateObjects(ofType: TravelTimeItem.className()) { oldObject, newObject in
                        newObject!["delete"] = false
                    }
                    migration.deleteData(forType: CacheItem.className())
                }
                
                /* Adds vessel watch favorite location fields.
                 Clears cache to force refresh
                 */
                if (oldSchemaVersion < 16) {
                    migration.enumerateObjects(ofType: VesselWatchFavoriteLocationItem.className()) { oldObject, newObject in
                        newObject!["id"] = 0
                        newObject!["name"] = ""
                        newObject!["zoom"] = 0.0
                        newObject!["latitude"] = 0.0
                        newObject!["longitude"] = 0.0

                    }
                    migration.deleteData(forType: CacheItem.className())
                    migration.deleteData(forType: VesselWatchFavoriteLocationItem.className())

                    
                }
                
        })
    }
}
