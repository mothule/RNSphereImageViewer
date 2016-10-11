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
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = resourcesPath[indexPath.row]
        return cell!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resourcesPath.count
    }

}

extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)

        let vc = RNSphereImageViewController()
        vc.configuration = RNSIConfiguration()
        let path = Bundle.main.path(forResource: resourcesPath[indexPath.row], ofType: "JPG")
        vc.configuration.filePath = path
        vc.configuration.fps = 60
        vc.userDelegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController : RNSIDelegate {
    // It will call when fail load a texture.
    func failLoadTexture(_ error: Error){
        print(error)
    }
    
    // It will call when abort for memory not enought.
    func abortForMemoryNotEnough(){
    }
    
    // It will call when
    func completeSetup(_ view: UIView){
    }
}
