//
//  MyRouteAlertsViewController.swift
//  WSDOT
//
//  Copyright (c) 2019 Washington State Department of Transportation
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
import RealmSwift
import SafariServices

class MyRouteReportViewController: RefreshViewController {

    var alerts = [HighwayAlertItem]()
    var alertTypeAlerts = [HighwayAlertItem]()
    
    var route: MyRouteItem?
    
    let cellIdentifier = "AlertCell"
    
    let segueHighwayAlertViewController = "HighwayAlertViewController"
    
    let segueMyRouteAlertViewController = "MyRouteAlertsViewController"
    let segueMyRouteCamerasViewController = "MyRouteCamerasViewControllers"
    let segueMyRouteTravelTimesViewController = "MyRouteTravelTimesViewController"
    
    let refreshControl = UIRefreshControl()

    fileprivate var alertMarkers = Set<GMSMarker>()

    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var alertsContainerView: UIView!
    @IBOutlet weak var camerasContainerView: UIView!
    @IBOutlet weak var travelTimesContainerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    var alertsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showOverlay(self.view)
        
        // Prepare Google mapView
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        
        MapThemeUtils.setMapStyle(mapView, traitCollection)
       
        // Check for traffic layer setting
        let trafficLayerPref = UserDefaults.standard.string(forKey: UserDefaultsKeys.trafficLayer)
        if let trafficLayerVisible = trafficLayerPref {
            if (trafficLayerVisible == "on") {
                mapView.isTrafficEnabled = true
            } else {
                mapView.isTrafficEnabled = false
            }
        }
        
        alertsContainerView.isHidden = false
        camerasContainerView.isHidden = true
        travelTimesContainerView.isHidden = true
        
        _ = drawRouteOnMap(Array(route!.route))
    
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MyAnalytics.screenView(screenName: "MyRouteAlerts")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
            MapThemeUtils.setMapStyle(mapView, traitCollection)
    }
    
    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex) {
        
        case 0:
            alertsContainerView.isHidden = false
            camerasContainerView.isHidden = true
            travelTimesContainerView.isHidden = true
            break
        case 1:
            alertsContainerView.isHidden = true
            camerasContainerView.isHidden = true
            travelTimesContainerView.isHidden = false
            break
        case 2:
            alertsContainerView.isHidden = true
            camerasContainerView.isHidden = false
            travelTimesContainerView.isHidden = true
            break
        default:
            return
        }
    }
    
    @IBAction func settingsAction(_ sender: UIBarButtonItem) {
    
        MyAnalytics.event(category: "My Route", action: "UIAction", label: "Route Settings")
    
        let editController = (UIDevice.current.userInterfaceIdiom == .phone ?
              UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
            : UIAlertController(title: "Settings", message: nil, preferredStyle: .alert) )
        
        editController.view.tintColor = Colors.tintColor
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (result : UIAlertAction) -> Void in
            //action when pressed button
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (result : UIAlertAction) -> Void in
        
            MyAnalytics.event(category: "My Route", action: "UIAction", label: "Delete Route")
        
            let alertController = UIAlertController(title: "Delete route \(self.route!.name)?", message:"This cannot be undone", preferredStyle: .alert)

            alertController.view.tintColor = Colors.tintColor

            let confirmDeleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) -> Void in
            
                MyAnalytics.event(category: "My Route", action: "UIAction", label: "Delete Route Confirmed")
                
                _ = MyRouteStore.delete(route: self.route!)
                
                self.navigationController?.popViewController(animated: true)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            alertController.addAction(confirmDeleteAction)
            
            self.present(alertController, animated: false, completion: nil)
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { (result : UIAlertAction) -> Void in
        
            MyAnalytics.event(category: "My Route", action: "UIAction", label: "Rename Route")
        
            let alertController = UIAlertController(title: "Edit Name", message:nil, preferredStyle: .alert)
            alertController.addTextField { (textfield) in
                textfield.placeholder = self.route!.name
            }
            alertController.view.tintColor = Colors.tintColor

            let okAction = UIAlertAction(title: "Ok", style: .default) { (_) -> Void in
        
                let textf = alertController.textFields![0] as UITextField
                var name = textf.text!
                if name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
                    name = self.route!.name
                }
                
                _ = MyRouteStore.updateName(forRoute: self.route!, name)
                self.title = name
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: false, completion: nil)

        }
        
        editController.addAction(cancelAction)
        editController.addAction(deleteAction)
        editController.addAction(renameAction)
    
        self.present(editController, animated: true, completion: nil)
    
    }
    
    @objc func refreshAction(_ refreshController: UIRefreshControl){
        loadAlerts(force: true)
    }
    
    func loadAlerts(force: Bool){
        
        if route != nil {
            
            let serviceGroup = DispatchGroup();
            
            requestAlertsUpdate(force, serviceGroup: serviceGroup)
                
            serviceGroup.notify(queue: DispatchQueue.main) {
                
                self.alertTypeAlerts.removeAll()

                for alert in self.alerts{
                    self.alertTypeAlerts.append(alert)
                }
                                
                let startLocation = CLLocation(latitude: self.route?.route.first?.lat ?? 0, longitude: self.route?.route.first?.long ?? 0)

                self.alerts = self.alerts.sorted(by:{CLLocation(latitude: $0.startLatitude, longitude: $0.startLongitude).distance(from: startLocation) < CLLocation(latitude: $1.startLatitude, longitude: $1.startLongitude).distance(from: startLocation)})

                self.alertsTableView.rowHeight = UITableView.automaticDimension
                self.alertsTableView.reloadData()
                
                self.hideOverlayView()
                
                self.drawAlerts()
                self.refreshControl.endRefreshing()

                self.alertsContainerView.isHidden = false
                
                if self.alerts.count == 0 {
                    self.alertsTableView.isHidden = true

                } else {
                    self.alertsTableView.isHidden = false
                }
                
            }
        }
    }
    

    fileprivate func requestAlertsUpdate(_ force: Bool, serviceGroup: DispatchGroup) {
        serviceGroup.enter()
        
        let routeRef = ThreadSafeReference(to: self.route!)
        
            HighwayAlertsStore.updateAlerts(force, completion: { error in
                if (error == nil){
                
                    let routeItem = try! Realm().resolve(routeRef)
                    let nearbyAlerts = MyRouteStore.getNearbyAlerts(forRoute: routeItem!, withAlerts: HighwayAlertsStore.getAllAlerts())
                    
                    self.alerts.removeAll()
                    
                    // copy alerts to unmanaged Realm object so we can access on main thread.
                    for alert in nearbyAlerts {
                        let tempAlert = HighwayAlertItem()
                        tempAlert.alertId = alert.alertId
                        tempAlert.county = alert.county
                        tempAlert.delete = alert.delete
                        tempAlert.endLatitude = alert.endLatitude
                        tempAlert.endLongitude = alert.endLongitude
                        tempAlert.endTime = alert.endTime
                        tempAlert.eventCategoryTypeDescription = alert.eventCategoryTypeDescription
                        tempAlert.eventStatus = alert.eventStatus
                        tempAlert.extendedDesc = alert.extendedDesc
                        tempAlert.headlineDesc = alert.headlineDesc
                        tempAlert.lastUpdatedTime = alert.lastUpdatedTime
                        tempAlert.priority = alert.priority
                        tempAlert.travelCenterPriorityId = alert.travelCenterPriorityId
                        tempAlert.region = alert.region
                        tempAlert.startDirection = alert.startDirection
                        tempAlert.startLatitude = alert.startLatitude
                        tempAlert.startLongitude = alert.startLongitude
                        tempAlert.displayLatitude = alert.displayLatitude
                        tempAlert.displayLongitude = alert.displayLongitude
                        tempAlert.startTime = alert.startTime
                        self.alerts.append(tempAlert)
                    }

                    self.alerts = self.alerts.sorted(by: {$0.lastUpdatedTime.timeIntervalSince1970  > $1.lastUpdatedTime.timeIntervalSince1970})
                    
                    serviceGroup.leave()
                }else{
                    serviceGroup.leave()
                    DispatchQueue.main.async {
                        AlertMessages.getConnectionAlert(backupURL: nil)
                    }
                }
            })
    }

    // MARK: Naviagtion
    // Get refrence to child VC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueHighwayAlertViewController {
            
            if let alertItem = (sender as? HighwayAlertItem) {
                let destinationViewController = segue.destination as! HighwayAlertViewController
            
                destinationViewController.alertId = alertItem.alertId
            }
            
            if let marker = sender as? GMSMarker {
            
                if let alertId = marker.userData as? Int {
            
                    let destinationViewController = segue.destination as! HighwayAlertViewController
                    destinationViewController.alertId = alertId
                }
            }
        } else if segue.identifier == segueMyRouteAlertViewController {
            if let destinationViewController = segue.destination as? MyRouteAlertsViewController {
                destinationViewController.alertDataDelegate = self
            }
        } else if segue.identifier == segueMyRouteCamerasViewController {
            if let destinationViewController = segue.destination as? MyRouteCamerasViewController {
                destinationViewController.route = self.route
            }
        } else if segue.identifier == segueMyRouteTravelTimesViewController {
            if let destinationViewController = segue.destination as? MyRouteTravelTimesViewController {
                destinationViewController.route = self.route
            }
        }
    }
}

// Acts as a delegate for the MyRouteAlertViewController
// so we can share alerts betweenn the two VCs
extension MyRouteReportViewController: AlertTableDataDelegate {
    func alertTableReady(_ tableView: UITableView) {
        
        self.alertsTableView = tableView
        
        self.alertsTableView.delegate = self
        self.alertsTableView.dataSource = self
        
        // refresh controller
        self.refreshControl.addTarget(self, action: #selector(MyRouteReportViewController.refreshAction(_:)), for: .valueChanged)
        self.alertsTableView.addSubview(refreshControl)
        
        self.loadAlerts(force: true)
        
    }
}

extension MyRouteReportViewController: GMSMapViewDelegate {

    // MARK: GMSMapViewDelegate
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        // Check for overlapping markers.
        var markers = alertMarkers
        markers.remove(marker)
 
        performSegue(withIdentifier: segueHighwayAlertViewController, sender: marker)
       
        return true
    }

    func drawAlerts(){
    
        // clear any old markers
        for marker in alertMarkers {
            marker.map = nil
        }
        
        alertMarkers.removeAll()
    
        for alert in self.alerts {
    
            let alertLocation = CLLocationCoordinate2D(latitude: alert.displayLatitude, longitude: alert.displayLongitude)
            let marker = GMSMarker(position: alertLocation)
            marker.snippet = "alert"
        
            marker.icon = UIHelpers.getAlertIcon(forAlert: alert)
        
            marker.userData = alert.alertId
            marker.map = mapView
        
            alertMarkers.insert(marker)
        }
    
    }

    /**
     * Method name: displayRouteOnMap()
     * Description: sets mapView camera to show all of the newly recording route if there is data.
     * Parameters: locations: Array of CLLocations that make up the route.
     */
    func drawRouteOnMap(_ route: [MyRouteLocationItem]) -> Bool {
        
        var locations = [CLLocation]()
        
        for location in route {
            locations.append(CLLocation(latitude: location.lat, longitude: location.long))
        }
        
        if let region = MyRouteStore.getRouteMapRegion(locations: locations) {
            
            // set Map Bounds
            let bounds = GMSCoordinateBounds(coordinate: region.nearLeft,coordinate: region.farRight)
            let camera = mapView.camera(for: bounds, insets:UIEdgeInsets.zero)
            mapView.camera = camera!
            
            let myPath = GMSMutablePath()
            
            for location in locations {
                myPath.add(location.coordinate)
            }
            
            let MyRoute = GMSPolyline(path: myPath)
            
            MyRoute.spans = [GMSStyleSpan(color: UIColor(red: 0, green: 0.6588, blue: 0.9176, alpha: 1))] /* #00a8ea */
            MyRoute.strokeWidth = 2
            MyRoute.map = mapView
            mapView.animate(toZoom: (camera?.zoom)! - 0.0)
        
            return true
        } else {
            return false
        }
    }
}

// MARK: - TableView
extension MyRouteReportViewController:  UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alerts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! LinkCell
        
        var alert = HighwayAlertItem()
        alert = alerts[indexPath.row]
        
        let htmlStyleString = "<style>body{font-family: '-apple-system'; font-size:\(cell.linkLabel.font.pointSize)px;}</style>"
        var htmlString = ""
    
        cell.updateTime.text = TimeUtils.timeAgoSinceDate(date: alert.lastUpdatedTime, numericDates: false)
        htmlString = htmlStyleString + alert.headlineDesc
        
        let attrStr = try! NSMutableAttributedString(
            data: htmlString.data(using: String.Encoding.unicode, allowLossyConversion: false)!,
            options: [ NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
        cell.linkLabel.attributedText = attrStr
        cell.linkLabel.delegate = self
        
        if #available(iOS 13, *){
            cell.linkLabel.textColor = UIColor.label
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueHighwayAlertViewController, sender: alerts[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MyRouteReportViewController:  INDLinkLabelDelegate {
    func linkLabel(_ label: INDLinkLabel, didLongPressLinkWithURL URL: Foundation.URL) {
        let activityController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    func linkLabel(_ label: INDLinkLabel, didTapLinkWithURL URL: Foundation.URL) {
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let svc = SFSafariViewController(url: URL, configuration: config)
        
        if #available(iOS 10.0, *) {
            svc.preferredControlTintColor = ThemeManager.currentTheme().secondaryColor
            svc.preferredBarTintColor = ThemeManager.currentTheme().mainColor
        } else {
            svc.view.tintColor = ThemeManager.currentTheme().mainColor
        }
        self.present(svc, animated: true, completion: nil)
    }
}
