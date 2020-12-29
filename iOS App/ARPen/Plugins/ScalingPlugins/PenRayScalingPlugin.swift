//
//  PenRayScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This plugin is used for PenRayScaling of an object.
 Uses "PenRayScaler" for updating the scale of an object per frame.
 For button where it is *essential* that they are executed once, the code is located here.
*/

class PenRayScalingPlugin: ModelingPlugin {
    
    private var scaler: PenRayScaler
    private var buttonEvents: ButtonEvents
        
    override init() {
        buttonEvents = ButtonEvents()
        scaler = PenRayScaler()
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Scaling (PenRay)"
        self.pluginGroupName = "Scaling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.scaler.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select/Deselect Model"
        self.button2Label.text = "Corner Scaling"
        self.button3Label.text = "Center Scaling"

    }
    
    override func deactivatePlugin() {
        scaler.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        scaler.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
            
        case .Button2:
          
            break
        
        case .Button3:
            break
        }
    }

    
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
