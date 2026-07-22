//
//  MountainPassAlertsViewController.swift
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

import UIKit
import RealmSwift
import SafariServices
import Foundation


class MountainPassAlertsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, INDLinkLabelDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    let cellIdentifier = "PassAlerts"

    var passId = 0
    var passAlertItem =  [PassAlertItem]()

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        
        activityIndicator.startAnimating()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        refreshControl.addTarget(self, action: #selector(MountainPassReportViewController.refreshAction(_:)), for: .valueChanged)
        
        tableView.addSubview(refreshControl)
                
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MyAnalytics.screenView(screenName: "MountainPassAlerts")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // refresh controller
        refreshControl.addTarget(self, action: #selector(MountainPassAlertsViewController.refreshAction(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)

        self.tableView.reloadData()
        fetchAlerts()
        self.activityIndicator.isHidden = true
        
    }
    
    
    @objc func refreshAction(_ refreshControl: UIRefreshControl) {
        fetchAlerts()
    }
    
    func fetchAlerts() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async { [weak self] in
            MountainPassStore.updatePasses(true, completion: { error in
                if (error == nil) {

                    DispatchQueue.main.async { [weak self] in
                        if let selfValue = self {
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
                                                       
                            selfValue.passAlertItem = []
                            
                            if let passItem = MountainPassStore.findPass(withId: selfValue.passId) {
                                                                
                                selfValue.title = "\(passItem.name) Alerts"
                                
                                for item in passItem.passAlerts {
                                    selfValue.passAlertItem.append(item)
                                }
                            }
                            
                            selfValue.passAlertItem = selfValue.passAlertItem.sorted(by: {( dateFormatter.date(from: $0.createdDate) ?? NSDate() as Date ) > dateFormatter.date(from: $1.createdDate) ?? NSDate() as Date})
                            
                            if selfValue.passAlertItem.count == 0 {
                                selfValue.passAlertItem.removeAll()
                                selfValue.updateTableViewBackground()
                                selfValue.tableView.reloadData()
                            }
                            
                            else {
                                selfValue.tableView.reloadData()

                            }
                            
                            selfValue.activityIndicator.stopAnimating()
                            selfValue.activityIndicator.isHidden = true
                            selfValue.refreshControl.endRefreshing()
                            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: selfValue.tableView)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        if let selfValue = self{
                            selfValue.refreshControl.endRefreshing()
                            AlertMessages.getConnectionAlert(backupURL: WsdotURLS.passes)
                        }
                    }
                }
            })
        }
    }
    
    func updateTableViewBackground() {
        let messageLabel = UILabel(frame: tableView.bounds)
        messageLabel.text = "No Alerts Reported"
        messageLabel.textColor = .black
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        tableView.backgroundView = messageLabel
        tableView.separatorStyle = .none
    }
    
    
    // MARK: tableview
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passAlertItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! LinkCell
        
        let htmlStyleLight =
        "<style>*{font-family:'-apple-system';font-size:\(cell.linkLabel.font.pointSize)px;color:black}h1{font-weight:bold}a{color: #007a5d}a strong{color: #007a5d}li{margin:10px 0}li:last-child{margin-bottom:25px}</style>"
        
        let htmlStyleDark =
        "<style>*{font-family:'-apple-system';font-size:\(cell.linkLabel.font.pointSize)px;color:white}h1{font-weight:bold}a{color: #007a5d}a strong{color: #007a5d}li{margin:10px 0}li:last-child{margin-bottom:25px}</style>"
        
        let AlertDescription = "<h1>" + passAlertItem[indexPath.row].eventCategoryTypeDescription + "</h1>"
        let AlertFullText = passAlertItem[indexPath.row].headlineMessage.replacingOccurrences(of: "</a><br></li>\n<li>", with: "</a></li>\n<li>", options: .regularExpression, range: nil)
        let htmlStringLight = htmlStyleLight + AlertDescription + AlertFullText
        let htmlStringDark = htmlStyleDark + AlertDescription + AlertFullText

        let attrStrLight = try! NSMutableAttributedString(
            data: htmlStringLight.data(using: String.Encoding.unicode, allowLossyConversion: false)!,
            options: [ NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
        let attrStrDark = try! NSMutableAttributedString(
            data: htmlStringDark.data(using: String.Encoding.unicode, allowLossyConversion: false)!,
            options: [ NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
        var alertPubDate: Date? = nil
        
        
        if (self.passAlertItem.count > 0) {
            
            if let alertPubDateValue = try? TimeUtils.formatTimeStamp(passAlertItem[indexPath.row].createdDate, dateFormat: "yyyy-MM-dd hh:mm a") {
                alertPubDate = alertPubDateValue
            } else {
                alertPubDate = TimeUtils.parseJSONDateToNSDate(passAlertItem[indexPath.row].createdDate)
            }
        }

        if let date = alertPubDate {
            cell.updateTime.text = TimeUtils.timeAgoSinceDate(date: date, numericDates: false)
        } else {
            cell.updateTime.text = "unavailable"
        }
        
        if self.traitCollection.userInterfaceStyle == .light {
            cell.linkLabel.attributedText = attrStrLight
            cell.linkLabel.linkHighlightColor = UIColor.lightGray
            cell.linkLabel.delegate = self
        }
        
        if self.traitCollection.userInterfaceStyle == .dark {
            cell.linkLabel.attributedText = attrStrDark
            cell.linkLabel.linkHighlightColor = UIColor.lightGray
            cell.linkLabel.delegate = self
        }
        
        if self.passAlertItem.count != 0 {
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let passAlert = passAlertItem[indexPath.row]
        launchPassAlertDetailsScreen(alertId: passAlert.eventId, latitude: passAlert.displayLatitude, longitude: passAlert.displayLongitude)

                tableView.deselectRow(at: indexPath, animated: true)

    }

    func launchPassAlertDetailsScreen(alertId: Int, latitude: Double, longitude: Double){

        let passAlertsStoryboard: UIStoryboard = UIStoryboard(name: "MountainPasses", bundle: nil)

        // Set up nav and vc stack
        let passNav = passAlertsStoryboard.instantiateViewController(withIdentifier: "PassNav") as! UINavigationController
        
        let mountainPassesView = passAlertsStoryboard.instantiateViewController(withIdentifier: "MountainPassesViewController") as! MountainPassesViewController
        
        let mountainPassTabBarView = passAlertsStoryboard.instantiateViewController(withIdentifier: "MountainPassTabBarViewController") as! MountainPassTabBarViewController
        
        let mountainPassAlertsView = passAlertsStoryboard.instantiateViewController(withIdentifier: "MountainPassAlertsViewController") as! MountainPassAlertsViewController
        
        let mountainPassAlertView = passAlertsStoryboard.instantiateViewController(withIdentifier: "MountainPassAlertDetailViewController") as! MountainPassAlertDetailViewController

        mountainPassTabBarView.passId = passId
        mountainPassAlertsView.passId = passId
        mountainPassAlertView.alertId = alertId
        mountainPassAlertView.fromPush = true
                        
        // assign vc stack to new nav controller
        if UIDevice.current.userInterfaceIdiom == .pad {
            passNav.setViewControllers([mountainPassesView, mountainPassTabBarView, mountainPassAlertsView, mountainPassAlertView], animated: false)

        } else {
            passNav.setViewControllers([mountainPassAlertView], animated: false)

        }

        setNavController(newNavigationController: passNav)

    }

    func setNavController(newNavigationController: UINavigationController){
        // get the main split view, check how VCs are currently displayed

        let rootViewController = UIApplication.shared.windows.first!.rootViewController as! UISplitViewController
        if (rootViewController.isCollapsed) {
            // Only one vc displayed, pop current stack and assign new vc stack
            let nav = rootViewController.viewControllers[0] as! UINavigationController
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)

        fetchAlerts()
        
        }

    // MARK: INDLinkLabelDelegate
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

