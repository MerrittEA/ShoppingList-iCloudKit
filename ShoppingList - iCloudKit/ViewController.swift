//
//  ViewController.swift
//  ShoppingList - iCloudKit
//
//  Created by PotPie on 10/4/17.
//  Copyright © 2017 PotPie - CareerFoundry. All rights reserved.
//

import UIKit
import CloudKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Fetching the userer record
        fetchUserRecordID()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // methods
    
    private func fetchUserRecordID() {
        // Fetch Default Container
        let defaultContainer = CKContainer.default()
        
        // Fetch Private Database
        
        let privateDatabase = defaultContainer.privateCloudDatabase
        
        // Fetch User Record
        defaultContainer.fetchUserRecordID(completionHandler: { (recordID, error) -> Void in
            if let responseError = error {
                print(responseError)
                
            } else if let userRecordID = recordID {
                DispatchQueue.async(execute: DispatchQueue.main, { () -> Void in
                    self.fetchUserRecord(userRecordID)
                })
            }
        })
    }
    
    private func fetchUserRecord(recordID: CKRecordID) {
        
    }
}

