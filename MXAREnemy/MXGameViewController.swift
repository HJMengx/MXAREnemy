//
//  GameViewController.swift
//  MXAREnemy
//
//  Created by mx on 2017/3/20.
//  Copyright © 2017年 mengx. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation
import CoreLocation

protocol MXGameViewControllerDelegate {
    func didKillEnemy(gameViewController : MXGameViewController,enemy : MXARItem)
}

class MXGameViewController: UIViewController {

    var captureSession : AVCaptureSession!
    
    weak var cameraPreView : AVCaptureVideoPreviewLayer!
    
    @IBOutlet var sceneView: SCNView!
    
    @IBOutlet weak var leftIndicator: UILabel!
    
    @IBOutlet weak var rightIndicator: UILabel!
    
    var enemy : MXARItem!
    
    var delegate : MXGameViewControllerDelegate!
    
    var locationManager = CLLocationManager()
    var heading: Double = 0
    var userLocation = CLLocation()
   
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let targetNode = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //加载摄像头
        self.loadBackCamera()
        if self.captureSession != nil {
            self.captureSession.startRunning()
        }
        
        //1
        self.locationManager.delegate = self
        //2
        self.locationManager.startUpdatingHeading()
        
        //3
        self.sceneView.scene = scene
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        self.scene.rootNode.addChildNode(self.cameraNode)
        self.setupTarget()
    }
    //设置目标
    func setupTarget(){
        //1
        let scene = SCNScene(named: "art.scnassets/\(self.enemy.enemyDescription).dae")
        //2
        let enemy = scene?.rootNode.childNode(withName: self.enemy.enemyDescription, recursively: true)
        //3
        if self.enemy.enemyDescription == "dragon" {
            enemy?.position = SCNVector3(x: 0, y: -15, z: 0)
        } else {
            enemy?.position = SCNVector3(x: 0, y: 0, z: 0)
        }
        
        //4
        let node = SCNNode()
        node.addChildNode(enemy!)
        node.name = "敌人"
        self.enemy.itemNode = node
    }
    
    //MARK: Create Caputre
    func createCapture()->(session : AVCaptureSession?,error : NSError?){
        var error : NSError?
        
        var session : AVCaptureSession?
        
        //初始化设备
        let backVideoDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.back)
        
        //判断设备是否创建成功
        if backVideoDevice != nil {
            //创建输入设备
            var videoInput : AVCaptureDeviceInput?
            
            do{
                videoInput = try AVCaptureDeviceInput.init(device: backVideoDevice!)
            }catch let inputError as NSError{
                error = inputError
                videoInput = nil
            }
            //创建会话
            if error == nil {
                session = AVCaptureSession.init()
                //添加输入，输出
                if session!.canAddInput(videoInput!) {
                    session!.addInput(videoInput)
                }else{
                    error = NSError.init(domain: "", code: 0, userInfo: ["description": "Error adding video input."])
                }
            }else{
                //不能创建输入设备
                error = NSError.init(domain: "", code: 0, userInfo: ["description": "Error Creating video input."])
            }
        }else{
            //不能创建后摄像头
            error = NSError.init(domain: "", code: 0, userInfo: ["description": "Error Creating video Device."])
        }
        
        return (session,error)
    }
    
    func loadBackCamera(){
        let sessionResult = self.createCapture()
        
        guard sessionResult.error == nil,sessionResult.session != nil else {
            print("\n\n error is \(sessionResult.error?.userInfo["description"]) \n\n")
            print("Error Can not  Creating Session")
            return
        }
        
        //赋值
        self.captureSession = sessionResult.session!
        
        //添加预览层
        if let cameraLayer = AVCaptureVideoPreviewLayer.init(session: self.captureSession) {
            
            cameraLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            cameraLayer.frame = self.view.bounds
            
            self.cameraPreView = cameraLayer
            
            self.view.layer.insertSublayer(self.cameraPreView, at: 0)
        }
        
    }
    
    //MARK: Action
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //1
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        
        //2
        let hitResult = sceneView.hitTest(location, options: nil)
        //3
        let fireBall = SCNParticleSystem(named: "Fireball.scnp", inDirectory: "art.scnassets")
        //4
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(x: 0, y: -5, z: 10)
        emitterNode.addParticleSystem(fireBall!)
        scene.rootNode.addChildNode(emitterNode)
        
        //5
        if hitResult.first != nil {
            //6
            self.enemy.itemNode?.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.removeFromParentNode(), SCNAction.hide()]))
            //1
            let sequence = SCNAction.sequence(
                [SCNAction.move(to: self.enemy.itemNode!.position, duration: 0.5),
                 //2
                    SCNAction.wait(duration: 3.5),
                    //3
                    SCNAction.run({_ in
                        self.delegate?.didKillEnemy(gameViewController: self, enemy: self.enemy)
                    })])
            emitterNode.runAction(sequence)
            
        } else {
            //7
            emitterNode.runAction(SCNAction.move(to: SCNVector3(x: 0, y: 0, z: -30), duration: 0.5))
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func repositionTarget(){
        //1
        let heading = self.getHeadingForDirectionFromCoordinate(from: userLocation, to: self.enemy.location)
        
        //2
        let delta = heading - self.heading
        
        if delta < -15.0 {
            leftIndicator.isHidden = false
            rightIndicator.isHidden = true
        } else if delta > 15 {
            leftIndicator.isHidden = true
            rightIndicator.isHidden = false
        } else {
            leftIndicator.isHidden = true
            rightIndicator.isHidden = true
        }
        
        //3
        let distance = userLocation.distance(from: self.enemy.location)
        
        //4
        if let node = self.enemy.itemNode {
            
            //5
            if node.parent == nil {
                node.position = SCNVector3(x: Float(delta), y: 0, z: Float(-distance))
                scene.rootNode.addChildNode(node)
            } else {
                //6
                node.removeAllActions()
                node.runAction(SCNAction.move(to: SCNVector3(x: Float(delta), y: 0, z: Float(-distance)), duration: 0.2))
            }
        }
    }
    func radiansToDegrees(_ radians: Double) -> Double {
        return (radians) * (180.0 / M_PI)
    }
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return (degrees) * (M_PI / 180.0)
    }
    
    func getHeadingForDirectionFromCoordinate(from: CLLocation, to: CLLocation) -> Double {
        //将经纬度转换为弧度
        let fLat = degreesToRadians(from.coordinate.latitude)
        let fLng = degreesToRadians(from.coordinate.longitude)
        let tLat = degreesToRadians(to.coordinate.latitude)
        let tLng = degreesToRadians(to.coordinate.longitude)
        
        //将弧度转换为角度
        let degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)))
        
        //如果值为负，则添加 360 度使它为正。这没有错，因为 -90 度其实就是 270 度。
        if degree >= 0 {
            return degree
        } else {
            return degree + 360
        }
    }
}

extension MXGameViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = fmod(newHeading.trueHeading, 360.0)
        self.repositionTarget()
    }
}
