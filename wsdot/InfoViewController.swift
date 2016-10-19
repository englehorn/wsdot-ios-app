//
//  InfoViewController.swift
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

import UIKit
import MessageUI

class InfoViewController: UIViewController, MFMailComposeViewControllerDelegate {
   
    @IBOutlet weak var aboutText: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    var version = "?"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let bundle = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        version = bundle as! String
    
        aboutText.sizeToFit()
        
        aboutText.text = "The mission of the Washington State Department of Transportation is to keep people and business moving by operating and improving the state's transportation systems vital to our taxpayers and communities. \n\nThe WSDOT mobile app was created to make it easier for you to know the latest about Washington's transportation system. \n\nQuestions, comments or suggestions about this app can be e-mailed to the WSDOT Communications Office at webfeedback@wsdot.wa.gov."
    
        appVersionLabel.text = "App version: " + version
    
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        GoogleAnalytics.screenView("/About")
    }
    
    @IBAction func composeFeedbackMessage(sender: UIButton) {
    
        let bundle = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let version = bundle as! String
    
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["webfeedback@wsdot.wa.gov"])
            mail.setSubject("WSDOT iOS v\(version) Feedback")
            presentViewController(mail, animated: true, completion: nil)
        } else {
            UIApplication.sharedApplication().openURL(NSURL(string: "mailto:")!)
        }
        
    }
    
    @IBAction func composeBugReport(sender: UIButton) {
    
        let bundle = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let version = bundle as! String
    
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["webfeedback@wsdot.wa.gov"])
            mail.setSubject("WSDOT iOS v\(version) Issue Report")
            mail.setMessageBody("<b>Issue Description:<b><br><br> <b>Steps to Reproduce Issue (if applicable):</b><br><br>", isHTML: true)
            presentViewController(mail, animated: true, completion: nil)
        } else {
            UIApplication.sharedApplication().openURL(NSURL(string: "mailto:")!)
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResult.Cancelled.rawValue:
            print("Cancelled")
        case MFMailComposeResult.Saved.rawValue:
            print("Saved")
        case MFMailComposeResult.Sent.rawValue:
            print("Sent")
        case MFMailComposeResult.Failed.rawValue:
            print("Error: \(error?.localizedDescription)")
        default:
            break
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
