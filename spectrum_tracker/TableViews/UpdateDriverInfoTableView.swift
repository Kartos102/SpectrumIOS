import Foundation
import UIKit

class UpdateDriverInfoTableView: UITableView {
    
    var tableData = [AssetModel]()
    var trackers = [AssetModel: TrackerModel]()
    let reuseIdentifier = "UpdateDriverInfoTableViewCell"
    let nibName = "UpdateDriverInfoTableView"
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
    
    func setData(_ data: [AssetModel], trackers: [AssetModel: TrackerModel]) {
        self.tableData = data
        self.trackers = trackers
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

// UITableViewDelegate
extension UpdateDriverInfoTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension UpdateDriverInfoTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! UpdateDriverInfoTableViewCell
        
        let asset = tableData[indexPath.section]
        let tracker = trackers[asset]
        cell.setCellData(asset, tracker: tracker, TableView: self, Row: indexPath.section)
       
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

class UpdateDriverInfoTableViewCell : UITableViewCell {

    var cellData: AssetModel!
    var tracker: TrackerModel!
    var tableView: UpdateDriverInfoTableView!

    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var txtDriverName: UITextField!
    @IBOutlet var txtDriverPhone: UITextField!
    @IBOutlet var txtVehicleName: UITextField!
    @IBOutlet var txtColor: UITextField!
    @IBOutlet var txtAutoRenew: UITextField!

    var contentViewMainConstraints = [NSLayoutConstraint]()
    
    let colorDropDown = DropDown()
    let autoRenewDropDown = DropDown()
    
    override func awakeFromNib() {
        super.awakeFromNib()
         self.updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
        
        colorDropDown.anchorView = txtColor
        colorDropDown.dataSource = ["RED".localized(), "ORANGE".localized(),
                                    "WHITE".localized(), "GREY".localized(),
                                    "BLACK".localized(), "SILVER".localized(),
                                    "BLUE".localized(), "GREEN".localized()]
        colorDropDown.selectionAction = { index, item in
            self.txtColor.text = item
        }
        colorDropDown.width = colorDropDown.anchorView!.plainView.bounds.width
        colorDropDown.bottomOffset = CGPoint(x: 0, y: colorDropDown.anchorView!.plainView.bounds.height + 4)
        colorDropDown.topOffset = CGPoint(x: 0, y: -(colorDropDown.anchorView!.plainView.bounds.height + 4))
        
        autoRenewDropDown.anchorView = txtAutoRenew
        autoRenewDropDown.dataSource = ["true", "false"]
        autoRenewDropDown.selectionAction = { index, item in
            self.txtAutoRenew.text = item
        }
        autoRenewDropDown.width = colorDropDown.anchorView!.plainView.bounds.width
        autoRenewDropDown.bottomOffset = CGPoint(x: 0, y: autoRenewDropDown.anchorView!.plainView.bounds.height + 4)
        autoRenewDropDown.topOffset = CGPoint(x: 0, y: -(autoRenewDropDown.anchorView!.plainView.bounds.height + 4))
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
    
    func setCellData(_ data: AssetModel, tracker: TrackerModel?, TableView tableView: UpdateDriverInfoTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        self.tracker = tracker ?? TrackerModel()
        
        txtDriverName.text = self.cellData.driverName
        txtDriverPhone.text = self.cellData.driverPhoneNumber
        txtVehicleName.text = self.tracker.plateNumber
        txtColor.text = self.tracker.color
        txtAutoRenew.text = self.tracker.autoRenew ? "True" : "False"
        
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
    
    @IBAction func onUpdate(_ sender: Any) {
        var id = cellData.trackerId
        if id == "" {
            id = cellData._id
        }
        
        let driverName = txtDriverName.text ?? ""
        let driverPhone = txtDriverPhone.text ?? ""
        let vehicleName = txtVehicleName.text ?? ""
        let color = txtColor.text ?? ""
        let autoRenew = txtAutoRenew.text ?? ""
        let assetId = cellData.assetId
        
        if self.tableView.parentVC is ViewControllerWaitingResult {
            (self.tableView.parentVC as! ViewControllerWaitingResult).setResult((id, driverName, driverPhone, vehicleName, assetId, color, autoRenew), from: "UpdateDriverInfoTableView-updateDriverItem")
        }
    }
    
    @IBAction func colorDropdownButtonTapped(_ sender: Any) {
        colorDropDown.show()
    }
    
    @IBAction func autoRenewDropdownButtonTapped(_ sender: Any) {
        autoRenewDropDown.show()
    }
    
}
