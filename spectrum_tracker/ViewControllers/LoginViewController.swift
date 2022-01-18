//
//  LoginViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftyUserDefaults
import FacebookLogin
import FBSDKLoginKit
class LoginViewController: BaseViewController, FBSDKLoginButtonDelegate{
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            
        }
        else if result.isCancelled {
            print("Cancelled")
        }
        else {
            self.goToMain()
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        return
    }
    
    
    
    @IBOutlet var btn_login: UIButton!
    @IBOutlet var FacebookSignInButton: FBSDKLoginButton!
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var labelCopyright: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var btn_remember: UIButton!
    var rFlag: Bool! = false
    
    @IBAction func onRemember(_ sender: Any) {
        rFlag = !rFlag
        print(rFlag)
        if(rFlag) {
            btn_remember.setImage(UIImage(named: "ic_checkbox_selected"),for:.normal)
        }
        else {
            btn_remember.setImage(UIImage(named: "ic_checkbox_normal"),for:.normal)
        }
    }
    
    @IBAction func onTermsofService(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/Legal.html") else {return}
        UIApplication.shared.open(url)
    }
    @IBAction func onPrivacyPolicy(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/Privacy.html") else {return}
        UIApplication.shared.open(url)
    }
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "LoginViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var forgotPasswordDlg: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = Defaults[.sautolock] ?? false
        print(UIApplication.shared.isIdleTimerDisabled)
        forgotPasswordDlg.isHidden = true
        forgotPasswordDlg.alpha = 0
        labelCopyright.text = "Copyright @ " + Date().year().toString() + " Spectrum Tracking | All rights reserved"
        
        self.rFlag = Defaults[.remember] ?? false
        let isLoggedIn = Defaults[.isLoggedIn] ?? false
        
        if self.rFlag {
            let username = Defaults[.username]
            let password = Defaults[.password]
            self.txtUsername.text = username
            self.txtPassword.text = password
            self.btn_remember.setImage(UIImage(named: "ic_checkbox_selected"),for:.normal)
            
            if isLoggedIn {
                login_func()
            }
        } else {
            let username = ""
            let password = ""
            self.txtUsername.text = username
            self.txtPassword.text = password
            Defaults[.username] = ""
            Defaults[.password] = ""
            Defaults[.isLoggedIn] = false
            btn_remember.setImage(UIImage(named: "ic_checkbox_normal"),for:.normal)
        }
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let isLoggedIn = Defaults[.isLoggedIn] ?? false
//        if(isLoggedIn) {
//            let username = Defaults[.username]
//            let password = Defaults[.password]
//            self.txtUsername.text = username
//            self.txtPassword.text = password
//            login_func()
//        }

        FacebookSignInButton.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onForgotPassword(_ sender: Any) {
        
        
        self.view.endEditing(true)
        
        self.forgotPasswordDlg.alpha = 0
        self.forgotPasswordDlg.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.forgotPasswordDlg.alpha = 1

        })

    }
    
    func cancelForgotPasswordDlg() {
        UIView.animate(withDuration: 0.2, animations: {
            self.forgotPasswordDlg.alpha = 0
            
        }) { (value) in
            self.forgotPasswordDlg.isHidden = true
            self.view.endEditing(true)
        }
    }
    
    @IBAction func onForgotPasswordBk(_ sender: Any) {
        
        cancelForgotPasswordDlg()
        
    }
    
    @IBAction func onCancelForgotPassword(_ sender: Any) {
        
        cancelForgotPasswordDlg()

    }
    @IBAction func unwindLoginViewSegue(_ sender:UIStoryboardSegue)
    {
        
    }
    
    @IBAction func onRegister(_ sender: Any) {
        self.present(RegisterViewController.getNewInstance(), animated: true, completion: nil)
    }
    func login_func()
    {
        var username = txtUsername.text ?? ""
        if(username == "") {
            self.view.makeToast("please enter username".localized())
            return
        }
        if(username[username.startIndex]==" "){
            username.removeFirst()
        }
        if(username.last==" "){
            username.removeLast()
        }
        //txtUsername.text = username
        
        let password = txtPassword.text ?? ""
        if(password == "") {
            self.view.makeToast("please enter password".localized())
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authLogin()
        
        let parameters: Parameters = [
            "email": username,
            "password": password
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        indicator.isHidden = false
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
    
            
            self.indicator.isHidden = true
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            //print(dataResponse.response)
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                Defaults[.isLoggedIn] = true
                Defaults[.remember] = self.rFlag
                Defaults[.username] = username
                Defaults[.password] = password
                let countrycode = Locale.current.regionCode
                if countrycode != "US" {
                    Global.shared.metricScale = 1.56
                    Global.shared.volumeMetricScale = 3.78541
                }
                else {
                    Global.shared.metricScale = 1.0
                    Global.shared.volumeMetricScale = 1.0
                }
                let csrfToken: String = dataResponse.response!.allHeaderFields["x-csrftoken"] as? String ?? ""
                Global.shared.csrfToken = csrfToken
                
                Global.shared.username = username
                
                UIApplication.shared.beginIgnoringInteractionEvents()
                //self.view.makeToast("login success") { didTap in
                UIApplication.shared.endIgnoringInteractionEvents()
                
                self.goToMain()
                //}
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    @IBAction func onLogin(_ sender: Any) {
        self.view.endEditing(true)
        login_func()
    }
    
    @IBAction func onRequestPassword(_ sender: Any) {
        self.view.endEditing(true)
        let email = (txtEmail.text ?? "").lowercased()
        if(email == "") {
            self.view.makeToast("plase enter email".localized())
            return
        }
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.authResendPasswordReset()
        
        let parameters: Parameters = [
            "email": email
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        indicator.isHidden = false
        
        
        Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseString { dataResponse in
            
            self.indicator.isHidden = true
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("email sent") { didTap in
                }
                self.cancelForgotPasswordDlg()
                let forgetViewController = ForgetViewController.getNewInstance() as! ForgetViewController
                forgetViewController.email = email
                self.present(forgetViewController, animated: true, completion: nil)
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    
    func goToMain() {
        //self.present(WeatherViewController.getNewInstance(), animated: true, completion: nil)
        //let mainSlideMenuController = MainSlideMenuController.getNewInstance()
        //VCManager.shared.mainSlideMenuC = mainSlideMenuController
        self.present(MainContainerViewController.getNewInstance(), animated: true, completion: nil)
        //self.present(VCManager.shared.mainSlideMenuC, animated: true, completion: nil)
       // VCManager.shared.mainSlideMenuC.view.makeToast("login success")
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
