//
//  SweepPluginProfileAndPath.swift
//  ARPen
//
//  Created by Jan Benscheid on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginProfileAndPath: ModelingPlugin {
   
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false

    override init() {
        
        super.init()
        
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "ModelingSweep1Plugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingSweep1Instructions")
        self.pluginIdentifier = "Sweep (Path)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
    }

    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                                
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    profile.usedInGeometry = true
                    path.usedInGeometry = true
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)                     
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                        
                    }
                    
                    let buildingAction = SweepBuildingAction(occtRef: sweep.occtReference!, scene: self.currentScene!, sweep: sweep)
                    self.undoRedoManager?.actionDone(buildingAction)

                    
                }
            }
        }
    }
}
