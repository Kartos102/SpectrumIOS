import Foundation
import UIKit
import DropDown
import SCLAlertView

class OrderServiceTableView: UITableView {
    
    var tableData = [OrderServiceModel]()
    let reuseIdentifier = "OrderServiceTableViewCell"
    let nibName = "OrderServiceTableView"
    let cellSpacingHeight:CGFloat = 0
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
    
    func setData(_ data: [OrderServiceModel]) {
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
    func getHeight() -> CGFloat {
        return CGFloat(CGFloat(tableData.count) * 258)
    }
}

// UITableViewDelegate
extension OrderServiceTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension OrderServiceTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! OrderServiceTableViewCell
        
        cell.setCellData(tableData[indexPath.section], TableView: self, Row: indexPath.section)
       
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

class OrderServiceTableViewCell : UITableViewCell {

    var cellData: OrderServiceModel!
    var tableView: OrderServiceTableView!

    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelExpirationDate: UILabel!
    @IBOutlet var labelServicePlan: UILabel!
    @IBOutlet var labelLteData: UILabel!
    @IBOutlet var labelAutoReview: UILabel!
    
    @IBOutlet var btnServicePlan: UIButton!
    @IBOutlet var btnLteData: UIButton!
    @IBOutlet var btnAutoReview: UIButton!
    
    @IBOutlet var viewBorderTop: UIView!
    
    var servicePlanDropdown: DropDown!
    var lteDataDropdown: DropDown!
    var autoReviewDropdown: DropDown!

    var contentViewMainConstraints = [NSLayoutConstraint]()
    
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
    
    func setCellData(_ data: OrderServiceModel, TableView tableView: OrderServiceTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        
       
        

        self.labelName.text = self.cellData.name == "" ? "driverName" : self.cellData.name
        self.labelExpirationDate.text = self.cellData.expirationDate
        self.labelServicePlan.text = self.cellData.servicePlanList[self.cellData.selectedServicePlanId].servicePlan
        self.labelLteData.text = self.cellData.lteDataList[self.cellData.selectedLTEDataId].lteData
        self.labelAutoReview.text = self.cellData.autoReview ? "Yes".localized() : "No".localized()
        
        servicePlanDropdown = DropDown()
        
        servicePlanDropdown.dataSource = [String]()
        
        for item in self.cellData.servicePlanList {
            servicePlanDropdown.dataSource.append(item.servicePlan)
        }
        
        servicePlanDropdown.anchorView = btnServicePlan
        servicePlanDropdown.backgroundColor = UIColor.groupTableViewBackground
        servicePlanDropdown.bottomOffset = CGPoint(x: 0, y:(servicePlanDropdown.anchorView?.plainView.bounds.height)!)
        servicePlanDropdown.direction = .bottom
        
        servicePlanDropdown.selectionAction = { (index: Int, title: String) in
//            self.labelServicePlan.text = title
            
            if self.tableView.parentVC is ViewControllerWaitingResult {
                
                for i in 0..<self.cellData.servicePlanList.count {
                    if self.cellData.servicePlanList[i].servicePlan == title {
                        
                        self.tableView.tableData[row].selectedServicePlanId = i

                        (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("servicePlan", from: "OrderServiceTableViewCell-need2UpdateBottomPrices")

                        let indexPath = self.tableView.indexPath(for: self)
                        if(indexPath != nil) {
                            self.tableView.reloadRows(at: [indexPath!], with: .none)
                        }
                        return
                    }
                }
            }
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////
        
        lteDataDropdown = DropDown()
        
        lteDataDropdown.dataSource = [String]()
        
        for item in self.cellData.lteDataList {
            lteDataDropdown.dataSource.append(item.lteData)
        }
        
        lteDataDropdown.anchorView = btnLteData
        lteDataDropdown.backgroundColor = UIColor.groupTableViewBackground
        lteDataDropdown.bottomOffset = CGPoint(x: 0, y:(lteDataDropdown.anchorView?.plainView.bounds.height)!)
        lteDataDropdown.direction = .bottom
        
        
        lteDataDropdown.selectionAction = { (index: Int, title: String) in
//            self.labelLteData.text = title
            
            if self.tableView.parentVC is ViewControllerWaitingResult {
                
                for i in 0..<self.cellData.lteDataList.count {
                    if self.cellData.lteDataList[i].lteData == title {
                        self.tableView.tableData[row].selectedLTEDataId = i
                        (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("lteData", from: "OrderServiceTableViewCell-need2UpdateBottomPrices")
                        
                        let indexPath = self.tableView.indexPath(for: self)
                        if(indexPath != nil) {
                            self.tableView.reloadRows(at: [indexPath!], with: .none)
                        }
                        return
                    }
                }
            }
            
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////
        
        autoReviewDropdown = DropDown()
        
        autoReviewDropdown.dataSource = [String]()

        autoReviewDropdown.dataSource.append("Yes")
        autoReviewDropdown.dataSource.append("No")

        autoReviewDropdown.anchorView = btnAutoReview
        autoReviewDropdown.backgroundColor = UIColor.groupTableViewBackground
        autoReviewDropdown.bottomOffset = CGPoint(x: 0, y:(autoReviewDropdown.anchorView?.plainView.bounds.height)!)
        autoReviewDropdown.direction = .bottom
        
        
        autoReviewDropdown.selectionAction = { (index: Int, title: String) in
//            self.labelAutoReview.text = title
            
            if title == "Yes" {
                self.tableView.tableData[row].autoReview = true
            } else {
                self.tableView.tableData[row].autoReview = false
            }
            
            if self.tableView.parentVC is ViewControllerWaitingResult {
                (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("autoReview", from: "OrderServiceTableViewCell-need2UpdateBottomPrices")
                
                let indexPath = self.tableView.indexPath(for: self)
                if(indexPath != nil) {
                    self.tableView.reloadRows(at: [indexPath!], with: .none)
                }
            }
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////
        
        
        
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
    
    @IBAction func onBtnServicePlan(sender: AnyObject) {
        if self.cellData.servicePlanEnabled {
            if self.servicePlanDropdown.isHidden {
                self.servicePlanDropdown.show()
            } else {
                self.servicePlanDropdown.hide()
            }
        }
    }
    
    @IBAction func onBtnInfo(_ sender: Any) {
        var result = ""

        let selectedIndex = self.cellData.selectedServicePlanId ?? 0
        let planDetails = cellData.servicePlanList[selectedIndex].planDetails
        for i in 0..<planDetails.count {
            result += "\(i + 1). \(planDetails[i])\n"
        }
        
        if result == "" {
            return
        }
        
        let alertController = UIAlertController(title: self.labelServicePlan.text!, message: "\n\(result)", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        
        let messageText = NSMutableAttributedString(
            string: "\n\(result)",
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ]
        )
        
        alertController.setValue(messageText, forKey: "attributedMessage")
        self.tableView.parentVC!.present(alertController, animated: true, completion: nil)
    }
    @IBAction func onBtnLteData(sender: AnyObject) {
        if self.cellData.lteDataEnabled {
            if self.lteDataDropdown.isHidden {
                self.lteDataDropdown.show()
            } else {
                self.lteDataDropdown.hide()
            }
        }
    }
    
    @IBAction func onBtnAutoReview(sender: AnyObject) {
        if self.autoReviewDropdown.isHidden {
            self.autoReviewDropdown.show()
        } else {
            self.autoReviewDropdown.hide()
        }
    }
}
