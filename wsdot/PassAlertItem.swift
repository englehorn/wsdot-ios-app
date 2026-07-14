//
//  PassAlertItem.swift
//  WSDOT
//
//  Copyright (c) 2026 Washington State Department of Transportation
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

class PassAlertItem: Object {
    
    @objc dynamic var passId: Int = 0
    @objc dynamic var eventId: Int = 0
    @objc dynamic var travelCenterPriorityId: Int = 0
    @objc dynamic var eventCategoryTypeDescription: String = ""
    @objc dynamic var headlineMessage: String = ""
    @objc dynamic var roadName: String = ""
    @objc dynamic var roadDirection: String = ""
    @objc dynamic var direction: String = ""
    @objc dynamic var displayLatitude: Double = 0.0
    @objc dynamic var displayLongitude: Double = 0.0
    @objc dynamic var createdDate: String = ""
    @objc dynamic var delete = false

    override static func primaryKey() -> String? {
        return "eventId"
    }
}
