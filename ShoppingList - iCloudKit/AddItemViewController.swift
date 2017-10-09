//
//  AddItemViewController.swift
//  ShoppingList - iCloudKit
//
//  Created by PotPie on 10/8/17.
//  Copyright © 2017 PotPie - CareerFoundry. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

protocol AddItemViewControllerDelegate {
    func controller(controller: AddItemViewController, didAddItem item: CKRecord)
    func controller(controller: AddItemViewController, didUpdateItem item: CKRecord)
}

class AddItemViewController: UIViewController {
    
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberStepper: UIStepper!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddItemViewControllerDelegate?
    var newItem: Bool = true
    
    var list: CKRecord!
    var item: CKRecord?
    
    // MARK ACTIONS
    
    @IBAction func numberDidChange(sender: UIStepper) {
        let number = Int(sender.value)
        
        //update number label
        numberLabel.text = "\(number)"
    }
    
    
    @IBAction func cancel(sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func save(sender: AnyObject) {
        //navigationController?.popViewController(animated: true)
        
        // Helpers
        let name = nameTextField.text
        let number = Int(numberStepper.value)
        
        //Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        if item == nil {
            //create record
            item = CKRecord(recordType: RecordTypeItems)
            
            //Initialize Reference
            let listReference = CKReference(recordID: list.recordID, action: .deleteSelf)
            
            //Congifure Record
            item?.setObject(listReference, forKey: "list")
        }
        
        //Configure Record
        item?.setObject(name! as CKRecordValue, forKey: "name")
        item?.setObject(number as CKRecordValue, forKey: "number")
        
        //Show Progress HUD
        SVProgressHUD.show()
        
        //Save Record
        
        privateDatabase.save(item!) { (record, error) -> Void in
            DispatchQueue.main.async { () -> Void in
                //Dismiss HUD
                SVProgressHUD.dismiss()
                
                //Process Response
                self.processResponse(record: record, error: error as! NSError)
            }
        }
    }
    
    
    //MARK View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        //Update Helper
        newItem = item == nil
        
        //Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: Selector("textFieldDidChange"), name: NSNotification.Name.UITextFieldTextDidChange, object: nameTextField)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameTextField.becomeFirstResponder()
    }
    
    //MARK View Methods
    
    private func processResponse(record: CKRecord?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We were not able to save your item."
        } else if record == nil {
            message = "We were not ablt to save you item."
        }
        
        if !message.isEmpty {
            // initialize alert controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            //present alert controller
            present(alertController, animated: true, completion: nil)
        } else {
            // notify delegate
            if newItem {
                delegate?.controller(controller: self, didAddItem: item!)
            } else {
                delegate?.controller(controller: self, didUpdateItem: item!)
            }
            
            //Pop view controller
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
        updateNumberStepper()
    }
    
    //MARK --
    
    private func updateNumberStepper() {
        if let number = item?.object(forKey: "number") as? Double {
            numberStepper.value = number
        }
    }
    
    private func updateNameTextField() {
        if let name = item?.object(forKey: "name") as? String {
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
    
    //MARK Notification Handeling
    
    func textFieldDidChange(notification: Notification) {
        updateSaveButton()
    }
}
