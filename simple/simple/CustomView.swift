//
//  CustomView.swift
//  simple
//
//  Created by 정지인님/Comm Media Cell on 2021/07/07.
//
import Foundation
import UIKit
@IBDesignable
final class CustomView:UIView{
    @IBOutlet private weak var titleLabel: UILabel!
    override init(frame:CGRect){
        
        super.init(frame: frame)
        self.configureView()
    }
    required init?(coder: NSCoder){
        super.init(coder: coder)
        self.configureView()
    }
    private func configureView(){
        guard let view=self.loadViewFromNib(nibName: "CustomView")else{return}
        view.frame=self.bounds
        self.addSubview(view)
    }
    func titleLabel(title:String){
        self.titleLabel.text=title
    }
}

