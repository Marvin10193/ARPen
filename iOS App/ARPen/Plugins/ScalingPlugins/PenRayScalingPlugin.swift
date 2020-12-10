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
        self.pluginIdentifier = "Scaling(PenRay)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.scaler.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "View Bounding Box"
        self.button2Label.text = "Select Corner"
        self.button3Label.text = ""

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
            cornerSelection()
            break
        
        case .Button3:
            break
        }
    }
    
    ///selects the corner of the bounding box for scaling
    /**
        Selection: If we hover over a corner and press the button, we select the corner for scaling. The mesh is changed out for a sceneKit representation of the OCCT mesh. The pivot is moved for the scale to be relative to the diagonal corner of the mesh.
     */
    func cornerSelection(){
        
        //if pencil Point hovers over a corner
        if scaler.hoverCorner != nil {
            
            //Case: select
            if (scaler.isACornerSelected == false){
                
                let selectedCornerName = scaler.hoverCorner?.name
                
                //get the selected corner
                scaler.selectedCorner = scaler.currentScene?.drawingNode.childNode(withName: selectedCornerName!, recursively: true)
                //color selectedCorner
                scaler.selectedCorner!.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 98/100, alpha: 1.0)
                
                scaler.isACornerSelected = true
            }
            
            //Case: deselect
            else
            {
                scaler.selectedTargets.first!.applyTransform()
                scaler.selectedCorner = SCNNode()
                scaler.selectedCorner!.name = "generic"
                
                scaler.isACornerSelected = false
                
            }
        }
    }
    
    
    
    
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
