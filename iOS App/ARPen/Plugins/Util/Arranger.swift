//
//  Arranger.swift
//  ARPen
//
//  Created by Jan Benscheid on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the selecting and arranging and "visiting" of objects, as this functionality is shared across multiple plugins. An examplary usage can be seen in `CombinePluginTutorial.swift`.
To "visit" means to march down the hierarchy of a node, e.g. to rearrange the object which form a Boolean operation.
*/
class Arranger {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    static let timeTillDrag: Double = 1
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
    
    
    //PARAMETER DER SICH AUTOMATISCH UPDATED
    var hoverTarget: ARPNode? {
        didSet {
            if let old = oldValue {
                old.highlighted = false
            }
            if let target = hoverTarget {
                target.highlighted = true
            }
        }
    }
    
    //ARRAY VON RELEVANZ
    var selectedTargets: [ARPNode] = []
    
    var visitTarget: ARPGeomNode?
    var dragging: Bool = false
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    private var lastClickPosition: SCNVector3?
    private var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    var didSelectSomething: ((ARPNode) -> Void)?
    
    
    
    
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
    }
    
    
    
    func activate(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.visitTarget = nil
        self.dragging = false
        self.justSelectedSomething = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
    }
    
    
    
    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
    
    
    func update(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
     
        
        if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
            hoverTarget = hit
        } else {
            hoverTarget = nil
        }
        
        // Start dragging when either the button has been held for long enough or pen has moved a certain distance.
        if (buttons[.Button1] ?? false) &&
                 ((Date() - (lastClickTime ?? Date())) > Arranger.timeTillDrag
                     || (lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > Arranger.maxDistanceTillDrag) {
                 dragging = true
              
                 if Arranger.snapWhenDragging {
                    
                    if selectedTargets.count == 1 {
                        
                        let node = selectedTargets.last
                        
                        node?.position = node!.boundingBox.min
                        print(node?.position)
                        
                        let node_min = node!.boundingBox.min
                        print("This is the minimal corner of the bounding box")
                        print(node_min)
                        
                        let node_max = node!.boundingBox.max
                        print("This is the maximal corner of the bounding box")
                        print(node_max)
                       
                                      
                        let height = node_max.y - node_min.y
                        let width = node_max.z - node_min.z
                        let length = node_max.x - node_min.x
                                          
                        let dimensions = SCNVector3(x: length/2, y: height/2, z: width/2)
                        
                        let vector_of_geometry = selectedTargets.reduce(SCNVector3(0,0,0), {$0 + ($1.position + dimensions)}) / Float(selectedTargets.count)
                        print(vector_of_geometry)
                                          
                        let shift = scene.pencilPoint.position - vector_of_geometry
                        
                        for target in selectedTargets {
                                target.position += shift
                        }
  
                    }
                    
                 }
             }
        
        if dragging, let lastPos = lastPenPosition {
            for target in selectedTargets {
                target.position += scene.pencilPoint.position - lastPos
            }
            lastPenPosition = scene.pencilPoint.position
        }
    }
    
    
    
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
            if let target = hoverTarget {
                if !selectedTargets.contains(target) {
                    selectTarget(target)
                }
            } else {
                for target in selectedTargets {
                    unselectTarget(target)
                }
            }
            
        default:
            break
        }
    }
    
    
    
    func didReleaseButton(_ button: Button) {
        switch button {
        case .Button1:
            if dragging {
                for target in selectedTargets {
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                        target.applyTransform()
                    }
                }
            } else {
                if let target = hoverTarget, !justSelectedSomething {
                    if selectedTargets.contains(target) {
                        unselectTarget(target)
                    }
                }
            }
            justSelectedSomething = false
            lastPenPosition = nil
            dragging = false
        default:
            break
        }
    }
    
    
    
    func didDoubleClick(_ button: Button) {
        if button == .Button1,
            let scene = currentScene {
            if let hit = hitTest(pointerPosition: scene.pencilPoint.position) as? ARPGeomNode {
                if hit.parent?.parent === visitTarget || visitTarget == nil {
                    visitTarget(hit)
                } else {
                    leaveTarget()
                }
            } else {
                leaveTarget()
            }
        }
    }
    
    
    
    
    func visitTarget(_ target: ARPGeomNode) {
        unselectTarget(target)
        target.visited = true
        visitTarget = target
    }
    
    
    
    func leaveTarget() {
        if let target = visitTarget {
            target.visited = false
            if let parent = target.parent?.parent as? ARPGeomNode {
                parent.visited = true
                visitTarget = parent
            } else {
                visitTarget = nil
            }
        }
    }
    
    
    
    
    func selectTarget(_ target: ARPNode) {
        target.selected = true
        selectedTargets.append(target)
        justSelectedSomething = true
        didSelectSomething?(target)
    }
    
    
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
    }
    
    
    
    ///hitTest gives PARENT Node back
    func hitTest(pointerPosition: SCNVector3) -> ARPNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
            
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPNode
           
    }
}
