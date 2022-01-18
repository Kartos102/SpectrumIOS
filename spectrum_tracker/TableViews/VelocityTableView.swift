import Foundation
import UIKit
import DropDown
import MapboxGeocoder

class VelocityTableView: UITableView {
    
    var tableData = [TrackerModel]()
    var cellHeight:CGFloat = 0;
    let reuseIdentifier = "VelocityTableViewCell"
    let nibName = "VelocityTableView"
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
        cellHeight = cell.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeights[indexPath] {
            return height ?? UITableView.automaticDimension
        }
        return UITableView.automaticDimension
    }

    
    // for this table view only to calculate table height
    func getHeight() -> CGFloat {
        return CGFloat(CGFloat(tableData.count) * 90)
    }
    
}

// UITableViewDelegate
extension VelocityTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension VelocityTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! VelocityTableViewCell
        let value = tableData[indexPath.section]
        
        cell.setCellData(value, TableView: self, Row: indexPath.section)
       
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

class VelocityTableViewCell : UITableViewCell {

    var cellData: TrackerModel!
    var tableView: VelocityTableView!

    @IBOutlet var wrapperView: UIStackView!
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelSpeed: UILabel!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var labelVoltage: UILabel!
    @IBOutlet var labelLastStart: UILabel!
    @IBOutlet var labelLastStop: UILabel!
    @IBOutlet var labelAlertTitle: UILabel!
    @IBOutlet var labelAlert: UILabel!
    @IBOutlet weak var labelFuel: UILabel!
    @IBOutlet var labelDayTrip: UILabel!
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var labelWiFiDataTitle: UILabel!
    @IBOutlet weak var labelWifiData: UILabel!
    @IBOutlet var labelMonthTrip: UILabel!
    @IBOutlet var labelYearTrip: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask1: URLSessionDataTask?
    var geocodingDataTask2: URLSessionDataTask?
    var vehicleExist: Bool = false
    var accOnChanged: Bool = true
    var accOffChanged: Bool = true
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
    
    func setCellData(_ data: TrackerModel, TableView tableView: VelocityTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
       /* print("\(self.labelName.text):\(self.cellData.0.name)")
        if(self.labelName.text != "--") {
            self.vehicleExist = true
        }
        else {
            self.vehicleExist = false
        }*/
        if !self.cellData.name.isEmpty {
            self.labelName.text = self.cellData.name
        } else {
            self.labelName.text = self.cellData.plateNumber
        }
        
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        self.labelSpeed.text = String(format: "%.1f",self.cellData.speedInMph * metricScale)
        if(self.cellData.accStatus == 0 || self.cellData.speedInMph == 0) {
            self.labelStatus.text = "Park"
            self.labelSpeed.text = "0"
        }
        else {
            self.labelStatus.text = "Drive"
        }
        if(self.cellData.trackerModel.lowercased() == "huaheng") {
            if self.cellData.voltage != 0.0 {
                self.labelVoltage.text = String(self.cellData.voltage)
            } else {
                self.labelVoltage.text = String(self.cellData.battery)
            }
            if(Float(self.cellData.tankVolume * 100) > 100) {
               // self.labelFuel.text = "100"
            }
            else {
               // self.labelFuel.text = String(Float(self.cellData.1.tankVolume * 100))
            }
        }
        else {
            self.labelVoltage.text = "N/A"
         //   self.labelFuel.text = "N/A"
        }
        if self.cellData.lastACCOntime != nil {
            self.labelLastStart.text = self.cellData.lastACCOntime?.toString("MM/dd HH:mm")
        }
        else {
            self.labelLastStart.text = "N/A"
        }
        if self.cellData.lastACCOfftime != nil {
            self.labelLastStop.text = self.cellData.lastACCOfftime?.toString("MM/dd HH:mm")
        }
        else {
            self.labelLastStop.text = "N/A"
        }
        if self.cellData.expirationDate != nil {
            self.labelVoltage.text = self.cellData.expirationDate?.toString("YYYY/MM/dd")
        }
        //self.labelThisTrip.text = String(format:"%.1f",self.cellData.1.weekMile)
        self.labelDayTrip.text = String(format:"%.1f",self.cellData.dayMile)
        self.labelMonthTrip.text = String(format:"%.1f",self.cellData.monthMile)
        self.labelYearTrip.text = String(format:"%.1f",self.cellData.yearMile)
        
        self.labelFuel.text = String(format: "%.1f", self.cellData.tankVolume)
        self.labelBattery.text = String(format: "%.1f", self.cellData.voltage)
        
        if self.cellData.hotspot == 1 {
            self.labelWiFiDataTitle.text = "WiFi Data"
            let dataLimit = Float(Int(cellData.dataLimit * 100)) / 100
            let dataVolume = Float(Int(cellData.dataVolumeCustomerCycle * 100)) / 100
            self.labelWifiData.text = String(format: "%.1f", dataLimit - dataVolume)
        } else {
            self.labelWiFiDataTitle.text = "RPM"
            self.labelWifiData.text = String(format: "%.1f", self.cellData.rpm)
        }
        
        if self.cellData.speedInMph > 30 {
            self.labelAlertTitle.text = "Alert".localized()
            self.labelAlert.text = String(self.cellData.lastAlert)
        } else {
            self.labelAlertTitle.text = "Last report".localized()
            if self.cellData.lastLogDateTime != nil {
                self.labelAlert.text = self.cellData.lastLogDateTime?.toString("MM/dd hh:mm a")
            }
        }
        
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
//    func UTCToLocal(date:String, fromFormat: String, toFormat: String) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = fromFormat
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        
//        let dt = dateFormatter.date(from: date)
//        dateFormatter.timeZone = TimeZone.current
//        dateFormatter.dateFormat = toFormat
//        
//        return dateFormatter.string(from: dt!)
//    }
    
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
//        self.contentView.backgroundColor = UIColor.clear
//        self.backgroundColor = UIColor.clear
        
        self.selectionStyle = .none
    }
    
}
