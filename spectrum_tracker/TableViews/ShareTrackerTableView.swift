//
//  ShareTrackerTableView.swift
//  spectrum_tracker
//
//  Created by Admin on 11/12/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import ContactsUI


class ShareTrackerTableView: UITableView {

    var tableData = [ShareModel]()
    let reuseIdentifier = "ShareTrackerTableViewCell"
    let nibName = "ShareTrackerTableView"
    let cellSpacingHeight:CGFloat = 2
    private var cellHeights: [IndexPath: CGFloat?] = [:]
    
    var parentVC: UIViewController?
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        
        self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        self.rowHeight = UITableView.automaticDimension
        self.estimatedRowHeight = 0
        
        self.separatorStyle = .none
        self.backgroundView = nil
        self.backgroundColor = UIColor.clear
        
        self.delegate = self
        self.dataSource = self
        
    }
    
    func setData(_ data: [ShareModel]) {
        self.tableData = data
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeights[indexPath] {
            return height ?? UITableView.automaticDimension
        }
        return UITableView.automaticDimension
    }

}
extension ShareTrackerTableView: UITableViewDelegate {
    
}

extension ShareTrackerTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ShareTrackerTableViewCell
        
        let _share = tableData[indexPath.section]
        cell.setCellData(_share, TableView: self, Row: indexPath.section)
        
        return cell
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
}
class ShareTrackerTableViewCell : UITableViewCell {
    
    var tableView: ShareTrackerTableView!
    var row: Int!
    var cellData: ShareModel!
    var contentViewMainConstraints = [NSLayoutConstraint]()
    @IBOutlet var wrapperView: UIView!
    @IBOutlet var editShareEmail: UITextField!
    @IBOutlet var labelSharedUser: UILabel!
    @IBOutlet var labelPlateNumber: UILabel!
    
    static var tmpRow = -1
    static var tmpEmail = ""
    static var tmpSharedUsers = ""
    
    @IBAction func onShowSharedUserDialog(_ sender: Any) {
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((self.cellData.reportId, self.row), from: "onShowSharedUserDialog")
        }
    }
    @IBAction func onUnShare(_ sender: Any) {
        if self.cellData.labelSharedUser == "Select Users" {
            (tableView.parentVC as! ViewControllerWaitingResult).view.makeToast("Please select users for unshare".localized())
        }
        else if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((self.cellData.reportId, self.cellData.labelSharedUser), from: "onUnShareAction")
        }
    }
    func validateEmail(enteredEmail:String) -> Bool {
        
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
        
    }
    @IBAction func onShare(_ sender: Any) {
        if self.editShareEmail.text == "" {
            (tableView.parentVC as! ViewControllerWaitingResult).view.makeToast("Please insert email for share".localized())
        }
        else if !validateEmail(enteredEmail: self.editShareEmail.text!) {
            (tableView.parentVC as! ViewControllerWaitingResult).view.makeToast("Invalid Email".localized())
        }
        else if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((self.cellData.reportId, self.editShareEmail.text), from: "onShareAction")
        }
    }
    
    @IBAction func onContactButtonTapped(_ sender: Any) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        contactPicker.delegate = self
        
        ShareTrackerTableViewCell.tmpRow = self.row
        ShareTrackerTableViewCell.tmpEmail = self.editShareEmail.text ?? ""
        ShareTrackerTableViewCell.tmpSharedUsers = self.labelSharedUser.text ?? ""
        
        tableView.parentVC?.present(contactPicker, animated: true, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
    func updateSnapWrapper2ContentViewConstraints(_ priority: UILayoutPriority) {
        
        if(!contentViewMainConstraints.isEmpty){
            for constraint in contentViewMainConstraints {
                constraint.isActive = false
            }
        }
        contentViewMainConstraints.removeAll()
        
        let leadingAnchor = wrapperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let traillingAnchor = wrapperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let topAnchor = wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let bottomAnchor = wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        
        leadingAnchor.priority = priority
        traillingAnchor.priority = priority
        topAnchor.priority = priority
        bottomAnchor.priority = priority
        
        contentViewMainConstraints = [
            leadingAnchor,
            traillingAnchor,
            topAnchor,
            bottomAnchor
        ]
        
        NSLayoutConstraint.activate(contentViewMainConstraints)
    }
    
    func setCellData(_ data: ShareModel, TableView tableView: ShareTrackerTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        self.row = row
        self.labelPlateNumber.text = self.cellData.plateNumber
        self.labelSharedUser.text = self.cellData.labelSharedUser
        self.editShareEmail.text = ""
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
        
        if ShareTrackerTableViewCell.tmpRow == row {
            if ShareTrackerTableViewCell.tmpEmail != "" {
                self.editShareEmail.text = ShareTrackerTableViewCell.tmpEmail
            }
            
            if ShareTrackerTableViewCell.tmpSharedUsers != "" {
                self.labelSharedUser.text = ShareTrackerTableViewCell.tmpSharedUsers
            }
            
            ShareTrackerTableViewCell.tmpSharedUsers = ""
            ShareTrackerTableViewCell.tmpEmail = ""
            ShareTrackerTableViewCell.tmpRow = -1
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = clearView
        
        self.backgroundView = clearView
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        
        self.selectionStyle = .none
    }
    
}

extension ShareTrackerTableViewCell: CNContactPickerDelegate {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let email = contact.emailAddresses.first?.value
        
        if let _email = email as String?, _email != "" {
            ShareTrackerTableViewCell.tmpEmail = _email
            self.editShareEmail.text = _email
        }
    }
}
