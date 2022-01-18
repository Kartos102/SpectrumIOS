import Foundation
import UIKit
import SwiftyJSON
import Alamofire

class AssetMultiSelectMoniterTableView: UITableView {
    
    var tableData = [TrackerModel]()
    let reuseIdentifier = "AssetMultiSelectMoniterTableViewCell"
    let nibName = "AssetMultiSelectMoniterTableView"
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.parentVC is ViewControllerWaitingResult {
            (self.parentVC as! ViewControllerWaitingResult).setTableViewHeight(scrollView.contentOffset.y)
        }
    }
    
    func getHeight() -> CGFloat {
        return CGFloat(CGFloat(tableData.count) * 100)
    }
}

// UITableViewDelegate
extension AssetMultiSelectMoniterTableView: UITableViewDelegate {
    
}

// UITableViewDataSource
extension AssetMultiSelectMoniterTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! AssetMultiSelectMoniterTableViewCell
        
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

class AssetMultiSelectMoniterTableViewCell : UITableViewCell {
    
    var cellData: TrackerModel!
    var tableView: AssetMultiSelectMoniterTableView!
    
    var row: Int!
    var imageUrl: String!
    
    @IBOutlet var wrapperView: UIView!
    @IBOutlet var btnSelect: UIButton!
    @IBOutlet var userPhoto: UIImageView!
    @IBOutlet var topSpace: NSLayoutConstraint!
    @IBOutlet var handler: UIView!
    @IBOutlet var labelDriverName: UILabel!
    @IBOutlet var labelLastUpdate: UILabel!
    @IBOutlet var labelNearAddress: UILabel!
    @IBOutlet var labelSpeed: UILabel!
    @IBOutlet var imageStatus: UIImageView!
    @IBOutlet weak var optionButton: UIButton!
    
    @IBOutlet weak var labelBattery: UILabel!
    @IBOutlet weak var iconBattery: UIImageView!
    @IBOutlet weak var labelTemp: UILabel!
    @IBOutlet weak var iconTemp: UIImageView!
    @IBOutlet weak var labelRPM: UILabel!
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
    
    func setCellData(_ data: TrackerModel, TableView tableView: AssetMultiSelectMoniterTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        
        self.btnSelect.isSelected = self.cellData.isSelected
        self.labelDriverName.text = self.cellData.driverName
        
        self.userPhoto.layer.cornerRadius =  self.userPhoto.frame.height / 2
        self.userPhoto.layer.masksToBounds = true
        //self.userPhoto.image = UIImage(named: "driver_empty")
        self.userPhoto.layer.borderWidth = 1.2
        self.userPhoto.layer.borderColor = UIColor(hexInt: 0xFF0066).cgColor
        if self.cellData.latLngDateTime != nil {
            self.labelLastUpdate.text = "Update:".localized() + " " + self.cellData.latLngDateTime!.toString("MM/dd HH:mm")
        } else {
            self.labelLastUpdate.text = ""
        }
        iconTemp.image = iconTemp.image?.withRenderingMode(.alwaysTemplate)
        iconTemp.tintColor = UIColor(hexString: "#f96f00")
        iconBattery.image = iconBattery.image?.withRenderingMode(.alwaysTemplate)
        iconBattery.tintColor = UIColor(hexString: "#008000")
        let rpm = self.cellData.rpm
        labelRPM.text = String(format: "%.1f",rpm) + " RPM"
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
        
        getImageUrl("driver_" + self.cellData.assetId + ".jpg", trackerId: self.cellData._id)
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
                if data != nil {
                    let json = JSON.init(parseJSON: String(data: data!, encoding: .utf8)!)
                    let result = json["results"].arrayValue
                    if result.count > 0 {
                        DispatchQueue.main.async {
                            self.labelNearAddress.text = "Near " + result[0]["address"].stringValue
                            Global.shared.allAddress[id] = result[0]["address"].stringValue
                        }
                    }
                }            }.resume()
                
            
        }
    }
    func getImageUrl(_ fileName : String, trackerId: String){
        let reqInfo = URLManager.getImageUrl()
        
        let parameters: Parameters = [
            "name" : fileName
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default , headers: headers)
        request.responseString {
            dataResponse in
            
            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.tableView.parentVC?.view.makeToast("server connect error".localized())
                return
            }
            let json = JSON.init(parseJSON: dataResponse.value!)
            if(json["success"].boolValue) {
                self.imageUrl = json["url"].stringValue
                Global.shared.driverPhotos[trackerId] = self.imageUrl
                
                let url = URL(string: self.imageUrl)
                self.userPhoto.load(url!)
            }
            else {
                self.userPhoto.image = UIImage(named: "driver_empty")
            }
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
    
    @IBAction func onPhotoUploadAction(_ sender: Any) {
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((row, isSelected), from: "photoUpload")
        }
    }
    
    @IBAction func onOptionAction(_ sender: Any) {
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((row, isSelected), from: "dotOption", sender: optionButton)
        }
    }
    
    @IBAction func onReplayAction(_ sender: Any) {
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((row, isSelected), from: "AssetMultiSelectTableViewCell-replay")
        }
    }
    @IBAction func onSelectChange(_ sender: Any) {
        
        let isSelected = !self.tableView.tableData[row].isSelected
        
        self.tableView.tableData[row].isSelected = isSelected
        
        if isSelected {
            Global.shared.selectedTrackerIds.append(tableView.tableData[row]._id)
        } else {
            if let index = Global.shared.selectedTrackerIds.firstIndex(of: tableView.tableData[row]._id) {
                Global.shared.selectedTrackerIds.remove(at: index)
            }
        }
        
        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult((row, isSelected), from: "AssetMultiSelectTableViewCell-selectedItem")
        }
    }
}
