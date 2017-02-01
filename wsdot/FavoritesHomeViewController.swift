//
//  FavroitesHomeViewController.swift
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

class FavoritesHomeViewController: UIViewController {
    
    let refreshControl = UIRefreshControl()
    var activityIndicator = UIActivityIndicatorView()
    var loadingRouteAlert = UIAlertController()

    // content types for the favorites list in order to appear on list.
    var sectionTypes: [FavoritesContent] = [.route, .ferrySchedule, .mountainPass, .camera, .travelTime]

    let segueNewRouteViewController = "NewRouteViewController"
    let segueMyRouteAlertsViewController = "MyRouteAlertsViewController"
    let segueFavoritesSettingsViewController = "FavoritesSettingsViewController"
    let segueTrafficMapViewController = "TrafficMapViewController"
    let segueRouteDeparturesViewController = "SailingsViewController"
    let segueCameraViewController = "CameraViewController"
    let segueTravelTimeViewController = "TravelTimeViewController"
    let segueMountainPassDetailsViewController = "MountianPassDetailsViewController"

    let textCellIdentifier = "TextCell"
    let myRouteCellIdentifier = "MyRouteCell"
    let travelTimesCellIdentifier = "TravelTimeCell"
    let ferryScheduleCellIdentifier = "FerryScheduleCell"
    let mountainPassCellIdentifier = "MountainPassCell"

    var cameras = [CameraItem]()
    var travelTimes = [TravelTimeItem]()
    var ferrySchedules = [FerryScheduleItem]()
    var mountainPasses = [MountainPassItem]()
    var savedLocations = [FavoriteLocationItem]()

    var myRoute: MyRouteItem? = nil

    @IBOutlet weak var emptyFavoritesView: UIView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // refresh controller
        refreshControl.addTarget(self, action: #selector(FavoritesHomeViewController.refreshAction(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sectionTypes = buildSectionTypeArray()
        
        initContent()
    }

    @IBAction func favoritesSettingButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: segueFavoritesSettingsViewController, sender: self)
    }
    
    @IBAction func createNewRouteButtonPressed(_ sender: UIBarButtonItem) {
    
        if MyRouteStore.getRoutes().count == 3 {
            self.present(AlertMessages.getAlert("Max Number of Routes Saved", message: "Please delete a saved route before making a new one", confirm: "OK"), animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: segueNewRouteViewController, sender: self)
        }
    }
    
    /**
     * Method name: getType
     * Description: returns the  FavoritesContent type of data help in the section.
     * Parameters: forSection: Section from above.
     */
    func getType(forSection: Int) -> FavoritesContent {
        return sectionTypes[forSection]
    }
    
    /**
     * Method name: getNumverOfRows
     * Description: using getType(), returns the size of the list corresponding to the sections data.
     * Parameters: inSection: Section from above.
     */
    func getNumberOfRows(inSection: Int) -> Int {
        switch (getType(forSection: inSection)){
        
        case .camera:
            return cameras.count
        case .travelTime:
            return travelTimes.count
        case .route:
            if MyRouteStore.getSavedRoute() != nil {
                return 1
            } else {
                return 0
            }
        case .ferrySchedule:
            return ferrySchedules.count
        case .mountainPass:
            return mountainPasses.count
        case .mapLocation:
            return savedLocations.count
        }
    }
    
    func getNumberOfSections() -> Int {
        return sectionTypes.count
    }
    
    /**
     * Method name: getTitle
     * Description: Returns a title for a section in the favorites list. 
     *              Required since sections can be changed. Uses sectionToTypeMap/
     * Parameters: forSection: The section to get a title for.
     */
    func getTitle(forSection: Int) -> String {
    
        switch (sectionTypes[forSection] ) {
        case .route:
            return myRoute == nil ? "" : MyRouteStore.sectionTitles[FavoritesContent.route.rawValue]
        case .camera:
            return cameras.count > 0 ? MyRouteStore.sectionTitles[FavoritesContent.camera.rawValue] : ""
        case .travelTime:
            return travelTimes.count > 0 ? MyRouteStore.sectionTitles[FavoritesContent.travelTime.rawValue] : ""
        case .ferrySchedule:
            return ferrySchedules.count > 0 ? MyRouteStore.sectionTitles[FavoritesContent.ferrySchedule.rawValue] : ""
        case .mountainPass:
            return mountainPasses.count > 0 ? MyRouteStore.sectionTitles[FavoritesContent.mountainPass.rawValue] : ""
        case .mapLocation:
            return savedLocations.count > 0 ? MyRouteStore.sectionTitles[FavoritesContent.mapLocation.rawValue] : ""
        }
    }
    
    /**
     * Method name: buildSectionArray
     * Description: checks UserDefaults to see if we have already set the title array up.
     *              Stored in userDefaults is an array of section titles that correspoind to
     *              the types of content in the favorites lists.
     */
    func buildSectionTypeArray() -> [FavoritesContent] {
    
        var sectionTypesOrderRawArray = UserDefaults.standard.array(forKey: UserDefaultsKeys.favoritesOrder) as? [Int] ?? [Int]()
        
        // init section
        if sectionTypesOrderRawArray.count == 0 {
            sectionTypesOrderRawArray.append(FavoritesContent.route.rawValue)
            sectionTypesOrderRawArray.append(FavoritesContent.ferrySchedule.rawValue)
            sectionTypesOrderRawArray.append(FavoritesContent.mountainPass.rawValue)
            sectionTypesOrderRawArray.append(FavoritesContent.mapLocation.rawValue)
            sectionTypesOrderRawArray.append(FavoritesContent.camera.rawValue)
            sectionTypesOrderRawArray.append(FavoritesContent.travelTime.rawValue)
            UserDefaults.standard.set(sectionTypesOrderRawArray, forKey: UserDefaultsKeys.favoritesOrder)
        }
        
        var sections = [FavoritesContent]()
        
        for sectionTypeRawValue in sectionTypesOrderRawArray {
            sections.append(FavoritesContent(rawValue: sectionTypeRawValue)!)
        }
        
        return sections
    }
    
    /**
     * Method name: checkAlerts
     * Description: action func for check alerts button on a route cell
     */
    func checkAlerts(sender: UIButton){
        performSegue(withIdentifier: segueMyRouteAlertsViewController, sender: self)
    }
}

extension FavoritesHomeViewController: INDLinkLabelDelegate {}

// MARK: - Data
extension FavoritesHomeViewController {

    /**
     * Method name: initContent()
     * Description: Starts loading favorites content, first by using users route to populate favorites if it hasen't already.
     */
    func initContent(){
    
        // pick which overlay to display
        myRoute = MyRouteStore.getSavedRoute()
        
        if let route = myRoute {
            if !route.hasFoundNearbyItems {
                showRouteOverlay()
            } else {
                showOverlay(self.view)
            }
        } else {
            showOverlay(self.view)
        }
        
        // Check if we have any favorites to show already.
        cameras = CamerasStore.getFavoriteCameras()
        travelTimes = TravelTimesStore.findFavoriteTimes()
        ferrySchedules = FerryRealmStore.findFavoriteSchedules()
        mountainPasses = MountainPassStore.findFavoritePasses()
        savedLocations = FavoriteLocationStore.getFavorites()
    
        if (tableEmpty()){
            emptyFavoritesView.isHidden = false
        }else {
            emptyFavoritesView.isHidden = true
        }
    
        if myRoute != nil {
        
            // First time loading this route, retrieve nearby items
            if !myRoute!.hasFoundNearbyItems {
                
                let serviceGroup = DispatchGroup();
                
                requestFerriesUpdate(true, serviceGroup: serviceGroup)
                requestCamerasUpdate(true, serviceGroup: serviceGroup)
                requestTravelTimesUpdate(true, serviceGroup: serviceGroup)
                requestMountainPassesUpdate(true, serviceGroup: serviceGroup)
                
                serviceGroup.notify(queue: DispatchQueue.main) {
                    
                    _ = MyRouteStore.selectNearbyCameras(forRoute: self.myRoute!)
                    _ = MyRouteStore.selectNearbyTravelTimes(forRoute: self.myRoute!)
                    _ = MyRouteStore.selectNearbyFerries(forRoute: self.myRoute!)
                    _ = MyRouteStore.selectNearbyPasses(forRoute: self.myRoute!)
                    
                    _ = MyRouteStore.turnOffFindNearby(route: self.myRoute!)
                    
                    // dismiss the routeLoadingOverlay
                    self.loadingRouteAlert.dismiss(animated: true, completion: nil)
                    
                    self.loadSelectedContent(false)
                }
            } else {
                loadSelectedContent(false)
            }
        } else {
            loadSelectedContent(false)
        }
    }

    /**
     * Method name: loadSelectedContent
     * Description: collects data from Stores to build favorites list. Uses a serviceGroup to collect data async.
     * Parameters: force: setting true will force Stores to update their data.
     */
    fileprivate func loadSelectedContent(_ force: Bool){

        let serviceGroup = DispatchGroup();
        
        if (self.ferrySchedules.count > 0){
            self.requestFerriesUpdate(force, serviceGroup: serviceGroup)
        }
        if (self.cameras.count > 0){
            self.requestCamerasUpdate(force, serviceGroup: serviceGroup)
        }
        if (self.travelTimes.count > 0) {
            self.requestTravelTimesUpdate(force, serviceGroup: serviceGroup)
        }
        if (self.mountainPasses.count > 0){
            self.requestMountainPassesUpdate(force, serviceGroup: serviceGroup)
        }
 
        serviceGroup.notify(queue: DispatchQueue.main) {
            self.cameras = CamerasStore.getFavoriteCameras()
            self.travelTimes = TravelTimesStore.findFavoriteTimes()
            self.ferrySchedules = FerryRealmStore.findFavoriteSchedules()
            self.mountainPasses = MountainPassStore.findFavoritePasses()
            self.savedLocations = FavoriteLocationStore.getFavorites()
            
            if (self.tableEmpty()){
                self.emptyFavoritesView.isHidden = false
            }else {
                self.emptyFavoritesView.isHidden = true
            }
          
            self.tableView.reloadData()
            self.hideOverlayView()
            self.refreshControl.endRefreshing()
        }
    }

    /**
     * Method name: showOverlay
     * Description: creates an loading indicator in the center of the screen.
     * Parameters: view: The view to display the loading indicator on.
     */
    func showOverlay(_ view: UIView) {
    
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
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

    func showRouteOverlay(){
        loadingRouteAlert = UIAlertController(title: nil, message: "Finding Favorites...", preferredStyle: .alert)
        loadingRouteAlert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame:CGRect(x:10, y:5, width:50, height:50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        loadingRouteAlert.view.addSubview(loadingIndicator)
        self.present(loadingRouteAlert, animated: true, completion: nil)
    }

    func refreshAction(_ refreshController: UIRefreshControl){
        loadSelectedContent(true)
    }

    /**
     * Method name: tableEmpty
     * Description: Returns true if the favorites table is empty
     */
    func tableEmpty() -> Bool {
        return
            (self.cameras.count == 0) &&
            (self.travelTimes.count == 0) &&
            (self.ferrySchedules.count == 0) &&
            (self.mountainPasses.count == 0) &&
            (self.savedLocations.count == 0) &&
            (self.myRoute == nil)
    }

    fileprivate func requestCamerasUpdate(_ force: Bool, serviceGroup: DispatchGroup) {
        serviceGroup.enter()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {[weak self] in
            CamerasStore.updateCameras(force, completion: { error in
                if (error == nil){
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
    }
    
    fileprivate func requestTravelTimesUpdate(_ force: Bool, serviceGroup: DispatchGroup){
        serviceGroup.enter()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { [weak self] in
            TravelTimesStore.updateTravelTimes(force, completion: { error in
                if (error == nil) {
                    serviceGroup.leave()
                } else {
                    serviceGroup.leave()
                    DispatchQueue.main.async { [weak self] in
                        if let selfValue = self{
                            selfValue.present(AlertMessages.getConnectionAlert(), animated: true, completion: nil)
                        }
                    }
                }
            })
        }
    }
    
    fileprivate func requestFerriesUpdate(_ force: Bool, serviceGroup: DispatchGroup){
        serviceGroup.enter()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { [weak self] in
            FerryRealmStore.updateRouteSchedules(force, completion: { error in
                if (error == nil) {
                    serviceGroup.leave()
                } else {
                    serviceGroup.leave()
                    DispatchQueue.main.async { [weak self] in
                        if let selfValue = self{
                            selfValue.present(AlertMessages.getConnectionAlert(), animated: true, completion: nil)
                        }
                    }
                }
            })
        }
    }
    
    fileprivate func requestMountainPassesUpdate(_ force: Bool, serviceGroup: DispatchGroup){
        serviceGroup.enter()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {[weak self] in
            MountainPassStore.updatePasses(force, completion: { error in
                if (error == nil){
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
    }
}

// MARK: - TableView
extension FavoritesHomeViewController:  UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return getNumberOfSections()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getTitle(forSection: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNumberOfRows(inSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch getType(forSection: indexPath.section) {
        case .camera:
        
            let cameraCell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath)

            let camera = cameras[indexPath.row]
            
            cameraCell.textLabel?.text = camera.title
            return cameraCell
        
        case .mapLocation:
            
            let locationCell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath)
            locationCell.textLabel?.text = savedLocations[indexPath.row].name
            return locationCell
            
        case .travelTime:
        
            let travelTimeCell = tableView.dequeueReusableCell(withIdentifier: travelTimesCellIdentifier) as! TravelTimeCell
            
            let travelTime = travelTimes[indexPath.row]
            
            travelTimeCell.routeLabel.text = travelTime.title
            
            travelTimeCell.subtitleLabel.text = String(travelTime.distance) + " miles / " + String(travelTime.averageTime) + " min"

            do {
                let updated = try TimeUtils.timeAgoSinceDate(date: TimeUtils.formatTimeStamp(travelTime.updated), numericDates: false)
                travelTimeCell.updatedLabel.text = updated
            } catch TimeUtils.TimeUtilsError.invalidTimeString {
                travelTimeCell.updatedLabel.text = "N/A"
            } catch {
                travelTimeCell.updatedLabel.text = "N/A"
            }
            
            travelTimeCell.currentTimeLabel.text = String(travelTime.currentTime) + " min"
            
            if (travelTime.averageTime > travelTime.currentTime){
                travelTimeCell.currentTimeLabel.textColor = Colors.tintColor
            } else if (travelTime.averageTime < travelTime.currentTime){
                travelTimeCell.currentTimeLabel.textColor = UIColor.red
            } else {
                travelTimeCell.currentTimeLabel.textColor = UIColor.darkText
            }
            
            travelTimeCell.sizeToFit()
            
            return travelTimeCell
        
        case .ferrySchedule:
        
            let ferryCell = tableView.dequeueReusableCell(withIdentifier: ferryScheduleCellIdentifier, for: indexPath) as! RoutesCustomCell
            
            let ferryScheduleItem = ferrySchedules[indexPath.row]
            
            ferryCell.title.text = ferryScheduleItem.routeDescription
            
            if ferryScheduleItem.crossingTime != nil {
                ferryCell.subTitleOne.isHidden = false
                ferryCell.subTitleOne.text = "Crossing time: ~ " + ferryScheduleItem.crossingTime! + " min"
            } else {
                ferryCell.subTitleOne.isHidden = true
            }
            
            ferryCell.subTitleTwo.text = TimeUtils.timeAgoSinceDate(date: ferryScheduleItem.cacheDate, numericDates: true)
            
            return ferryCell
            
        case .mountainPass:
        
            let passCell = tableView.dequeueReusableCell(withIdentifier: mountainPassCellIdentifier) as! MountainPassCell
            
            let passItem = mountainPasses[indexPath.row]
            
            passCell.nameLabel.text = passItem.name
            
            if (passItem.forecast.count > 0){
                passCell.forecastLabel.text = WeatherUtils.getForecastBriefDescription(passItem.forecast[0].forecastText)
                passCell.weatherImage.image = UIImage(named: WeatherUtils.getIconName(passItem.forecast[0].forecastText, title: passItem.forecast[0].day))
            } else {
                passCell.forecastLabel.text = ""
                passCell.weatherImage.image = nil
            }
            
            passCell.updatedLabel.text = TimeUtils.timeAgoSinceDate(date: passItem.dateUpdated, numericDates: false)
            
            return passCell
            
        case .route:
        
            let routeCell = tableView.dequeueReusableCell(withIdentifier: myRouteCellIdentifier, for: indexPath) as! MyRouteCell
            
            routeCell.checkAlertsButton.tag = indexPath.row
            routeCell.checkAlertsButton.addTarget(self, action:#selector(FavoritesHomeViewController.checkAlerts), for: .touchUpInside)
            routeCell.checkAlertsButton.layer.cornerRadius = 3
            
            routeCell.textLabel?.text = myRoute!.name
            return routeCell
        
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /**
     * Set up custom edit actions.
     *    Delete: removes the item from favorites. If trying to delete a route, will ask for comfirmation.
     *    Rename: lets user change the name of the item. Only avaiable for a route.
     */
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let updateAction = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            
            tableView.reloadRows(at: [indexPath], with: .right)
            
            let alertController = UIAlertController(title: "New Name", message:nil, preferredStyle: .alert)
            alertController.addTextField { (textfield) in
                textfield.placeholder = "My Route"
            }
            alertController.view.tintColor = Colors.tintColor

            let okAction = UIAlertAction(title: "Ok", style: .default) { (_) -> Void in
        
                let textf = alertController.textFields![0] as UITextField
                var name = textf.text!
                if name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
                    name = "My Route"
                }
                _ = MyRouteStore.updateName(forRoute: MyRouteStore.getSavedRoute()!, name)
                self.tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: false, completion: nil)
            
        }
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Remove" , handler: { (action:UITableViewRowAction, indexPath:IndexPath) -> Void in
        
            // Delete the row from the data source
            switch self.getType(forSection: indexPath.section) {
            case .mapLocation:
                FavoriteLocationStore.deleteFavorite(self.savedLocations[indexPath.row])
                self.savedLocations.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                break
            case .camera:
                CamerasStore.updateFavorite(self.cameras[indexPath.row], newValue: false)
                self.cameras.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                break
            case .travelTime:
                TravelTimesStore.updateFavorite(self.travelTimes[indexPath.row], newValue: false)
                self.travelTimes.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                break
            case .ferrySchedule:
                FerryRealmStore.updateFavorite(self.ferrySchedules[indexPath.row], newValue: false)
                self.ferrySchedules.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                break
            case .mountainPass:
                MountainPassStore.updateFavorite(self.mountainPasses[indexPath.row], newValue: false)
                self.mountainPasses.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            case .route:
                let alertController = UIAlertController(title: "Are you sure you want to delete this route?", message:"This cannot be undone.", preferredStyle: .alert)

                alertController.view.tintColor = Colors.tintColor

                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) -> Void in
                    tableView.reloadData()
                
                    _ = MyRouteStore.delete(route: self.myRoute!)
                    self.myRoute = nil
                    
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    if (self.tableEmpty()){
                        self.emptyFavoritesView.isHidden = false
                    }else {
                        self.emptyFavoritesView.isHidden = true
                    }
                }
            
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
                    tableView.reloadRows(at: [indexPath], with: .right)
                }
            
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
            
                self.present(alertController, animated: false, completion: nil)
                
                break
            }
        })
        if getType(forSection: indexPath.section) == .route {
            return [deleteAction, updateAction]
        } else {
            return [deleteAction]
        }
    }
 
 // MARK: - Navigation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (getType(forSection: indexPath.section)){
        case .mapLocation:
            performSegue(withIdentifier: segueTrafficMapViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        case .camera:
            performSegue(withIdentifier: segueCameraViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            break
        case .route:
            performSegue(withIdentifier: segueTrafficMapViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            break
        case .travelTime:
            performSegue(withIdentifier: segueTravelTimeViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            break
        case .ferrySchedule:
            performSegue(withIdentifier: segueRouteDeparturesViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        case .mountainPass:
            performSegue(withIdentifier: segueMountainPassDetailsViewController, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == segueTrafficMapViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
            
                if getType(forSection: indexPath.section) == .route {
                    UserDefaults.standard.set(myRoute!.displayLatitude, forKey: UserDefaultsKeys.mapLat)
                    UserDefaults.standard.set(myRoute!.displayLongitude, forKey: UserDefaultsKeys.mapLon)
                    UserDefaults.standard.set(myRoute!.displayZoom, forKey: UserDefaultsKeys.mapZoom)
                    segue.destination.title = "Traffic Map"
                }else{
                    let locationItem = self.savedLocations[indexPath.row] as FavoriteLocationItem
                    UserDefaults.standard.set(locationItem.latitude, forKey: UserDefaultsKeys.mapLat)
                    UserDefaults.standard.set(locationItem.longitude, forKey: UserDefaultsKeys.mapLon)
                    UserDefaults.standard.set(locationItem.zoom, forKey: UserDefaultsKeys.mapZoom)
                    segue.destination.title = "Traffic Map"
                }
            }
        }
       
        if segue.identifier == segueMyRouteAlertsViewController {
            segue.destination.title = "Alerts On Route: \(myRoute!.name)"
        }
        
        if segue.identifier == segueCameraViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                let cameraItem = self.cameras[indexPath.row] as CameraItem
                let destinationViewController = segue.destination as! CameraViewController
                destinationViewController.cameraItem = cameraItem
            }
        }
        if segue.identifier == segueTravelTimeViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                let travelTimeItem = self.travelTimes[indexPath.row] as TravelTimeItem
                let destinationViewController = segue.destination as! TravelTimeDetailsViewController
                destinationViewController.travelTime = travelTimeItem
            }
        }
        if segue.identifier == segueRouteDeparturesViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                let routeItem = self.ferrySchedules[indexPath.row] as FerryScheduleItem
                let destinationViewController = segue.destination as! RouteTabBarViewController
                destinationViewController.routeItem = routeItem
            }
        }
        if segue.identifier == segueMountainPassDetailsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                let passItem = self.mountainPasses[indexPath.row] as MountainPassItem
                let destinationViewController = segue.destination as! MountainPassTabBarViewController
                destinationViewController.passItem = passItem
            }
        }
    }


}
