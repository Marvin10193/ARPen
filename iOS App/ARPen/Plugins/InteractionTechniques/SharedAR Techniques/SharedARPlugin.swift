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

class SharedARPlugin: Plugin,PenDelegate,TouchDelegate{
    
    private var csvData : DataFrame?
    private var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil
    private var tapGesture : UITapGestureRecognizer?
    var currentMode : String?
    var relocationTask: Bool?

    
    override init(){
        super.init()
        self.pluginImage = UIImage.init(named: "CubeByExtractionPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ExtrudePluginInstructions")
        self.pluginIdentifier = "SharedAR"
        self.pluginGroupName = "SharedAR"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "CubeByExtractionPluginDisabled")
        self.isExperimentalPlugin = true
        
        self.relocationTask = false
    }
    
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = true
        
        self.currentView = view
        self.setupScene(sceneNumber: 1)
        self.currentMode = "Base"
        self.relocationTask = false
        
        self.pluginManager?.penScene.rootNode.addChildNode((self.pluginManager?.penScene.pencilPoint)!)
    }
    
    override func deactivatePlugin() {
        super.deactivatePlugin()
    }
    
    func setupScene(sceneNumber: Int){
        self.resetScene()
        
        
        var url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        switch sceneNumber{
        case 1 :
            url = url.appendingPathComponent("Demo1").appendingPathExtension("csv")
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
        // start end timer in recognition task
    }
    
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    
    // Same ResetScene as in the Viewcontroller, just so I dont have to use the
    // Notification Center or somehow get the correct ViewController to reset the
    // scene, once I change the scene to load on the Sender Device
    func resetScene(){
        guard let penScene = self.pluginManager?.penScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
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
            
            let informationPackage : [String : Any] = ["nodeHighlightData" : "Nil"]
            NotificationCenter.default.post(name: .nodeCommand, object: nil, userInfo: informationPackage)
        }
    }
}
