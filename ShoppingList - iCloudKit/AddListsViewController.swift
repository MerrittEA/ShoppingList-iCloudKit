//
//  AddListsViewController.swift
//  ShoppingList - iCloudKit
//
//  Created by PotPie on 10/4/17.
//  Copyright © 2017 PotPie - CareerFoundry. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

// protocol for communication between the add lists controller and the list controller

protocol AddListViewControllerDelegate {
    func controller(controller: AddListsViewController, didAddList list: CKRecord)
    func controller(controller: AddListsViewController, didUpdateList list: CKRecord)
}


class AddListsViewController: UIViewController {
    
    //Outlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // Actions
    
    @IBAction func cancel(sender: AnyObject) {
        
    }
    
    @IBAction func save(sender: AnyObject) {
        // helpers
        let name = nameTextField.text
        
        //Fetching the database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        if list == nil {
            list = CKRecord(recordType: RecordTypeLists)
        }
        
        //Configure Record
        list?.setObject(name as! CKRecordValue, forKey: "name")
        
        //Show Progress HUD
        SVProgressHUD.show()
        
        //Saveing the Record
        privateDatabase.save(list!, completionHandler: { (record, error) -> Void in
            DispatchQueue.async(execute: DispatchQueue.main(), { () -> Void in
                //Dismiss the progress indicator
                SVProgressHUD.dismiss()
                
                //Process response
                self.processResponse(record, error: error)
            })
        })
    }
    
    //Properties
    
    var delegate: AddListViewControllerDelegate?
    var newList: Bool = true
    
    var list: CKRecord?
    
    
    //Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
        //Update Helper
        newList = list == nil
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: "textFieldTextDidChange:", name: UITextFieldDidChangeNotification, object: nameTextField)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //View Methods
    
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    private func updateNameTextField() {
        if let name = list?.object(forKey: "name") as? String {
            nameTextField.text = name
        }
    }
    
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
        }
    }
    
    private func processResponse(record: CKRecord?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Not able to save your list."
            
        } else if record == nil {
            message = "We were not able to save your list."
        }
        
        if !message.isEmpty {
            //Initialize alert controller
            let alertController = UIAlertController(title: "error", message: message, preferredStyle: .alert)
            
            //present the alert controller
            presentedViewController(alertController, animated: true, completion: nil)
            
        } else {
            //notify the delegate
            if newList {
                delegate?.controller(controller: self, didAddList: list!)
            } else {
                delegate?.controller(controller: self, didUpdateList: list!)
            }
            
            //pop view controller
            navigationController?.popViewController(animated: true)
        }
    }
    
    // notification handeling
    
    func textFieldTextDidChange(notification: NSNotification) {
        updateSaveButton()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
