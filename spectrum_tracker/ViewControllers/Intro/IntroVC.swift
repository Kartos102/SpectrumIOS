//
//  IntroVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/8/8.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import EAIntroView

class IntroVC: UIViewController {

    @IBOutlet weak var introContainerView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var introView: EAIntroView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let page1 = EAIntroPage(customViewFromNibNamed: "IntroPage1")!
        let page2 = EAIntroPage(customViewFromNibNamed: "IntroPage2")!
        let page3 = EAIntroPage(customViewFromNibNamed: "IntroPage3")!
        let page4 = EAIntroPage(customViewFromNibNamed: "IntroPage4")!
        let page5 = EAIntroPage(customViewFromNibNamed: "IntroPage5")!
        let page6 = EAIntroPage(customViewFromNibNamed: "IntroPage6")!
        
        let pages = [page1, page2]
        introView = EAIntroView(frame: introContainerView.bounds,
                                andPages: pages)
        introView.delegate = self
        introView.skipButton.isHidden = true
        introView.pageControl.isHidden = true
        introView.show(in: introContainerView)
        pageControl.numberOfPages = pages.count
        self.scrollTo(page: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let launchCount = UserDefaults.standard[.launchCount] ?? 0
        
        if launchCount >= 3 {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            UIApplication.shared.keyWindow?.rootViewController = vc
        } else {
            UserDefaults.standard[.launchCount] = launchCount + 1
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        introView.scrollToPage(for: UInt(self.pageControl.currentPage + 1), animated: true)
        self.scrollTo(page: self.pageControl.currentPage + 1)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        UIApplication.shared.keyWindow?.rootViewController = vc
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        UIApplication.shared.keyWindow?.rootViewController = vc
    }
    
}

extension IntroVC: EAIntroDelegate {
    func intro(_ introView: EAIntroView!, pageEndScrolling page: EAIntroPage!, with pageIndex: UInt) {
        self.scrollTo(page: Int(pageIndex))
    }
    
    func scrollTo(page: Int) {
        self.pageControl.currentPage = Int(page)
        if page < 2 {
            self.skipButton.isHidden = false
            self.nextButton.isHidden = false
            self.doneButton.isHidden = true
        } else {
            self.skipButton.isHidden = true
            self.nextButton.isHidden = true
            self.doneButton.isHidden = false
        }
    }
}
