//
//  DetailController.swift
//  simple
//
//  Created by 정지인님/Comm Media Cell on 2021/07/07.
//

import UIKit

final class DetailController:UIViewController{
    @IBOutlet private weak var firstView: CustomView!
    @IBOutlet private weak var secondView: CustomView!
    @IBOutlet private weak var thirdView: CustomView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firstView.titleLabel(title:"first view")
        self.secondView.titleLabel(title:"second view")
        self.thirdView.titleLabel(title:"third view")

        // Do any additional setup after loading the view.
    }
    
}
