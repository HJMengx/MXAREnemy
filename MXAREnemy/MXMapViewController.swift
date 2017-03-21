//
//  MXMapViewController.swift
//  MXAREnemy
//
//  Created by mx on 2017/3/20.
//  Copyright © 2017年 mengx. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MXMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate var userLocaltionManager : CLLocationManager = CLLocationManager.init()
    
    var enemys : [MXARItem] = [MXARItem]()
    
    var currentUserLocation : CLLocation?
    
    var selectedAnnotation : MXAnnotationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //请求授权等相关操作
        self.requestAuthorization()
        //跟踪位置
        self.mapView.userTrackingMode = .follow
        //显示用户位置
        self.mapView.showsUserLocation = true
        //mapView 模式
//        self.mapView.mapType = .satellite
        //设置敌人
        self.setupEnemys()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //添加敌人位置
        for enemy in self.enemys {
            self.mapView.addAnnotation(MXAnnotationView.init(coordinate: enemy.location.coordinate, item: enemy))
        }
    }
    
    //MARK: Position
    func setupEnemys(){
            //CurrentPosition location is longtitude is 112.366714631414 and latitude is 26.968948366096
            //26.9657660000,112.3721890000 26.9656990000,112.3724150000 26.9659670000,112.3723450000 26.9655360000,112.3722110000
        //这个位置需要改变，基于自己现在位置最好
        let enemy1 = MXARItem(location: CLLocation.init(latitude: 26.965766000, longitude:
            112.3721890000), enemyDescription: "wolf",itemNode: nil)
        
        let enemy2 = MXARItem(location: CLLocation.init(latitude: 26.9656990000, longitude:
            112.3724150000 ), enemyDescription: "wolf",itemNode: nil)
        
        let enemy3 = MXARItem(location: CLLocation.init(latitude: 26.9659670000, longitude:
            112.3723450000), enemyDescription: "wolf",itemNode: nil)
        
        let enemy4 = MXARItem(location: CLLocation.init(latitude: 26.9655360000, longitude:
            112.3722110000), enemyDescription: "wolf",itemNode: nil)
        
        self.enemys.append(enemy1)
        self.enemys.append(enemy2)
        self.enemys.append(enemy3)
        self.enemys.append(enemy4)
    }
    
    private func requestAuthorization(){
        self.userLocaltionManager.delegate = self
        self.mapView.delegate = self
        //十米刷新一次
        self.userLocaltionManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            //请求权限
            self.userLocaltionManager.requestWhenInUseAuthorization()
        }
        //开始监听位置
        self.userLocaltionManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cameraOperation(_ sender: UIButton) {
        
    }
    
}



extension MXMapViewController : CLLocationManagerDelegate,MKMapViewDelegate,MXGameViewControllerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            //取得最后一个位置
            let lastLocation = locations.last!
            //位置范围
            if lastLocation.horizontalAccuracy < 100 {
                manager.stopUpdatingLocation()
                //缩放,地图范围
                let span = MKCoordinateSpan.init(latitudeDelta: 0.014, longitudeDelta: 0.014)
                
                //地图显示
                let region = MKCoordinateRegion.init(center: lastLocation.coordinate, span: span)
                
                self.mapView.region = region
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        self.currentUserLocation = userLocation.location
    }
    //选中了
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //计算距离
        let selectCoordinate = view.annotation!.coordinate
        
        if let userCoordinate = self.currentUserLocation {
            //判断距离,小于100米
            if userCoordinate.distance(from: CLLocation.init(latitude: selectCoordinate.latitude, longitude: selectCoordinate.longitude)) < 100 {
                
                let storyBoard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
                
                if let gameViewController =  storyBoard.instantiateViewController(withIdentifier: "MXGameViewController") as? MXGameViewController {
                    if let annotation = view.annotation as? MXAnnotationView{
                        //设置选中
                        self.selectedAnnotation = annotation
                        //跳转
                        gameViewController.enemy = annotation.item
                        
                        gameViewController.delegate = self
                        
                        
                        gameViewController.userLocation = self.mapView.userLocation.location!
                        
                        self.present(gameViewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func didKillEnemy(gameViewController: MXGameViewController, enemy: MXARItem) {
        
        
        DispatchQueue.main.async {
            gameViewController.dismiss(animated: true, completion: nil)
            
            let index = self.enemys.index { (item : MXARItem) -> Bool in
                return item.location == enemy.location
            }
            
            self.enemys.remove(at: index!)
            
            if self.selectedAnnotation != nil {
                
                self.mapView.removeAnnotation(self.selectedAnnotation)
                
                self.selectedAnnotation = nil
            }
        }
    }
}
