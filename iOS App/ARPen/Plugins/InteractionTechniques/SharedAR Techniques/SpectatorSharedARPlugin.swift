//
//  SpectatorSharedARPlugin.swift
//  ARPen
//
//  Created by Marvin Bruna on 17.08.22.
//  Copyright © 2022 RWTH Aachen. All rights reserved.
//

import Foundation
import SpriteKit
import ARKit
import TabularData
import RealityKit
import MultipeerConnectivity
import CSVLogger
import CoreMotion


class SpectatorSharedARPlugin: Plugin,PenDelegate,TouchDelegate{
    
    var csvData : DataFrame?
    var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil
    var tapGesture : UITapGestureRecognizer?
    var currentMode : String?
    var relocationTask : Bool?
    var userPosition = "Opposite"
    let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let fileManager = FileManager.default
    
    var logger : CSVLogFile?
    
    let userID = "0"
    
    private var motionManager : CMMotionManager = CMMotionManager()
    var currentMeasurement: DataPoint? = nil
    private var timerForMovementUpdate = Timer()
    private var lastDevicePosition : SCNVector3? = nil
    private var lastDeviceOrientation: SCNVector3? = nil
    private var timerForTaskTime = Timer()
    
    
    var objectNumber = 0
    var sequenceNumber = 0
    
    var sceneNumber = 0
    var helpTimer = Timer()
    var helpToggled = true

    
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    
    override init(){
        self.relocationTask = false
        self.currentMode = "Base"
        self.logger = CSVLogFile()
        
        
        super.init()
        self.pluginImage = UIImage.init(named:"CubeByExtractionPlugin")
        self.pluginInstructionsImage = UIImage.init(named:"ExtrudePluginInstructions")
        self.pluginIdentifier = "SpectatorSharedAR"
        self.pluginGroupName = "SharedAR"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "CubeByExtractionPluginDisabled")
        self.isExperimentalPlugin = true
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = true
        
        self.currentView = view
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        
       // self.setupScene(sceneNumber: 0)
        self.currentMode = "Base"
        
        self.pluginManager?.penScene.pencilPoint.isHidden = true
        
        self.relocationTask = false
        
    }
    
    
    override func deactivatePlugin() {
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
        self.timerForMovementUpdate.invalidate()
        self.helpTimer.invalidate()
        self.timerForTaskTime.invalidate()
        super.deactivatePlugin()
    }
    
    
    func setupScene(sceneNumber: Int){
        self.resetScene()
        self.highlightedNode = nil
        
        
        var url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        switch sceneNumber{
        case 0 :
            url = url.appendingPathComponent("Demo1").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 1:
            url = url.appendingPathComponent("Scene1").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 2:
            url = url.appendingPathComponent("Scene2").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 3:
            url = url.appendingPathComponent("Scene3").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 4:
            url = url.appendingPathComponent("Scene4").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 5:
            url = url.appendingPathComponent("Scene5").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 6:
            url = url.appendingPathComponent("Scene6").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 7:
            url = url.appendingPathComponent("Scene7").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 8:
            url = url.appendingPathComponent("Scene8").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 9:
            url = url.appendingPathComponent("Scene9").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 10:
            url = url.appendingPathComponent("Scene10").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 11:
            url = url.appendingPathComponent("Scene11").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 12:
            url = url.appendingPathComponent("Scene12").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        default:
            let informationPackage: [String : Any] = ["labelStringData": "Specified scene was not found!"]
            NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
        }
        self.sceneNumber = sceneNumber
    }
    
    
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode]) {
        
        var studyNodes : [ARPenStudyNode] = []
        let superNode = scene.drawingNode
        
        for row in csvData!.rows{
            var arPenStudyNode : ARPenStudyNode
            arPenStudyNode = studyNodeClass.init(withPosition: SCNVector3(row[1] as! Double, row[2] as! Double - 0.2, row[3] as! Double), andDimension: Float(0.03))
            arPenStudyNode.inTrialState = true
            arPenStudyNode.name = String(row.index)
            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
            layer.backgroundColor = UIColor.orange.cgColor
            let textLayer = CATextLayer()
            textLayer.frame = layer.bounds
            textLayer.fontSize = layer.bounds.size.height - 20.0
            textLayer.string = "\(row[0]!)"
            textLayer.alignmentMode = .center
            textLayer.foregroundColor = UIColor.black
                .cgColor
            textLayer.display()
            layer.addSublayer(textLayer)
            arPenStudyNode.geometry?.firstMaterial?.diffuse.contents = layer
            studyNodes.append(arPenStudyNode)
        }
        
        studyNodes.forEach({superNode.addChildNode($0)})
        
        return (superNode,studyNodes)
        
    }
    
    
    
    // Similar ResetScene as in the Viewcontroller, just so I dont have to use the
    // Notification Center or somehow get the correct ViewController to reset the
    // scene, once I change the scene to load on the Sender Device
    func resetScene(){
        guard let penScene = self.pluginManager?.penScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
        
        self.sequenceNumber = 0
        self.objectNumber = 0

        self.stopDeviceUpdate()
        
        //reset recorded actions of undo redo manager
        self.pluginManager?.undoRedoManager.resetUndoRedoManager()
    }
    
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        if self.pluginManager != nil && self.relocationTask!{
            let pluginManager = self.pluginManager!
            let touchLocation = sender.location(in: self.currentView)
            let hitResults = pluginManager.sceneView.hitTest(touchLocation, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            if hitResults.contains(where: {$0.node is SelectableNode && $0.node is ARPenStudyNode}){
                self.highlightedNode = hitResults.filter({$0.node is ARPenStudyNode}).first?.node as? ARPenStudyNode
                
                let alertInformationPackage : [String : Any] = ["alertInformation" : "Confirm?"]
                NotificationCenter.default.post(name: .alertCommand, object: nil, userInfo: alertInformationPackage)
            }
            else{
                self.highlightedNode = nil
                let informationPackage : [String: Any] = ["labelStringData" : "Tap did not intersect a Node!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
            }
        }
    }
    
    func onIdleMovement(to position: SCNVector3) {
        if currentMode == "Opacity" && !self.relocationTask! && self.helpToggled{
            if highlightedNode != nil{
                for node in pluginManager!.penScene.drawingNode.childNodes{
                    if node.name != highlightedNode!.name && node.name != "renderedRay"{
                        node.opacity = 0.5
                    }
                    else{
                        node.opacity = 1.0
                    }
                }
            }
        }
        else if currentMode == "Opacity" && !self.relocationTask! && !self.helpToggled{
            for node in pluginManager!.penScene.drawingNode.childNodes{
                node.opacity = 1.0
            }
        }
    }
    
    func updateMovement(){
        guard let cameraPos = pluginManager?.sceneView.pointOfView else {return}
        guard let deviceMotion = motionManager.deviceMotion else {return}
        
        var rotation = SCNVector3(deviceMotion.attitude.roll.radiansToDegrees, deviceMotion.attitude.yaw.radiansToDegrees,deviceMotion.attitude.pitch.radiansToDegrees)
        if rotation.x < 0 {rotation.x += 360}
        if rotation.y < 0 {rotation.y += 360}
        if rotation.z < 0 {rotation.z += 360}
        
        let position = cameraPos.convertVector(cameraPos.worldPosition, from: nil)
        
        if lastDevicePosition != nil && lastDeviceOrientation != nil && currentMeasurement != nil{
            let movement = position - lastDevicePosition!
            lastDevicePosition = position
            
            var rotationDifference = rotation - lastDeviceOrientation!
            if abs(rotationDifference.x) > 180 {
                rotationDifference.x = 360.0 * (rotationDifference.x >= 0 ? 1.0 : -1) - rotationDifference.x
            }
            if abs(rotationDifference.y) > 180 {
                rotationDifference.y = 360.0 * (rotationDifference.y >= 0 ? 1.0 : -1) - rotationDifference.y
            }
            if abs(rotationDifference.z) > 180 {
                rotationDifference.z = 360.0 * (rotationDifference.z >= 0 ? 1.0 : -1) - rotationDifference.z
            }
            lastDeviceOrientation = rotation
            
            currentMeasurement!.translationInX += movement.x
            currentMeasurement!.translationInY += movement.y
            currentMeasurement!.translationInZ += movement.z
            currentMeasurement!.translationInXAbsolute += movement.x.magnitude
            currentMeasurement!.translationInYAbsolute += movement.y.magnitude
            currentMeasurement!.translationInZAbsolute += movement.z.magnitude
            currentMeasurement!.rotationAroundX += rotationDifference.x
            currentMeasurement!.rotationAroundY += rotationDifference.y
            currentMeasurement!.rotationAroundZ += rotationDifference.z
            currentMeasurement!.rotationAroundXAbsolute += rotationDifference.x.magnitude
            currentMeasurement!.rotationAroundYAbsolute += rotationDifference.y.magnitude
            currentMeasurement!.rotationAroundZAbsolute += rotationDifference.z.magnitude
        }
        else{
            lastDevicePosition = position
            lastDeviceOrientation = rotation
        }
    }
    
    func startDeviceUpdate(){
        print("Meassurement started")
        currentMeasurement = DataPoint()
        self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber) + String(relocationTask!), inDirectory: documentsDirectory, options: .lineNumbering)
        self.logger?.header = "HighlightedNode,TranslationInX,TranslationInY,TranslationInZ,TranslationInXAbsolute,TranslationInYAbsolute,TranslationInZAbsolute,SummedTranslationInXAbsolute,SummedTranslationInYAbsolute,SummedTranslationInZAbsolute,RotationAroundX,RotationAroundY,RotationAroundZ,RotationAroundXAbsolute,RotationAroundYAbsolute,RotationAroundZAbsolute,SummedRotationAroundXAbsolute,SummedRotationAroundYAbsolute,SummedRotationAroundZAbsolute,WrongNode,Success,HelpButtonPresses,TotalHelpButtonPressesForSequence,TimeForNode,SummedTimeForNodes,FullTaskTime,HelpActiveTime,HelpActive"
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        self.timerForMovementUpdate = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateMovement()})
        self.timerForTaskTime = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateTime()})
        self.startHelpTimer()
    }
    
    func startHelpTimer(){
        self.helpTimer = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateTime()})
    }
    
    func stopHelpTimer(){
        self.helpTimer.invalidate()
    }
    
    func updateTime(){
        currentMeasurement!.overallTime += (1.0/30.0)
        currentMeasurement!.timeForCurrentNode += (1.0/30.0)
        currentMeasurement!.activeHelpTime += (1.0/30.0)
    }
    
    func logCurrent(){
        currentMeasurement!.summedTranslationInXAbsolute += currentMeasurement!.translationInXAbsolute
        currentMeasurement!.summedTranslationInYAbsolute += currentMeasurement!.translationInYAbsolute
        currentMeasurement!.summedTranslationInZAbsolute += currentMeasurement!.translationInZAbsolute
        currentMeasurement!.summedRotationAroundXAbsolute += currentMeasurement!.rotationAroundXAbsolute
        currentMeasurement!.summedRotationAroundYAbsolute += currentMeasurement!.rotationAroundYAbsolute
        currentMeasurement!.summedRotationAroundZAbsolute += currentMeasurement!.rotationAroundZAbsolute
        currentMeasurement!.totalButtonPressesInSequence += currentMeasurement!.buttonPressesForCurrentNode
        currentMeasurement!.summedTimeForNodes += currentMeasurement!.timeForCurrentNode
        
        
        self.logger?.logObjects(in: [self.highlightedNode!.name!,currentMeasurement!.translationInX,currentMeasurement!.translationInY,currentMeasurement!.translationInZ,currentMeasurement!.translationInXAbsolute,currentMeasurement!.translationInYAbsolute,currentMeasurement!.translationInZAbsolute,currentMeasurement!.summedTranslationInXAbsolute,currentMeasurement!.summedTranslationInYAbsolute,currentMeasurement!.summedTranslationInZAbsolute,currentMeasurement!.rotationAroundX,currentMeasurement!.rotationAroundY,currentMeasurement!.rotationAroundZ,currentMeasurement!.rotationAroundXAbsolute,currentMeasurement!.rotationAroundYAbsolute,currentMeasurement!.rotationAroundZAbsolute,currentMeasurement!.summedRotationAroundXAbsolute,currentMeasurement!.summedRotationAroundYAbsolute,currentMeasurement!.summedRotationAroundZAbsolute,currentMeasurement!.wrongNode,currentMeasurement!.success,currentMeasurement!.buttonPressesForCurrentNode,currentMeasurement!.totalButtonPressesInSequence,currentMeasurement!.timeForCurrentNode,currentMeasurement!.summedTimeForNodes,currentMeasurement!.overallTime,currentMeasurement!.activeHelpTime,self.helpToggled])
        
        currentMeasurement!.translationInX = 0
        currentMeasurement!.translationInY = 0
        currentMeasurement!.translationInZ = 0
        currentMeasurement!.translationInXAbsolute = 0
        currentMeasurement!.translationInYAbsolute = 0
        currentMeasurement!.translationInZAbsolute = 0
        currentMeasurement!.rotationAroundX = 0
        currentMeasurement!.rotationAroundY = 0
        currentMeasurement!.rotationAroundZ = 0
        currentMeasurement!.rotationAroundXAbsolute = 0
        currentMeasurement!.rotationAroundYAbsolute = 0
        currentMeasurement!.rotationAroundZAbsolute = 0
        currentMeasurement!.buttonPressesForCurrentNode = 0
        currentMeasurement!.timeForCurrentNode = 0
        
        
        self.objectNumber += 1
        if self.objectNumber == 3 {
            self.sequenceNumber += 1
            self.stopDeviceUpdate()
            if self.relocationTask! {
                self.relocationTask?.toggle()
                let informationPackage : [String: Any] = ["taskChangeData": "ChangeTask"]
                NotificationCenter.default.post(name: .changeTaskMode, object: nil, userInfo: informationPackage)
                let labelInformationPackage : [String : Any] = ["labelStringData" : "Inform presenter that you are done."]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: labelInformationPackage)
            }
            if self.sequenceNumber == 5{
                self.sequenceNumber = 0
            }
            print("Measurement stopped!")
            return
        }
    }
    
    
    func stopDeviceUpdate(){
        self.timerForMovementUpdate.invalidate()
        self.helpTimer.invalidate()
        self.timerForTaskTime.invalidate()
        
        self.objectNumber = 0
    }
    
    
     struct DataPoint{
        var translationInX : Float = 0
        var translationInY : Float = 0
        var translationInZ : Float = 0
        var translationInXAbsolute : Float = 0
        var translationInYAbsolute : Float = 0
        var translationInZAbsolute : Float = 0
        var rotationAroundX : Float = 0
        var rotationAroundY : Float = 0
        var rotationAroundZ : Float = 0
        var rotationAroundXAbsolute : Float = 0
        var rotationAroundYAbsolute : Float = 0
        var rotationAroundZAbsolute : Float = 0
        var summedTranslationInXAbsolute : Float = 0
        var summedTranslationInYAbsolute : Float = 0
        var summedTranslationInZAbsolute : Float = 0
        var summedRotationAroundXAbsolute : Float = 0
        var summedRotationAroundYAbsolute : Float = 0
        var summedRotationAroundZAbsolute : Float = 0
        var wrongNode : Int = 0
        var timeForCurrentNode : Float = 0
        var summedTimeForNodes : Float = 0
        var overallTime : Float = 0
        var activeHelpTime : Float = 0
        var buttonPressesForCurrentNode : Int = 0
        var totalButtonPressesInSequence : Int = 0
        var success: Int{
            get { return wrongNode > 0 ? 0 : 1}
        }
    }
}
