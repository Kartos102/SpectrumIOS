//
//  ChatInviteDialogVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/10/16.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit

class ChatInviteDialogVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var contactContainerView: UIView!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    var inviteHandler: ((String) -> ())? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func contactButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func inviteButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, email != "" else { return }
        self.inviteHandler?(email)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
}
