//
//  TollRatesViewController.swift
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
import UIKit

class TollRatesViewController: UIViewController{


    @IBOutlet weak var SR520ContainerView: UIView!
    @IBOutlet weak var SR16ContainerView: UIView!
    @IBOutlet weak var SR167ContainerView: UIView!
    @IBOutlet weak var I405ContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Toll Rates"
    }
    
    // Remove and add hairline for nav bar
    override func viewWillAppear(animated: Bool) {
        GoogleAnalytics.screenView("/Toll Rates/SR520")
    
        let img = UIImage()
        self.navigationController?.navigationBar.shadowImage = img
        self.navigationController?.navigationBar.setBackgroundImage(img, forBarMetrics: .Default)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
    }
    
    @IBAction func indexChanged(sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex){
            
        case 0:
            GoogleAnalytics.screenView("/Toll Rates/SR520")
            SR520ContainerView.hidden = false
            SR16ContainerView.hidden = true
            SR167ContainerView.hidden = true
            I405ContainerView.hidden = true
            break
        case 1:
            GoogleAnalytics.screenView("/Toll Rates/SR16")
            SR520ContainerView.hidden = true
            SR16ContainerView.hidden = false
            SR167ContainerView.hidden = true
            I405ContainerView.hidden = true
            break
        case 2:
            GoogleAnalytics.screenView("/Toll Rates/SR167")
            SR520ContainerView.hidden = true
            SR16ContainerView.hidden = true
            SR167ContainerView.hidden = false
            I405ContainerView.hidden = true
            break
        case 3:
            GoogleAnalytics.screenView("/Toll Rates/I405")
            SR520ContainerView.hidden = true
            SR16ContainerView.hidden = true
            SR167ContainerView.hidden = true
            I405ContainerView.hidden = false
            break
        default:
            break
        }
    }
}