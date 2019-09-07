//
//  RNSphereImageViewController.swift
//  RNSphereImageViewController
//
//  Created by mothule on 2016/09/06.
//  Copyright © 2016年 mothule. All rights reserved.
//

import GLKit
import OpenGLES

/**
 Configuration for RNSphereImageViewController.
 It try to create as ajust as one can.
 */
public struct RNSIConfiguration {
    // Frame per second
    public var fps: Int = 30

    // field of view
    public var fovy: Float = 50

    // max distance from center
    public var zoomOutMax: Float = 3.0

    // file's path of a image's file for Texture.
    public var filePath: String?

    // UIImage for Texture
    public var image: UIImage?

    // options of GLKTextureLoader
    public var textureLoadOptions: [String : NSNumber] = [GLKTextureLoaderOriginBottomLeft:NSNumber(value: true as Bool)]

    // a friction will use camera smooth move.
    public var frictionOfCameraMove: Float = 0.9

    // sphere stack size
    public var stackSize: Int = 32

    // sphere slice size
    public var sliceSize: Int = 32
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
open class RNSphereImageViewController: GLKViewController {

    // camera
    fileprivate var fovyDegree: GLfloat = 50.0
    fileprivate var positionZ: GLfloat = 0.0
    fileprivate var maxPositionZ: GLfloat = -3.0

    // posture
    fileprivate var rotationYaw: Float = 0.0
    fileprivate var rotationPitch: Float = 0.0
    fileprivate var rotationVelocityYaw: Float = 0.0
    fileprivate var rotationVelocityPitch: Float = 0.0

    // input
    fileprivate var touchPrevPoint: CGPoint = CGPoint.zero


    // draw data
    fileprivate var sphereVertexData: [GLfloat]?
    fileprivate var vertexArray: GLuint = 0
    fileprivate var vertexBuffer: GLuint = 0
    fileprivate var textureInfo: GLKTextureInfo?

    // draw
    fileprivate var context: EAGLContext? = nil
    fileprivate var effect: GLKBaseEffect? = nil

    // delegate
    open var userDelegate: RNSIDelegate?

    // required.
    var configuration: RNSIConfiguration!

    deinit {
        self.tearDownGL()

        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.context = EAGLContext(api: .openGLES2)
        if !(self.context != nil) {
            print("Failed to create ES context")
        }

        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24

        self.view.layer.magnificationFilter = CALayerContentsFilter.linear
        self.view.layer.minificationFilter = CALayerContentsFilter.linear
        sphereVertexData = getSphere()
        preferredFramesPerSecond = configuration.fps
        fovyDegree = GLfloat(configuration.fovy)
        maxPositionZ = GLfloat(-configuration.zoomOutMax)

        self.setupGL()
        userDelegate?.completeSetup(self.view)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil

            self.tearDownGL()

            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }

        userDelegate?.abortForMemoryNotEnough()
    }


    fileprivate func setupGL() {


        EAGLContext.setCurrent(self.context)

        self.effect = GLKBaseEffect()
        self.effect!.useConstantColor = GLboolean(GL_TRUE)

        glEnable(GLenum(GL_CULL_FACE))
        glFrontFace(GLenum(GL_CW))

        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)

        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * sphereVertexData!.count), &sphereVertexData!, GLenum(GL_STATIC_DRAW))

        do {
            if let filePath = configuration.filePath {
                textureInfo = try GLKTextureLoader.texture(withContentsOfFile: filePath, options: configuration.textureLoadOptions)
            } else if let image = configuration.image {
                textureInfo = try GLKTextureLoader.texture(with: image.cgImage!, options: configuration.textureLoadOptions)
            }

        } catch {
            print(error)
            userDelegate?.failLoadTexture(error)
        }

        // 頂点情報の設定
        let strideSize: Int32 = Int32(MemoryLayout<GLfloat>.size * 5)
        // XYZ座標
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), strideSize, nil)
        // 2Dテクスチャ
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), strideSize, BUFFER_OFFSET(12))

        glBindVertexArrayOES(0)
    }
    
    fileprivate func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer {
        return UnsafeRawPointer(bitPattern: i)!
    }

    fileprivate func tearDownGL() {
        EAGLContext.setCurrent(self.context)

        if let _ = self.textureInfo {
            var name: GLuint = self.textureInfo!.name
            glDeleteTextures(1, &name)
        }
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)

        self.effect = nil
    }

    // MARK: - GLKView and GLKViewController delegate methods
    func update() {
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fovyDegree), aspect, 0.01, 50.0)

        self.effect?.transform.projectionMatrix = projectionMatrix

        self.effect?.texture2d0.enabled = GLboolean(GL_TRUE)
        self.effect?.texture2d0.name = textureInfo!.name

        var baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, positionZ)
        baseModelViewMatrix = GLKMatrix4RotateWithVector3(baseModelViewMatrix, rotationYaw, GLKVector3Make(0, 1, 0))
        baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotationPitch, cosf(rotationYaw), 0.0, sinf(rotationYaw) )

        // Compute the model view matrix for the object rendered with GLKit
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 0.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        self.effect?.transform.modelviewMatrix = modelViewMatrix

        // Auto rotate
        rotationYaw += Float(self.timeSinceLastUpdate * Double(0.1))

        let pi_2: GLfloat = GLfloat(Double.pi / 2.0)

        // Inertia and camera work
        rotationYaw += Float(self.timeSinceLastUpdate * Double(rotationVelocityYaw))
        if positionZ < 0.0 {
            positionZ -= Float(self.timeSinceLastUpdate * Double(rotationVelocityPitch))

        } else {
            rotationPitch += Float(self.timeSinceLastUpdate * Double(rotationVelocityPitch))
            if rotationPitch > pi_2 {
                positionZ -= (rotationPitch - pi_2)
            }
        }

//        // Clamp
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

    override open func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(1.0, 1.0, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))

        glBindVertexArrayOES(vertexArray)

        // Render the object with GLKit
        self.effect?.prepareToDraw()

//        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(gSphereVertexData.count/5))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(sphereVertexData!.count/5))
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

        let distanceX = sqrtf( Pow(Float(pos.x - touchPrevPoint.x) ))
        let distanceY = sqrtf( Pow(Float(pos.y - touchPrevPoint.y) ))

        let radianX = atanf((distanceX/2.0)/50.0) * 2.0 // 50 is feeling
        rotationVelocityYaw   += radianX * (touchPrevPoint.x - pos.x < 0.0 ? -1.0 : 1.0)

        let radianY = atanf((distanceY/2.0)/50.0) * 2.0
        rotationVelocityPitch += radianY * (touchPrevPoint.y - pos.y < 0.0 ? -1.0 : 1.0)

        touchPrevPoint = pos
    }

    fileprivate func Pow(_ val: Float) -> Float {
        return val * val
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }


    fileprivate func getSphere() -> [GLfloat] {

        let pi2: Double = 2.0 * Double.pi
        let stackSize = configuration.stackSize
        let vtxSize = configuration.sliceSize
        let maxRadius: Double = 1.0

        var vtxes: [GLfloat] = []

        for stackIdx in 0..<stackSize {
            let r1      =  sin(Double.pi   * (Double(stackIdx    ) / Double(stackSize)))
            let h1      = -cos(Double.pi   * (Double(stackIdx    ) / Double(stackSize)))
            let r2      =  sin(Double.pi   * (Double(stackIdx + 1) / Double(stackSize)))
            let h2      = -cos(Double.pi   * (Double(stackIdx + 1) / Double(stackSize)))
            let tv1     =  Double(stackIdx  ) / Double(stackSize)
            let tv2     =  Double(stackIdx+1) / Double(stackSize)
//            print("現階層:\(stackIdx) 現階層の高さ:\(h1) 現階層の中心からの距離:\(r1) 次階層の高さ:\(h2) 次階層の中心からの距離:\(r2)")
//            print("Current stack No:\(stackIdx) Current level:\(h1) Current distance from center:\(r1) Next level:\(h2) Next distance from center:\(r2)")

            let radius1: Double = maxRadius * r1
            let radius2: Double = maxRadius * r2

            let uStride: Double = 1.0 / Double(vtxSize)

            for vtxIdx in 0..<vtxSize {
                let theta1: Double = pi2 * (Double(vtxIdx    ) / Double(vtxSize))
                let theta2: Double = pi2 * (Double(vtxIdx + 1) / Double(vtxSize))
                let tu1: Double    = Double(vtxIdx    ) * uStride
                let tu2: Double    = Double(vtxIdx + 1) * uStride


                let x11: GLfloat = GLfloat(radius1 * cos(theta1))
                let y11: GLfloat = GLfloat(radius1 * sin(theta1))
                let u11: GLfloat = GLfloat(tu1)
                let v11: GLfloat = GLfloat(tv1)

                let x12: GLfloat = GLfloat(radius1 * cos(theta2))
                let y12: GLfloat = GLfloat(radius1 * sin(theta2))
                let u12: GLfloat = GLfloat(tu2)
                let v12: GLfloat = GLfloat(tv1)

                let x21: GLfloat = GLfloat(radius2 * cos(theta1))
                let y21: GLfloat = GLfloat(radius2 * sin(theta1))
                let u21: GLfloat = GLfloat(tu1)
                let v21: GLfloat = GLfloat(tv2)

                let x22: GLfloat = GLfloat(radius2 * cos(theta2))
                let y22: GLfloat = GLfloat(radius2 * sin(theta2))
                let u22: GLfloat = GLfloat(tu2)
                let v22: GLfloat = GLfloat(tv2)

                // 最初のuと最後のuで頂点間のu幅が違う
                // は調べてない


                vtxes += [x11, GLfloat(h1), y11, u11, v11]
                vtxes += [x21, GLfloat(h2), y21, u21, v21]
                vtxes += [x22, GLfloat(h2), y22, u22, v22]
//                print("v1(\(x11),\(h1),\(y11), \(u11),\(v11)) v2(\(x21),\(h2),\(y21), \(u21),\(v21)) v3(\(x22),\(h2),\(y22), \(u22),\(v22))")

                vtxes += [ x11, GLfloat(h1), y11, u11, v11]
                vtxes += [ x22, GLfloat(h2), y22, u22, v22]
                vtxes += [ x12, GLfloat(h1), y12, u12, v12]
//                print("v4(\(x11),\(h1),\(y11), \(u11),\(v11)) v5(\(x22),\(h2),\(y22), \(u22),\(v22)) v6(\(x12),\(h1),\(y12), \(u12),\(v12))")
            }
        }
        return vtxes
    }
}
