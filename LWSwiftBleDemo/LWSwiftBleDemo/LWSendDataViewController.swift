//
//  LWSendDataViewController.swift
//  LWSwiftBleDemo
//
//  Created by ios on 2017/7/5.
//  Copyright © 2017年 swiftHPRT. All rights reserved.
//

import UIKit


typealias sendDataBlock = (String)->()

class LWSendDataViewController: UIViewController {

    @IBOutlet weak var sendDataTF: UITextField!
    
    var sendB:sendDataBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "发送数据"
        // Do any additional setup after loading the view.
    
    }

    
    @IBAction func clickSend(_ sender: Any) {
        sendDataTF.resignFirstResponder()
        
        if sendB != nil {
            sendB!(sendDataTF.text!)
            
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    

}
