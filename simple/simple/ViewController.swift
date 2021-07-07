//
//  ViewController.swift
//  simple
//
//  Created by 정지인님/Comm Media Cell on 2021/07/07.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func clickEvent(_ sender: Any) {
        if let controller=self.storyboard?.instantiateViewController(withIdentifier: "DetailController"){
            self.navigationController?.pushViewController(controller, animated: true)
    }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    

    
    
}

