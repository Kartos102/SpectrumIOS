//
//  RegisterViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ForgetViewController: BaseViewController {

    
    var email = ""
    
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtPassword: UITextField!
    
    @IBOutlet weak var txtConfirm: UITextField!
    @IBOutlet weak var txtVerification: UITextField!
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ForgetViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.txtEmail.text = email
        self.txtPassword.text = ""
        self.txtConfirm.text = ""
        self.txtVerification.text = ""
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func onRegister(_ sender: Any) {
        
        self.view.endEditing(true)

        let email = (txtEmail.text ?? "").lowercased()
        let password = txtPassword.text ?? ""
        let passwordConform = txtConfirm.text ?? ""
        let verificationCode = txtVerification.text ?? ""
        
        
        if(email == "") {
            self.view.makeToast("please enter email".localized())
            return
        }

        
        if(password == "") {
            self.view.makeToast("please enter password".localized())
            return
        }
        
        if(password != passwordConform) {
            self.view.makeToast("password confirm does not match".localized())
            return
        }

        if(verificationCode == "") {
            self.view.makeToast("please enter verification Code".localized())
            return
        }
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authResetPassword()
        
        let parameters: Parameters = [
            "email": email,
            "password": password,
            "confirm-password": passwordConform,
            "code": verificationCode
        ]
        
        let headers: HTTPHeaders = [:]
        
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
                self.view.makeToast("reset success".localized()) { didTap in
                    self.dismiss(animated: true, completion: nil)
                }
                return;
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }

        
    }
    

    @IBAction func onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
