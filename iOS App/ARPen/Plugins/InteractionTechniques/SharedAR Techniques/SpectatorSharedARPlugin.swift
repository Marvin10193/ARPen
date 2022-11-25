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
    
    var csvData : DataFrame? //CSVData of the scenes stored beforehand, used for the positions of the cubes
    var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil
    var tapGesture : UITapGestureRecognizer? //TapGesture
    var currentMode : String? //The current Mode
    var relocationTask : Bool? // Relocation task yes or no
    var userPosition = "Opposite" // Current user position (Opposite,NinetyDegree,SideBySide)
    let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) //URL documentsDirectory
    
    var logger : CSVLogFile? //logger 1 for recogntion part
    var relocationTaskLogger : CSVLogFile? //logger 2 for relocation part
    
    let userID = "23" // current user id 0-23
    
    private var motionManager : CMMotionManager = CMMotionManager() //MotionManager
    var currentMeasurement: DataPoint? = nil //Measurement
    private var timerForMovementUpdate = Timer() //Timer for the movement part
    private var lastDevicePosition : SCNVector3? = nil
    private var lastDeviceOrientation: SCNVector3? = nil
    private var timerForTaskTime = Timer() //Timer for the overall task time
    
    
    var objectNumber = 0 //Current object number 0,1,2
    
    var sceneNumber = 0  //current scene number 0 = Demo, 1-12 regular scenes in the study trials
    var helpTimer = Timer() //only active if help is active
    var helpToggled = false  // indicate if help is toggled or not.
    var currentSequence : [String] = [] //stores the currentsequence received from other device to enable comparing input to this received sequence.
    
    var layersAsTextures : [CALayer] = [] //Layers used as textures for the numbers on the cubes 0-47
    
    var sequenceNumber = 0 //current seequence

    //currently highlighted node
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    //Init
    override init(){
        self.relocationTask = false
        self.currentMode = "Base"
        self.logger = CSVLogFile()
        self.relocationTaskLogger = CSVLogFile()
        
        
        super.init()
        self.pluginImage = UIImage.init(named:"CubeByExtractionPlugin")
        self.pluginInstructionsImage = UIImage.init(named:"ExtrudePluginInstructions")
        self.pluginIdentifier = "SpectatorSharedAR"
        self.pluginGroupName = "SharedAR"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "CubeByExtractionPluginDisabled")
        self.isExperimentalPlugin = true
        
        self.initLayersAsTextures()
    }
    
    //Activate
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
    
    //Deactivate
    override func deactivatePlugin() {
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
        self.timerForMovementUpdate.invalidate()
        self.helpTimer.invalidate()
        self.timerForTaskTime.invalidate()
        super.deactivatePlugin()
    }
    
    //Setup layers used as texture numbering the cubes from 0-47 from all sides
    func initLayersAsTextures(){
        for i in 0...47{
            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
            layer.backgroundColor = UIColor.orange.cgColor
            let textLayer = CATextLayer()
            textLayer.frame = layer.bounds
            textLayer.fontSize = layer.bounds.size.height - 20
            textLayer.string = i.description
            textLayer.alignmentMode = .center
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.display()
            layer.addSublayer(textLayer)
            layersAsTextures.append(layer)
        }
    }
    
    //setup the current scene, load csv accordingly and call preparedARPenNodes to rebuild the scene based on the csv data.
    func setupScene(sceneNumber: Int){
        self.resetScene()
 
        self.sceneNumber = sceneNumber

        switch sceneNumber{
        case 0 :
            guard let csvData = try? DataFrame(contentsOfCSVFile: documentsDirectory.appendingPathComponent("Demo1").appendingPathExtension("csv")) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        case 1,2,3,4,5,6,7,8,9,10,11,12:
            guard let csvData = try? DataFrame(contentsOfCSVFile: documentsDirectory.appendingPathComponent("Scene"+String(sceneNumber)).appendingPathExtension("csv")) else{
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

    }
    
    //Rebuilding scene based on csv data.
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode]) {
        
        var studyNodes : [ARPenStudyNode] = []
        let superNode = scene.drawingNode
        
        for row in csvData!.rows{
            var arPenStudyNode : ARPenStudyNode
            arPenStudyNode = studyNodeClass.init(withPosition: SCNVector3(row[1] as! Double, row[2] as! Double, row[3] as! Double + 0.135), andDimension: Float(0.03))
            arPenStudyNode.inTrialState = true
            arPenStudyNode.name = String(row.index)
            arPenStudyNode.geometry?.firstMaterial?.diffuse.contents = self.layersAsTextures[row.index]
            studyNodes.append(arPenStudyNode)
        }
        
        studyNodes.forEach({superNode.addChildNode($0)})
        
        return (superNode,studyNodes)
        
    }
    
    
    
    // Similar ResetScene as in the Viewcontroller, just so I dont have to use the
    // Notification Center or somehow get the correct ViewController to reset the scene
    func resetScene(){
        guard let penScene = self.pluginManager?.penScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
        
        self.stopDeviceUpdate()
        
        self.objectNumber = 0
        self.sequenceNumber = 0

        
        //reset recorded actions of undo redo manager
        self.pluginManager?.undoRedoManager.resetUndoRedoManager()
    }
    
    //Tap onlt available during relocation task to select node.
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
    
    //constantly fires even without a pen in view, used to set opacity of the nodes in Opacity-Mode
    func onIdleMovement(to position: SCNVector3) {
        DispatchQueue.main.async {
            if self.currentMode == "Opacity" && !self.relocationTask! && self.helpToggled{
                if self.highlightedNode != nil{
                    for node in self.pluginManager!.penScene.drawingNode.childNodes{
                        if node.name != self.highlightedNode!.name{
                            node.opacity = 0.5
                        }
                        else{
                            node.opacity = 1.0
                        }
                    }
                }
                else{
                    for node in self.pluginManager!.penScene.drawingNode.childNodes{
                        node.opacity = 0.5
                    }
                }
            }
            else if (self.currentMode == "Opacity" && !self.relocationTask! && !self.helpToggled) || self.relocationTask!{
                for node in self.pluginManager!.penScene.drawingNode.childNodes{
                    node.opacity = 1.0
                }
            }
        }
    }
    
    //Update the Movement, Based on earlier movement tracking for ARPen studies.
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
    
    //Starts a meassurement, this gets called if we receive the start command from a device using the SharedARPlugin
    func startDeviceUpdate(){
        print("Meassurement started")
        //Show message if we are starting a recognition trial phase.
        if !self.relocationTask!{
        let messageInformationPackage : [String : Any] = ["labelStringData": "Trial Started!"]
        NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: messageInformationPackage)
        }
        
        //Relocation Trial Logging setup
        currentMeasurement = DataPoint()
        self.helpToggled = false
        if self.relocationTask!{
            self.relocationTaskLogger = CSVLogFile(name: "SharedAR_ID " + userID + "_Relocation" , inDirectory: documentsDirectory, options: .init())
            self.relocationTaskLogger?.header = "Trial,Mode,UserPosition,Scene,HighlightedNodes,TrialTime,AbsoluteTranslationInXYZ,AbsoluteRotationAroundXYZ,SummedTranslationInX,SummedTranslationInY,SummedTranslationInZ,SummedTranslationInXAbsolute,SummedTranslationInYAbsolute,SummedTranslationInZAbsolute,SummedRotationAroundX,SummedRotationAroundY,SummedRotationAroundZ,SummedRotationAroundXAbsolute,SummedRotationAroundYAbsolute,SummedRotationAroundZAbsolute,#WrongNodes,Success,CUT!!,OverallTime,HelpCurrentlyActive,SummedHelpTime,HelpButtonPresses,TimeForNode1,TimeForNode2,TimeForNode3,SummedTimeForNode1+2,HelpTimeForNode1,HelpTimeForNode2,HelpTimeForNode3,SummedHelpTimeForNode1+2,TranslationInXNode1,TranslationInYNode1,TranslationInZNode1,TranslationInXNode2,TranslationInYNode2,TranslationInZNode2,TranslationInXNode3,TranslationInYNode3,TranslationInZNode3,SummedTranslationInXNode1+2,SummedTranslationInYNode1+2,SummedTranslationInZNode1+2,TranslationInXAbsoluteNode1,TranslationInYAbsoluteNode1,TranslationInZAbsoluteNode1,TranslationInXAbsoluteNode2,TranslationInYAbsoluteNode2,TranslationInZAbsoluteNode2,TranslationInXAbsoluteNode3,TranslationInYAbsoluteNode3,TranslationInZAbsoluteNode3,SummedTranslationInXAbsoluteNode1+2,SummedTranslationInYAbsoluteNode1+2,SummedTranslationInZAbsoluteNode1+2,RotationAroundXNode1,RotationAroundYNode1,RotationAroundZNode1,RotationAroundXNode2,RotationAroundYNode2,RotationAroundZNode2,RotationAroundXNode3,RotationAroundYNode3,RotationAroundZNode3,SummedRotationAroundXNode1+2,SummedRotationAroundYNode1+2,SummedRotationAroundZNode1+2,RotationAroundXAbsoluteNode1,RotationAroundYAbsoluteNode1,RotationAroundZAbsoluteNode1,RotationAroundXAbsoluteNode2,RotationAroundYAbsoluteNode2,RotationAroundZAbsoluteNode2,RotationAroundXAbsoluteNode3,RotationAroundYAbsoluteNode3,RotationAroundZAbsoluteNode3,SummedRotationAroundXAbsoluteNode1+2,SummedRotationAroundYAbsoluteNode1+2,SummedRotationAroundZAbsoluteNode1+2,HelpButtonPressesNode1,HelpButtonPressesNode2,HelpButtonPressesNode3"
        }
        //Recognition Trial logging setup
        else if !self.relocationTask!{
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + "_Recognition", inDirectory: documentsDirectory, options: .init())
            self.logger?.header = "Trial,Mode,UserPosition,Scene,HighlightedNodes,DiscoveryYime,AbsoluteTranslationInXYZ,AbsoluteRotationAroundXYZ,TrialTime,HelpTimeInTrial,HelpCurrentlyActive,SummedHelpTimeNodesOnly,HelpButtonPresses,SummedTranslationInX,SummedTranslationInY,SummedTranslationInZ,SummedTranslationInXAbsolute,SummedTranslationInYAbsolute,SummedTranslationInZAbsolute,SummedRotationAroundX,SummedRotationAroundY,SummedRotationAroundZ,SummedRotationAroundXAbsolute,SummedRotationAroundYAbsolute,SummedRotationAroundZAbsolute,CUT!!,TimeForNode1,TimeForNode2,TimeForNode3,SummedTimeForNode1+2,HelpTimeForNode1,HelpTimeForNode2,HelpTimeForNode3,SummedHelpTimeForNode1+2,TranslationInXNode1,TranslationInYNode1,TranslationInZNode1,TranslationInXNode2,TranslationInYNode2,TranslationInZNode2,TranslationInXNode3,TranslationInYNode3,TranslationInZNode3,SummedTranslationInXNode1+2,SummedTranslationInYNode1+2,SummedTranslationInZNode1+2,TranslationInXAbsoluteNode1,TranslationInYAbsoluteNode1,TranslationInZAbsoluteNode1,TranslationInXAbsoluteNode2,TranslationInYAbsoluteNode2,TranslationInZAbsoluteNode2,TranslationInXAbsoluteNode3,TranslationInYAbsoluteNode3,TranslationInZAbsoluteNode3,SummedTranslationInXAbsoluteNode1+2,SummedTranslationInYAbsoluteNode1+2,SummedTranslationInZAbsoluteNode1+2,RotationAroundXNode1,RotationAroundYNode1,RotationAroundZNode1,RotationAroundXNode2,RotationAroundYNode2,RotationAroundZNode2,RotationAroundXNode3,RotationAroundYNode3,RotationAroundZNode3,SummedRotationAroundXNode1+2,SummedRotationAroundYNode1+2,SummedRotationAroundZNode1+2,RotationAroundXAbsoluteNode1,RotationAroundYAbsoluteNode1,RotationAroundZAbsoluteNode1,RotationAroundXAbsoluteNode2,RotationAroundYAbsoluteNode2,RotationAroundZAbsoluteNode2,RotationAroundXAbsoluteNode3,RotationAroundYAbsoluteNode3,RotationAroundZAbsoluteNode3,SummedRotationAroundXAbsoluteNode1+2,SummedRotationAroundYAbsoluteNode1+2,SummedRotationAroundZAbsoluteNode1+2,HelpButtonPressesNode1,HelpButtonPressesNode2,HelpButtonPressesNode3"
        }
        
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        self.timerForMovementUpdate = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateMovement()})
        self.timerForTaskTime = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateTaskTimes()})
    }
    
    //Started if button to activate additional visualization is pressed.
    func startHelpTimer(){
        self.helpTimer = Timer.scheduledTimer(withTimeInterval: (1.0/30.0), repeats: true, block: {_ in self.updateHelpTime()})
    }
    
    //Stopped if button to deactivate additional visualziation is pressed.
    func stopHelpTimer(){
        self.helpTimer.invalidate()
    }
    
    //Update for the help timer (overall and per node)
    func updateHelpTime(){
        currentMeasurement!.activeHelpTimeForCurrentNode += (1.0/30.0)
        currentMeasurement!.trialActiveHelpTime += (1.0/30.0)
    }
    
    
    //update for the task timer (overall and per node)
    func updateTaskTimes(){
        currentMeasurement!.overallTime += (1.0/30.0)
        currentMeasurement!.timeForCurrentNode += (1.0/30.0)
    }
    
    //Timer reset for individual nodes
    func resetTimeForCurrentNode(){
        currentMeasurement?.timeForCurrentNode = 0
        currentMeasurement?.activeHelpTimeForCurrentNode = 0
    }
    
    //LOG!!
    func logCurrent(){
        //Update all invidual measurements!
        currentMeasurement!.summedTranslationInX += currentMeasurement!.translationInX
        currentMeasurement!.summedTranslationInY += currentMeasurement!.translationInY
        currentMeasurement!.summedTranslationInZ += currentMeasurement!.translationInZ
        
        currentMeasurement!.summedRotationAroundX += currentMeasurement!.rotationAroundX
        currentMeasurement!.summedRotationAroundY += currentMeasurement!.rotationAroundY
        currentMeasurement!.summedRotationAroundZ += currentMeasurement!.rotationAroundZ
        
        currentMeasurement!.summedTranslationInXAbsolute += currentMeasurement!.translationInXAbsolute
        currentMeasurement!.summedTranslationInYAbsolute += currentMeasurement!.translationInYAbsolute
        currentMeasurement!.summedTranslationInZAbsolute += currentMeasurement!.translationInZAbsolute
        
        currentMeasurement!.summedRotationAroundXAbsolute += currentMeasurement!.rotationAroundXAbsolute
        currentMeasurement!.summedRotationAroundYAbsolute += currentMeasurement!.rotationAroundYAbsolute
        currentMeasurement!.summedRotationAroundZAbsolute += currentMeasurement!.rotationAroundZAbsolute
        
        currentMeasurement!.totalButtonPressesInSequence += currentMeasurement!.buttonPressesForCurrentNode
        
        currentMeasurement!.summedTimeForNodes += currentMeasurement!.timeForCurrentNode
        currentMeasurement!.summedActiveHelpTime += currentMeasurement!.activeHelpTimeForCurrentNode
        
        
        //Help Time for Single node
        currentMeasurement!.activeHelpTimeForSingleNode.append(currentMeasurement!.activeHelpTimeForCurrentNode)
        currentMeasurement!.summedActiveHelpTimeForSingleNode.append(currentMeasurement!.summedActiveHelpTime)
        
        //Time For Single Node
        currentMeasurement!.timeForSingleNode.append(currentMeasurement!.timeForCurrentNode)
        currentMeasurement!.summedTimeForCurrentNodes.append(currentMeasurement!.summedTimeForNodes)
        
        //Translation for Single Nodes
        currentMeasurement!.translationInXForSingleNode.append(currentMeasurement!.translationInX)
        currentMeasurement!.translationInYForSingleNode.append(currentMeasurement!.translationInY)
        currentMeasurement!.translationInZForSingleNode.append(currentMeasurement!.translationInZ)
        
        currentMeasurement!.translationInXAbsoluteForSingleNode.append(currentMeasurement!.translationInXAbsolute)
        currentMeasurement!.translationInYAbsoluteForSingleNode.append(currentMeasurement!.translationInYAbsolute)
        currentMeasurement!.translationInZAbsoluteForSingleNode.append(currentMeasurement!.translationInZAbsolute)
        
        currentMeasurement!.summedTranslationInXAbsoluteForSingleNode.append(currentMeasurement!.summedTranslationInXAbsolute)
        currentMeasurement!.summedTranslationInYAbsoluteForSingleNode.append(currentMeasurement!.summedTranslationInYAbsolute)
        currentMeasurement!.summedTranslationInZAbsoluteForSingleNode.append(currentMeasurement!.summedTranslationInZAbsolute)
        
        currentMeasurement!.summedTranslationInXForSingleNode.append(currentMeasurement!.summedTranslationInX)
        currentMeasurement!.summedTranslationInYForSingleNode.append(currentMeasurement!.summedTranslationInY)
        currentMeasurement!.summedTranslationInZForSingleNode.append(currentMeasurement!.summedTranslationInZ)
        
        //Rotation for Single Nodes
        currentMeasurement!.rotationAroundXForSingleNode.append(currentMeasurement!.rotationAroundX)
        currentMeasurement!.rotationAroundYForSingleNode.append(currentMeasurement!.rotationAroundY)
        currentMeasurement!.rotationAroundZForSingleNode.append(currentMeasurement!.rotationAroundZ)
        
        currentMeasurement!.rotationAroundXAbsoluteForSingleNode.append(currentMeasurement!.rotationAroundXAbsolute)
        currentMeasurement!.rotationAroundYAbsoluteForSingleNode.append(currentMeasurement!.rotationAroundYAbsolute)
        currentMeasurement!.rotationAroundZAbsoluteForSingleNode.append(currentMeasurement!.rotationAroundZAbsolute)
        
        currentMeasurement!.summedRotationAroundXAbsoluteForSingleNode.append(currentMeasurement!.summedRotationAroundXAbsolute)
        currentMeasurement!.summedRotationAroundYAbsoluteForSingleNode.append(currentMeasurement!.summedRotationAroundYAbsolute)
        currentMeasurement!.summedRotationAroundZAbsoluteForSingleNode.append(currentMeasurement!.summedRotationAroundZAbsolute)
        
        currentMeasurement!.summedRotationAroundXForSingleNode.append(currentMeasurement!.summedRotationAroundX)
        currentMeasurement!.summedRotationAroundYForSingleNode.append(currentMeasurement!.summedRotationAroundY)
        currentMeasurement!.summedRotationAroundZForSingleNode.append(currentMeasurement!.summedRotationAroundZ)
        
        //HelpButton Press for Single Node
        currentMeasurement!.buttonPressesForSingleNode.append(currentMeasurement!.buttonPressesForCurrentNode)
        
        
        if self.relocationTask!{
            currentMeasurement!.selectedSequence.append(self.highlightedNode!.name!)
            if self.currentSequence[self.objectNumber] != self.highlightedNode!.name!{
                print("Wrong node")
                currentMeasurement!.wrongNode += 1
            }
        }
        
        //Log!!
        self.objectNumber += 1
        if self.objectNumber == 3 {
            self.stopDeviceUpdate()
            currentMeasurement!.absoluteTranslationInXYZSummed = currentMeasurement!.summedTranslationInXAbsolute + currentMeasurement!.summedTranslationInYAbsolute + currentMeasurement!.summedTranslationInZAbsolute
            currentMeasurement!.absoluteRotationAroundXYZSummed = currentMeasurement!.summedRotationAroundXAbsolute + currentMeasurement!.summedRotationAroundYAbsolute + currentMeasurement!.summedRotationAroundZAbsolute
            //Recognition Task actual writing the log.
            if !self.relocationTask!{
                self.logger?.logObjects(in: [self.sequenceNumber,
                                             self.currentMode,
                                             self.userPosition,
                                             self.sceneNumber,
                                             self.currentSequence.joined(separator: "/"),
                                             currentMeasurement!.summedTimeForNodes,
                                             currentMeasurement!.absoluteTranslationInXYZSummed,
                                             currentMeasurement!.absoluteRotationAroundXYZSummed,
                                             currentMeasurement!.overallTime,
                                             currentMeasurement!.trialActiveHelpTime,
                                             self.helpToggled,
                                             currentMeasurement!.summedActiveHelpTime,
                                             currentMeasurement!.totalButtonPressesInSequence,
                                             currentMeasurement!.summedTranslationInX,
                                             currentMeasurement!.summedTranslationInY,
                                             currentMeasurement!.summedTranslationInZ,
                                             currentMeasurement!.summedTranslationInXAbsolute,
                                             currentMeasurement!.summedTranslationInYAbsolute,
                                             currentMeasurement!.summedTranslationInZAbsolute,
                                             currentMeasurement!.summedRotationAroundX,
                                             currentMeasurement!.summedRotationAroundY,
                                             currentMeasurement!.summedRotationAroundZ,
                                             currentMeasurement!.summedRotationAroundXAbsolute,
                                             currentMeasurement!.summedRotationAroundYAbsolute,
                                             currentMeasurement!.summedRotationAroundZAbsolute,
                                             "SINGULAR DATA FOLLOWING!",
                                             currentMeasurement!.timeForSingleNode[0],
                                             currentMeasurement!.timeForSingleNode[1],
                                             currentMeasurement!.timeForSingleNode[2],
                                             currentMeasurement!.summedTimeForCurrentNodes[1],
                                             currentMeasurement!.activeHelpTimeForSingleNode[0],
                                             currentMeasurement!.activeHelpTimeForSingleNode[1],
                                             currentMeasurement!.activeHelpTimeForSingleNode[2],
                                             currentMeasurement!.summedActiveHelpTimeForSingleNode[1],
                                             currentMeasurement!.translationInXForSingleNode[0],
                                             currentMeasurement!.translationInYForSingleNode[0],
                                             currentMeasurement!.translationInZForSingleNode[0],
                                             currentMeasurement!.translationInXForSingleNode[1],
                                             currentMeasurement!.translationInYForSingleNode[1],
                                             currentMeasurement!.translationInZForSingleNode[1],
                                             currentMeasurement!.translationInXForSingleNode[2],
                                             currentMeasurement!.translationInYForSingleNode[2],
                                             currentMeasurement!.translationInZForSingleNode[2],
                                             currentMeasurement!.summedTranslationInXForSingleNode[1],
                                             currentMeasurement!.summedTranslationInYForSingleNode[1],
                                             currentMeasurement!.summedTranslationInZForSingleNode[1],
                                             currentMeasurement!.translationInXAbsoluteForSingleNode[0],
                                             currentMeasurement!.translationInYAbsoluteForSingleNode[0],
                                             currentMeasurement!.translationInZAbsoluteForSingleNode[0],
                                             currentMeasurement!.translationInXAbsoluteForSingleNode[1],
                                             currentMeasurement!.translationInYAbsoluteForSingleNode[1],
                                             currentMeasurement!.translationInZAbsoluteForSingleNode[1],
                                             currentMeasurement!.translationInXAbsoluteForSingleNode[2],
                                             currentMeasurement!.translationInYAbsoluteForSingleNode[2],
                                             currentMeasurement!.translationInZAbsoluteForSingleNode[2],
                                             currentMeasurement!.summedTranslationInXAbsoluteForSingleNode[1],
                                             currentMeasurement!.summedTranslationInYAbsoluteForSingleNode[1],
                                             currentMeasurement!.summedTranslationInZAbsoluteForSingleNode[1],
                                             currentMeasurement!.rotationAroundXForSingleNode[0],
                                             currentMeasurement!.rotationAroundYForSingleNode[0],
                                             currentMeasurement!.rotationAroundZForSingleNode[0],
                                             currentMeasurement!.rotationAroundXForSingleNode[1],
                                             currentMeasurement!.rotationAroundYForSingleNode[1],
                                             currentMeasurement!.rotationAroundZForSingleNode[1],
                                             currentMeasurement!.rotationAroundXForSingleNode[2],
                                             currentMeasurement!.rotationAroundYForSingleNode[2],
                                             currentMeasurement!.rotationAroundZForSingleNode[2],
                                             currentMeasurement!.summedRotationAroundXForSingleNode[1],
                                             currentMeasurement!.summedRotationAroundYForSingleNode[1],
                                             currentMeasurement!.summedRotationAroundZForSingleNode[1],
                                             currentMeasurement!.rotationAroundXAbsoluteForSingleNode[0],
                                             currentMeasurement!.rotationAroundYAbsoluteForSingleNode[0],
                                             currentMeasurement!.rotationAroundZAbsoluteForSingleNode[0],
                                             currentMeasurement!.rotationAroundXAbsoluteForSingleNode[1],
                                             currentMeasurement!.rotationAroundYAbsoluteForSingleNode[1],
                                             currentMeasurement!.rotationAroundZAbsoluteForSingleNode[1],
                                             currentMeasurement!.rotationAroundXAbsoluteForSingleNode[2],
                                             currentMeasurement!.rotationAroundYAbsoluteForSingleNode[2],
                                             currentMeasurement!.rotationAroundZAbsoluteForSingleNode[2],
                                             currentMeasurement!.summedRotationAroundXAbsoluteForSingleNode[1],
                                             currentMeasurement!.summedRotationAroundYAbsoluteForSingleNode[1],
                                             currentMeasurement!.summedRotationAroundZAbsoluteForSingleNode[1],
                                             currentMeasurement!.buttonPressesForSingleNode[0],
                                             currentMeasurement!.buttonPressesForSingleNode[1],
                                             currentMeasurement!.buttonPressesForSingleNode[2]])
            }
            //Relocation task actual writing the log.
            else if self.relocationTask! {
                self.relocationTask?.toggle()
                
                self.relocationTaskLogger?.logObjects(in: [self.sequenceNumber,
                                                           self.currentMode,
                                                           self.userPosition,
                                                           self.sceneNumber,
                                                           currentMeasurement!.selectedSequence.joined(separator: "/"),
                                                           currentMeasurement!.summedTimeForNodes,
                                                           currentMeasurement!.absoluteTranslationInXYZSummed,
                                                           currentMeasurement!.absoluteRotationAroundXYZSummed,
                                                           currentMeasurement!.summedTranslationInX,
                                                           currentMeasurement!.summedTranslationInY,
                                                           currentMeasurement!.summedTranslationInZ,
                                                           currentMeasurement!.summedTranslationInXAbsolute,
                                                           currentMeasurement!.summedTranslationInYAbsolute,
                                                           currentMeasurement!.summedTranslationInZAbsolute,
                                                           currentMeasurement!.summedRotationAroundX,
                                                           currentMeasurement!.summedRotationAroundY,
                                                           currentMeasurement!.summedRotationAroundZ,
                                                           currentMeasurement!.summedRotationAroundXAbsolute,
                                                           currentMeasurement!.summedRotationAroundYAbsolute,
                                                           currentMeasurement!.summedRotationAroundZAbsolute,
                                                           currentMeasurement!.wrongNode,
                                                           currentMeasurement!.success,
                                                           "SINGULAR DATA FOLLOWING",
                                                           currentMeasurement!.overallTime,
                                                           self.helpToggled,
                                                           currentMeasurement!.summedActiveHelpTime,
                                                           currentMeasurement!.totalButtonPressesInSequence,
                                                           currentMeasurement!.timeForSingleNode[0],
                                                           currentMeasurement!.timeForSingleNode[1],
                                                           currentMeasurement!.timeForSingleNode[2],
                                                           currentMeasurement!.summedTimeForCurrentNodes[1],
                                                           currentMeasurement!.activeHelpTimeForSingleNode[0],
                                                           currentMeasurement!.activeHelpTimeForSingleNode[1],
                                                           currentMeasurement!.activeHelpTimeForSingleNode[2],
                                                           currentMeasurement!.summedActiveHelpTimeForSingleNode[1],
                                                           currentMeasurement!.translationInXForSingleNode[0],
                                                           currentMeasurement!.translationInYForSingleNode[0],
                                                           currentMeasurement!.translationInZForSingleNode[0],
                                                           currentMeasurement!.translationInXForSingleNode[1],
                                                           currentMeasurement!.translationInYForSingleNode[1],
                                                           currentMeasurement!.translationInZForSingleNode[1],
                                                           currentMeasurement!.translationInXForSingleNode[2],
                                                           currentMeasurement!.translationInYForSingleNode[2],
                                                           currentMeasurement!.translationInZForSingleNode[2],
                                                           currentMeasurement!.summedTranslationInXForSingleNode[1],
                                                           currentMeasurement!.summedTranslationInYForSingleNode[1],
                                                           currentMeasurement!.summedTranslationInZForSingleNode[1],
                                                           currentMeasurement!.translationInXAbsoluteForSingleNode[0],
                                                           currentMeasurement!.translationInYAbsoluteForSingleNode[0],
                                                           currentMeasurement!.translationInZAbsoluteForSingleNode[0],
                                                           currentMeasurement!.translationInXAbsoluteForSingleNode[1],
                                                           currentMeasurement!.translationInYAbsoluteForSingleNode[1],
                                                           currentMeasurement!.translationInZAbsoluteForSingleNode[1],
                                                           currentMeasurement!.translationInXAbsoluteForSingleNode[2],
                                                           currentMeasurement!.translationInYAbsoluteForSingleNode[2],
                                                           currentMeasurement!.translationInZAbsoluteForSingleNode[2],
                                                           currentMeasurement!.summedTranslationInXAbsoluteForSingleNode[1],
                                                           currentMeasurement!.summedTranslationInYAbsoluteForSingleNode[1],
                                                           currentMeasurement!.summedTranslationInZAbsoluteForSingleNode[1],
                                                           currentMeasurement!.rotationAroundXForSingleNode[0],
                                                           currentMeasurement!.rotationAroundYForSingleNode[0],
                                                           currentMeasurement!.rotationAroundZForSingleNode[0],
                                                           currentMeasurement!.rotationAroundXForSingleNode[1],
                                                           currentMeasurement!.rotationAroundYForSingleNode[1],
                                                           currentMeasurement!.rotationAroundZForSingleNode[1],
                                                           currentMeasurement!.rotationAroundXForSingleNode[2],
                                                           currentMeasurement!.rotationAroundYForSingleNode[2],
                                                           currentMeasurement!.rotationAroundZForSingleNode[2],
                                                           currentMeasurement!.summedRotationAroundXForSingleNode[1],
                                                           currentMeasurement!.summedRotationAroundYForSingleNode[1],
                                                           currentMeasurement!.summedRotationAroundZForSingleNode[1],
                                                           currentMeasurement!.rotationAroundXAbsoluteForSingleNode[0],
                                                           currentMeasurement!.rotationAroundYAbsoluteForSingleNode[0],
                                                           currentMeasurement!.rotationAroundZAbsoluteForSingleNode[0],
                                                           currentMeasurement!.rotationAroundXAbsoluteForSingleNode[1],
                                                           currentMeasurement!.rotationAroundYAbsoluteForSingleNode[1],
                                                           currentMeasurement!.rotationAroundZAbsoluteForSingleNode[1],
                                                           currentMeasurement!.rotationAroundXAbsoluteForSingleNode[2],
                                                           currentMeasurement!.rotationAroundYAbsoluteForSingleNode[2],
                                                           currentMeasurement!.rotationAroundZAbsoluteForSingleNode[2],
                                                           currentMeasurement!.summedRotationAroundXAbsoluteForSingleNode[1],
                                                           currentMeasurement!.summedRotationAroundYAbsoluteForSingleNode[1],
                                                           currentMeasurement!.summedRotationAroundZAbsoluteForSingleNode[1],
                                                           currentMeasurement!.buttonPressesForSingleNode[0],
                                                           currentMeasurement!.buttonPressesForSingleNode[1],
                                                           currentMeasurement!.buttonPressesForSingleNode[2]])
                
                let informationPackage : [String: Any] = ["taskChangeData": "ChangeTask"]
                NotificationCenter.default.post(name: .changeTaskMode, object: nil, userInfo: informationPackage)
                let labelInformationPackage : [String : Any] = ["labelStringData" : "Sequence done."]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: labelInformationPackage)
                let setConfirmationAlertOnPresenterInformationPackage : [String : Any] = ["confirmData" : "Confirm sequence?"]
                NotificationCenter.default.post(name: .trialLogConfirmation, object: nil, userInfo: setConfirmationAlertOnPresenterInformationPackage)
                
                self.sequenceNumber += 1
            }
            print("Measurement stopped!")
            self.currentMeasurement = nil
            return
        }
        
        //Reset for next node
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
        currentMeasurement!.activeHelpTimeForCurrentNode = 0
        
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
         var summedTranslationInX : Float = 0
         var summedTranslationInY : Float = 0
         var summedTranslationInZ : Float = 0
         var translationInXAbsolute : Float = 0
         var translationInYAbsolute : Float = 0
         var translationInZAbsolute : Float = 0
         var summedTranslationInXAbsolute : Float = 0
         var summedTranslationInYAbsolute : Float = 0
         var summedTranslationInZAbsolute : Float = 0
         
         var rotationAroundX : Float = 0
         var rotationAroundY : Float = 0
         var rotationAroundZ : Float = 0
         var summedRotationAroundX : Float = 0
         var summedRotationAroundY : Float = 0
         var summedRotationAroundZ : Float = 0
         var rotationAroundXAbsolute : Float = 0
         var rotationAroundYAbsolute : Float = 0
         var rotationAroundZAbsolute : Float = 0
         var summedRotationAroundXAbsolute : Float = 0
         var summedRotationAroundYAbsolute : Float = 0
         var summedRotationAroundZAbsolute : Float = 0
         
         
         var wrongNode : Int = 0
         var timeForCurrentNode : Float = 0
         var summedTimeForNodes : Float = 0
         var overallTime : Float = 0
         
         var absoluteTranslationInXYZSummed : Float = 0
         var absoluteRotationAroundXYZSummed : Float = 0
         var activeHelpTimeForCurrentNode : Float = 0
         
         var trialActiveHelpTime : Float = 0
         var summedActiveHelpTime : Float = 0
         var buttonPressesForCurrentNode : Int = 0
         var totalButtonPressesInSequence : Int = 0
         
         var success: Int{
             get { return wrongNode > 0 ? 0 : 1}
         }
         var translationInXForSingleNode : [Float] = []
         var translationInYForSingleNode : [Float] = []
         var translationInZForSingleNode : [Float] = []
         var translationInXAbsoluteForSingleNode : [Float] = []
         var translationInYAbsoluteForSingleNode : [Float] = []
         var translationInZAbsoluteForSingleNode : [Float] = []
         var rotationAroundXForSingleNode : [Float] = []
         var rotationAroundYForSingleNode : [Float] = []
         var rotationAroundZForSingleNode : [Float] = []
         var rotationAroundXAbsoluteForSingleNode : [Float] = []
         var rotationAroundYAbsoluteForSingleNode : [Float] = []
         var rotationAroundZAbsoluteForSingleNode : [Float] = []
         var summedTranslationInXAbsoluteForSingleNode : [Float] = []
         var summedTranslationInYAbsoluteForSingleNode : [Float] = []
         var summedTranslationInZAbsoluteForSingleNode : [Float] = []
         var summedRotationAroundXAbsoluteForSingleNode : [Float] = []
         var summedRotationAroundYAbsoluteForSingleNode : [Float] = []
         var summedRotationAroundZAbsoluteForSingleNode : [Float] = []
         var buttonPressesForSingleNode : [Int] = []
         var activeHelpTimeForSingleNode : [Float] = []
         var summedActiveHelpTimeForSingleNode : [Float] = []
         var timeForSingleNode : [Float] = []
         var summedTimeForCurrentNodes : [Float] = []
         var selectedSequence : [String] = []
         var summedTranslationInXForSingleNode : [Float] = []
         var summedTranslationInYForSingleNode : [Float] = []
         var summedTranslationInZForSingleNode : [Float] = []
         var summedRotationAroundXForSingleNode : [Float] = []
         var summedRotationAroundYForSingleNode : [Float] = []
         var summedRotationAroundZForSingleNode : [Float] = []
    }
}
