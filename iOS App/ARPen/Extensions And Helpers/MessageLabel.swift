//
//  MessageLabel.swift
//  ARPen
//
//  Created by Marvin Bruna on 13.05.22.
//  Copyright © 2022 RWTH Aachen. All rights reserved.
//
// Used to display important notfications to the Spectator and Presenter which disappear after a set amount of time.


import UIKit

@IBDesignable
class MessageLabel: UILabel {
    var ignoreMesssage = false
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
    
    func displayMessage(_ text: String, duration: TimeInterval = 3.0){
        guard !ignoreMesssage else {return}
        guard !text.isEmpty else{
            DispatchQueue.main.async {
                self.isHidden = true
                self.text = ""
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isHidden = false
            self.text = text
            
            let tag = self.tag + 1
            self.tag = tag
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration){
                if self.tag == tag {
                    self.isHidden = true
                }
            }
        }
    }
}
