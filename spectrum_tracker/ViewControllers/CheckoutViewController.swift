import UIKit
import Alamofire
import SwiftyJSON
import DropDown
import LGButton
import UIKit

class CheckoutViewController: BaseViewController {


    @IBOutlet var txtNameOnCard: UITextField!
    @IBOutlet var txtStreetAddress: UITextField!
    @IBOutlet var txtCity: UITextField!
    @IBOutlet weak var txtState: UITextField!
    @IBOutlet var txtZip: UITextField!
    @IBOutlet var txtCardNumber: UITextField!
    @IBOutlet var txtExpirationDate: UITextField!
    @IBOutlet var txtCVCode: UITextField!
    @IBOutlet weak var btnSelectCountry: UIButton!
    @IBOutlet weak var lblCountry: UILabel!
//    @IBOutlet var btnSelectState: UIButton!
//    @IBOutlet var labelState: UILabel!
    
    @IBOutlet weak var txtLast4Digits: CustomTextField!
    @IBOutlet weak var txtOldCVCode: CustomTextField!
    @IBOutlet weak var txtOldExpirationDate: CustomTextField!
    
    @IBOutlet var modalView: UIView!
    @IBOutlet var orderSummaryTableView: OrderSummaryTableView!
    
    @IBOutlet weak var oldCardView: UIStackView!
    @IBOutlet weak var newCardView: UIStackView!
    @IBOutlet var labelServicePlan: UILabel!
    @IBOutlet var labelLTEPlan: UILabel!
    @IBOutlet var labelTax: UILabel!
    @IBOutlet var labelTotal: UILabel!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet weak var placeYourOrderButton: UIButton!
    
    @IBOutlet weak var placeOrderButton: LGButton!
    var paymentCompleteHandler: (() -> ())? = nil

    @IBAction func onDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var switchCard: UISegmentedControl!
    @IBAction func onSwitchCard(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            newCardView.isHidden = false
            oldCardView.isHidden = true
        }else {
            newCardView.isHidden = true
            oldCardView.isHidden = false
        }
    }
    
    var userId: String! = ""  // get after auth api called
    
    var statusDropdown: DropDown!
    var coutriesDropdown: DropDown!
    var selectedState: String!
    var selectedCountry: String = ""
    
    class InitData {
        var shippingAddress: ShippingAddressHolder!
        var from: String!
        var orderTrackerList = [OrderTrackerModel]() // used when from is "ShippingAddressViewController"
        var orderServiceItemList = [OrderServiceModel]() // used when from is "OrderServiceViewController"
    }
    
    var initData = InitData()
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "CheckoutViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
//        initStatusDropdown()
        initCoutriesDropdown()
        doAuth()
        modalView.isHidden = true
        modalView.alpha = 0
        
        
        
        if initData.from == "OrderServiceViewController" {
            
            
            
            
            var itemList = self.initData.orderServiceItemList
            
            var sum1: Double = 0
            var sum2: Double = 0
            
            var index = 0
            
            var orderSummaryList = [OrderSummaryModel]()
            
            for i in 0..<itemList.count  {
                
                let item = itemList[i]

                index = index + 1
                
                let tracker = item.name
                
                let dataPlan = "$" + item.servicePlanList[item.selectedServicePlanId].price.priceString()
                let LTEData = "$" + item.lteDataList[item.selectedLTEDataId].price.priceString()
                
                var dateTd = item.expirationDate.toDate("yyyy-MM-dd") ?? Date()
                
                if dateTd.setTime() > Date().setTime() {
                    dateTd = Date()
                }
                
                if dataPlan.contains("No Service") || dataPlan == "" {
                    dateTd = dateTd.date(plusMonth: 1)
                } else if dataPlan.contains("Annual") {
                    dateTd = dateTd.date(plusMonth: 1)
                    dateTd = dateTd.date(plusYear: 1)
                } else {
                    dateTd = dateTd.date(plusMonth: 2)
                }
                
                let autoRenew = item.autoReview!
                
                let orderSummary = OrderSummaryModel()
                
                orderSummary.vehicle = "Vehicle #" + index.toString()
                orderSummary.tracker = tracker ?? ""
                orderSummary.dateTd = dateTd.toString("yyyy-MM-dd")
                orderSummary.dataPlan = dataPlan
                orderSummary.LTEData = LTEData
                orderSummary.autoRenew = autoRenew ? "true" : "false"
                
                
                orderSummaryList.append(orderSummary)
                
                sum1 = sum1 + item.servicePlanList[item.selectedServicePlanId].price
                sum2 = sum2 + item.lteDataList[item.selectedLTEDataId].price

            }
            
            let amount = sum1 + sum2
            
            self.orderSummaryTableView.setData(orderSummaryList)
            self.orderSummaryTableView.reloadData()
            
            self.labelServicePlan.text = "$" + sum1.priceString()
            self.labelLTEPlan.text = "$" + sum2.priceString()
            self.labelTax.text = "$0.00"
            self.labelTotal.text = "$" + amount.priceString()
            self.labelTime.text = Date().toString("MM/dd/yyyy hh:mm:ss a")
            self.placeOrderButton.titleString = "PLACE ORDER $" + amount.priceString()
            
            
            self.modalView.alpha = 0
            self.modalView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.modalView.alpha = 1
                
            })
        }
        
        
        
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
    
    @IBAction func onCountry(_ sender: Any) {
        self.view.endEditing(true)
        self.coutriesDropdown.show()
    }
    
    @IBAction func onOKAY(_ sender: Any) {
        UIView.animate(withDuration: 0.2, animations: {
            self.modalView.alpha = 0
            
        }) { (value) in
            self.modalView.isHidden = true
        }
        
    }
    
    @IBAction func onPlaceOrder(_ sender: Any) {
        if initData.from == "ShippingAddressViewController" {
            
                self.placeYourOrderButton.isEnabled = false
                self.doWorkForOrderTracker(userId)
                
            
        } else if initData.from == "OrderServiceViewController" {
           
                self.placeYourOrderButton.isEnabled = false
                self.doWorkForOrderService(userId)
          
        }
    }
    @IBAction func onPlaceYourOrder(_ sender: Any) {
//steed
//        self.mainViewController = MonitorViewController.getNewInstance()
//        return
        
        if initData.from == "ShippingAddressViewController" {
            
                self.placeYourOrderButton.isEnabled = false
                self.doWorkForOrderTracker(userId)
             
        } else if initData.from == "OrderServiceViewController" {
           
                self.placeYourOrderButton.isEnabled = false
                self.doWorkForOrderService(userId)
           
        }
        
    }
    
    func make_order_summary_html(_ itemList: [OrderServiceModel], _ servicePlanListSum: Double, _ lteDataListSum: Double, _ amount: Double) -> String {
        
        var sendHtml = ""
        
        sendHtml = sendHtml + "<p style='text-align:center; font-size:20px; color:blue;'>Order Summary</p>"
        sendHtml = sendHtml + "<br>"
        sendHtml = sendHtml + "<replace_data>"
        
        sendHtml = sendHtml + "<table class='order-summay' cellspacing='10' width='390'>"
        sendHtml = sendHtml + "<tbody>"
        
        
        sendHtml = sendHtml + "<tr>"
        
        let upTax: Double! = 1.0
        let downTax: Double! = 0
        
        
        let taxPrice = amount * downTax
        let totalSum = amount * upTax
        
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Service Plan:</td><td class='order-summay-right-text'>" + servicePlanListSum.priceString() + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>LTE Plan: </td><td class='order-summay-right-text'>" + lteDataListSum.priceString() + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Tax: </td><td class='order-summay-right-text'>" + "$" + taxPrice.priceString() + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Total: </td><td class='order-summay-right-text'>" + "$" + totalSum.priceString() + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        let now = Date()
        sendHtml = sendHtml + "<td>Time: </td><td class='order-summay-right-text'>" + now.toString("yyyy/MM/dd HH:mm:ss") + "</td>"
        
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "</tbody>"
        sendHtml = sendHtml + "</table>"

        
        return sendHtml
    }
    
    func doWorkForOrderService(_ userId: String) {
        let itemList = self.initData.orderServiceItemList
        
        var paymentItmes: [JSON] = []
        
        
        
        for item in itemList {
            if item.servicePlanList.count != 1 {
                let servicePlan = item.servicePlanList[item.selectedServicePlanId].servicePlan ?? ""
                let planText = item.lteDataList[item.selectedLTEDataId].lteData ?? ""
                
                
                paymentItmes.append(JSON([
                    "renew": item.autoReview ? "Yes" : "No",
                    "textPlan": planText,
                    "service": true,
                    "trackerId": item.trackerId]
                ))
                                
                paymentItmes.append(JSON([
                    "renew": item.autoReview ? "Yes" : "No",
                    "service": true,
                    "trackPlan": servicePlan,
                    "trackerId": item.trackerId]
                ))
                
            } else {
                let servicePlan = item.servicePlanList[item.selectedServicePlanId].servicePlan ?? ""
                paymentItmes.append(JSON([
                    "service": true,
                    "renew": item.autoReview ? "Yes": "No",
                    "trackPlan": servicePlan,
                    "trackerId": item.trackerId]
                ))
            }
        }
        
        var amount: Double! = 0
        
        var servicePlanListSum: Double! = 0
        var lteDataListSum: Double! = 0
        
        for item in itemList {
            servicePlanListSum = servicePlanListSum + item.servicePlanList[item.selectedServicePlanId].price
            lteDataListSum = lteDataListSum + item.lteDataList[item.selectedLTEDataId].price
        }
        
        amount = servicePlanListSum + lteDataListSum
        if switchCard.selectedSegmentIndex == 1 {
        
        
            if(txtNameOnCard.text == "") {
                self.view.makeToast("please enter name on card")
                return
            }
            
            if(txtZip.text == "") {
                self.view.makeToast("please enter zip")
                return
            }
            
            if(txtCardNumber.text == "") {
                self.view.makeToast("please enter card number")
                return
            }
            
            if(txtExpirationDate.text == "") {
                self.view.makeToast("please enter expiration date")
                return
            }
            
            if(txtCVCode.text == "") {
                self.view.makeToast("please enter cv code")
                return
            }
            
            if(txtExpirationDate.text!.count > 5) {
                self.view.makeToast("please enter correct expiration date")
                return
            }
        
        }else {
            if txtOldCVCode.text == "" {
                self.view.makeToast("please enter cv code")
                return
            }
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
            // do some tasks..
        }
        
        self.showLoader()
        
        let reqInfo = URLManager.ordersPayment()
        var parameters: Parameters = [:]
        if switchCard.selectedSegmentIndex == 1 {
            parameters = [
                "paymentType":"card",
                "transactionType": "purchase",
                "card_holder_name": txtNameOnCard.text ?? "",
                "card_holder_address": txtStreetAddress.text ?? "",
                "card_holder_city": txtCity.text ?? "",
                "card_holder_zip": txtZip.text ?? "",
                "card_holder_state": txtState.text ?? "",
                "card_holder_country": lblCountry.text ?? "",
                "card_number": txtCardNumber.text ?? "",
                //"card_expiry": (txtExpirationDate.text ?? "").replacingOccurrences(of: "/", with: "_"),
                "card_expiry": (txtExpirationDate.text ?? "").replacingOccurrences(of: "/", with: ""),
                "card_cvv": txtCVCode.text ?? "",
                "currency_code": "USD",
                "amount": amount,
                "items": JSON(paymentItmes).rawString() ?? "",
                "auth": userId,
                "productService": "service",
                "sendHtml": make_order_summary_html(itemList, servicePlanListSum, lteDataListSum, amount)
            ]
        }else {
            parameters = [
                "paymentType":"token",
                "transactionType": "purchase",
                "card_cvv": txtOldCVCode.text ?? "",
                "currency_code": "USD",
                "amount": amount,
                "items": JSON(paymentItmes).rawString() ?? "",
                "auth": userId,
                "productService": "service",
                "sendHtml": make_order_summary_html(itemList, servicePlanListSum, lteDataListSum, amount)
            ]
        }
        
        
        let headers: HTTPHeaders = [
            :
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let success = json["success"].boolValue
                
                if success {
                    self.view.makeToast("Your have successfully made payment. The confirmation has been sent to your email")
                    self.paymentCompleteHandler?()
                    self.dismiss(animated: true)
                } else {
                    self.placeYourOrderButton.isEnabled = true
                    self.view.makeToast("some error occured")
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                let errorMsg = error.message == "" ? "failed" : error.message
                self.view.makeToast(errorMsg)
                self.placeYourOrderButton.isEnabled = true
            }
            
        }
        
    }
    
    func make_tracker_service_html(_ itemList: [OrderTrackerModel]) -> String {
        var sendHtml = ""
        let customer_name = self.initData.shippingAddress.name
        let card_number = txtCardNumber.text ?? ""
        var card_type = "false"
        
        if (card_number.first ?? "0") == "3" {
            card_type = "American Express"
        }
        if (card_number.first ?? "0") == "4" {
            card_type = "Visa"
        }
        if (card_number.first ?? "0") == "5" {
            card_type = "Mastercard"
        }
        if (card_number.first ?? "0") == "6" {
            card_type = "Discover"
        }
        
        sendHtml = "<p style='text-align:center; font-size:20px; color:blue;'>Order Summary</p>"
        sendHtml = sendHtml + " <br>  "
        sendHtml = sendHtml + "<h3>Dear " + customer_name! + ", thank-you for ordering from us!  Here is a summary of your purchase order. </h3>"
        sendHtml = sendHtml + "<table class='order-summay' cellspacing='10' width='390'>"
        sendHtml = sendHtml + "<tbody>";
        sendHtml = sendHtml + "<tr>"
        
        sendHtml = sendHtml + "<td>Email: </td><td class='order-summay-right-text'>" + initData.shippingAddress.email + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Name: </td><td class='order-summay-right-text'>" + initData.shippingAddress.name + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Card type: </td><td class='order-summay-right-text'>" + card_type + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        
        sendHtml = sendHtml + "<td>Card last 4 digits: </td><td class='order-summay-right-text'>" + String(card_number.suffix(4)) + "</td>"
        
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        
        sendHtml = sendHtml + "<td>Shipping Address: </td><td class='order-summay-right-text'>" + initData.shippingAddress.streetAddress + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td> </td><td class='order-summay-right-text'>" + initData.shippingAddress.streetAddress + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td> </td><td class='order-summay-right-text'>"
        sendHtml = sendHtml + initData.shippingAddress.streetAddress
        sendHtml = sendHtml + "  " + initData.shippingAddress.state
        sendHtml = sendHtml + "  " + initData.shippingAddress.zipCode + "</td>"
        sendHtml = sendHtml + "</tr>"
        
        var subTotal: Double! = 0
        
        for item in itemList {
            let productName: String! = item.name
            let unit: Int! = item.count
            sendHtml = sendHtml + "<tr>"
            sendHtml = sendHtml + "<td>Product:</td><td class='order-summay-right-text'> " + productName + "</td>"
            sendHtml = sendHtml + "</tr>"
            sendHtml = sendHtml + "<tr>"
            sendHtml = sendHtml + "<td>Unit : </td><td class='order-summay-right-text'> " + unit.toString() + "</td>"
            sendHtml = sendHtml + "</tr>"
            subTotal = subTotal + Double(item.count) * item.price;
        }
        
        sendHtml = sendHtml + "<tr>"
        
        var upTax: Double! = 1.0
        var downTax: Double! = 0.0
        
        if selectedState == "Kentucky" {
            upTax = 1.06
            downTax = 0.06
        } else {
            upTax = 1.00
            downTax = 0.00
        }
        
        let taxPrice: Double! = subTotal * downTax
        let totalPrice: Double! = subTotal * upTax
        
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Products:</td><td class='order-summay-right-text'>" + "$" + String(subTotal) + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Shipping: </td><td class='order-summay-right-text'>" + "$" + String(totalPrice) + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        sendHtml = sendHtml + "<td>Tax: </td><td class='order-summay-right-text'>" + "$" + String(taxPrice) + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "<tr>"
        
        sendHtml = sendHtml + "<tr>"
        let now = Date()

        sendHtml = sendHtml + "<td>Time: </td><td class='order-summay-right-text'>" + now.toString("yyyy/MM/dd HH:mm:ss") + "</td>"
        sendHtml = sendHtml + "</tr>"
        sendHtml = sendHtml + "</tbody>"
        sendHtml = sendHtml + "</table>"
        
        return sendHtml
        
    }
    
    func doWorkForOrderTracker(_ userId: String) {
        let itemList = self.initData.orderTrackerList
        
        let paymentItmes: [JSON]! = []
        
        var amount: Double! = 0
        var subTotal:Double! = 0
        
        for item in itemList {
            subTotal = subTotal + item.price * Double(item.count)
        }
        
        let upTax: Double! = 1
        var shipping: Double! = 0
        let defaultShipping: Double! = 0
        shipping = (subTotal > 0 && subTotal < (100 / upTax)) ? defaultShipping : 0
        
        amount = subTotal * upTax + shipping
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
            // do some tasks..
        }
        
        self.showLoader()
        
        let reqInfo = URLManager.ordersPayment()
        
        
        let parameters: Parameters = [
            "transactionType": "purchase",
            "card_holder_name": txtNameOnCard.text ?? "",
            "card_holder_address": txtStreetAddress.text ?? "",
            "card_holder_city": txtCity.text ?? "",
            "card_holder_zip": txtZip.text ?? "",
            "card_holder_state": txtState.text ?? "",
            "card_holder_country": lblCountry.text ?? "",
            "card_number": txtCardNumber.text ?? "",
            "card_expiry": (txtExpirationDate.text ?? "").replacingOccurrences(of: "/", with: "_"),
            "card_cvv": txtCVCode.text ?? "",
            "currency_code": "USD",
            "amount": amount,
            "items": JSON(paymentItmes).rawString() ?? "",
            "auth": userId,
            "productService": "card",
            "sendHtml": make_tracker_service_html(itemList)
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let success = json["success"].boolValue
                
                if success {
                    self.view.makeToast("Your have successfully made payment. The confirmation has been sent to your email")
                    self.paymentCompleteHandler?()
                    self.dismiss(animated: true)
                } else {
                    self.placeYourOrderButton.isEnabled = true
                    self.view.makeToast("some error occured")
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                let errorMsg = error.message == "" ? "failed" : error.message
                self.view.makeToast(errorMsg)
                self.placeYourOrderButton.isEnabled = true
            }
            
        }
        
        
        
    }
    
    func doAuth() {
        
        
        
        self.view.endEditing(true)
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
            // do some tasks..
        }
        
        self.showLoader()
        
        let reqInfo = URLManager.doAuth()
        
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            print(json)
            if(code == 200) {
                
                self.userId = json["userId"].stringValue
                if json["last4Digits"].exists() && json["exp_date"].exists() {
                    self.txtLast4Digits.text = json["last4Digits"].stringValue
                    self.txtOldExpirationDate.text = json["exp_date"].stringValue
                }
                
            } else {
                self.view.makeToast("failed to get user Id")
            }
            
        }
    }
    
    func initCoutriesDropdown() {
        coutriesDropdown = DropDown()
        
        coutriesDropdown.dataSource = countryList
        coutriesDropdown.anchorView = btnSelectCountry
        coutriesDropdown.backgroundColor = UIColor.groupTableViewBackground
        coutriesDropdown.bottomOffset = CGPoint(x: 0, y:(coutriesDropdown.anchorView?.plainView.bounds.height)!)
        coutriesDropdown.direction = .bottom
        
        selectedCountry = coutriesDropdown.dataSource.first!
        
        coutriesDropdown.selectionAction = { (index: Int, title: String) in
            self.selectedCountry = title
            self.lblCountry.text = self.selectedCountry
        }
        
        lblCountry.text = selectedCountry
    }
    
//    func initStatusDropdown() {
//        statusDropdown = DropDown()
//
//        statusDropdown.dataSource = [
//            "Alabama",
//            "Alaska",
//            "Arizona",
//            "Arkansas",
//            "California",
//            "Colorado",
//            "Connecticut",
//            "Delaware",
//            "District Of Columbia",
//            "Florida",
//            "Georgia",
//            "Hawaii",
//            "Idaho",
//            "Illinois",
//            "Indiana",
//            "Iowa",
//            "Kansas",
//            "Kentucky",
//            "Louisiana",
//            "Maine",
//            "Maryland",
//            "Massachusetts",
//            "Michigan",
//            "Minnesota",
//            "Mississippi",
//            "Missouri",
//            "Montana",
//            "Nebraska",
//            "Nevada",
//            "New Hampshire",
//            "New Jersey",
//            "New Mexico",
//            "New York",
//            "North Carolina",
//            "North Dakota",
//            "Ohio",
//            "Oklahoma",
//            "Oregon",
//            "Pennsylvania",
//            "Rhode Island",
//            "South Carolina",
//            "South Dakota",
//            "Tennessee",
//            "Texas",
//            "Utah",
//            "Vermont",
//            "Virginia",
//            "Washington",
//            "West Virginia",
//            "Wisconsin",
//            "Wyoming"
//        ]
//        statusDropdown.anchorView = btnSelectState
//        statusDropdown.backgroundColor = UIColor.groupTableViewBackground
//        statusDropdown.bottomOffset = CGPoint(x: 0, y:(statusDropdown.anchorView?.plainView.bounds.height)!)
//        statusDropdown.direction = .bottom
//
//        selectedState = statusDropdown.dataSource.first!
//
//        statusDropdown.selectionAction = { (index: Int, title: String) in
//            self.selectedState = title
//            self.labelState.text = self.selectedState
//        }
//
//        labelState.text = selectedState
//    }
}
