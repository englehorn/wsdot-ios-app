//
//  BestTimesToTravelStore.swift
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

import Alamofire
import SwiftyJSON
import Foundation

class BestTimesToTravelStore: Decodable {

    typealias FetchBestTimesToTravelAvailablityCompletion = (_ data: Bool, _ error: Error?) -> ()
    typealias FetchBestTimesToTravelCompletion = (_ data: BestTimesToTravelItem?, _ error: Error?) -> ()
   
    static var session: Session?
   
    static func isBestTimesToTravelAvailable(_ completion: @escaping FetchBestTimesToTravelAvailablityCompletion) {

        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = Session(configuration: configuration)

        session!.request("https://data.wsdot.wa.gov/mobile/travelCharts.json").validate().responseDecodable(of: BestTimesToTravelStore.self) { response in
            switch response.result {
            case .success:
                if let value = response.data {
                    let json = JSON(value)
                    completion(json["available"].boolValue, nil)
                }
            case .failure(let error):
                print(error)
                completion(false, error)
            }
        }
    }
    
    static func getBestTimesToTravel(_ completion: @escaping FetchBestTimesToTravelCompletion) {
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = Session(configuration: configuration)

        session!.request("https://data.wsdot.wa.gov/mobile/travelCharts.json").validate().responseDecodable(of: BestTimesToTravelStore.self) { response in
            switch response.result {
            case .success:
                if let value = response.data {
                    let json = JSON(value)
                    let bestTimes = parseBestTimesJSON(json)
                    completion(bestTimes, nil)
                }
            case .failure(let error):
                print(error)
                completion(nil, error)
            }
        }
    }
    
    fileprivate static func parseBestTimesJSON(_ json: JSON) -> BestTimesToTravelItem{

        var routes = [BestTimesToTravelRouteItem]()
        
        for (_,route):(String, JSON) in json["routes"] {
            
            var charts = [TravelChartItem]()
            
            for (_,chart):(String, JSON) in route["charts"] {
                let travelChartItem = TravelChartItem(url: chart["url"].stringValue, altText: chart["altText"].stringValue)
                charts.append(travelChartItem)
            }
            
            let routeItem = BestTimesToTravelRouteItem(name: route["name"].stringValue, charts: charts)
            routes.append(routeItem)
            
        }
        
        return BestTimesToTravelItem(available: json["available"].boolValue, name: json["name"].stringValue, routes: routes)
    }
    
}
