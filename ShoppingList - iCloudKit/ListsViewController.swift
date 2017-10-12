//
//  ViewController.swift
//  ShoppingList - iCloudKit
//
//  Created by PotPie on 10/4/17.
//  Copyright © 2017 PotPie - CareerFoundry. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

let RecordTypeLists = "Lists"
let RecordTypeItems = "Items"

let SegueList = "List"
let SegueListDetail = "ListDetail"



class ListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddListViewControllerDelegate {
    
    static let ListCell = "ListCell"
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    //var RecordTypeLists = "Lists"
    
    var lists = [CKRecord]()
    
    var selection: Int?
    
    let SegueListDetail = "ListDetail"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        fetchLists()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // helper methods
    
        private func setupView() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicatorView.startAnimating()
    }
    
    private func fetchLists() {
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // Initialize Query
        let query = CKQuery(recordType: RecordTypeLists, predicate: NSPredicate(format: "TRUEPREDICATE"))
        
        // Configure Query (arranging the query)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Perform Query
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) -> Void in
            DispatchQueue.main.async {
                self.processResponseForQuery(records: records, error: error as NSError?)
            }
        }
    }
    
    private func processResponseForQuery(records: [CKRecord]?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Error fetching records"
        } else if let records = records {
            lists = records
            
            if lists.count == 0 {
                message = "No records found"
            }
        } else {
            message = "No records found"
        }
        
        if message.isEmpty {
            tableView.reloadData()
        } else {
            messageLabel.text = message
        }
        
        updateView()
    }
    
    private func updateView() {
        let hasRecords = lists.count > 0
        
        tableView.isHidden = !hasRecords
        messageLabel.isHidden = hasRecords
        activityIndicatorView.stopAnimating()
    }
    
    private func sortLists() {
        lists.sort {
            var result = false
            let name0 = $0.object(forKey: "name") as? String
            let name1 = $1.object(forKey: "name") as? String
            
            if let listName0 = name0, let listName1 = name1 {
                result = listName0.localizedCaseInsensitiveCompare(listName1) == .orderedAscending
            }
            
            return result
        }
    }
    
    private func deleteRecord(list: CKRecord) {
        // fetching the database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        //ShowProgress Hud
        SVProgressHUD.show()
        
        //Delete list
        privateDatabase.delete(withRecordID: list.recordID, completionHandler: { (recordID, error) -> Void in
            DispatchQueue.main.async {
                //Dismiss the Progress HUD
                SVProgressHUD.dismiss()
                
                // Process the response
                self.processResponseForDeleteRequest(record: list, recordID: recordID, error: error as NSError?)
            }
        })
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecordID?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Unable to delete list"
            
        } else if recordID == nil {
            message = "Unable to delete list"
        }
        
        if message.isEmpty {
            //Calculate row indes
            let index = lists.index(of: record)
            
            if let index = index {
                //update data source
                lists.remove(at: index)
                
                if lists.count > 0 {
                    //update table view
                    tableView.deleteRows(at: [NSIndexPath(row: index, section: 0) as IndexPath], with: .right)
                } else {
                    //update message label
                    messageLabel.text = "No records found"
                    
                    //udpate view
                    updateView()
                }
            }
        } else {
            // initialize alert controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            //present the alert controller
            present(alertController, animated: true, completion: nil)
        }
    }

    // Table View Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeu Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ListsViewController.ListCell, for: indexPath)
        
        // Configureing the cell (arrangeing the cell)
        cell.accessoryType = .detailDisclosureButton
        
        //fetching Record for cell
        let list = lists[indexPath.row]
        
        if let listName = list.object(forKey: "name") as? String {
            //configure cell
            cell.textLabel?.text = listName
            
        } else {
            cell.textLabel?.text = ""
        }
        return cell
    }
    // Table view Delegte Methods
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //save selection
        selection = indexPath.row
        
        // Perform Segue
        
        performSegue(withIdentifier: SegueListDetail, sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        // Get record
        let list = lists[indexPath.row]
        
        //delete record
        deleteRecord(list: list)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Segue stuff
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SegueList:
            //Fetch Desitination View Controller
            let listViewController = segue.destination as! ListViewController
            
            //Fetch Selection
            let list = lists[tableView.indexPathForSelectedRow!.row]
            
            //Configure view controller
            listViewController.list = list
            
            
        case SegueListDetail:
            // Fetch Destination view controller
            let addListViewController = segue.destination as! AddListsViewController
            
            // configue view controller
            addListViewController.delegate = self
            
            if let selection = selection {
                //fetch list
                let list = lists[selection]
                
                // configure view controller
                addListViewController.list = list
            }
        default: break
        }
    }
    
    // Add List View Controller Delegate Methods
    
    func controller(controller: AddListsViewController, didAddList list: CKRecord) {
        // Add list to lists
        lists.append(list)
        
        //Sort Lists
        sortLists()
        
        //Update table view
        tableView.reloadData()
        
        //Update view
        updateView()
    }
    
    func controller(controller: AddListsViewController, didUpdateList list: CKRecord) {
        //Sort lists
        sortLists()
        
        //Update Table View
        tableView.reloadData()
    }
}

