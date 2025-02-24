//
//  CurvePlugin.swift
//  ARPen
//
//  Created by Jan Benscheid on 30.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class ModelingPlugin: Plugin {
    

    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    /// The curve designer "sub-plugin", responsible for the interactive path creation
    var curveDesigner: CurveDesigner
    
    override init() {
        // Initialize curve designer
        curveDesigner = CurveDesigner()
        
        super.init()
        
        //Specify Plugin Information
        self.pluginImage = UIImage.init(named: "ModelingPathPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingPathInstructions")
        self.pluginIdentifier = "Path Tool"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        // This UI contains buttons to represent the other two buttons on the pen and an undo button
        // Important: when using this xib-file, implement the IBActions shown below and the IBOutlets above
        nibNameOfCustomUIView = "ThreeButtons"
 
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.curveDesigner.activate(scene: scene, urManager: urManager)
        
        self.button1Label.text = "Finish"
        self.button2Label.text = "Sharp Corner"
        self.button3Label.text = "Round Corner"
    }
    
    override func deactivatePlugin() {
        self.curveDesigner.deactivate()
        
        super.deactivatePlugin()
    }
    
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }

    @IBAction func softwarePenButtonPressed(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : true]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : true]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : false]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : false]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    //override func undo(){
       // curveDesigner.undo()
   // }

}
