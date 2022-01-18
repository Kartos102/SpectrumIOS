//
//  FamilyTableView.swift
//  spectrum_tracker
//
//  Created by Admin on 11/13/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit

class FamilyTableView: UITableView {
    var tableData = [FamilyModel]()
    let reuseIdentifier = "FamilyTableViewCell"
    let nibName = "FamilyTableView"
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
    
    func setData(_ data: [FamilyModel]) {
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
extension FamilyTableView: UITableViewDelegate {
    
}

extension FamilyTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! FamilyTableViewCell
        
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
class FamilyTableViewCell : UITableViewCell {
    
    var tableView: FamilyTableView!
    var row: Int!
    var cellData: FamilyModel!
    var contentViewMainConstraints = [NSLayoutConstraint]()
    @IBOutlet var wrapperView: UIView!
    @IBOutlet var labelUserName: UILabel!
    @IBOutlet var btn_switch: UISwitch!
    @IBAction func onValueChanged(_ sender: UISwitch) {
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((self.cellData.reportId, sender.isOn), from: "changeStatus")
        }
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
    
    func setCellData(_ data: FamilyModel, TableView tableView: FamilyTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        self.row = row
        self.labelUserName.text = self.cellData.name
        if self.cellData.flag == "1" {
            self.btn_switch.isOn = true
        }else {
            self.btn_switch.isOn = false
        }
        
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
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
