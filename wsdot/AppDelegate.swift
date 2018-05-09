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
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        let eventTheme = Theme(rawValue: EventStore.getActiveEventThemeId()) ?? .defaultTheme
        ThemeManager.applyTheme(theme: eventTheme)

        migrateRealm()
        CachesStore.initCacheItem()
        
        GMSServices.provideAPIKey(ApiKeys.getGoogleAPIKey())
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: ApiKeys.getAdId());
        
        // EasyTipView Setup
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = UIColor(hue:0.46, saturation:0.99, brightness:0.6, alpha:1)
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top

        // Make these preferences global for all future EasyTipViews
        EasyTipView.globalPreferences = preferences
        
        if (GoogleAnalytics.analytics_enabled){
            
            // Optional: configure GAI options.
            if let gai = GAI.sharedInstance() {
            
                gai.tracker(withTrackingId: ApiKeys.getGoogleAnalyticsID())
            
                if (GoogleAnalytics.analytics_dryrun){
                    gai.dryRun = GoogleAnalytics.analytics_dryrun
                    gai.logger.logLevel = GAILogLevel.verbose
                }
                
                gai.trackUncaughtExceptions = true  // report uncaught exceptions
            }
        }
        // Reset Warning each time app starts
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasSeenWarning)
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
        }
        
        return true
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        FerryRealmStore.flushOldData()
        CamerasStore.flushOldData()
        TravelTimesStore.flushOldData()
        HighwayAlertsStore.flushOldData()
        NotificationsStore.flushOldData()
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        FerryRealmStore.flushOldData()
        CamerasStore.flushOldData()
        TravelTimesStore.flushOldData()
        HighwayAlertsStore.flushOldData()
        NotificationsStore.flushOldData()
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print message ID.
      //  if let messageID = userInfo[gcmMessageIDKey] {
      //      print("Message ID: \(messageID)")
      //  }

        // Print full message.
      //  print(userInfo)
        print("didReceiveRemoteNotification.")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print message ID.
        // if let messageID = userInfo[gcmMessageIDKey] {
        //   print("Message ID: \(messageID)")
        //}
        
        // Print full message.
        print("didReceiveRemoteNotification w/ completionHandler.")

        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Update the app interface directly.
        print("catch local notification")
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        

        // Display the notificaion.
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    func migrateRealm(){
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 4,
            
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
            
        })
    }
}
