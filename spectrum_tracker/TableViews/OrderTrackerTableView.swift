import Foundation
import UIKit

class OrderTrackerTableView: UITableView {
    
    var tableData = [OrderTrackerModel]()
    let reuseIdentifier = "OrderTrackerTableViewCell"
    let nibName = "OrderTrackerTableView"
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
    
    func setData(_ data: [OrderTrackerModel]) {
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

// UITableViewDelegate
extension OrderTrackerTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "OrderTrackerTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension OrderTrackerTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! OrderTrackerTableViewCell
        
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

class OrderTrackerTableViewCell : UITableViewCell {

    var cellData: OrderTrackerModel!
    var tableView: OrderTrackerTableView!

    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var orderTrackerImageView: UIImageView!
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelSubtitle: UILabel!
    @IBOutlet var labelPriceTotal: UILabel!
    @IBOutlet var labelCount: UILabel!

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
    
    func setCellData(_ data: OrderTrackerModel, TableView tableView: OrderTrackerTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        
        labelTitle.text = self.cellData.name
        labelSubtitle.text = self.cellData.description
        labelCount.text = self.cellData.count.toString()
        labelPriceTotal.text = "$" + (self.cellData.price * Double(self.cellData.count)).priceString()
        let url = URL(string: URLManager.imageBaseUrl + self.cellData.image)
        orderTrackerImageView.kf.setImage(with: url)
        
        
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

    @IBAction func onMinus(_ sender: Any) {
        let indexPath = self.tableView.indexPath(for: self)
        if(indexPath == nil) {
            return
        }
        if self.tableView.tableData[indexPath!.section].count <= 0 {
            return
        }
        self.tableView.tableData[indexPath!.section].count = self.tableView.tableData[indexPath!.section].count - 1
        self.tableView.reloadRows(at: [indexPath!], with: .fade)
        
        if self.tableView.parentVC is ViewControllerWaitingResult {
            (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("", from: "OrderTrackerTableViewCell-minus")
        }
        
    }

    @IBAction func onPlus(_ sender: Any) {
        let indexPath = self.tableView.indexPath(for: self)
        if(indexPath == nil) {
            return
        }

        self.tableView.tableData[indexPath!.section].count = self.tableView.tableData[indexPath!.section].count + 1
        self.tableView.reloadRows(at: [indexPath!], with: .fade)
        
        if self.tableView.parentVC is ViewControllerWaitingResult {
            (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("", from: "OrderTrackerTableViewCell-minus")
        }
    }

    @IBAction func onRemove(_ sender: Any) {
        
        let indexPath = self.tableView.indexPath(for: self)
        if(indexPath == nil) {
            return
        }
        self.tableView.tableData.remove(at: indexPath!.section)
        
        if self.tableView.parentVC is ViewControllerWaitingResult {
            (self.tableView.parentVC as! ViewControllerWaitingResult).setResult("", from: "OrderTrackerTableViewCell-remove")
        }
        
        self.tableView.reloadData()
    }
}
