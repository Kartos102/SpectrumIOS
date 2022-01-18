import Foundation
import UIKit
import DropDown
import SwiftyJSON
//import DLRadioButton

class AssetSingleSelectTableView: UITableView {
    
    var tableData = [TrackerModel]()
    let reuseIdentifier = "AssetSingleSelectTableViewCell"
    let nibName = "AssetSingleSelectTableView"
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
    
    func setData(_ data: [TrackerModel]) {
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
    
    // for this table view only to calculate table height
    func getHeight() -> CGFloat {
        return CGFloat((tableData.count) * 100)
    }
    
    
}

// UITableViewDelegate
extension AssetSingleSelectTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension AssetSingleSelectTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! AssetSingleSelectTableViewCell
        
        cell.setCellData(self.tableData[indexPath.section], TableView: self, Row: indexPath.section)
       
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

class AssetSingleSelectTableViewCell : UITableViewCell {

    var cellData: TrackerModel!
    var tableView: AssetSingleSelectTableView!

    var row: Int!
    
    @IBOutlet var wrapperView: UIView!
    @IBOutlet var btnSelect: UIButton!
    @IBOutlet weak var driverPhotoContainerView: UIView!
    @IBOutlet weak var driverPhotoImageView: UIImageView!
    @IBOutlet var topSpace: NSLayoutConstraint!
    @IBOutlet var labelVehicleName: UILabel!
    
    @IBOutlet weak var labelNearAddress: UILabel!
    
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var imageBattery: UIImageView!
    @IBOutlet weak var labelTemp: UILabel!
    @IBOutlet weak var imageTemp: UIImageView!
    @IBOutlet weak var labelRpm: UILabel!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var labelSpeed: UILabel!
    @IBOutlet weak var labelUpdate: UILabel!
    
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
    
    func setCellData(_ data: TrackerModel, TableView tableView: AssetSingleSelectTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data

        self.btnSelect.isSelected = self.cellData.isSelected
        
        self.driverPhotoImageView.layer.cornerRadius =  self.driverPhotoImageView.frame.height / 2
        self.driverPhotoImageView.layer.masksToBounds = true
        self.driverPhotoImageView.layer.borderWidth = 1.2
        self.driverPhotoImageView.layer.borderColor = UIColor(hexInt: 0xFF0066).cgColor
        
        if let imageUrl = Global.shared.driverPhotos[data._id], let url = URL(string: imageUrl) {
            self.driverPhotoImageView.load(url)
        } else {
            self.driverPhotoImageView.image = UIImage(named: "driver_empty")
        }
        
        self.labelVehicleName.text = self.cellData.driverName
        if self.cellData.latLngDateTime != nil {
            self.labelUpdate.text = "Update:".localized() + " " + self.cellData.latLngDateTime!.toString("MM/dd HH:mm")
        } else {
            self.labelUpdate.text = ""
        }
        imageTemp.image = imageTemp.image?.withRenderingMode(.alwaysTemplate)
        imageTemp.tintColor = UIColor(hexString: "#f96f00")
        imageBattery.image = imageBattery.image?.withRenderingMode(.alwaysTemplate)
        imageBattery.tintColor = UIColor(hexString: "#008000")
        let rpm = self.cellData.rpm
        labelRpm.text = String(format: "%.1f",rpm) + " RPM"
        let coolant = self.cellData.coolanttemp
        labelTemp.text = String(format: "%.1f",coolant) + "°C"
        let battery = self.cellData.voltage
        if self.cellData.trackerModel == "QUECLINK" {
            labelBattery.text = String(format: "%.1f",battery) + "%"
        }else {
            labelBattery.text = String(format: "%.1f",battery) + "V"
        }
        var speed = self.cellData.speedInMph
        
        if self.cellData.accStatus != 0 && self.cellData.speedInMph != 0 {
            self.imageStatus.backgroundColor = UIColor(red: 0, green: 200, blue: 83)
        }
        else if self.cellData.accStatus != 0 && self.cellData.speedInMph == 0 {
            speed = 0
            self.imageStatus.backgroundColor = UIColor(red: 186, green: 69, blue: 240)
        }
        else {
            speed = 0
            self.imageStatus.backgroundColor = UIColor(red: 244, green: 31, blue: 27)
        }
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        let distUnit = Global.getDistanceUnit() == "miles" ? " mph" : " kmh"
        self.labelSpeed.text = String(format: "%.0f",speed * metricScale) + distUnit
        if Global.shared.allAddress.keys.contains(self.cellData._id) { //&& !self.cellData.changeFlag {
            self.labelNearAddress.text = "Near " + Global.shared.allAddress[self.cellData._id]!
        } else {
            getNeadAddress(self.cellData.lat ?? 0.0,self.cellData.lng ?? 0.0,self.cellData._id)
        }
       
        self.row = row
        
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    func getNeadAddress(_ lat : Double, _ lng : Double, _ id : String){
        if let url = URL(string: "https://api.nettoolkit.com/v1/geo/reverse-geocodes?latitude="+lat.toString()+"&longitude="+lng.toString()+"&key=9pZmjAAHOLwLLmeDe54Y8epAGWrv53Fm8YhPgmI9") {
            URLSession.shared.dataTask(with: url) {
                data, response, error in
                let json = JSON.init(parseJSON: String(data: data!, encoding: .utf8)!)
                let result = json["results"].arrayValue
                if result.count > 0 {
                    DispatchQueue.main.async {
                        self.labelNearAddress.text = "Near " + result[0]["address"].stringValue
                        Global.shared.allAddress[id] = result[0]["address"].stringValue
                    }
                }
            }.resume()
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
    
    @IBAction func onSelectChange(_ sender: Any) {
        for item in tableView.tableData {
            item.isSelected = false
        }
        
        self.tableView.tableData[row].isSelected = true
        self.tableView.reloadData()

        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult(self.cellData, from: "AssetSingleSelectTableViewCell-selectedItem")
        }
    }
}
