//
//  MXARItem.swift
//  MXAREnemy
//
//  Created by mx on 2017/3/21.
//  Copyright © 2017年 mengx. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

struct MXARItem {
    let location : CLLocation
    
    let enemyDescription : String
    
    var itemNode : SCNNode?
}
