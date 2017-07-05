//
//  ViewController.swift
//  LWSwiftBleDemo
//
//  Created by ios on 2017/7/4.
//  Copyright © 2017年 swiftHPRT. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    var centralManager :CBCentralManager?
    var cbperiphral :CBPeripheral?
    var cbchracters :CBCharacteristic?
    var periphralArray :[CBPeripheral] = []
    var tableView :UITableView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.white
        
        self.title = "蓝牙Demo"
        let rightItem = UIBarButtonItem(title:"开始扫描",style:UIBarButtonItemStyle.plain,target:self,action:#selector(clickRight))
        self.navigationItem.rightBarButtonItem = rightItem
        
        let leftItem = UIBarButtonItem(title:"断开连接",style:UIBarButtonItemStyle.plain,target:self,action:#selector(clickLeft))
        self.navigationItem.leftBarButtonItem = leftItem
        
        initUI()
    }
    
    func clickRight()  {
        print("点击开始扫描")
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
    }

    func clickLeft()  {
        print("点击断开连接")
        if cbperiphral != nil {
            centralManager?.cancelPeripheralConnection(cbperiphral!)
        }
        
        
    }
    
    private func initUI(){
        
        tableView = UITableView.init(frame:CGRect(x:0,y:0,width:UIScreen.main.bounds.size.width,height:UIScreen.main.bounds.size.height), style: UITableViewStyle.plain)
        tableView!.dataSource = self
        tableView!.delegate = self
        self.view.addSubview(tableView!)
        centralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
        
    }

}


extension ViewController:UITableViewDataSource,UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return periphralArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style:UITableViewCellStyle.subtitle,reuseIdentifier:"cell")
        }
        
        let per = periphralArray[indexPath.row]
        if per.name == nil {
            cell?.textLabel?.text = "设备名称 ：Unknown"
        }else{
            cell?.textLabel?.text = String.init(format: "设备名称 ：%@",per.name!)
        }
        
        if per.identifier.uuidString.isEmpty {
            cell?.detailTextLabel?.text = "UUID : Unknown"
        }else{
            cell?.detailTextLabel?.text = String.init(format: "UUID : %@", per.identifier.uuidString)
        }
        
        
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let peripherals = periphralArray[indexPath.row]
        centralManager?.connect(peripherals, options: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
}

extension ViewController:CBCentralManagerDelegate,CBPeripheralDelegate{
    
    //看中心的状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            clickRight()
            print("poweredOn")
        
        }
    }
    
    //扫描到外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var isExited = false
        
        for characters in periphralArray {
            if characters.identifier == peripheral.identifier{
                isExited = true
            }
        }
        
        if !isExited {
            periphralArray.append(peripheral)
        }
        
        tableView!.reloadData()
    }
    
    //连接上外设
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("连接上外设")
        cbperiphral = peripheral
        peripheral.discoverServices(nil)
        peripheral.delegate = self
        centralManager!.stopScan()
        //发送数据
        let sendVC = LWSendDataViewController.init()
        
        let alerCtl = UIAlertController(title:nil,message:"蓝牙已连接，是否发送数据",preferredStyle:UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel) { (alerts:UIAlertAction) in
            
            print("cancel")
        }
        
        let confirmAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (alerts:UIAlertAction) in
            print("confirm")
            
            self.navigationController?.pushViewController(sendVC, animated: true)
            
        }
        
        alerCtl.addAction(cancelAction)
        alerCtl.addAction(confirmAction)
        self.present(alerCtl, animated: true, completion: nil)
        sendVC.sendB = {(sendString)->() in
            print("\(sendString)")
            let data = sendString.data(using:.utf8)
            self.cbperiphral?.writeValue(data!, for: self.cbchracters!, type: .withResponse)
        }
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(peripheral.name) 连接失败 == \(error?.localizedDescription)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\(peripheral.name) 断开连接 == \(error?.localizedDescription)")
    }
    
    //扫描到Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("didDiscoverServices == \(error?.localizedDescription)")
            return
        }
        
        for ser in peripheral.services! {
            peripheral .discoverCharacteristics(nil, for: ser)
        }
        
        
    }
    
    //扫描到Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("didDiscoverCharacteristicsFor == \(error?.localizedDescription)")
            return
        }
        
        for cha in service.characteristics! {
            
            if cha.uuid.uuidString == "49535343-8841-43F4-A8D4-ECBE34729BB3" {
                peripheral.readValue(for: cha)
                service.peripheral.setNotifyValue(true, for: cha)
                cbchracters = cha
            }
            
        }
        
    }
    
    //获取的charateristic的值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("didUpdateValueForcharacteristic == \(error?.localizedDescription)")
            return
        }
        
        print("value == \(characteristic.value)")
        
    }
    
    //写数据后回调
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("didWriteValueForcharacteristic == \(error?.localizedDescription)")
            return
        }
        
        print("数据后回调 == \(characteristic)")
        
        
    }
    
    
}










