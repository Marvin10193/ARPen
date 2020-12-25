//
//  PenRotator.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the "visiting" and rotation of meshes.
 */
class PenRotator {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?

    var startPenOrientation = simd_quatf()
    var updatedPenOrientation = simd_quatf()
    var quaternionFromStartToUpdatedPenOrientation = simd_quatf()
    var updatesSincePressed = 0
    var selected : Bool = false
    var firstSelection : Bool = false
        
    //hoverTarget uses didSet to update any dependency automatically
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
    
    //selectedTargets is the Array of selected ARPNodes
    var selectedTargets: [ARPNode] = []
    
    var visitTarget: ARPGeomNode?
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false

    
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
        self.justSelectedSomething = false
    }

    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
    ///gets executed each frame and is responsible for scaling
    /**
        
     */
    func update(scene: PenScene, buttons: [Button : Bool]) {
        
        //check for button press
        buttonEvents.update(buttons: buttons)
       
        if selectedTargets.count != 1 {
            //check whether or not you hover over created geometry
            if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
                hoverTarget = hit
            } else {
                hoverTarget = nil
            }
        }
        
        //geometry was selected
        if selectedTargets.count == 1 {
            let pressed = buttons[Button.Button2]!
            
            if pressed
            {
                
                //if just pressed, initialize PenOrientation
                if updatesSincePressed == 0 {
                    startPenOrientation = scene.pencilPoint.simdOrientation
                }
                
                print(startPenOrientation)
                updatesSincePressed += 1
                
                updatedPenOrientation = scene.pencilPoint.simdOrientation
                print(updatedPenOrientation)
                quaternionFromStartToUpdatedPenOrientation = updatedPenOrientation * simd_inverse(startPenOrientation)
                
                let rotationAxis = selectedTargets.first!.simdConvertVector(quaternionFromStartToUpdatedPenOrientation.axis, from: nil)
                quaternionFromStartToUpdatedPenOrientation = simd_quatf(angle: quaternionFromStartToUpdatedPenOrientation.angle, axis: rotationAxis)
                
                if selected == true && quaternionFromStartToUpdatedPenOrientation.angle.radiansToDegrees < 20.0 {
                    quaternionFromStartToUpdatedPenOrientation = quaternionFromStartToUpdatedPenOrientation.normalized
                    selectedTargets.first!.simdLocalRotate(by: quaternionFromStartToUpdatedPenOrientation)
                    //for measurement
                }
                
                startPenOrientation = updatedPenOrientation
            }
      
        }
    }
 
    ///a hitTest for the geometry in the scene
    /**
        
     */
    func hitTest(pointerPosition: SCNVector3) -> ARPNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPNode
    }
    
    ///
    /**
        
     */
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
            
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
    
    ///
    /**
        
     */
    func didReleaseButton(_ button: Button) {
        switch button {
        case .Button1:
            if let target = hoverTarget, !justSelectedSomething {
                    if selectedTargets.contains(target) {
                        unselectTarget(target)
                    }
                }
            justSelectedSomething = false
            
        case .Button2:
            for target in selectedTargets {
                DispatchQueue.global(qos: .userInitiated).async {
                    // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                    target.applyTransform()
                }
            }
            updatesSincePressed = 0
        default:
            break
        }
    }
    
    ///
    /**
        
     */
    func didDoubleClick(_ button: Button) {
       //empty on purpose
    }
    
    ///
    /**
        
     */
    func visitTarget(_ target: ARPGeomNode) {
        unselectTarget(target)
        target.visited = true
        visitTarget = target
    }
    
    ///
    /**
        
     */
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

    ///
    /**
        
     */
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
        hoverTarget = nil
        target.name = "generic"
        selected = false
    }
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPNode) {
        if selectedTargets.count != 1 {
            target.selected = true
            target.name = "selected"
            selected = true
            selectedTargets.append(target)
            justSelectedSomething = true
            didSelectSomething?(target)
            updatesSincePressed = 0
        }
    }
    
}
