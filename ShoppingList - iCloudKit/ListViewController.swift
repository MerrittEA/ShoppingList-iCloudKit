//
//  ListViewController.swift
//  ShoppingList - iCloudKit
//
//  Created by PotPie on 10/8/17.
//  Copyright © 2017 PotPie - CareerFoundry. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

let SegueItemDetail = "ItemDetail"

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddItemViewControllerDelegate {
    
    static let ItemCell = "ItemCell"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var list: CKRecord!
    var items = [CKRecord]()
    var selection: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set title
        title = list.object(forKey: "name") as? String
        
        setupView()
        fetchItems()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: View Methods
    
    private func setupView() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicatorView.startAnimating()
    }
    
    private func updateView() {
        let hasRecords = items.count > 0
        
        tableView.isHidden = !hasRecords
        messageLabel.isHidden = hasRecords
        activityIndicatorView.stopAnimating()
    }
    
    // MARK: Helper Methods
    
    private func fetchItems() {
        //Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        //Initialze Query
        let reference = CKReference(record: list.recordID, action: .deleteSelf)
        let query = CKQuery(recordType: RecordTypeItems, predicate: NSPredicate(format: "list == %@", reference))
        
        //Configure Query
        query.sortDescripors = [NSSortDescriptor(key: "name", ascending: true)]
        
        //Perform Query
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) -> Void in
            DispatchQueue.main.async {
                () -> Void in
                // Process Response on Main THread
                self.processResponseForQuery(records, error: error)
            }
        }
    }
    
    private func processResponseForQuery(records: [CKRecord]?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Error Fecthing Items for List"
            
        } else if let records = records {
            items = records
            
            if items.count == 0 {
                message = "No items found"
            }
        } else {
            message = "No items found"
        }
        
        if message.isEmpty {
            tableView.reloadData()
        } else {
            messageLabel.text = message
        }
        
        updateView()
    }
    
    private func sortItems() {
        items.sort {
            var result = false
            let name0 = $0.object(forKey: "name") as? String
            let name1 = $1.object(forKey: "name") as? String
            
            if let itemName0 = name0, let itemName1 = name1 {
                result = itemName0.localizedCaseInsensitiveCompare(itemName1) == .orderedAscending
            }
            
            return result
        }
    }
    
    private func deleteRecord(item: CKRecord) {
        //Fetch Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        //SHow hud
        SVProgressHUD.show()
        
        //Delete List
        privateDatabase.delete(withRecordID: item.recordID) { (recordID, error) -> Void in
            DispatchQueue.main.async { () -> Void in
                //Dismiss HUD
                SVProgressHUD.dismiss()
                
                //Process response
                self.processResponseForDeleteRequest(record: item, recordID: recordID, error: error! as NSError)
            }
        }
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecordID?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete the item."
            
        } else if recordID == nil {
            message = "We are unable to delete the item."
        }
        
        if message.isEmpty {
            // Calculate Row Index
            let index = items.index(of: record)
            
            if let index = index {
                // Update Data Source
                items.remove(at: index)
                
                if items.count > 0 {
                    // Update Table View
                    tableView.deleteRows(at: [NSIndexPath(row: index, section: 0) as IndexPath], with: .right)
                    
                } else {
                    // Update Message Label
                    messageLabel.text = "No Items Found"
                    
                    // Update View
                    updateView()
                }
            }
            
        } else {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
        }
    }
    
    //METHODS: Tableview Data Source Methods
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        // Fetch record
        let item = items[indexPath.row]
        
        //Delete record
        deleteRecord(item: item)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ListViewController.ItemCell, for: indexPath)
        
        // Configure the cell
        cell.accessoryType = .detailDisclosureButton
        
        //fetch record
        let item = items[indexPath.row]
        
        if let itemName = item.object(forKey: "name") as? String {
            //Configure cell
            cell.textLabel?.text = itemName
        } else {
            cell.textLabel?.text = "-"
        }
        
        if let itemNumber = item.object(forKey: "number") as? Int {
            //configure cell
            cell.detailTextLabel?.text = "\(itemNumber)"
            
        } else {
            cell.detailTextLabel?.text = "1"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //MARK - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Save Selection
        selection = indexPath.row
        
        // Perform Segue
        performSegue(withIdentifier: SegueItemDetail, sender: self)
    }
    
    //MARK - Add Item View Controller Delegate Methods
    
    func controller(controller: AddItemViewController, didAddItem item: CKRecord) {
        // Add Items to Items
        items.append(item)
        
        //Sort items
        sortItems()
        
        //Update TableView
        tableView.reloadData()
        
        //Update View
        updateView()
    }
    
    func controller(controller: AddItemViewController, didUpdateItem item: CKRecord) {
        //sort items
        sortItems()
        
        // update table view
        tableView.reloadData()
    }
    
    // MARK: Segue Life Cycle
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SegueItemDetail:
            // Fetch Destination View Controller
            let addItemViewController = segue.destination as! AddItemViewController
            
            // Configure View Controller
            addItemViewController.list = list
            addItemViewController.delegate = self
            
            if let selection = selection {
                // Fetch Item
                let item = items[selection]
                
                // Configure View Controller
                addItemViewController.item = item
            }
        default:
            break
        }
    }

}












