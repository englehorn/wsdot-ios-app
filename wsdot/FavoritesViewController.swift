//
//  FavoritesViewController.swift
//  wsdot
//
//  Created by Logan Sims on 6/29/16.
//  Copyright © 2016 wsdot. All rights reserved.
//

import UIKit

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let TITLE = "Favorites"

    let ferriesCellIdentifier = "FerriesFavoriteCell"

    @IBOutlet weak var favoritesTable: UITableView!

    var favoriteRoutes = [FerriesRouteScheduleItem]()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = TITLE
        
        // refresh controller
        refreshControl.addTarget(self, action: #selector(FavoritesViewController.loadFavorites), forControlEvents: .ValueChanged)
        favoritesTable.addSubview(refreshControl)
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.loadFavorites()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.favoritesTable.editing = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize Tab Bar Item
        tabBarItem = UITabBarItem(title: TITLE, image: UIImage(named: "ic-star"), tag: 1)
    }
    
    @objc private func loadFavorites(){
        
        let serviceGroup = dispatch_group_create();
        self.requestFavoriteFerries(serviceGroup)
        
        dispatch_group_notify(serviceGroup, dispatch_get_main_queue()) { // 2
            self.favoritesTable.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    private func requestFavoriteFerries(serviceGroup: dispatch_group_t){
        // Dispatch work with QOS user initated for top priority.
        // weak binding in case user navigates away and self becomes nil.
        dispatch_group_enter(serviceGroup)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { [weak self] in
            RouteSchedulesStore.getRouteSchedules(false, favoritesOnly: true, completion: { data, error in
                if let validData = data {
                    if let selfValue = self{
                        selfValue.favoriteRoutes = validData
                    }
                    dispatch_group_leave(serviceGroup)
                } else {
                    dispatch_group_leave(serviceGroup)
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        if let selfValue = self{
                            selfValue.presentViewController(AlertMessages.getConnectionAlert(), animated: true, completion: nil)
                        }
                    }
                }
                
            })
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch(section){
        case 0:
            if self.favoriteRoutes.count > 0 {
                return "Ferry Schedules"
            }
            return nil
         default:
            return nil
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch(section){
            
        case 0:
            return favoriteRoutes.count
            
            
        default:
            return 0
            
        }
    }
    

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch(indexPath.section){
            
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(ferriesCellIdentifier) as! RoutesCustomCell
            
            cell.title.text = favoriteRoutes[indexPath.row].routeDescription
            
            if self.favoriteRoutes[indexPath.row].crossingTime != nil {
                cell.subTitleOne.hidden = false
                cell.subTitleOne.text = "Crossing time: ~ " + self.favoriteRoutes[indexPath.row].crossingTime! + " min"
            } else {
                cell.subTitleOne.hidden = true
            }
            
            cell.subTitleTwo.text = TimeUtils.timeSinceDate(self.favoriteRoutes[indexPath.row].cacheDate, numericDates: true)
            
            return cell
            
        default:
            return tableView.dequeueReusableCellWithIdentifier("", forIndexPath: indexPath)

        }
        

        
        
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.favoritesTable.setEditing(editing, animated: animated)
    }

    // support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    // support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            
            switch (indexPath.section) {
            case 0:
                RouteSchedulesStore.updateFavorite(favoriteRoutes[indexPath.row].routeId, newValue: false)
                favoriteRoutes.removeAtIndex(indexPath.row)
                
                break
            default:
                break
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
