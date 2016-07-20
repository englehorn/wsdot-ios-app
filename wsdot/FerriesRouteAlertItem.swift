//
//  FerriesRouteAlertItem.swift
//  WSDOT
//
//  Created by Logan Sims on 6/29/16.
//  Copyright © 2016 wsdot. All rights reserved.
//
import Foundation
 
class FerriesRouteAlertItem: NSObject {
 
    var uuid: String = NSUUID().UUIDString
    var bulletinId: Int = 0
    var publishDate: String = ""
    var alertDescription: String = ""
    var alertFullTitle: String = ""
    var alertFullText: String = ""
 
 
    init(id: Int, date: String, desc: String, title: String, text: String) {
        super.init()
        self.bulletinId = id
        self.publishDate = date
        self.alertDescription = desc
        self.alertFullTitle = title
        self.alertFullText = text
    }
}