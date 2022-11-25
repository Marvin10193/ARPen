//
//  Utilities.swift
//  ARPen
//
//  Created by Krishna Subramanian on 20.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import simd
import ARKit

extension UIViewController {
    func showAlert(title: String,
                   message: String,
                   buttonTitle: String = "OK",
                   showCancel: Bool = false,
                   buttonHandler: ((UIAlertAction) -> Void)? = nil) {
        print(title + "\n" + message)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonHandler))
        if showCancel {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func makeRoundedCorners(button: UIButton!) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = button.frame.width/2
    }
}

extension CGImagePropertyOrientation {
    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}

@available(iOS 12.0, *)
extension ARWorldMap {
    var snapshotAnchor: SnapshotAnchor? {
        return anchors.compactMap { $0 as? SnapshotAnchor }.first
    }
}

// Setup notification names to be observed
extension Notification.Name {
    static let cameraDidChangeTrackingState = Notification.Name("cameraDidChangeTrackingState")
    static let sessionDidUpdate = Notification.Name("sessionDidUpdate")
    static let virtualObjectDidRenderAtAnchor = Notification.Name("virtualObjectDidRenderAtAnchor")
    static let shareSCNNodeData = Notification.Name("shareSCNNodeData")
    static let shareARPNodeData = Notification.Name("shareARPNodeData")
    static let labelCommand = Notification.Name("labelCommand")
    static let nodeCommand = Notification.Name("nodeCommand")
    static let changeModeCommand = Notification.Name("changeModeCommand")
    static let changeTaskMode = Notification.Name("changeTaskMode")
    static let changeSceneCommand = Notification.Name("changeSceneCommand")
    static let changePositionCommand = Notification.Name("changePositionCommand")
    static let infoLabelCommand = Notification.Name("infoLabelCommand")
    static let measurementCommand = Notification.Name("measurementCommand")
    static let alertCommand = Notification.Name("alertCommand")
    static let sequenceData = Notification.Name("sequenceData")
    static let trialLogConfirmation = Notification.Name("trialLogConfirmation")
}

@available(iOS 12.0, *)
extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .limited:
            return "Limited"
        case .extending:
            return "Extending"
        case .mapped:
            return "Mapped"
        }
    }
}

extension ARCamera.TrackingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .notAvailable:
            return "Not Available"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.excessiveMotion):
            return "Excessive Motion"
        case .limited(.insufficientFeatures):
            return "Insufficient Features"
        case .limited(.relocalizing):
            return "Relocalizing"
        }
    }
}

extension ARCamera.TrackingState {
    var localizedFeedback: String {
        switch self {
        case .normal:
            // No planes detected; provide instructions for this app's AR interactions.
            return "Move around to map the environment."

        case .notAvailable:
            return "Tracking unavailable."

        case .limited(.excessiveMotion):
            return "Move the device more slowly."

        case .limited(.insufficientFeatures):
            return "Point the device at an area with visible surface detail, or improve lighting conditions."

        case .limited(.relocalizing):
            return "Resuming session — move to where you were when the session was interrupted."

        case .limited(.initializing):
            return "Initializing AR session."
        }
    }
}

// MARK: - Utilities used in SharedAR
// Creates a 3D Coordinate System, displayed on the ARImageAnchor when tracked, to give an indication that the WorldOrigin has been reset
extension SCNGeometry{
    
    static func generateCoordinateSystemAxes(length: Float = 0.1, thickness: Float = 2.0, color: Int) -> SCNNode {
        let thicknessInM = (length/100) * thickness
        let cornerRadius = thickness / 2.0
        let offset = length / 2.0
        let xAxisBox = SCNBox.init(width: CGFloat(length), height: CGFloat(thicknessInM), length: CGFloat(thicknessInM), chamferRadius: CGFloat(cornerRadius))
        let yAxisBox = SCNBox.init(width: CGFloat(thicknessInM), height: CGFloat(length), length: CGFloat(thicknessInM), chamferRadius: CGFloat(cornerRadius))
        let zAxisBox = SCNBox.init(width: CGFloat(thicknessInM), height: CGFloat(thicknessInM), length: CGFloat(length), chamferRadius: CGFloat(cornerRadius))
        
        if color == 1{
            xAxisBox.firstMaterial?.diffuse.contents = UIColor.red
            yAxisBox.firstMaterial?.diffuse.contents = UIColor.green
            zAxisBox.firstMaterial?.diffuse.contents = UIColor.blue
        }
        else if color != 1{
            xAxisBox.firstMaterial?.diffuse.contents = UIColor.yellow
            yAxisBox.firstMaterial?.diffuse.contents = UIColor.orange
            zAxisBox.firstMaterial?.diffuse.contents = UIColor.brown
        }
        
        let xAxis = SCNNode(geometry: xAxisBox)
        let yAxis = SCNNode(geometry: yAxisBox)
        let zAxis = SCNNode(geometry: zAxisBox)
        
        xAxis.position = SCNVector3Make(offset, 0, 0)
        yAxis.position = SCNVector3Make(0,offset,0)
        zAxis.position = SCNVector3Make(0, 0, offset)
        
        let axes = SCNNode()
        
        axes.addChildNode(xAxis)
        axes.addChildNode(yAxis)
        axes.addChildNode(zAxis)
        
        return axes
    }
}

/* Was used for sharing SCNVector3 in earlier versions. Leaving it here for potential future use.
extension SCNVector3: Codable {
    private enum CodingKeys: String, CodingKey{
        case x,y,z
    }
    
    public init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let x = try values.decode(Float.self, forKey: .x)
        let y = try values.decode(Float.self, forKey: .y)
        let z = try values.decode(Float.self, forKey: .z)
        self.init(x,y,z)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
    }
}*/

/*
extension String{
    func fileName() -> String{
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
    
    func fileExtension() -> String{
        return URL(fileURLWithPath: self).pathExtension
    }
}*/

// Structure of the JSON, loading the sequenceData results in the the structs seen here.
struct ResponseData : Decodable{
    var id: [ID]
}

struct ID: Decodable{
    var scene: [Scene]
}

struct Scene: Decodable{
    var sequence: [Sequence]
}

struct Sequence : Decodable{
    var node : [ColoredNode]
}

struct ColoredNode : Decodable{
    var index : Int
}

//Used to chunk arrays into specific sizes, was used for the creation of the scenes and to later on countercheck in SharedARPlugin
extension Array{
    func chunked(into size: Int) -> [[Element]]{
        return stride(from: 0, to: count, by: size).map{
            Array(self[$0 ..< Swift.min($0 + size,count)])
        }
    }
}
