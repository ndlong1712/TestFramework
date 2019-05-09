//
//  UnenrollViewController.swift
//  TenTech
//
//  Created by Nguyen Dinh Long on 3/28/19.
//  Copyright © 2019 Nguyen Dinh Long. All rights reserved.
//

import UIKit
protocol UnenrollViewControllerDelegate: class {
    func unenrollVcDidUnenroll()
}

class UnenrollViewController: BaseViewController {
    static let ClassName = "UnenrollViewController"
    
    @IBOutlet weak var viewAlpha: UIView!
    @IBOutlet weak var btnCheckUnenroll: UIButton!
    @IBOutlet weak var lbRefund: UILabel!
    @IBOutlet weak var lbAnnounce: UILabel!
    @IBOutlet weak var lbNameCourse: UILabel!
    @IBOutlet weak var lbCompany: UILabel!
    @IBOutlet weak var lbThanks: UILabel!
    @IBOutlet weak var lbTotalAmount: UILabel!
    @IBOutlet weak var lbTotalFee: UILabel!
    @IBOutlet weak var btnUnenroll: TenPrimaryButtonFontSizeMedium!
    
    @IBOutlet weak var lbTotalLearningAmount: UILabel!
    @IBOutlet weak var lbTotalChargedAmount: UILabel!
    @IBOutlet weak var lbUnEnrollCourse: UILabel!
    
    
    var data: MyCourseResponseModel?
    weak var delegate: UnenrollViewControllerDelegate?
    var topics: [String]?
    
    override func initView() {
        setText()
        tabBarController?.tabBar.isHidden = true
        let midItem = NavigationMidItem(title: "Un-Enroll".localized())
        let leftItem = NavigationItem(title: nil, image: "icons-back")
        navigationSetting = NavigationSetting(midItem: midItem, leftItem: leftItem, rightItem: nil)
        navigationSetting?.setUpNavigation(viewController: self)
        btnCheckUnenroll.setImage(UIImage(named: "selected-icon"), for: .selected)
        btnCheckUnenroll.setImage(UIImage(named: "uncheck-icon"), for: .normal)

        if let data = self.data {
            if let name = data.name {
                lbNameCourse.text = name
            }
            if let company = data.orgName {
                lbCompany.text = company
            }
        }
        btnCheckUnenroll.isSelected = false
        btnUnenroll.isEnabled = false
        
//        AlertHelper.showStandardDialogTwoButton(viewController: self, title: "Notice".localized(), message: "You are going to unenroll the course".localized(), buttonLeftTitle: "Unenroll".localized(), buttonRightTitle: "Dismiss".localized(), leftAction: {
//            self.presenter?.unEnroll(crsSig: data[index].signature!)
//        }, rightAction: {
//
//        }, buttonAlignment: .horizontal)
    }
    
    func setText() {
        lbThanks.text = "Accounting info".localized()
        lbTotalLearningAmount.text = "Total learning amount".localized()
        lbTotalChargedAmount.text = "Total charged fee".localized()
        lbRefund.text = "Refund".localized()
        lbAnnounce.text = "The amount will be refunded to your wallet after un-enrollment".localized()
        lbUnEnrollCourse.text = "Un-Enroll this course".localized()
        btnUnenroll.setTitle("Un-Enroll".localized(), for: .normal)
    }
    
    override func fetchData() { //followTopic
        let apiBuilder = RequestAPIBuilder<UnenrollInfoResponseModel>()
        apiBuilder.dataRequest = APIHelper.sharedInstance.requestAPI(url: "\(TenUrl.RootAppConfig)\(TenUrl.GetUnenrollInfo)", httpMethod: .post, parameters: ["crsSig":data!.signature!], enableAuth: true)
        apiBuilder
            .addView(view: self)
            .subscribe(complete: { (unenrollInfoResponseModel) in
                print(unenrollInfoResponseModel)
                if let topics = unenrollInfoResponseModel.followTopic {
                    self.topics = topics
                }
                if unenrollInfoResponseModel.crsAmt == 0 || unenrollInfoResponseModel.crsAmt == nil  { // free
                    self.unEnroll(isFreeCourse: true)
                    self.viewAlpha.isHidden = false
                } else {
                    self.lbTotalAmount.text = "\(unenrollInfoResponseModel.crsAmt ?? 0)"
                    self.lbTotalFee.text = "\(unenrollInfoResponseModel.useAmt ?? 0)"
                    let used = (unenrollInfoResponseModel.crsAmt ?? 0) - (unenrollInfoResponseModel.useAmt ?? 0)
//                    self.lbAnnounce.text = "An amount of \(used) TEN has just been refunded to your account"
                    self.lbRefund.text = "\(used)"
                }
        })
            .subscribe (failure: { (error) in
                AlertHelper.showStandardDialog(viewController: self, title: nil, message: error.localizedDescription, buttonTitle: "OK", buttonAction: {
                    self.navigationController?.popViewController(animated: true)
                })
        })
    }
    
    @IBAction func didTapUnenroll(_ sender: Any) {
        unEnroll(isFreeCourse: false)
    }
    
    @IBAction func didCheckBoxUnenroll(_ sender: Any) {
        btnCheckUnenroll.isSelected = !btnCheckUnenroll.isSelected
        btnUnenroll.isEnabled = !btnUnenroll.isEnabled
    }
    
    func unEnroll(isFreeCourse: Bool) {
        if let data = self.data {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let name = data.name {
                    AlertHelper.showStandardDialogTwoButton(viewController: self, title: "Notice".localized(), message: "\("You are going to unenroll the course".localized()) \"\(name)\"", buttonLeftTitle: "Unenroll".localized(), buttonRightTitle: "Dismiss".localized(), leftAction: {
                        self.requestUnenroll(crsSig: data.signature!)
                    }, rightAction: {
                        if isFreeCourse {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }, buttonAlignment: .horizontal)
                } else {
                    AlertHelper.showStandardDialogTwoButton(viewController: self, title: "Notice".localized(), message: "You are going to unenroll the course".localized(), buttonLeftTitle: "Unenroll".localized(), buttonRightTitle: "Dismiss".localized(), leftAction: {
                        self.requestUnenroll(crsSig: data.signature!)
                    }, rightAction: {
                        if isFreeCourse {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }, buttonAlignment: .horizontal)
                }
            }
        }
    }
    
    func requestUnenroll(crsSig: String) {
        let rqModel = UnEnrollRequestModel.init(crsSig: crsSig)
        let apiBuilder = RequestAPIBuilder<Bool>()
        apiBuilder.dataRequest = APIHelper.sharedInstance.requestAPI(url: "\(TenUrl.Root)\(TenUrl.UnEnRoll)", httpMethod: .post, parameters: rqModel.convertToDict(), enableAuth: true)
        apiBuilder
            .addView(view: self)
            .subscribe(complete: { (result) in
                print("UNENROLL: \(result)")
                if result {
                    if let topics = self.topics {
                        NotificationHelper.unsubcribeTopics(topics: topics)
                    }
                    self.delegate?.unenrollVcDidUnenroll()
                    self.navigationController?.popViewController(animated: true)
                }
            })
    }
    
}

struct UnenrollInfoResponseModel: Codable {
    let crsAmt : Double?
    let signature : String?
    let useAmt : Double?
    let followTopic: [String]?
}
