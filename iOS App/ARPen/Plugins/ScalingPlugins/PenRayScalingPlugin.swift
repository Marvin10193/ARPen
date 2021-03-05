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

class PenRayScalingPlugin: ScalingPlugin {
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "ScalingPen")
        self.pluginInstructionsImage = UIImage.init(named: "PenRayScalingInstructions")
        self.pluginIdentifier = "Scaling (PenRay)"
        self.pluginGroupName = "Manipulation"
        self.needsBluetoothARPen = false
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.scaler.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select/Deselect Model"
        self.button2Label.text = "Corner Scaling"

    }
    
 
    
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
