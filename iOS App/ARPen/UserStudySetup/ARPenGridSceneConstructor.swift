//
//  SceneConstructor.swift
//  ARPen
//
//  Created by Philipp Wacker on 02.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit
import CSVLogger


struct ARPenGridSceneConstructor : ARPenSceneConstructor {
    
    let numberOfStudyNodes = 64
    
    
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode]) {
        var studyNodes : [ARPenStudyNode] = []
        let superNode = SCNNode()
    

        
        let cubesPerDimension = Int(floor(pow(Double(numberOfStudyNodes), 1/3)))
        
        
        let screenCenterPosition = view.unprojectPoint(SCNVector3(x: Float(view.frame.width) / 2.0, y: Float(view.frame.height / 2.0), z: 0))
        superNode.position = screenCenterPosition
        superNode.position.z -= 0.4
        superNode.position.y -= 0.3
        
        var lookAtPoint = screenCenterPosition
        lookAtPoint.y = superNode.position.y
        superNode.look(at: lookAtPoint)
        
        var x = -0.15
        var y = 0.05
        var z = -0.25
        
        var arPenStudyNode : ARPenStudyNode
        
        for _ in 0...cubesPerDimension {
            
            y = 0.25
            
            //Changed this such that we have one more cube in this dimension, original was Int(cubesPerDimension/2)
            for _ in 0...Int(cubesPerDimension/2 + 1) {
                
                z = -0.25
                
                for _ in 0...cubesPerDimension{
                    
                    let dimensionOfBox = 0.03 //+ Double(Int.random(in: 0 ... 1)) * 0.01
                    let range = (-0.025, 0.025)
                    
                    let randomDoubleForX = drand48()
                    let randomDoubleForY = drand48()
                    let randomDoubleForZ = drand48()
                    
                    
                    let distance = range.1 - range.0
                    let xPositionOffset = range.0 + (randomDoubleForX * distance)
                    let yPositionOffset = range.0 + (randomDoubleForY * distance)
                    let zPositionOffset = range.0 + (randomDoubleForZ * distance)
                    
                    arPenStudyNode = studyNodeClass.init(withPosition: SCNVector3Make(Float(x + xPositionOffset), Float(y + yPositionOffset), Float(z + zPositionOffset)), andDimension: Float(dimensionOfBox))
                    studyNodes.append(arPenStudyNode)
                    
                    //lowered original value from 0.1 to 0.09 to keep cubes closer together, creating a more dense scene with more potential occlusion
                    z += 0.09
                    
                }
                //lowered original value from 0.1 to 0.09 to keep cubes closer together, creating a more dense scene with more potential occlusion
                y += 0.09
                
            }
            //lowered original value from 0.1 to 0.09 to keep cubes closer together, creating a more dense scene with more potential occlusion
            x += 0.09
            
        }
        
        studyNodes.shuffle()
        studyNodes.forEach({superNode.addChildNode($0)})
        
        return (superNode, studyNodes)
    }
    
    
}
