//
//  ViewController.swift
//  Demo
//
//  Created by mothule on 2016/09/11.
//  Copyright © 2016年 mothule. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let resourcesPath: [String] = ["sample3", "sample4"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resourcesPath.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = resourcesPath[indexPath.row]
        return cell!
    }
}

extension ViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let vc = RNSphereImageViewController()
        vc.configuration = RNSIConfiguration()
        let path = NSBundle.mainBundle().pathForResource(resourcesPath[indexPath.row], ofType: "JPG")
        vc.configuration.filePath = path
        vc.configuration.fps = 60
        vc.userDelegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController : RNSIDelegate {
    // It will call when fail load a texture.
    func failLoadTexture(error: ErrorType){
        print(error)
    }
    
    // It will call when abort for memory not enought.
    func abortForMemoryNotEnough(){
    }
    
    // It will call when
    func completeSetup(view: UIView){
    }
}
