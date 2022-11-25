//
//  ARPNodeData.swift
//  ARPen
//
//  Created by Marvin Bruna on 13.05.22.
//  Copyright © 2022 RWTH Aachen. All rights reserved.
//
/*
 MARK: - Used to potentially share data regarding ARP Data such as ARPBox etc.

import Foundation

class ARPNodeData : Codable {
    // Name of the Plugin used, so we can switch case it once we receive this data
    let pluginName: String!
    
    // Radius for the Sphere
    let radius : Double?
    
    // Position for all Node-types
    let positon: SCNVector3?
    
    // Properties for Boxes/Cylinders/Pyramids
    let width : Double?
    let height: Double?
    let length: Double?
    
    
    // Color Properties so we can restore the ARPGeomNode with the same color on the other device(s)
    var hue: CGFloat?
    var saturation: CGFloat = 0.3  // THIS SHOULD BE EQUAL TO THE VALUE SET IN ARPGEOMNODE
    var brightness: CGFloat = 0.9  // THIS SHOULD BE EQUAL TO THE VALUE SET IN ARGEOPMNODE
    var alpha: CGFloat = 1         // THIS SHOULD BE EQUAL TO THE VALUE SET IN ARGEOMNODE
    
    private enum CodingKeys: String, CodingKey{
        case radius = "radius", position = "position", width = "width", height = "height", length = "length", pluginName = "pluginName", hue = "hue"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.pluginName = try values.decode(String.self, forKey: .pluginName)
        self.radius = try values.decodeIfPresent(Double.self, forKey: .radius)
        self.positon = try values.decodeIfPresent(SCNVector3.self, forKey: .position)
        self.width = try values.decodeIfPresent(Double.self, forKey: .width)
        self.height = try values.decodeIfPresent(Double.self, forKey: .height)
        self.length = try values.decodeIfPresent(Double.self, forKey: .length)
        self.hue = try values.decodeIfPresent(CGFloat.self, forKey: .hue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pluginName, forKey: .pluginName)
        try container.encodeIfPresent(radius, forKey: .radius)
        try container.encodeIfPresent(positon, forKey: .position)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(length, forKey: .length)
        try container.encodeIfPresent(hue, forKey: .hue)

    }
    
    init(pluginName: String, radius: Double? = 0.0, positon: SCNVector3? = SCNVector3(x: 0, y: 0, z: 0), width: Double? = 0.0, height: Double? = 0.0,
         length : Double? = 0.0, hue : CGFloat? = 0){
        self.pluginName = pluginName
        self.radius = radius
        self.positon = positon
        self.width = width
        self.height = height
        self.length = length
        self.hue = hue
    }
}
 */
