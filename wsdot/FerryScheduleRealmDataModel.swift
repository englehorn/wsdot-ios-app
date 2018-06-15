//
//  FerriesRealmModels.swift
//  WSDOT
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

import Foundation
import RealmSwift

class FerryScheduleItem: Object {
    @objc dynamic var routeId = 0
    @objc dynamic var routeDescription = ""
    @objc dynamic var selected = false
    @objc dynamic var crossingTime: String? = nil
    @objc dynamic var cacheDate = Date(timeIntervalSince1970: 0)
    let routeAlerts = List<FerryAlertItem>()
    let scheduleDates = List<FerryScheduleDateItem>()
    let terminalPairs = List<FerryTerminalPairItem>()
    
    @objc dynamic var delete = false
    
    override static func primaryKey() -> String? {
        return "routeId"
    }
}

class FerryAlertItem: Object {
    @objc dynamic var bulletinId = 0
    @objc dynamic var publishDate = ""
    @objc dynamic var alertDescription = ""
    @objc dynamic var alertFullTitle = ""
    @objc dynamic var alertFullText = ""
}

class FerryTerminalPairItem: Object {
    @objc dynamic var aTerminalId = 0
    @objc dynamic var aTerminalName = ""
    @objc dynamic var bTerminalId = 0
    @objc dynamic var bTterminalName = ""
}

class FerryScheduleDateItem: Object {
    @objc dynamic var date = Date(timeIntervalSince1970: 0)
    let sailings = List<FerrySailingsItem>()
}

class FerrySailingsItem: Object {
    @objc dynamic var departingTerminalId = -1
    @objc dynamic var departingTerminalName = ""
    @objc dynamic var arrivingTerminalId = -1
    @objc dynamic var arrivingTerminalName = ""
    let annotations = List<Annotation>()
    let times = List<FerryDepartureTimeItem>()
}

class FerryDepartureTimeItem: Object {
    @objc dynamic var departingTime = Date(timeIntervalSince1970: 0)
    @objc dynamic var  arrivingTime: Date? = nil
    let annotationIndexes = List<AnnotationIndex>()

}

class AnnotationIndex: Object {
    @objc dynamic var index = -1
}

class Annotation: Object{
    @objc dynamic var message = ""
}

