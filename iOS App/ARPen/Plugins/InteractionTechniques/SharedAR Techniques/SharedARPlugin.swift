//
//  SharedARPlugin.swift
//  ARPen
//
//  Created by Marvin Bruna on 29.07.22.
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

class SharedARPlugin: Plugin,PenDelegate,TouchDelegate{
    
    private var csvData : DataFrame? //Used for the positions of the cubes
    private var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil

    var currentMode : String? //The current mode
    var relocationTask: Bool? //Are we in relocation task or not?
    
    var timer = Timer() //Timer
    var currentlyMeasuringANode = false //Are we measuring a node inside a trial?
    var trialInProgress = false //Is a trial in progresss?
    
    var logger : CSVLogFile?
    
    let userID = "23" //Current user ID 0-23
    
    var userPosition = "Opposite" //Current user Position (Opposite,NinetyDegree,SideBySide)
    
    let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) //URL to documentDirectory
    
    var objectNumber = 0 //which number in the sequence 0,1,2
    var sequenceNumber = 0 // which sequence 0,1,2,3,4,5

    var sceneNumber = 0 // which scene 0 = Demo, 1-12 Normal scenes for the trials
    
    var layersAsTextures : [CALayer] = [] //Layers for the cubes to display numbers
    
    var currentMeasurement : DataPoint? = nil //Measurement
    
    var jsonSequenceDataForColoring : [ID] = [] //JsonData for the coloring of cubes to help the presenter
    
    var tapGesture : UITapGestureRecognizer?
    
    var videoColor : Bool = false
    
    
    
    
    //Init
    override init(){
        self.relocationTask = false
        self.currentMode = "Base"
        self.logger = CSVLogFile()
        
        super.init()
        self.pluginImage = UIImage.init(named: "CubeByExtractionPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ExtrudePluginInstructions")
        self.pluginIdentifier = "SharedAR"
        self.pluginGroupName = "SharedAR"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "CubeByExtractionPluginDisabled")
        self.isExperimentalPlugin = true
        
        self.initLayersTextures()
        self.jsonSequenceDataForColoring = loadJson(filename: "sequenceData")!
        
    }
    
    //ActivatePlugin, starting with base mode and the demo scene. TapGesture to color cubes.
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = true
        
        self.currentView = view
        self.relocationTask = false
        self.currentMode = "Base"
        self.setupScene(sceneNumber: 0)
        
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.colorCurrentSequence))
        self.currentView?.addGestureRecognizer(self.tapGesture!)
        
        self.pluginManager?.penScene.rootNode.addChildNode((self.pluginManager?.penScene.pencilPoint)!)

        
    }
    
    //Remove GestureRecognizer and deactive plugin
    override func deactivatePlugin() {
        timer.invalidate()
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
        
        super.deactivatePlugin()
    
    }
    
    //The layers for the cubes = the numbers from 0-47 on all sides of the cubes.
    func initLayersTextures(){
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
    

    //Setup function for the scene, CSV-part loaded accordingly and used to build the scene based on that information.
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
    
    //Actual rebuild of the scene based on the csvdata happens here.
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode]) {
        
        var studyNodes : [ARPenStudyNode] = []
        let superNode = scene.drawingNode
        
        for row in csvData!.rows{
            var arPenStudyNode : ARPenStudyNode
            arPenStudyNode = studyNodeClass.init(withPosition: SCNVector3(row[1] as! Double, row[2] as! Double , row[3] as! Double + 0.135), andDimension: Float(0.03))
            arPenStudyNode.inTrialState = true
            arPenStudyNode.name = String(row.index)
            arPenStudyNode.geometry?.firstMaterial?.diffuse.contents = layersAsTextures[row.index]
            studyNodes.append(arPenStudyNode)
        }
        
        studyNodes.forEach({superNode.addChildNode($0)})
        return (superNode,studyNodes)
        
    }
    
    // starts a new trial, if the mode is video we change the color back to default if we forgot to toggle the coloring off. This gets called by pressing the start trial button.
    func startTrial(){
        self.currentMeasurement = DataPoint()
        if (self.currentMode == "Video"){
            self.sceneConstructionResults?.studyNodes.forEach({
                $0.geometry?.firstMaterial?.emission.contents = UIColor.magenta
                $0.geometry?.firstMaterial?.emission.intensity = 0
            })
        }
        self.logger = CSVLogFile(name: "SharedAR_ID" + userID + "_RelocationPresenter", inDirectory: self.documentsDirectory, options: .init())
        self.logger?.header = "Trial,Mode,UserPosition,Scene,HightlightedNodes,SummedTrialTime,OverallTime,TimeForNode1,TimeForNode2,TimeForNode3,SummedTimeNode1+2"
        self.timer = Timer.scheduledTimer(timeInterval: (1.0/30.0), target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        let startMeasurementInformationPackage : [String : Any] = ["measurementCommandData" : "Start"]
        NotificationCenter.default.post(name: .measurementCommand, object: nil, userInfo: startMeasurementInformationPackage)
        
        self.trialInProgress.toggle()
        
        let messageLabelInformationPackage : [String : Any] = ["labelStringData" : "Trial Started!"]
        NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: messageLabelInformationPackage)
        
    }

    //Using pen click to start and stop measurement of a node during a trial. This information gets send to the other device, to also start/stop there.
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {
        if !self.relocationTask! && !self.currentlyMeasuringANode && self.highlightedNode != nil && self.trialInProgress {
            self.currentMeasurement?.timeForCurrentNode = 0.0
            let resetTimeForCurrentNodeInformationPackage : [String : Any] = ["measurementCommandData" : "ResetCurrentNodeTime"]
            NotificationCenter.default.post(name: .measurementCommand, object: nil, userInfo: resetTimeForCurrentNodeInformationPackage)
            
            self.currentlyMeasuringANode = true
            
            //Set Label so I can see its currently running
            let informationPackage : [String : Any] = ["sharedARInfoLabelData": String(currentMode!.prefix(1) + userPosition.prefix(1) + "+")]
            NotificationCenter.default.post(name: .infoLabelCommand, object: nil, userInfo: informationPackage)
            self.currentMeasurement!.currentSequence.append(self.highlightedNode!.name!)
            
        }
        else if !self.relocationTask! && self.currentlyMeasuringANode && self.currentMeasurement!.currentSequence.last == self.highlightedNode?.name! && self.trialInProgress{
            self.currentlyMeasuringANode = false
            
            self.currentMeasurement!.timeForSingleNode.append(self.currentMeasurement!.timeForCurrentNode)
            self.currentMeasurement!.summedTimeCurrentNodes += self.currentMeasurement!.timeForCurrentNode
            self.currentMeasurement!.summedTimeForCurrentNodes.append(self.currentMeasurement!.summedTimeCurrentNodes)
                    
            //Set Label to no Text, so i know its stopped currently
            let informationPackage : [String : Any] = ["sharedARInfoLabelData": ""]
            NotificationCenter.default.post(name: .infoLabelCommand, object: nil, userInfo: informationPackage)
            
            //Send Sequence Up Until now
            let sequenceInformationPackage : [String : Any] = ["sequenceData" : self.currentMeasurement!.currentSequence]
            NotificationCenter.default.post(name: .sequenceData, object: nil, userInfo: sequenceInformationPackage)
            
            //Log the current Value for the current object on other device
            let logMeasurementInformationPackage : [String : Any] = ["measurementCommandData" : "Log"]
            NotificationCenter.default.post(name: .measurementCommand, object: nil, userInfo: logMeasurementInformationPackage)
            
            //Log on the device running this plugin.
            self.objectNumber += 1
            if objectNumber == 3 {
                self.timer.invalidate()
                self.logger?.logObjects(in: [self.sequenceNumber,self.currentMode,self.userPosition,self.sceneNumber,self.currentMeasurement!.currentSequence.joined(separator: "/"),self.currentMeasurement!.summedTimeForCurrentNodes[2],self.currentMeasurement!.fullTaskTime,self.currentMeasurement!.timeForSingleNode[0],self.currentMeasurement!.timeForSingleNode[1],self.currentMeasurement!.timeForSingleNode[2],self.currentMeasurement!.summedTimeForCurrentNodes[1]])
                self.sequenceNumber += 1
                self.objectNumber = 0
                
                self.sceneConstructionResults?.studyNodes.forEach({
                    $0.geometry?.firstMaterial?.emission.contents = UIColor.magenta
                    $0.geometry?.firstMaterial?.emission.intensity = 0
                })
                
                //Inform via label that a recognition trial has been completed and automatically switch to the relocation task on the other device and here aswell.
                if self.sequenceNumber < 6{
                    let informationPackageDoneMeassuring: [String : Any] = ["labelStringData": "Data Point done, switch task!"]
                    NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackageDoneMeassuring)
                    
                    let informationPackageSwapTask : [String : Any] = ["taskChangeData" : "ChangeTask"]
                    NotificationCenter.default.post(name: .changeTaskMode, object: nil, userInfo: informationPackageSwapTask)
                    
                    self.relocationTask?.toggle()
                }
                //Inform via label that the final recognition trial in a Mode x Position is done and that after the next relocation is done we should swtich to the next setup
                else if self.sequenceNumber == 6{
                    let informationPackageDoneMeassuring: [String : Any] = ["labelStringData": "One last relocation, then next setting!"]
                    NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackageDoneMeassuring)
                    let informationPackageSwapTask : [String : Any] = ["taskChangeData" : "ChangeTask"]
                    NotificationCenter.default.post(name: .changeTaskMode, object: nil, userInfo: informationPackageSwapTask)
                    self.relocationTask?.toggle()
                }
            }
        }
    }
    
    
    func onPenClickStarted(at position: SCNVector3, startedButton: Button) {
    }
    
    //Update the timers, 30Hz
    @objc func updateTimer(){
        self.currentMeasurement!.fullTaskTime += (1.0/30.0)
        self.currentMeasurement!.timeForCurrentNode += (1.0/30.0)
        
    }
    
    //The highlighted node
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    
    // Similar ResetScene as in the Viewcontroller, just so I dont have to use the
    // Notification Center or somehow get the correct ViewController to reset the scene
    // also invalidating all timers and resetting their values etc.
    func resetScene(){
        guard let penScene = self.pluginManager?.penScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
        self.timer.invalidate()
        self.currentlyMeasuringANode = false
        self.objectNumber = 0
        self.sequenceNumber = 0
        //reset recorded actions of undo redo manager
        self.pluginManager?.undoRedoManager.resetUndoRedoManager()
    }
    
    //This constantly fires, while we just move the pen around.
    func onIdleMovement(to position: SCNVector3) {
        DispatchQueue.main.async {
            //If not in relcation task and a pluginmanager correctly exists, start a hit test based on the position of the pen and if it hits a node, highlight it.
            if self.pluginManager != nil && !self.relocationTask!{
                let pluginManager = self.pluginManager!
                let projectedPencilPoint = pluginManager.sceneView.projectPoint(pluginManager.penScene.pencilPoint.position)
                let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPoint.x), y: CGFloat(projectedPencilPoint.y))
                let hitResults = pluginManager.sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
                if hitResults.contains(where: {$0.node is ARPenStudyNode}){
                    self.highlightedNode = hitResults.filter({$0.node is ARPenStudyNode}).first?.node as? ARPenStudyNode
                    
                    switch self.currentMode{
                    //If mode is base simply send the name of the highlighted node.
                    case "Base":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    //If mode is ray, create a SCNNode from the camera to the hitresults position. Send this data and the highlighted node name to other device.
                    case "Ray":
                        let cameraNode = pluginManager.sceneView.pointOfView
                        let renderedRay = SCNNode()
                        let firstHitResult = hitResults.filter({$0.node is ARPenStudyNode}).first
                        renderedRay.name = "renderedRay"
                        renderedRay.buildLineInTwoPointsWithRotation(from: cameraNode!.worldPosition, to: firstHitResult!.worldCoordinates, radius: 0.003, color: .red)
                        
                        let informationPackageRay: [String : Any] = ["nodeData" : renderedRay]
                        NotificationCenter.default.post(name: .shareSCNNodeData, object: nil, userInfo: informationPackageRay)
                        
                        let informationPackageHighlight : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackageHighlight)
                    //If mode is video, send the name of the highlighted node.
                    case "Video":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    //If mode is Opacity, send name of the highlighted node.
                    case "Opacity":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                        
                    default:
                        let informationPackage: [String : Any] = ["labelStringData" : "Unknown Mode Set!"]
                        NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                    }
                }
                else{
                    self.highlightedNode = nil
                    switch self.currentMode{
                    //If hittest is negative, send update to other device indicating that no node is highlighted.
                    case "Base":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    //If hittest is negative, send update to other deivce indicating that no node is highlighted and the ray no goes from camera to the unprojectedFarPlanePoint.
                    case "Ray":
                        let cameraNode = pluginManager.sceneView.pointOfView
                        let unprojectedPointVector = SCNVector3(projectedCGPoint.x, projectedCGPoint.y, 1)
                        let unprojectedFarPlanePoint = pluginManager.sceneView.unprojectPoint(unprojectedPointVector)
                        let renderedRay = SCNNode()
                        renderedRay.name = "renderedRay"
                        renderedRay.buildLineInTwoPointsWithRotation(from: cameraNode!.worldPosition, to: unprojectedFarPlanePoint, radius: 0.003, color: .red)
                        
                        let informationPackageHighlight : [String : Any] = ["nodeHighlightData" : "Nil"]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackageHighlight)
                        
                        let informationPackageRay : [String : Any] = ["nodeData" : renderedRay]
                        NotificationCenter.default.post(name: .shareSCNNodeData, object: nil, userInfo: informationPackageRay)
                    //If hittest is negativ, send update to other device indicating that no node is highlighted.
                    case "Video":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    //If hittest is negativ, send update to other device indicating that no node is highlighted.
                    case "Opacity":
                        let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                        NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    default:
                        let informationPackage: [String : Any] = ["labelStringData" : "Unknown Mode Set!"]
                        NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                    }
                }
                
            }
            else{
                self.highlightedNode = nil
                
                if !self.relocationTask!{
                    let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                }
            }
        }
    }
    
    //Triggered by tapping the screen, with this plugin active, reads information from the loaded JSON file to color the current sequence of cubes that needs to be pointed at.
    @objc func colorCurrentSequence(){
        var k = 0
        self.sceneConstructionResults?.studyNodes.forEach({
            $0.geometry?.firstMaterial?.emission.contents = UIColor.magenta
            $0.geometry?.firstMaterial?.emission.intensity = 0
        })
        if self.sceneNumber == 0 {
            return
        }
        if (self.currentMode == "Base" || self.currentMode == "Ray" || self.currentMode == "Opacity") && self.sequenceNumber < 6{
            for node in self.jsonSequenceDataForColoring[Int(self.userID)!].scene[self.sceneNumber - 1].sequence[self.sequenceNumber].node{
                switch k{
                case 0:
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.cyan
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                case 1:
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                case 2:
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.green
                    self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                default:
                    return
                }
                k += 1
            }
        }
        //For the video we enable toggling on and off, despite we reset it on trial start anyways to be 100% safe.
        if (!self.trialInProgress && self.currentMode == "Video" && self.sequenceNumber < 6){
            self.videoColor.toggle()
            if (self.videoColor){
                for node in self.jsonSequenceDataForColoring[Int(self.userID)!].scene[self.sceneNumber - 1].sequence[self.sequenceNumber].node{
                    switch k{
                    case 0:
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.cyan
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                    case 1:
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                    case 2:
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.contents = UIColor.green
                        self.sceneConstructionResults?.studyNodes.first(where: {$0.name == node.index.description})?.geometry?.firstMaterial?.emission.intensity = 0.4
                    default:
                        return
                    }
                    k += 1
                }
            }
            else if (!self.videoColor){
                return
            }
        }
    }
    
    //Loads a specified JSON file, here used to load the sequenceData.json
    func loadJson(filename fileName: String) -> [ID]?{
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json"){
            do{
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(ResponseData.self, from: data)
                return jsonData.id
            }
            catch{
                print("error: \(error)")
            }
        }
        return nil
    }
    
    //DataPointStruct
    struct DataPoint{
        var timeForSingleNode : [Float] = []
        var summedTimeForCurrentNodes : [Float] = []
        var fullTaskTime : Float = 0.0
        var summedTimeCurrentNodes : Float = 0.0
        var currentSequence : [String] = []
        var timeForCurrentNode : Float = 0.0
    }
    
    //Was used to check for duplicates in the sequences, not used anymore though.
    /*
    func checkDuplicate(){
        var joinedArray = [Int]()
        for j in 4...23{
        for i in 0...11{
            for k in 0...5{
                for z in 0...2{
                    joinedArray.append(self.jsonSequenceDataForColoring[j].scene[i].sequence[k].node[z].index)
                }
            }
            print(joinedArray.chunked(into: 3))
            let dups = Dictionary(grouping: joinedArray, by: {$0}).filter { $1.count > 1}.keys
            joinedArray.removeAll()
        }
            print(" ")
        }
    }*/
}
