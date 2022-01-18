
import UIKit

class SharedUserTableView: UITableView {

    var tableData = [SharedUserModel]()
    let reuseIdentifier = "SharedUserTableViewCell"
    let nibName = "SharedUserTableView"
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
    
    func setData(_ data: [SharedUserModel]) {
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
        return CGFloat(CGFloat(tableData.count) * 40)
    }
}
extension SharedUserTableView: UITableViewDelegate {
    
}

extension SharedUserTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! SharedUserTableViewCell
        
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
class SharedUserTableViewCell : UITableViewCell {
    
    var tableView: SharedUserTableView!
    var row: Int!
    var cellData: SharedUserModel!
    var contentViewMainConstraints = [NSLayoutConstraint]()
    @IBOutlet var wrapperView: UIView!
    @IBOutlet var labelUserEmail: UILabel!
    @IBOutlet var btnSelect: UIButton!
    @IBAction func onSelectAction(_ sender: Any) {
        let isSelected = !self.tableView.tableData[row].checked
        
        self.tableView.tableData[row].checked = isSelected
        
        
        if let indexPath = self.tableView.indexPath(for: self) {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((row, isSelected), from: "SharedUserTableViewCell-selectedItem")
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
    
    func setCellData(_ data: SharedUserModel, TableView tableView: SharedUserTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        self.row = row
        self.labelUserEmail.text = self.cellData.email
        self.btnSelect.isSelected = self.cellData.checked
        
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
