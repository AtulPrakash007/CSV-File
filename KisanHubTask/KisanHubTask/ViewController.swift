//
//  ViewController.swift
//  KisanHubTask
//
//  Created by Mac on 8/30/17.
//  Copyright © 2017 AtulPrakash. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let myQueue = OperationQueue()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    
    //---------------------------------
    //--- It's called on create the class and load the xib, so it will not allow to show Alert
    //--- Performed other operation which is required at class init
    //---------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if removeExistingCSVFile() {
            print("Successfully removed")
        }else{
            print("Not available")
        }
        activityIndicator("Fetching...")
        
        self.addObserver(self, forKeyPath: "networkChanged", options: NSKeyValueObservingOptions(rawValue: 0), context: &kNetworkChanged)
        
    }

    //---------------------------------
    //--- In this section we are unable to show the Alert on netwrok connection
    //--- It just called before the view Appears
    //--- Almost Api is called here
    //---------------------------------

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //---------------------------------
    //--- As this will load after the view appears so, the netwprk checked and the api called
    //---------------------------------
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Here called as this section will work after the view appears
        if (Reachability.isConnectedToNetwork()){
            queueApiCall(country: ["UK","England","Wales","Scotland"], value: ["Tmax","Tmin","Tmean","Sunshine","Rainfall"])
            
        }else{
            DispatchQueue.main.async {
                self.effectView.removeFromSuperview()
            }
            showNetworkAlert(title: "Info", message: "Please connect to network, Kill the App and run again")
        }
    }
    
    //---------------------------------
    //--- Here all observer are removed
    //---------------------------------

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.myQueue.removeObserver(self, forKeyPath: "operations", context: &kQueueOperationsChanged)
        self.removeObserver(self, forKeyPath: "networkChanged", context: &kNetworkChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //---------------------------------
    //--- If again the App runs or due to network failure again need to start
    //--- It will remove the old csv file
    //---------------------------------

    func removeExistingCSVFile() -> Bool {
        let file = "weather.csv"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let pathURL = dir.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: pathURL.path){
        
                do {
                    try FileManager.default.removeItem(atPath: pathURL.path)
                    return true
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                    return false
                }
            }
        }
        return false
    }
    
    //---------------------------------
    //--- Using Session called all the Url
    //--- As here required to call total of 20 Api. so Operation queue is used to handle all call
    //--- From here the fetchd txt file converted into String and handover to another method
    //---------------------------------
    
    func queueApiCall(country cArray:[String],value vArray:[String]) -> Void {
        myQueue.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        myQueue.addObserver(self, forKeyPath: "operations", options: NSKeyValueObservingOptions(rawValue: 0), context: &kQueueOperationsChanged)
        
        for i in 0..<cArray.count {
            for j in 0..<vArray.count {
                let baseUrl = "\(kBaseUrl)\(vArray[j])/date/\(cArray[i]).txt"
                print(baseUrl)
                let urlString = URL(string: baseUrl)
                myQueue.addOperation {
                    
                    if let url = urlString {
                        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                            if error != nil {
                                print(error ?? "Error Genereated")
                            }
                            else {
                                if let usableData = data {
                                    semaphore.signal()
                                    let string = String(data: usableData, encoding: String.Encoding.utf8)
                                    print(string ?? "")
                                    self.storeData(parsedString: string!, forCountry: cArray[i], forValue: vArray[j])
                                }
                            }
                        }
                        task.resume()
                        semaphore.wait()
                    }
                }
            }
        }
    }
    
    //---------------------------------
    //--- Here by using the Fetched String file an array created as per reuired csv entry
    //--- As per the txt file conditions are made to handle the empty entry for 2017
    //--- As per requirement the condition may will change or It should be make automated
    //---------------------------------

    func storeData(parsedString getValue:String, forCountry name:String,  forValue value:String) -> Void {
        let month = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        var finalArray = [[String]]()
        
        let readings = getValue.components(separatedBy: .newlines)
        
        if readings.isEmpty {
            
        }else{
            let firstIndexOfEmptyLine = readings.index(of: "")
            print(firstIndexOfEmptyLine ?? "")
            let startIndex = firstIndexOfEmptyLine!+2
            
            if readings.count > startIndex {
                for i in startIndex..<readings.count {
                    
                    var clientData = readings[i].components(separatedBy: .whitespacesAndNewlines)
                    clientData = clientData.filter { $0 != "" }
                    if readings[i].isEmpty {
                        print("Empty at index: \(i)")
                        break
                    }
                    if i == 115 {
                        print(clientData)
                    }
                    print("\(clientData.count) at index: \(i)")
                    
                    var i = 0
                    // currently the conditions are based upon the data shown in url
                    // if that changes conditions will also change
                    if clientData.count > 12 {
                        
                        while clientData.count > 6 {
                            let feedArray = [name,value,clientData[0],month[i],clientData[1]]
                            finalArray.append(feedArray)
                            clientData.remove(at: 1)
                            
                            i += 1
                        }
                    }else{
                        while clientData.count > 3 {
                            let feedArray = [name,value,clientData[0],month[i],clientData[1]]
                            finalArray.append(feedArray)
                            clientData.remove(at: 1)
                            i += 1
                        }
                        // Can fetch here the current month and start the i value from there
                        for i in 7...11 {
                            let feedArray = [name,value,clientData[0],month[i],"N/A"]
                            finalArray.append(feedArray)
                        }
                    }
//                        print(finalArray)
                }
                createCSVFile(finalArray: finalArray)
            }
            
        }
    }
    
    //---------------------------------
    //--- Here In file manager the csv file created
    //--- It will check if existing csv file avialble then it will append into it
    //--- If exisiting not available then create first entry with the heading
    //---------------------------------
    
    func createCSVFile(finalArray tempArray:[[String]]) -> Void {
        let file = "weather.csv"
        let heading = "region_code,weather_param,year,key,value\n" //region_code,weather_param,year, key, value
        var csvText = heading
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let pathURL = dir.appendingPathComponent(file)
            print(pathURL)
            for arr in tempArray {
                let newLine = "\(arr[0]),\(arr[1]),\(arr[2]),\(arr[3]),\(arr[4])\n"
                csvText.append(newLine)
            }
            
            if FileManager.default.fileExists(atPath: pathURL.path){
                print("File Exists")
                
                //remove the header if file exists
                let start = csvText.index(csvText.startIndex, offsetBy: 0)
                let end = csvText.index(start, offsetBy: 41)
                csvText.removeSubrange(start..<end)
                
                //Existing Writing
                do {
                    let fileHandle = try FileHandle.init(forWritingTo: pathURL)
                    fileHandle.seekToEndOfFile()
                    let data = csvText.data(using: String.Encoding.utf8, allowLossyConversion: false)
                    fileHandle.write(data!)
                    fileHandle.closeFile()
                } catch (let e) {
                    print(e)
                }
                
            }else{
                //New Writing
                do {
                    
                    try csvText.write(to: pathURL, atomically: true, encoding: String.Encoding.utf8)
                }
                catch (let e) {
                    print(e)
                }
            }
        }
    }
    
    //---------------------------------
    //--- Show Alert in case if Netowrk lost
    //---------------------------------

    func showNetworkAlert(title tString:String, message mString:String) -> Void {
        let alertMessage:UIAlertController = UIAlertController(title: tString, message: mString, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel) { (result : UIAlertAction) -> Void in
            print("Cancel")
        }
        
        alertMessage.addAction(cancel)
        self.present(alertMessage, animated: true, completion: nil)
    }
    
    //---------------------------------
    //--- Show Custom activity Indicator
    //---------------------------------

    func activityIndicator(_ title: String) {
        
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        
        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        
        effectView.addSubview(activityIndicator)
        effectView.addSubview(strLabel)
        view.addSubview(effectView)
    }
    
    //---------------------------------
    //--- As per KVO Logic get the observer and take action
    //--- In case network drop happens it will cancel all operations
    //---------------------------------

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "operations" && context == &kQueueOperationsChanged{
            if myQueue.operations.count == 0 {
                print("Queue Empty")
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                }
            }
        }
        
        if keyPath == "networkChanged" && context == &kNetworkChanged{
            if (Reachability.isConnectedToNetwork()){
                
            }else{
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                }
                showNetworkAlert(title: "Oops", message: "Network connection lost, Please connect to network and run app again")
                self.myQueue.cancelAllOperations()
                if removeExistingCSVFile() {
                    print("Successfully removed")
                }else{
                    print("Not available")
                }
            }
        }
    }
}

//---------------------------------
//--- End of Class
//---------------------------------


 //************************
 //***Another methods to create api call
 //**** Both are working
 //**********************
 
/*
    func apiCall(parse string:String) {
        
        let urlString = URL(string: string)
        
        if let url = urlString {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error ?? "Error Genereated")
                }
                else {
                    if let usableData = data {
                        
                        let string = String(data: usableData, encoding: String.Encoding.utf8)
                        print(string ?? "")
                        //                      let readings = string?.components(separatedBy: "\n")
                        //                      for i in
                        let arrayOfString:[String] = (string?.components(separatedBy: "\n"))!
                        print(arrayOfString)
                    }
                }
            }
            task.resume()
        }
    }
    
    
    func thirdApproach() -> Void {
        let month = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        var finalArray = [[String]]()
        let urlString = URL(string: "http://www.metoffice.gov.uk/pub/data/weather/uk/climate/datasets/Tmax/date/UK.txt")
        do{
            let string = try String.init(contentsOf: urlString!, encoding: String.Encoding.utf8)
            //            print(string)
            let readings = string.components(separatedBy: .newlines)
            
            if readings.isEmpty {
                
            }else{
                let firstIndexOfEmptyLine = readings.index(of: "")
                print(firstIndexOfEmptyLine ?? "")
                let startIndex = firstIndexOfEmptyLine!+2
                
                if readings.count > startIndex {
                    for i in startIndex..<readings.count {
                        
                        var clientData = readings[i].components(separatedBy: .whitespacesAndNewlines)
                        clientData = clientData.filter { $0 != "" }
                        if readings[i].isEmpty {
                            print("Empty at index: \(i)")
                            break
                        }
                        if i == 115 {
                            print(clientData)
                        }
                        print("\(clientData.count) at index: \(i)")
                        
                        var i = 0
                        // currently the conditions are based upon the data shown in url
                        // if that changes conditions will also change
                        if clientData.count > 12 {
                            
                            while clientData.count > 6 {
                                let feedArray = ["UK","Max temp",clientData[0],month[i],clientData[1]]
                                finalArray.append(feedArray)
                                clientData.remove(at: 1)
                                
                                i += 1
                            }
                        }else{
                            while clientData.count > 3 {
                                let feedArray = ["UK","Max temp",clientData[0],month[i],clientData[1]]
                                finalArray.append(feedArray)
                                clientData.remove(at: 1)
                                i += 1
                            }
                            for i in 7...11 {
                                let feedArray = ["UK","Max temp","2017",month[i],"N/A"]
                                finalArray.append(feedArray)
                            }
                        }
                        //                        print(finalArray)
                    }
                    createCSVFile(finalArray: finalArray)
                }
                
            }
        }catch (let e) {
            print(e)
        }
    }
*/


