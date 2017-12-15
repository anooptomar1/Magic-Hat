//
//  ViewController.swift
//  MagicHat
//
//  Created by Jennifer Liu on 29/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Outlets

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var throwBallButton: UIButton!
    @IBOutlet weak var magicButton: UIButton!
    
    // MARK: Properties
    
    private var planeAnchor: ARPlaneAnchor?
    private var hatNode: SCNNode?
    private var currentBallNode: SCNNode?
    private var balls = [SCNNode]()
    private var trackingTimer: Timer?
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Show instruction
        AlertView.showAlert(controller: self, message: AlertView.Messages.instruction)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if the device supports ARWorldTrackingConfiguration
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            
            // Enable plane detection
            configuration.planeDetection = .horizontal
            
            sceneView.session.run(configuration)
            
        } else {
            let configuration = AROrientationTrackingConfiguration()
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: Actions
    
    @IBAction func throwBall(_ sender: Any) {
        
        // Create ball
        let ball = SCNSphere(radius: 0.02)
        currentBallNode = SCNNode(geometry: ball)
        currentBallNode?.physicsBody = .dynamic()
        currentBallNode?.physicsBody?.friction = 0.5
        currentBallNode?.physicsBody?.rollingFriction = 0.6
        currentBallNode?.physicsBody?.allowsResting = true
        currentBallNode?.physicsBody?.isAffectedByGravity = true
        
        // Apply transformation
        let camera = sceneView.session.currentFrame?.camera
        let cameraTransform = camera?.transform
        currentBallNode?.simdTransform = cameraTransform!
        
        // Add current ball node to balls array
        balls.append(currentBallNode!)
        
        // Add ball to the scene
        sceneView.scene.rootNode.addChildNode(currentBallNode!)
        
        // Set force to be applied
        let force = simd_make_float4(0, 0, -3, 0)
        let rotatedForce = simd_mul(cameraTransform!, force)
        let vectorForce = SCNVector3(x:rotatedForce.x, y:rotatedForce.y, z:rotatedForce.z)
        
        // Apply force to ball
        currentBallNode?.physicsBody?.applyForce(vectorForce, asImpulse: true)
    }
 
    @IBAction func magic(_ sender: Any) {
        
        for ball in balls {
    
            // Delete balls in the hat
            if hatBoundingBoxContains(ball) {
                ball.removeFromParentNode()
            }
        }
        
        // Add sparkles animation
        let hat = sceneView.scene.rootNode.childNode(withName: "hat", recursively: true)
        let sparkles = SCNParticleSystem(named: "Sparkles.scnp", inDirectory: "art.scnassets")
        hat?.addParticleSystem(sparkles!)
    }
    
    // MARK: Helpers
    
    func hatBoundingBoxContains(_ node: SCNNode) -> Bool {
        // Recursive check, to get the boolean results at real time
        return hatBoundingBoxContains(node.position)
    }
    
    func hatBoundingBoxContains(_ point: SCNVector3) -> Bool {
        
        // Get the tube node of the hat
        let tubeNode = hatNode?.childNode(withName: "tube", recursively: true)

        // Initialize both the max and min information for the hat tube at once
        var (min, max) = (tubeNode?.presentation.boundingBox)!
        
        let size = max - min
        min = SCNVector3((tubeNode?.presentation.worldPosition.x)! - size.x/2,
                         (tubeNode?.presentation.worldPosition.y)!,
                         (tubeNode?.presentation.worldPosition.z)! - size.z/2)
        max = SCNVector3((tubeNode?.presentation.worldPosition.x)! + size.x/2,
                         (tubeNode?.presentation.worldPosition.y)! + size.y,
                         (tubeNode?.presentation.worldPosition.z)! + size.z/2)
        print (min, max)
        return
            point.x >= min.x  &&
                point.y >= min.y  &&
                point.z >= min.z  &&
                
                point.x < max.x  &&
                point.y < max.y  &&
                point.z < max.z
    }
}

// MARK: - ViewController: ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, hatNode == nil else { return }
        
        // Extend the plane for the balls to be able to land on the floor
        let planeExtension: CGFloat = 50
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x) * planeExtension,
                             height: CGFloat(planeAnchor.extent.z) * planeExtension)

        // Create floor plane as a node
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0
        
        // Position floor plane
        planeNode.position = SCNVector3Make(0, 0, 0)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0) // Rotate plane 90 degrees to be parallel to the floor
        
        // Add physics to the floor
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        
        // Add floor plane to the scene
        node.addChildNode(planeNode)
        
        // Position hat on the floor plane
        let position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        createMagicHatFromScene(position, node: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // Update plane anchors and nodes matching the setup in 'renderer(_:didAdd:for:)'
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transformation
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, 'ARSCNView' automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // Adjust hat and balls' lighting to match with the light detected
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            hatNode?.light?.intensity = lightEstimate.ambientIntensity
            balls.forEach { $0.light?.intensity = lightEstimate.ambientIntensity }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        AlertView.showAlert(controller: self, message: AlertView.Messages.sessionFailed)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .notAvailable:
            AlertView.showAlert(controller: self, message: AlertView.Messages.cameraTrackingError)
            break
        case .limited:
            trackingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { _ in
                session.run(AROrientationTrackingConfiguration())
                self.trackingTimer?.invalidate()
                self.trackingTimer = nil
            })
        case .normal:
            if trackingTimer != nil {
                trackingTimer!.invalidate()
                trackingTimer = nil
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        AlertView.showAlert(controller: self, message: AlertView.Messages.sessionInterrupted)
    }
    
    // MARK: Helpers
    
    private func createMagicHatFromScene(_ position: SCNVector3, node : SCNNode) {
        guard let scene = SCNScene(named: "magicHat.scn", inDirectory: "art.scnassets") else {
            fatalError("Unable to find scene")
        }
        
        hatNode = scene.rootNode.childNode(withName: "hat", recursively: true)
        
        // Position scene
        hatNode?.position = position
        node.addChildNode(hatNode!)
    }
}
