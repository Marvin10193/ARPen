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
    
    private var csvData : DataFrame?
    private var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil

    var currentMode : String?
    var relocationTask: Bool?
    
    var timeSinceLast = 0.0
    var overallTime = 0.0
    var summedTimeSinceLast = 0.0
    var timer = Timer()
    var timerIsRunning = false
    
    var logger : CSVLogFile?
    
    let userID = "0"
    
    var userPosition = "Opposite"
    
    let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let fileManager = FileManager.default
    
    var objectNumber = 0
    var sequenceNumber = 0

    var sceneNumber = 0
    
    var sequenceData : [ID] = []
    
    
    
    
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
        
        DispatchQueue.main.async {
            self.sequenceData = self.loadJson(filename: "sequenceData")!
        }
    }
    
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = true
        
        self.currentView = view
        self.relocationTask = false
        self.currentMode = "Base"
        self.setupScene(sceneNumber: 0)
        
        self.pluginManager?.penScene.rootNode.addChildNode((self.pluginManager?.penScene.pencilPoint)!)

        
    }
    
    override func deactivatePlugin() {
        timer.invalidate()
        super.deactivatePlugin()
    
    }
    

    
    func setupScene(sceneNumber: Int){
        self.resetScene()
        self.objectNumber = 0
        self.sequenceNumber = 0
        self.sceneNumber = sceneNumber
        
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
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 1:
            url = url.appendingPathComponent("Scene1").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 2:
            url = url.appendingPathComponent("Scene2").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 3:
            url = url.appendingPathComponent("Scene3").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + "Scene" + currentMode! + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 4:
            url = url.appendingPathComponent("Scene4").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 5:
            url = url.appendingPathComponent("Scene5").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 6:
            url = url.appendingPathComponent("Scene6").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 7:
            url = url.appendingPathComponent("Scene7").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 8:
            url = url.appendingPathComponent("Scene8").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 9:
            url = url.appendingPathComponent("Scene9").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 10:
            url = url.appendingPathComponent("Scene10").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 11:
            url = url.appendingPathComponent("Scene11").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        case 12:
            url = url.appendingPathComponent("Scene12").appendingPathExtension("csv")
            guard let csvData = try? DataFrame(contentsOfCSVFile: url) else{
                let informationPackage : [String: Any] = ["labelStringData": "Could not load CSV!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                return
            }
            self.csvData = csvData
            self.sceneConstructionResults = preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
            self.logger = CSVLogFile(name: "SharedAR_ID" + userID + userPosition + currentMode! + "Scene" + String(sceneNumber), inDirectory: documentsDirectory, options: .lineNumbering)
            self.logger?.header = "TimeSinceLast,SummedTimeSinceLast,FullTaskTime,HighlightedNode"
        default:
            let informationPackage: [String : Any] = ["labelStringData": "Specified scene was not found!"]
            NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
        }

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
    
    
    func onPenClickStarted(at position: SCNVector3, startedButton: Button) {
        if !self.relocationTask! && !self.timerIsRunning {
            if self.highlightedNode?.name == self.sequenceData[Int(self.userID)! - 1].scene[self.sceneNumber-1].sequence[self.sequenceNumber].node[self.objectNumber].index.description{
                self.timerIsRunning = true
            
                if !self.timer.isValid{
                    self.timer = Timer.scheduledTimer(timeInterval: (1.0/30.0), target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                }
                    
                self.timeSinceLast = 0.0

                    
                //Set Label so I can see its currently running
                let informationPackage : [String : Any] = ["sharedARInfoLabelData": String(currentMode!.prefix(1) + userPosition.prefix(1) + "+")]
                NotificationCenter.default.post(name: .infoLabelCommand, object: nil, userInfo: informationPackage)
                
                //Start Logging for current object on other device
                if objectNumber == 0{
                    let startMeasurementInformationPackage : [String : Any] = ["measurementCommandData" : "Start"]
                    NotificationCenter.default.post(name: .measurementCommand, object: nil, userInfo: startMeasurementInformationPackage)
                }
            }
            else{
                let informationPackageWrongNode : [String : Any] = ["labelStringData" : "Wrong node by presenter."]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackageWrongNode)
            }
        }
        else if !self.relocationTask! && self.timerIsRunning {
            if self.highlightedNode?.name == self.sequenceData[0].scene[self.sceneNumber-1].sequence[self.sequenceNumber].node[self.objectNumber].index.description{
                self.timerIsRunning = false
                
                self.summedTimeSinceLast += self.timeSinceLast
                    
                self.logger?.logObjects(in: [self.timeSinceLast,self.summedTimeSinceLast,self.overallTime,self.highlightedNode!.name!])
                    
                //Set Label to no Text, so i know its stopped currently
                let informationPackage : [String : Any] = ["sharedARInfoLabelData": " "]
                NotificationCenter.default.post(name: .infoLabelCommand, object: nil, userInfo: informationPackage)
                
                //Log the current Value for the current object on other device
                let logMeasurementInformationPackage : [String : Any] = ["measurementCommandData" : "Log"]
                NotificationCenter.default.post(name: .measurementCommand, object: nil, userInfo: logMeasurementInformationPackage)
                
                self.objectNumber += 1
                if objectNumber == 3 {
                    self.sequenceNumber += 1
                    self.objectNumber = 0
                    self.timer.invalidate()
                    self.timeSinceLast = 0.0
                    self.overallTime = 0.0
                    self.summedTimeSinceLast = 0.0
                    if self.sequenceNumber == 5{
                        self.sequenceNumber = 0
                        let informationPackageDoneMeassuring: [String : Any] = ["labelStringData": "Data Point done, switch task!"]
                        NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackageDoneMeassuring)
                    }
                }
            }
            else{
                let informationPackageWrongNode : [String : Any] = ["labelStringData" : "Presenter left correct node."]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackageWrongNode)
            }
        }
    }
    
    @objc func updateTimer(){
        self.overallTime += (1.0/30.0)
        self.timeSinceLast += (1.0/30.0)
        
    }
    
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    
    // Similar ResetScene as in the Viewcontroller, just so I dont have to use the
    // Notification Center or somehow get the correct ViewController to reset the
    // scene, once I change the scene to load on the Sender Device
    // also invalidating all timers and resetting their values etc.
    func resetScene(){
        guard let penScene = self.pluginManager?.penScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
        self.timer.invalidate()
        self.timeSinceLast = 0.0
        self.timerIsRunning = false
        self.overallTime = 0.0
        self.summedTimeSinceLast = 0.0
        self.objectNumber = 0
        self.sequenceNumber = 0
        //reset recorded actions of undo redo manager
        self.pluginManager?.undoRedoManager.resetUndoRedoManager()
    }
    
    func onIdleMovement(to position: SCNVector3) {
        if self.pluginManager != nil && !self.relocationTask!{
            let pluginManager = self.pluginManager!
            let projectedPencilPoint = pluginManager.sceneView.projectPoint(pluginManager.penScene.pencilPoint.position)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPoint.x), y: CGFloat(projectedPencilPoint.y))
            let hitResults = pluginManager.sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            if hitResults.contains(where: {$0.node is ARPenStudyNode}){
                self.highlightedNode = hitResults.filter({$0.node is ARPenStudyNode}).first?.node as? ARPenStudyNode
                
                switch self.currentMode{
                case "Base":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
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
                    
                case "Video":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    
                case "Opacity":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : self.highlightedNode?.name!]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)

                    for node in pluginManager.penScene.drawingNode.childNodes{
                        if node.name != self.highlightedNode!.name{
                            node.opacity = 0.5
                        }
                        else{
                            node.opacity = 1.0
                        }
                    }
                default:
                    let informationPackage: [String : Any] = ["labelStringData" : "Unknown Mode Set!"]
                    NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
                }
            }
            else{
                self.highlightedNode = nil
                switch self.currentMode{
                case "Base":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
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
                case "Video":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                case "Opacity":
                    let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
                    NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
                    
                    for node in pluginManager.penScene.drawingNode.childNodes{
                        node.opacity = 0.5
                    }
                    
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
}
