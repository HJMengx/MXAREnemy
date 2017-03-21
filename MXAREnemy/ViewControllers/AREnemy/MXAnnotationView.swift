//
//  MXAnnotationView.swift
//  MXAREnemy
//
//  Created by mx on 2017/3/21.
//  Copyright © 2017年 mengx. All rights reserved.
//

import UIKit
import MapKit

class MXAnnotationView: NSObject,MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D

    var title: String?
    
    var item : MXARItem!
    
    init(coordinate : CLLocationCoordinate2D,item : MXARItem) {
        
        self.coordinate = coordinate
        
        self.item = item
        
        self.title = item.enemyDescription
        
        super.init()
    }
}
