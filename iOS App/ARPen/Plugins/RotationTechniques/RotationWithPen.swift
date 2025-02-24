//
//  RotationWithPenTest.swift
//  ARPen
//
//  Created by Donna Klamma on 22.05.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RotationWithPenPlugin: Plugin{
    
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    var undoButtonPressed = false
    
    var startPenOrientation = simd_quatf()
    var updatedPenOrientation = simd_quatf()
    var quaternionFromStartToUpdatedPenOrientation = simd_quatf()
    var updatesSincePressed = 0
    var selected : Bool = false
    var firstSelection : Bool = false
    
    //Variables For USER STUDY TASK
    var randomAngle : Float = 0.0
    var randomAxis = simd_float3()
    var randomOrientation = simd_quatf()
    
    var ModelToRotatedBoxOrientation = simd_quatf()
    var originialBoxOrientation = simd_quatf()
    
    //variables for measuring
    var selectionCounter = 0
    var angleBetweenBoxAndModel : Float = 0.0
    var angleBetweenBoxAndModelEnd : Float = 0.0
    var degreesBoxWasRotated : Float = 0.0
    var degreesPenWasRotated: Float = 0.0
    
    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    
    var userStudyReps = 0
    
    var studyData : [String:String] = [:]
    
    var rotationTime: Float = 0
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "RotationDirectPen")
        self.pluginInstructionsImage = UIImage.init(named: "RotationDirectPenInstructions")
        
        self.pluginIdentifier = "Direct Pen"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Rotation"
        self.isExperimentalPlugin = true
        
        nibNameOfCustomUIView = "ThreeButtons"
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]){
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let model = scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let sceneView = self.currentView else { return }
        let checked = buttons[Button.Button2]!
        
        let pressed = buttons[Button.Button1]!
        if pressed{
            //"activate" box while buttons is pressed and select it therefore
            //project point onto image plane and see if geometry is behind it via hittest
            let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
            var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            if hitResults.first?.node == model{
                hitResults.removeFirst()
            }
            if hitResults.first?.node == scene.pencilPoint{
                hitResults.removeFirst()
            }
            if let boxHit = hitResults.first?.node{
                if selected == false{
                    selected = true
                    
                    box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    
                    selectionCounter = selectionCounter + 1
                    if selectionCounter == 1{
                        startTime = Date()
                        degreesPenWasRotated = 0.0
                    }
                    //used for checkButton so it cannot be pressed twice in a row on accident
                    firstSelection = true
                }
            }
            
            //if just pressed, initialize PenOrientation
            if updatesSincePressed == 0 {
                startPenOrientation = scene.pencilPoint.simdOrientation
            }
            updatesSincePressed += 1
            
            
            updatedPenOrientation = scene.pencilPoint.simdOrientation
            quaternionFromStartToUpdatedPenOrientation = updatedPenOrientation * simd_inverse(startPenOrientation)
            //for measurement
            degreesPenWasRotated = degreesPenWasRotated + abs(quaternionFromStartToUpdatedPenOrientation.angle.radiansToDegrees)
            
            let rotationAxis = box.simdConvertVector(quaternionFromStartToUpdatedPenOrientation.axis, from: nil)
            var rotQuat = simd_quatf(angle: quaternionFromStartToUpdatedPenOrientation.angle, axis: rotationAxis)
            
            if selected == true && rotQuat.angle.radiansToDegrees < 20.0 {
                degreesBoxWasRotated = degreesBoxWasRotated + abs(rotQuat.angle.radiansToDegrees)
                rotQuat = rotQuat.normalized
                box.simdLocalRotate(by: rotQuat)
                
            }
            
            startPenOrientation = updatedPenOrientation
        }
        else{
            selected = false
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            updatesSincePressed = 0
            
            //if task is ended at this point the left amount of degrees between the objects is recorded
            ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
            if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                angleBetweenBoxAndModelEnd = ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            else{
                angleBetweenBoxAndModelEnd = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            
            //in case task is ended at this point record endTime
            endTime = Date()
        }
        
        
        //user study task
        if checked == true && firstSelection == true && selected == false {
            elapsedTime = endTime.timeIntervalSince(startTime)
            
            //create random orientation for model
            randomAngle = Float.random(in: 0...360).degreesToRadians
            randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
            randomOrientation = simd_quatf(angle: randomAngle, axis: randomAxis)
            randomOrientation = randomOrientation.normalized
            
            //new random orientation for model
            model.simdLocalRotate(by: randomOrientation)
            //reset box Orientation
            box.simdOrientation = originialBoxOrientation
            
            //measurement variables
            selectionCounter = 0
            degreesBoxWasRotated = 0.0
            degreesPenWasRotated = 0.0
            
            ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
            if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            else{
                angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            
            selected = false
            firstSelection = false
            //box.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            userStudyReps += 1
        }
        
        //in the case a mistake was made undo to re-do attempt
        if self.undoButtonPressed == true {
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            elapsedTime = 0.0
            selectionCounter = 0
            degreesPenWasRotated = 0.0
            degreesBoxWasRotated = 0.0
            firstSelection = false
            selected = false
            
            //create random orientation for model
            randomAngle = Float.random(in: 0...360).degreesToRadians
            randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
            randomOrientation = simd_quatf(angle: randomAngle, axis: randomAxis)
            randomOrientation = randomOrientation.normalized
            
            //new random orientation for model
            model.simdLocalRotate(by: randomOrientation)
            //reset box Orientation
            box.simdOrientation = originialBoxOrientation
            
            ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
            if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            else{
                angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
          
            self.undoButtonPressed = false
            
        }
        
        //make objects disappear after six reps
        if userStudyReps == 10{
            box.removeFromParentNode()
            model.removeFromParentNode()
        }
        
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Rotate"
        self.button2Label.text = "Finish"
        self.button3Label.text = ""
        
        //source mode: https://www.dropbox.com/s/u0tifsdbzwrt0e1/ARKit.zip?dl=0
        let ship = SCNScene(named: "art.scnassets/arkit-rocket.dae")
        let rocketNode = ship?.rootNode.childNode(withName: "Rocket", recursively: true)
        rocketNode?.scale = SCNVector3Make(0.3, 0.3, 0.3)
        let rocketNodeModel = rocketNode?.clone()
        
        let boxNode = rocketNode!
        //create Object to rotate
        if boxNode != scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            boxNode.position = SCNVector3(0, 0, -0.5)
            boxNode.name = "currentBoxNode"
            boxNode.opacity = 0.9
            
            scene.drawingNode.addChildNode(boxNode)
        }
        else{
            boxNode.position = SCNVector3(0, 0, -0.5)
        }
        originialBoxOrientation = boxNode.simdOrientation
        
        //create random orientation for model
        randomAngle = Float.random(in: 0...360).degreesToRadians
        randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
        randomOrientation = simd_quatf(angle: Float(randomAngle), axis: randomAxis)
        randomOrientation = randomOrientation.normalized
        
        //create Object as model
        let boxModel = rocketNodeModel!
        if boxModel != scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.position = SCNVector3(0, 0, -0.5)
            boxModel.name = "modelBoxNode"
            boxModel.opacity = 0.5
            
            boxModel.simdLocalRotate(by: randomOrientation)
            scene.drawingNode.addChildNode(boxModel)
        }
        else{
            boxModel.position = SCNVector3(0, 0, -0.5)
        }
        
        ModelToRotatedBoxOrientation = boxNode.simdOrientation * simd_inverse(boxModel.simdOrientation)
        if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
            angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
        }
        else{
            angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
        }
    }
    
    override func deactivatePlugin() {
        if let box = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            box.removeFromParentNode()
        }
        
        if let modelBox = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            modelBox.removeFromParentNode()
        }
        
        super.deactivatePlugin()
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
    @IBAction func undoButtonPressed(_ sender: Any) {
        self.undoButtonPressed = true
    }
    
}
