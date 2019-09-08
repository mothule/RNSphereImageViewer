//
//  SCNVector3+Extension.swift
//  RNSphereImageViewController
//
//  Created by motoki kawakami on 2019/09/09.
//  Copyright © 2019 mothule. All rights reserved.
//

import QuartzCore
import SceneKit

extension SCNVector3
{
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    func normalized() -> SCNVector3 {
        return self / length()
    }
}

func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}
