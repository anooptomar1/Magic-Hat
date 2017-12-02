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
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
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
        guard let hatNode = hatNode?.presentation else { return }
        
        for ball in balls {
            if hatNode.boundingBoxContains(point: ball.presentation.position) {
                ball.removeFromParentNode()
            }
        }
        
        // Add sparkles animation
        let hat = sceneView.scene.rootNode.childNode(withName: "hat", recursively: true)
        let sparkles = SCNParticleSystem(named: "Sparkles.scnp", inDirectory: "art.scnassets")
        hat?.addParticleSystem(sparkles!)
    }
}

// MARK: - ViewController: ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        // Create hat node for a detected ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor, hatNode == nil else { return nil }
        
        self.planeAnchor = planeAnchor
        let position = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
        hatNode = createMagicHatFromScene(position)
        
        return hatNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.center == self.planeAnchor?.center || self.planeAnchor == nil else { return }

        // Set the floor's geometry to be the detected plane
        let floor = sceneView.scene.rootNode.childNode(withName: "floor", recursively: true)
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.y))
        floor?.geometry = plane
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
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
    
    private func createMagicHatFromScene(_ position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/magicHat", withExtension: "scn") else {
            print("Could not find magic hat scene")
            return nil
        }
        
        guard let node = SCNReferenceNode(url: url) else { return nil }
        
        node.load()
        
        // Position scene
        node.position = position
        
        return node
    }
}
