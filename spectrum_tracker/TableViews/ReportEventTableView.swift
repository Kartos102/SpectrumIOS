import Foundation
import UIKit

class ReportEventTableView: UITableView {

    var tableData = [ReportEventModel]()
    let reuseIdentifier = "ReportEventTableViewCell"
    let nibName = "ReportEventTableView"
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
        self.backgroundColor = UIColor(hexInt: 0xffffff)
        
        self.delegate = self
        self.dataSource = self
        
    }
    
    func setData(_ data: [ReportEventModel]) {
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.parentVC is ViewControllerWaitingResult {
            (self.parentVC as! ViewControllerWaitingResult).setTableViewHeight(scrollView.contentOffset.y)
        }
    }
    
    func getHeight() -> CGFloat {
        return CGFloat(CGFloat(tableData.count) * 41)
    }
}

// UITableViewDelegate
extension ReportEventTableView: UITableViewDelegate {
    
}

// UITableViewDataSource
extension ReportEventTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ReportEventTableViewCell
        
        cell.setCellData(self.tableData[self.tableData.count - indexPath.section - 1], TableView: self, Row: indexPath.section)
        
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


class ReportEventTableViewCell : UITableViewCell {
    
    var cellData: ReportEventModel!
    var tableView: ReportEventTableView!
    
    var row: Int!
    
    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var label_DateTime: UILabel!
    @IBOutlet var label_Event: UILabel!
    
    @IBAction func onClickAddress(_ sender: Any) {
        guard let url = URL(string: self.cellData.address.trimmingCharacters(in: CharacterSet.whitespaces)) else {return}
        UIApplication.shared.open(url)
    }
    
    var contentViewMainConstraints = [NSLayoutConstraint]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
    func updateSnapWrapper2ContentViewConstraints(_ priority: UILayoutPriority) {
        
        if(!contentViewMainConstraints.isEmpty) {
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
    
    func setCellData(_ data: ReportEventModel, TableView tableView: ReportEventTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        self.label_DateTime.text = self.cellData.dateTime
        self.label_Event.text = self.cellData.alarm
        self.row = row
        
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
