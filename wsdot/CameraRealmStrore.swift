//  CamerasStore.swift
//  WSDOT
//
//  Created by Logan Sims on 7/28/16.
//  Copyright © 2016 wsdot. All rights reserved.
//
import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift

class CamerasStore {
    
    typealias UpdateCamerasCompletion = (error: NSError?) -> ()
    
    static func getAllCameras() -> [CameraItem]{
        let realm = try! Realm()
        let cameraItems = realm.objects(CameraItem.self)
        return Array(cameraItems)
    }
    
    static func getFavoriteCameras() -> [CameraItem]{
        let realm = try! Realm()
        let cameraItems = realm.objects(CameraItem.self).filter("selected == true")
        return Array(cameraItems)
    }
    
    static func getCamerasByRoadName(roadName : String) -> [CameraItem]{
        let realm = try! Realm()
        let cameraItems = realm.objects(CameraItem.self).filter("roadName == \"\(roadName)\"")
        return Array(cameraItems)
    }
    
    static func updateFavorite(camera: CameraItem, newValue: Bool){
        let realm = try! Realm()
        try! realm.write{
            camera.selected = newValue
        }
    }
    
    static func updateCameras(force: Bool, completion: UpdateCamerasCompletion) {
        
        let deltaUpdated = NSCalendar.currentCalendar().components(.Second, fromDate: CachesStore.getUpdatedTime(CachedData.Cameras), toDate: NSDate(), options: []).second
        
        if ((deltaUpdated > TimeUtils.updateTime) || force){
            
            Alamofire.request(.GET, "http://data.wsdot.wa.gov/mobile/Cameras.js").validate().responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        let cameras = self.parseCamerasJSON(json)
                        self.saveCameras(cameras)
                        CachesStore.updateTime(CachedData.Cameras, updated: NSDate())
                        completion(error: nil)
                    }
                case .Failure(let error):
                    print(error)
                    completion(error: error)
                }
            }
        }else{
            completion(error: nil)
        }
        
    }
    
    // TODO: Make this smarter
    private static func saveCameras(cameras: [CameraItem]){
        
        let realm = try! Realm()
        
        let oldFavoriteCameras = self.getFavoriteCameras()
        let newCameras = List<CameraItem>()
        
        for camera in cameras {
            for oldCameras in oldFavoriteCameras {
                if (oldCameras.cameraId == camera.cameraId){
                    camera.selected = true
                }
            }
            newCameras.append(camera)
        }
        
        deleteAll()
        
        for newCamera in newCameras{
            try! realm.write{
                realm.add(newCamera)
            }
        }
    }

    private static func deleteAll(){
        let realm = try! Realm()
        try! realm.write{
            realm.delete(realm.objects(CameraItem))
        }
    }
    
    private static func parseCamerasJSON(json: JSON) ->[CameraItem]{
        var cameras = [CameraItem]()
        for (_,cameraJson):(String, JSON) in json["cameras"]["items"] {
            let camera = CameraItem()
            camera.cameraId = cameraJson["id"].intValue
            camera.url = cameraJson["url"].stringValue
            camera.title = cameraJson["title"].stringValue
            camera.roadName = cameraJson["roadName"].stringValue
            camera.latitude = cameraJson["lat"].doubleValue
            camera.longitude = cameraJson["lon"].doubleValue
            camera.video = cameraJson["video"].boolValue
            cameras.append(camera)
        }
        return cameras
    }
}
