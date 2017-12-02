//
//  SCNNode.swift
//  MagicHat
//
//  Created by Jennifer Liu on 30/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import ARKit

// MARK: - SCNNode

extension SCNNode {
    
    func boundingBoxContains(point: SCNVector3, in node: SCNNode) -> Bool {
        let localPoint = convertPosition(point, from: node)
        return boundingBoxContains(point: localPoint)
    }
    
    func boundingBoxContains(point: SCNVector3) -> Bool {
        return BoundingBox(boundingBox).contains(point)
    }
    
    struct BoundingBox {
        let min: SCNVector3
        let max: SCNVector3
        
        init(_ boundTuple: (min: SCNVector3, max: SCNVector3)) {
            min = boundTuple.min
            max = boundTuple.max
        }
        
        func contains(_ point: SCNVector3) -> Bool {
            let contains =
                min.x <= point.x &&
                    min.y <= point.y &&
                    min.z <= point.z &&
                    
                    max.x > point.x &&
                    max.y > point.y &&
                    max.z > point.z
            
            return contains
        }
    }
}
