import UIKit
import Alamofire
import SwiftyJSON
import DropDown

import UIKit

class ShippingAddressViewController: BaseViewController {

    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtStreetAddress: UITextField!
    @IBOutlet var txtCity: UITextField!
    @IBOutlet var txtZipCode: UITextField!
    @IBOutlet var labelState: UILabel!
    @IBOutlet var btnSelectStatus: UIButton!
    
    var statusDropdown: DropDown!
    var selectedState: String!
    
    class InitData {
        var orderTrackerList = [OrderTrackerModel]()
    }
    
    var initData = InitData()
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ShippingAddressViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        initStatusDropdown()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onState(_ sender: Any) {
        self.view.endEditing(true)
        statusDropdown.show()
    }
    
    @IBAction func onMakePayment(_ sender: Any) {
        let name = txtName.text ?? ""
        let email = txtEmail.text ?? ""
        let streetAddress = txtStreetAddress.text ?? ""
        let city = txtCity.text ?? ""
        let zipCode = txtZipCode.text ?? ""
        let state = selectedState
        
        if(name == "") {
            self.view.makeToast("please enter name".localized())
            return
        }
        if(email == "") {
            self.view.makeToast("please enter email".localized())
            return
        }
        if(streetAddress == "") {
            self.view.makeToast("please enter street address".localized())
            return
        }
        if(city == "") {
            self.view.makeToast("please enter city".localized())
            return
        }
        if(zipCode == "") {
            self.view.makeToast("please zip code".localized())
            return
        }
        if(state == "") {
            self.view.makeToast("please enter state".localized())
            return
        }
        
        
        let checkoutVC = CheckoutViewController.getNewInstance() as! CheckoutViewController
        checkoutVC.initData.shippingAddress = ShippingAddressHolder(name, email, streetAddress, city, zipCode, state!)
        checkoutVC.initData.from = "ShippingAddressViewController"
        checkoutVC.initData.orderTrackerList = self.initData.orderTrackerList
        
        self.slideMenuController()?.changeMainViewController(checkoutVC, close: true)
        
        
        
        
    }
    
    func initStatusDropdown() {
        statusDropdown = DropDown()
        
        statusDropdown.dataSource = [
            "Alabama",
            "Alaska",
            "Arizona",
            "Arkansas",
            "California",
            "Colorado",
            "Connecticut",
            "Delaware",
            "District Of Columbia",
            "Florida",
            "Georgia",
            "Hawaii",
            "Idaho",
            "Illinois",
            "Indiana",
            "Iowa",
            "Kansas",
            "Kentucky",
            "Louisiana",
            "Maine",
            "Maryland",
            "Massachusetts",
            "Michigan",
            "Minnesota",
            "Mississippi",
            "Missouri",
            "Montana",
            "Nebraska",
            "Nevada",
            "New Hampshire",
            "New Jersey",
            "New Mexico",
            "New York",
            "North Carolina",
            "North Dakota",
            "Ohio",
            "Oklahoma",
            "Oregon",
            "Pennsylvania",
            "Rhode Island",
            "South Carolina",
            "South Dakota",
            "Tennessee",
            "Texas",
            "Utah",
            "Vermont",
            "Virginia",
            "Washington",
            "West Virginia",
            "Wisconsin",
            "Wyoming"
        ]
        statusDropdown.anchorView = btnSelectStatus
        statusDropdown.backgroundColor = UIColor.groupTableViewBackground
        statusDropdown.bottomOffset = CGPoint(x: 0, y:(statusDropdown.anchorView?.plainView.bounds.height)!)
        statusDropdown.direction = .bottom
        
        selectedState = statusDropdown.dataSource.first!

        statusDropdown.selectionAction = { (index: Int, title: String) in
            self.selectedState = title
            self.labelState.text = self.selectedState
        }
        labelState.text = selectedState
    }
}
