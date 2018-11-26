//
//  MyRouteAlertsViewController.swift
//  WSDOT
//
//  Copyright (c) 2017 Washington State Department of Transportation
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

class MyRouteAlertsViewController: UIViewController {

    var alerts = [HighwayAlertItem]()
    
    var trafficAlerts = [HighwayAlertItem]()
    var constructionAlerts = [HighwayAlertItem]()
    var specialEvents = [HighwayAlertItem]()
    
    var route: MyRouteItem?
    
    let cellIdentifier = "AlertCell"
    let segueHighwayAlertViewController = "HighwayAlertViewController"

    let refreshControl = UIRefreshControl()
    var activityIndicator = UIActivityIndicatorView()

    @IBOutlet weak var noAlertsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showOverlay(self.view)
        loadAlerts(force: true)
        
        // refresh controller
        refreshControl.addTarget(self, action: #selector(FavoritesHomeViewController.refreshAction(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        MyAnalytics.screenView(screenName: "My Route Alerts")
    }

    func refreshAction(_ refreshController: UIRefreshControl){
        loadAlerts(force: true)
    }

    @IBAction func checkAgainButtonPressed(_ sender: UIButton) {
        //noAlertsView.isHidden = true
        showOverlay(self.view)
        loadAlerts(force: true)
    }
    
    func loadAlerts(force: Bool){
        
        if route != nil {
            
            let serviceGroup = DispatchGroup();
            
            requestAlertsUpdate(force, serviceGroup: serviceGroup)
                
            serviceGroup.notify(queue: DispatchQueue.main) {
            
                if self.alerts.count == 0 {
                    self.noAlertsView.isHidden = false
                } else {
                    self.noAlertsView.isHidden = true
                }
                
                self.constructionAlerts.removeAll()
                self.specialEvents.removeAll()
                self.trafficAlerts.removeAll()
                
                for alert in self.alerts{
                    if alert.headlineDesc.lowercased().contains("construction") || alert.eventCategory.lowercased().contains("construction") {
                        self.constructionAlerts.append(alert)
                    }else if alert.eventCategory.lowercased() == "special event"{
                        self.specialEvents.append(alert)
                    }else {
                        self.trafficAlerts.append(alert)
                    }
                }
                
                self.trafficAlerts = self.trafficAlerts.sorted(by: {$0.lastUpdatedTime.timeIntervalSince1970  > $1.lastUpdatedTime.timeIntervalSince1970})
                self.constructionAlerts = self.constructionAlerts.sorted(by: {$0.lastUpdatedTime.timeIntervalSince1970  > $1.lastUpdatedTime.timeIntervalSince1970})
                self.specialEvents = self.specialEvents.sorted(by: {$0.lastUpdatedTime.timeIntervalSince1970  > $1.lastUpdatedTime.timeIntervalSince1970})

                self.tableView.rowHeight = UITableView.automaticDimension
            
                self.tableView.reloadData()
                self.hideOverlayView()
                self.refreshControl.endRefreshing()
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
                        tempAlert.eventCategory = alert.eventCategory
                        tempAlert.eventStatus = alert.eventStatus
                        tempAlert.extendedDesc = alert.extendedDesc
                        tempAlert.headlineDesc = alert.headlineDesc
                        tempAlert.lastUpdatedTime = alert.lastUpdatedTime
                        tempAlert.priority = alert.priority
                        tempAlert.region = alert.region
                        tempAlert.startDirection = alert.startDirection
                        tempAlert.startLatitude = alert.startLatitude
                        tempAlert.startLongitude = alert.startLongitude
                        tempAlert.startTime = alert.startTime
                        self.alerts.append(tempAlert)
                    }

                    self.alerts = self.alerts.sorted(by: {$0.lastUpdatedTime.timeIntervalSince1970  > $1.lastUpdatedTime.timeIntervalSince1970})
                    
                    serviceGroup.leave()
                }else{
                    serviceGroup.leave()
                    DispatchQueue.main.async { [weak self] in
                        if let selfValue = self{
                            selfValue.present(AlertMessages.getConnectionAlert(), animated: true, completion: nil)
                        }
                    }
                }
            })
        
    }

    /**
     * Method name: showOverlay
     * Description: creates an loading indicator in the center of the screen.
     * Parameters: view: The view to display the loading indicator on.
     */
    func showOverlay(_ view: UIView) {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.style = .whiteLarge
        activityIndicator.color = UIColor.gray
        activityIndicator.center = CGPoint(x: view.center.x, y: view.center.y - self.navigationController!.navigationBar.frame.size.height)
        
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    /**
     * Method name: hideOverlayView
     * Description: Removes the loading overlay created in showOverlay
     */
    func hideOverlayView(){
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }

    // MARK: Naviagtion
    // Get refrence to child VC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueHighwayAlertViewController {
            let alertItem = (sender as! HighwayAlertItem)
            let destinationViewController = segue.destination as! HighwayAlertViewController
            destinationViewController.alertItem = alertItem
        }
    }

}

// MARK: - TableView
extension MyRouteAlertsViewController:  UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch(section){
        case 0:
            return "Traffic Incidents" + (self.title != "Alert" && (trafficAlerts.count == 0) ? " - None Reported": "")
        case 1:
            return "Construction"  + (self.title != "Alert" && (constructionAlerts.count == 0) ? " - None Reported": "")
        case 2:
            return "Special Events"  + (self.title != "Alert" &&  (specialEvents.count == 0) ? " - None Reported": "")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch(section){
            
        case 0:
            return trafficAlerts.count
        case 1:
            return constructionAlerts.count
        case 2:
            return specialEvents.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! LinkCell
        

        var alert = HighwayAlertItem()
        
        switch indexPath.section {
            case 0:
            alert = trafficAlerts[indexPath.row]
            break
            case 1:
            alert = constructionAlerts[indexPath.row]
            break
            case 2:
            alert = specialEvents[indexPath.row]
            break
            default:
            break
        }
        
        let htmlStyleString = "<style>body{font-family: '\(cell.linkLabel.font.fontName)'; font-size:\(cell.linkLabel.font.pointSize)px;}</style>"
        var htmlString = ""
    
        cell.updateTime.text = TimeUtils.timeAgoSinceDate(date: alert.lastUpdatedTime, numericDates: false)
        htmlString = htmlStyleString + alert.headlineDesc
        
        let attrStr = try! NSMutableAttributedString(
            data: htmlString.data(using: String.Encoding.unicode, allowLossyConversion: false)!,
            options: [ NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
        cell.linkLabel.attributedText = attrStr
        cell.linkLabel.delegate = self
        
        switch (alert.priority){
            
        case "highest":
            cell.backgroundColor = UIColor(red: 255/255, green: 232/255, blue: 232/255, alpha: 1.0) /* #ffe8e8 */
            break
        case "high":
            cell.backgroundColor = UIColor(red: 255/255, green: 244/255, blue: 232/255, alpha: 1.0) /* #fff4e8 */
            break
        default:
            cell.backgroundColor = UIColor(red: 255/255, green: 254/255, blue: 232/255, alpha: 1.0) /* #fffee8 */
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueHighwayAlertViewController, sender: alerts[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MyRouteAlertsViewController:  INDLinkLabelDelegate {
    func linkLabel(_ label: INDLinkLabel, didLongPressLinkWithURL URL: Foundation.URL) {
        let activityController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    func linkLabel(_ label: INDLinkLabel, didTapLinkWithURL URL: Foundation.URL) {
        let svc = SFSafariViewController(url: URL, entersReaderIfAvailable: true)
        if #available(iOS 10.0, *) {
            svc.preferredControlTintColor = ThemeManager.currentTheme().secondaryColor
            svc.preferredBarTintColor = ThemeManager.currentTheme().mainColor
        } else {
            svc.view.tintColor = ThemeManager.currentTheme().mainColor
        }
        self.present(svc, animated: true, completion: nil)
    }
}
