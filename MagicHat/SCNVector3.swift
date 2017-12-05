//
//  SCNVector3.swift
//  MagicHat
//
//  Created by Jennifer Liu on 30/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import ARKit

// MARK: - SCNVector3

extension SCNVector3{
    
    static func + (left: SCNVector3, right : SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func - (left: SCNVector3, right : SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func / (left: SCNVector3, right : Float) -> SCNVector3 {
        return SCNVector3(left.x / right, left.y / right, left.z / right)
    }
    
    static func * (left: SCNVector3, right : Float) -> SCNVector3 {
        return SCNVector3(left.x * right, left.y * right, left.z * right)
    }
}
