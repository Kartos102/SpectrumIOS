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

class RegisterViewController: BaseViewController {

    
    @IBOutlet var txtFirstName: UITextField!
    @IBOutlet var txtLastName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtPasswordConfirm: UITextField!
    
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "RegisterViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.txtFirstName.text = ""
//        self.txtLastName.text = ""
//        self.txtEmail.text = ""
//        self.txtPassword.text = ""
//        self.txtPasswordConfirm.text = ""
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
        
        let firstName = txtFirstName.text ?? ""
        let lastName = txtLastName.text ?? ""
        let email = txtEmail.text ?? ""
        let password = txtPassword.text ?? ""
        let passwordConform = txtPasswordConfirm.text ?? ""
        
        if(firstName == "") {
            self.view.makeToast("please enter first name".localized())
            return
        }
        
        if(lastName == "") {
            self.view.makeToast("please enter last name".localized())
            return
        }

        
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
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.".localized())
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authRegister()
        
        let parameters: Parameters = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName
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
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.dismiss(animated: true, completion: nil)
//                let verifyViewController = VerifyViewController.getNewInstance() as! VerifyViewController
//                verifyViewController.email = email
//                self.present(verifyViewController, animated: true, completion: nil)
//                self.view.makeToast("register success") { didTap in
//                }
                
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
