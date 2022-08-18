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

class SpectatorSharedARPlugin: Plugin,PenDelegate,TouchDelegate{
    
    private var csvData : DataFrame?
    private var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil
    private var tapGesture : UITapGestureRecognizer?
    var currentMode : String?
    var relocationTask : Bool?
    
    
    var highlightedNode : ARPenStudyNode? = nil{
        didSet{
            oldValue?.highlighted = false
            self.highlightedNode?.highlighted = true
        }
    }
    
    
    override init(){
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
        
        pluginManager?.allowPenInput = false
        pluginManager?.allowTouchInput = true
        
        self.currentView = view
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        
        self.setUpScene(sceneNumber: 1)
        self.currentMode = "Base"
        
        self.pluginManager?.penScene.pencilPoint.removeFromParentNode()
        
        self.relocationTask = false
        
    }
    
    
    override func deactivatePlugin() {
        super.deactivatePlugin()
        
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func setUpScene(sceneNumber: Int){
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
    
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene: PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode:SCNNode, studyNodes:[ARPenStudyNode]){
        
        var studyNodes: [ARPenStudyNode] = []
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
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.display()
            layer.addSublayer(textLayer)
            arPenStudyNode.geometry?.firstMaterial?.diffuse.contents = layer
            studyNodes.append(arPenStudyNode)
        }
        
        studyNodes.forEach({superNode.addChildNode($0)})
        return (superNode,studyNodes)
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
    
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        if self.pluginManager != nil && self.relocationTask!{
            let pluginManager = self.pluginManager!
            let touchLocation = sender.location(in: self.currentView)
            let hitResults = pluginManager.sceneView.hitTest(touchLocation, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            if hitResults.contains(where: {$0.node is SelectableNode && $0.node is ARPenStudyNode}){
                // do something in the future
            }
            else{
                let informationPackage : [String: Any] = ["labelStringData" : "Tap did not intersect a Node!"]
                NotificationCenter.default.post(name: .labelCommand, object: nil, userInfo: informationPackage)
            }
        }
    }
    
    func onIdleMovement(to position: SCNVector3) {
        if currentMode == "Opacity" && !self.relocationTask!{
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
    }
    
    
}
