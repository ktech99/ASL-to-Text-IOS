//
//  ViewController.swift
//  Gesture-Recognition-101-CoreML-ARKit
//
//  Created by Hanley Weng on 10/22/17.
//  Copyright © 2017 Emerging Interactions. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var textOverlay: UITextField!
    
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    var visionRequests = [VNRequest]()
    
    var gestureFrequenciesMap = [String: Int]()
    var gestureFrequenciesSize = 0
    var maxChar = "❎"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ARKIT ---
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene() // SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // --- ML & VISION ---
        
        // Setup Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: example_5s0_hand_model().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        textOverlay.layer.shadowOpacity = 0.1
        textOverlay.layer.shadowRadius = 8
        textOverlay.layer.shadowColor = UIColor.black.cgColor
        textOverlay.layer.backgroundColor = UIColor.clear.cgColor
        textOverlay.backgroundColor = UIColor.white
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - MACHINE LEARNING
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
    }
    
    func updateCoreML() {
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Run Vision Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    func getMaxChar(computedPrediction: String) {
        gestureFrequenciesSize += 1
        if (gestureFrequenciesSize > 30) {
            gestureFrequenciesSize = 0
            var max = 0
            for (prediction, frequency) in gestureFrequenciesMap {
                if (frequency > max) {
                    max = frequency
                    maxChar = prediction
                }
            }
            gestureFrequenciesMap.removeAll()
        } else {
            if gestureFrequenciesMap.keys.contains(computedPrediction) {
                gestureFrequenciesMap[computedPrediction] = gestureFrequenciesMap[computedPrediction]! + 1
            } else {
                gestureFrequenciesMap[computedPrediction] = 1
            }
        }
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations.prefix(4) // top 3 results
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        // Render Classifications
        DispatchQueue.main.async {
            // Print Classifications
            // print(classifications)
            // print("-------------")
            
            
            // Display Top Symbol
            var symbol = "❎"
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            // Only display a prediction if confidence is above 1%
            let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
            
            if (topPredictionScore != nil && topPredictionScore! > 0.01) {
                self.textOverlay.layer.borderColor = UIColor.clear.cgColor
                self.getMaxChar(computedPrediction: topPredictionName)
                if (self.maxChar.contains("hi")) {
                    symbol = "Hi"
                    self.textOverlay.backgroundColor = UIColor.white
                }
                if (self.maxChar.contains("love")) {
                    symbol = "I love you ❤️"
                    self.textOverlay.backgroundColor = UIColor.white
                }
                if (self.maxChar == "negative") {
                    symbol = "❎"
                    self.textOverlay.backgroundColor = UIColor.clear
                    self.textOverlay.layer.borderColor = UIColor.clear.cgColor
                }
                if (self.maxChar == "cat") {
                    symbol = "🐱"
                    self.textOverlay.backgroundColor = UIColor.clear
                }
            }
            self.textOverlay.text = symbol
        }
    }
    
    // MARK: - HIDE STATUS BAR
    override var prefersStatusBarHidden : Bool { return true }
}
