//
//  RNSphereImageViewController.swift
//  RNSphereImageViewController
//
//  Created by mothule on 2016/09/06.
//  Copyright © 2016年 mothule. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

/**
 Configuration for RNSphereImageViewController.
 It try to create as ajust as one can.
 */
public struct RNSIConfiguration {
    // Frame per second
    public var fps: Int = 60

    // field of view
    public var fovy: Float = 60

    // max distance from center
    public var zoomOutMax: Float = 100.0

    // file's path of a image's file for Texture.
    public var filePath: String?

    // UIImage for Texture
    public var image: UIImage?

    // a friction will use camera smooth move.
    public var frictionOfCameraMove: Float = 0.9

    // Sphere segment count
    public var segmentCount: Int = 32
}

/**

 */
public protocol RNSIDelegate : class {
    // It will call when fail load a texture.
    func failLoadTexture(_ error: Error)

    // It will call when abort for memory not enought.
    func abortForMemoryNotEnough()

    // It will call when
    func completeSetup(_ view: UIView)
}

/**
    This view controller can watch a spherical image.
 */
open class RNSphereImageViewController: UIViewController, SCNSceneRendererDelegate {

    // camera
    fileprivate var positionZ: SCNFloat = 0.0
    fileprivate var maxPositionZ: SCNFloat = -3.0

    // posture
    fileprivate var rotationYaw: SCNFloat = 0.0
    fileprivate var rotationPitch: SCNFloat = 0.0
    fileprivate var rotationVelocityYaw: SCNFloat = 0.0
    fileprivate var rotationVelocityPitch: SCNFloat = 0.0

    // renderer
    private var previousTime: TimeInterval = 0.0

    // input
    fileprivate var touchPrevPoint: CGPoint = CGPoint.zero

    // delegate
    open var userDelegate: RNSIDelegate?

    // required.
    var configuration: RNSIConfiguration!

    private weak var cameraNode: SCNNode!
    private weak var modelNode: SCNNode!

    override open var prefersStatusBarHidden: Bool { return true }
    override open var shouldAutorotate: Bool { return true }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneView = SCNView()
        self.view = sceneView
        sceneView.delegate = self
        sceneView.preferredFramesPerSecond = configuration.fps
        sceneView.rendersContinuously = true
        
        sceneView.backgroundColor = UIColor.gray
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 0)
        cameraNode.camera!.fieldOfView = CGFloat(configuration.fovy)
        cameraNode.camera!.zFar = Double(configuration.zoomOutMax)
        scene.rootNode.addChildNode(cameraNode)
        self.cameraNode = cameraNode
        
        let sphere = SCNSphere(radius: 100)
        sphere.segmentCount = configuration.segmentCount
        
        let image = findImage(with: configuration)
        sphere.materials.first?.diffuse.contents = image
        sphere.materials.first?.isDoubleSided = true
        let sphereNode = SCNNode(geometry:  sphere)
        scene.rootNode.addChildNode(sphereNode)
        modelNode = sphereNode
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)
        self.view.layer.magnificationFilter = CALayerContentsFilter.linear
        self.view.layer.minificationFilter = CALayerContentsFilter.linear
        
        userDelegate?.completeSetup(self.view)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil
        }
        userDelegate?.abortForMemoryNotEnough()
    }

    private func findImage(with configuration: RNSIConfiguration) -> UIImage? {
        if let filePath = configuration.filePath {
            return UIImage(named: filePath)
        } else if let image = configuration.image {
            return image
        }
        let error = NSError(domain: "texture", code: -1, userInfo: nil)
        userDelegate?.failLoadTexture(error)
        return nil
    }

    // MARK: - SCNSceneRendererDelegate
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let timeSinceLastUpdate = time - previousTime
        defer {
            previousTime = time
        }

        // Camera matrix
        var matrix = SCNMatrix4MakeTranslation(0, 0, positionZ)
        let horizontal = SCNVector3(0, 1, 0).cross(vector: SCNVector3(sinf(rotationYaw), 0.0, cosf(rotationYaw))).normalized()
        matrix = SCNMatrix4Rotate(matrix, rotationYaw, 0, 1, 0)
        matrix = SCNMatrix4Rotate(matrix, rotationPitch, horizontal.x, horizontal.y, horizontal.z)
        cameraNode.transform = matrix
        
        // Auto rotate
        rotationYaw += Float(timeSinceLastUpdate * Double(0.1))

        let pi_2: SCNFloat = SCNFloat.pi / 2.0

        // Inertia and camera work
        rotationYaw += SCNFloat(timeSinceLastUpdate * Double(rotationVelocityYaw))
        if positionZ < 0.0 {
            positionZ -= SCNFloat(timeSinceLastUpdate * Double(rotationVelocityPitch))

        } else {
            rotationPitch += SCNFloat(timeSinceLastUpdate * Double(rotationVelocityPitch))
            if rotationPitch > pi_2 {
                positionZ -= (rotationPitch - pi_2)
            }
        }

        // Clamp
        if rotationPitch > pi_2 {
            rotationPitch = pi_2
        } else if rotationPitch < -pi_2 {
            rotationPitch = -pi_2
        }
        if positionZ < maxPositionZ {
            positionZ = maxPositionZ
            rotationVelocityPitch = 0.0
        }
        if positionZ > 0.0 {
            positionZ = 0.0
        }

        // Friction
        rotationVelocityYaw *= configuration.frictionOfCameraMove
        rotationVelocityPitch *= configuration.frictionOfCameraMove
        if fabsf(rotationVelocityYaw) <= 0.0000001 {
            rotationVelocityYaw = 0.0
        }
        if fabsf(rotationVelocityPitch) <= 0.0000001 {
            rotationVelocityPitch = 0.0
        }
    }

   
    // MARK: - Input
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        rotationVelocityYaw = 0.0
        rotationVelocityPitch = 0.0

        let touch: UITouch = touches.first! as UITouch
        touchPrevPoint = touch.location(in: self.view)
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        let touch: UITouch = touches.first! as UITouch
        let pos: CGPoint = touch.location(in: self.view)

        
        let distanceX = sqrtf(Float(pos.x - touchPrevPoint.x) * Float(pos.x - touchPrevPoint.x))
        let distanceY = sqrtf(Float(pos.y - touchPrevPoint.y) * Float(pos.y - touchPrevPoint.y))

        let radianX = atanf((distanceX/2.0)/50.0) * 2.0 // 50 is feeling
        rotationVelocityYaw   += radianX * (touchPrevPoint.x - pos.x < 0.0 ? -1.0 : 1.0)

        let radianY = atanf((distanceY/2.0)/50.0) * 2.0
        rotationVelocityPitch += radianY * (touchPrevPoint.y - pos.y < 0.0 ? -1.0 : 1.0)

        touchPrevPoint = pos
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
