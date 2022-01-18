import UIKit
import Alamofire
import SwiftyJSON

class UpdateCreditCardViewController: BaseViewController {

    @IBOutlet var txtNameOnCard: UITextField!
    @IBOutlet var txtCardNumber: UITextField!
    @IBOutlet var txtExpirationDate: UITextField!
    @IBOutlet var txtCVCode: UITextField!

    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "UpdateCreditCardViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.txtNameOnCard.text = ""
        self.txtCardNumber.text = ""
        self.txtExpirationDate.text = ""
        self.txtCVCode.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func onUpdateCreditCard(_ sender: Any) {
        
        let name = txtNameOnCard.text ?? ""
        let cardNumber = txtCardNumber.text ?? ""
        var expDate = txtExpirationDate.text ?? ""
        var cvCode = txtCVCode.text ?? ""
        
        expDate = expDate.replacingOccurrences(of: "/", with: "_")
        cvCode = cvCode.replacingOccurrences(of: " ", with: "")
        
        if(name == "") {
            self.view.makeToast("please enter name".localized())
            return
        }
        if(cardNumber == "") {
            self.view.makeToast("please enter card number".localized())
            return
        }
        if(expDate == "") {
            self.view.makeToast("please enter exp date".localized())
            return
        }
        if(cvCode == "") {
            self.view.makeToast("please enter cv code".localized())
            return
        }
        
        
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        
        let reqInfo = URLManager.tokenizeCreditCard()
        

        let parameters: Parameters = [
            "tractionType": "authorize",
            "card_holder_name": name,
            "card_number": cardNumber,
            "card_expiry": expDate,
            "card_cvv": cvCode
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
                
                let transaction_status = json["transaction_status"].stringValue
                if(transaction_status == "approved") {
                    
                    self.view.makeToast("card approved")

                    let item = CreditTokenInfoModel(
                        json["token"]["token_type"].stringValue,
                        json["token"]["token_data"]["token_data"].stringValue,
                        json["card"]["cardholder_name"].stringValue,
                        json["card"]["type"].stringValue,
                        json["card"]["exp_date"].stringValue)
                    
                    self.updateCreditCardInfo(item)
                    
                } else {
                    self.view.makeToast("Retry your credit card. If still not working, please contact us for assistance".localized())
                }
                
            } else {
                self.view.makeToast("error")
            }
            
        }
        
    }
    
    func updateCreditCardInfo(_ creditTokenInfo: CreditTokenInfoModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
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
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let userId = json["userId"].stringValue
                
                self.updateCreditCardInfoSecondary(userId, creditTokenInfo)
                
            } else {
                self.view.makeToast("failed to get user Id".localized())
            }
            
        }
        
    }
    
    func updateCreditCardInfoSecondary(_ userId: String, _ creditTokenInfo: CreditTokenInfoModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        self.showLoader()
        
        let reqInfo = URLManager.updateCreditCardInfoSecondary(userId)
        
        let parameters: Parameters = [
            "token_type": creditTokenInfo.token_type,
            "token_number": creditTokenInfo.token_number,
            "cardholder_name": creditTokenInfo.cardholder_name,
            "card_type": creditTokenInfo.card_type,
            "exp_date": creditTokenInfo.exp_date,
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            if(code == 200) {
                self.view.makeToast("You have successfully updated credit card info".localized())
            } else {
                self.view.makeToast("failed")
            }
            
        }
    }
    
}
