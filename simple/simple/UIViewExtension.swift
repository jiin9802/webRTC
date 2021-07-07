//
//  UIViewExtension.swift
//  simple
//
//  Created by 정지인님/Comm Media Cell on 2021/07/07.
//

import Foundation
import UIKit

extension UIView{
    
    func loadViewFromNib(nibName: String)->UIView?{
        let bundle=Bundle(for: type(of: self))
        let nib=UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
