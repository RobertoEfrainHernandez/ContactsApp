//
//  ContactInfoController.swift
//  CodeTestRobertoHernandez
//
//  Created by Roberto Hernandez on 12/20/18.
//  Copyright © 2018 Roberto Efrain Hernandez. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

//Protocol for Updating ContactsController
protocol ContactInfoDelegate {
    func didUpdateContactInfo()
}

class ContactInfoController: UITableViewController {
    
    //MARK:- Properties
    fileprivate let realm = try! Realm()
    var phones: List<Phone>?
    var emails: List<Email>?
    var addresses: List<Address>?
    fileprivate var contactColor: UIColor!
    
    var contactInfoDelegate: ContactInfoDelegate?
    var contact: Contact? {
        didSet {
           loadPhoneEmailAddress()
        }
    }
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setTableView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Color", style: .plain, target: self, action: #selector(handleColorChanged))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let name = contact?.name ?? "John Doe"
        contactColor = UIColor(hexString: contact?.color ?? "C70039")!
        ContactHUD.setColor(color: contactColor)
        title = name
        updateNavBar(contactColor)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK:- Fileprivate and Selector Methods
    fileprivate func setTableView() {
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    fileprivate func updateNavBar(_ color: UIColor) {
        let contrast = ContrastColorOf(color, returnFlat: true)
        let attributes : [NSAttributedString.Key : Any] = [.foregroundColor : contrast]
        if let navBar = navigationController?.navigationBar {
            navBar.barTintColor = color
            navBar.titleTextAttributes = attributes
            navBar.largeTitleTextAttributes = attributes
            navBar.tintColor = contrast
        }
    }
    
    fileprivate func loadPhoneEmailAddress() {
        phones = contact?.phoneNums
        emails = contact?.emails
        addresses = contact?.addresses
        tableView.reloadData()
    }
    
    @objc fileprivate func handleColorChanged() {
        if let currentContact = self.contact {
            Realm.changeColor(contact: currentContact, table: tableView)
            contactColor = UIColor(hexString: currentContact.color)!
            updateNavBar(contactColor)
            contactInfoDelegate?.didUpdateContactInfo()
        }
    }
}

//MARK:- Extension for TableView Methods
extension ContactInfoController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return setHeaderView(for: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return setNumberRows(for: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ContactInfoCell(style: .default, reuseIdentifier: nil)
        setUpCell(for: cell, color: contactColor, indexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 2:
            showiMessage(for: indexPath)
        case 3:
            showMail(for: indexPath)
        case 4:
            showOpenInMaps(for: indexPath)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteContactItem(indexPath)
            self.contactInfoDelegate?.didUpdateContactInfo()
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            self.editContactItem(indexPath)
            self.contactInfoDelegate?.didUpdateContactInfo()
        }
        contactColor = UIColor(hexString: contact?.color ?? "008B8B")!
        edit.backgroundColor = contactColor
        if (indexPath.section == 0 || indexPath.section == 1) {
            return [edit]
        }
        
        return [delete, edit]
    }
}

//MARK:- Extension for Deleting and Editing Methods for TableViewRowAction
extension ContactInfoController {
    fileprivate func deleteContactItem(_ indexPath: IndexPath) {
        if let currentContact = contact {
            switch indexPath.section {
            case 2:
                Realm.delete(realmObject: currentContact.phoneNums[indexPath.row], table: tableView)
            case 3:
                Realm.delete(realmObject: currentContact.emails[indexPath.row], table: tableView)
            case 4:
               Realm.delete(realmObject: currentContact.addresses[indexPath.row], table: tableView)
            default:
                break
            }
        }
    }
    
    fileprivate func editContactItem(_ indexPath: IndexPath) {
        if let currentContact = contact {
            switch indexPath.section {
            case 0:
                Realm.handleName(contact: currentContact, table: tableView, controller: self)
            case 1:
                Realm.addBirthday(contact: currentContact, table: tableView, controller: self)
            case 2:
                Realm.edit(phoneIndex: indexPath, contact: currentContact, table: tableView, controller: self)
            case 3:
                Realm.edit(emailIndex: indexPath, contact: currentContact, table: tableView, controller: self)
            default:
                Realm.edit(addressIndex: indexPath, contact: currentContact, table: tableView, controller: self)
            }
        }
    }
}
