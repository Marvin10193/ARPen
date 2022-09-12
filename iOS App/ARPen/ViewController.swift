//
//  ViewController.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity
import RealityKit
import MetalKit
import ReplayKit
import Photos
import VideoToolbox
import OSLog
import AVKit
import TabularData
import CSVLogger


/**
 The "Main" ViewController. This ViewController holds the instance of the PluginManager.
 Furthermore it holds the ARKitView.
 */
class ViewController: UIViewController, ARSCNViewDelegate, PluginManagerDelegate, UITableViewDelegate {

    @IBOutlet var arSceneView: ARSCNView!
    @IBOutlet weak var softwarePenButton: UIButton!
    @IBOutlet weak var imageForPluginInstructions: UIImageView!
    @IBOutlet weak var pluginInstructionsLookupButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var viewForCustomPluginView: UIView!
    
    // Persistence: Saving and loading current model
    @IBOutlet weak var saveModelButton: UIButton!
    @IBOutlet weak var loadModelButton: UIButton!
    @IBOutlet weak var shareModelButton: UIButton!
    
    @IBOutlet weak var snapshotThumbnail: UIImageView! // Screenshot thumbnail to help the user find feature points in the World
    @IBOutlet weak var statusLabel: UILabel!
    
    // This ARAnchor acts as the point of reference for all models when storing/loading
    var persistenceSavePointAnchor: ARAnchor?
    var persistenceSavePointAnchorName: String = "persistenceSavePointAnchor"
    
//    // This ARAnchor acts as the point of reference for all models when sharing
//    var sharePointAnchor: ARAnchor?
//    var sharePointAnchorName: String = "sharePointAnchor"
    
    var saveIsSuccessful: Bool = false
    
    var storedNode: SCNReferenceNode? = nil // A reference node used to pre-load the models and render later
    var sharedNode: SCNNode? = nil
    
    var horizontalSurfacePosition : SCNVector3?
    
    @IBOutlet weak var menuToggleButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    var menuViewNavigationController : UINavigationController?
    var menuTableViewController = UITableViewController(style: .grouped)
    var tableViewDataSource : UITableViewDiffableDataSource<Int, Plugin>? = nil
    var menuGroupingInfo : [(String, [Plugin])]? = nil
    
    var bluetoothARPenConnected: Bool = false
    /**
     The PluginManager instance
     */
    var pluginManager: PluginManager!
    
    let userStudyRecordManager = UserStudyRecordManager() // Manager for storing data from user studies
    
    //Everything used in the shared session and functionality handling
    var multipeerSession: MultipeerSession?
    var peerSesssionIDs = [MCPeerID: String]()
    var sessionIDObservation: NSKeyValueObservation?
    var rayToggledOn = true
    @IBOutlet weak var messageLabel: MessageLabel!
    var joinedMessageDisplayed: Bool = false
    @IBOutlet weak var pipView: MTKView!
    @IBOutlet weak var pipViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pipViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var raySettingButton: UIButton!
    @IBOutlet weak var opacitySettingButton: UIButton!
    @IBOutlet weak var baseSettingButton: UIButton!
    @IBOutlet weak var videoSettingButton: UIButton!
    @IBOutlet weak var demoSceneButton: UIButton!
    @IBOutlet weak var sceneOneButton: UIButton!
    @IBOutlet weak var sceneTwoButton: UIButton!
    @IBOutlet weak var sceneThreeButton: UIButton!
    @IBOutlet weak var sceneFourButton: UIButton!
    @IBOutlet weak var sceneFiveButton: UIButton!
    @IBOutlet weak var sceneSixButton: UIButton!
    @IBOutlet weak var sceneSevenButton: UIButton!
    @IBOutlet weak var sceneEightButton: UIButton!
    @IBOutlet weak var sceneNineButton: UIButton!
    @IBOutlet weak var sceneTenButton: UIButton!
    @IBOutlet weak var sceneElevenButton: UIButton!
    @IBOutlet weak var sceneTwelveButton: UIButton!
    @IBOutlet weak var sharedARInfoLabel: UILabel!
    @IBOutlet weak var oppositePositionButton: UIButton!
    @IBOutlet weak var sideBySidePositionButton: UIButton!
    @IBOutlet weak var ninetyDegreePositionButton: UIButton!
    @IBOutlet weak var changeTaskButton: UIButton!
    @IBOutlet weak var toggleSharedARHelp: UIButton!
    @IBOutlet weak var toggleSharedARHelpLabel: UILabel!

    
    
    var currentScene = 0
    
    let videoProcessor = VideoProcessor()
    var videoRenderer: Renderer!
    var lastTrackingState: Bool = false
    var latestKnownWorldTransform: simd_float4x4 = matrix_identity_float4x4
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    var videoOutputURL : URL!
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    let defaultLog = Logger()
    var sceneDict = ["Scene1" : 1,
                     "Scene2" : 2,
                     "Scene3" : 3,
                     "Scene4" : 4,
                     "Scene5" : 5,
                     "Scene6" : 6,
                     "Scene7" : 7,
                     "Scene8" : 8,
                     "Scene9" : 9,
                     "Scene10": 10,
                     "Scene11": 11,
                     "Scene12": 12
                                  ]
    
    //A standard viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make the corners of UI buttons rounded
        self.makeRoundedCorners(button: self.pluginInstructionsLookupButton)
        self.makeRoundedCorners(button: self.settingsButton)
        self.makeRoundedCorners(button: self.undoButton)
        self.makeRoundedCorners(button: self.redoButton)
        self.makeRoundedCorners(button: self.saveModelButton)
        self.makeRoundedCorners(button: self.loadModelButton)
        self.makeRoundedCorners(button: self.shareModelButton)
        self.makeRoundedCorners(button: self.raySettingButton)
        self.makeRoundedCorners(button: self.opacitySettingButton)
        self.makeRoundedCorners(button: self.videoSettingButton)
        self.makeRoundedCorners(button: self.baseSettingButton)
        self.makeRoundedCorners(button: self.demoSceneButton)
        self.makeRoundedCorners(button: self.sceneOneButton)
        self.makeRoundedCorners(button: self.sceneTwoButton)
        self.makeRoundedCorners(button: self.sceneThreeButton)
        self.makeRoundedCorners(button: self.sceneFourButton)
        self.makeRoundedCorners(button: self.sceneFiveButton)
        self.makeRoundedCorners(button: self.sceneSixButton)
        self.makeRoundedCorners(button: self.sceneSevenButton)
        self.makeRoundedCorners(button: self.sceneEightButton)
        self.makeRoundedCorners(button: self.sceneNineButton)
        self.makeRoundedCorners(button: self.sceneTenButton)
        self.makeRoundedCorners(button: self.sceneElevenButton)
        self.makeRoundedCorners(button: self.sceneTwelveButton)
        self.makeRoundedCorners(button: self.sideBySidePositionButton)
        self.makeRoundedCorners(button: self.ninetyDegreePositionButton)
        self.makeRoundedCorners(button: self.oppositePositionButton)
        self.makeRoundedCorners(button: self.changeTaskButton)
        self.makeRoundedCorners(button: self.toggleSharedARHelp)
        self.toggleSharedARHelpLabel.layer.cornerRadius = 5
        self.toggleSharedARHelpLabel.layer.masksToBounds = true
        
        self.undoButton.isHidden = false
        self.undoButton.isEnabled = true
        
        self.redoButton.isHidden = false
        self.redoButton.isEnabled = true
        
        self.shareModelButton.isHidden = true
        
        //Hide the Setting Buttons for SharedAR until plugin is Selected
        self.toggleSharedARHelp.isHidden = true
        self.toggleSharedARHelp.isEnabled = true
        
        
        self.raySettingButton.isHidden = true
        self.raySettingButton.isEnabled = true
        
        
        self.opacitySettingButton.isHidden = true
        self.opacitySettingButton.isEnabled = true
        
        self.videoSettingButton.isHidden = true
        self.videoSettingButton.isEnabled = true
        
        self.baseSettingButton.isHidden = true
        self.baseSettingButton.isEnabled = true
        
        self.demoSceneButton.isHidden = true
        self.demoSceneButton.isEnabled = true
        
        self.sceneOneButton.isHidden = true
        self.sceneOneButton.isEnabled = true
        
        self.sceneTwoButton.isHidden = true
        self.sceneTwoButton.isEnabled = true
        
        self.sceneThreeButton.isHidden = true
        self.sceneThreeButton.isEnabled = true
        
        self.sceneFourButton.isHidden = true
        self.sceneFourButton.isEnabled = true
        
        self.sceneFiveButton.isHidden = true
        self.sceneFiveButton.isEnabled = true
        
        self.sceneSixButton.isHidden = true
        self.sceneSixButton.isEnabled = true
        
        self.sceneSevenButton.isHidden = true
        self.sceneSevenButton.isEnabled = true
        
        self.sceneEightButton.isHidden = true
        self.sceneEightButton.isEnabled = true
        
        self.sceneNineButton.isHidden = true
        self.sceneNineButton.isEnabled = true
        
        self.sceneTenButton.isHidden = true
        self.sceneTenButton.isEnabled = true
        
        self.sceneElevenButton.isHidden = true
        self.sceneElevenButton.isEnabled = true
        
        self.sceneTwelveButton.isHidden = true
        self.sceneTwelveButton.isEnabled = true
        
        self.sideBySidePositionButton.isHidden = true
        self.sideBySidePositionButton.isEnabled = true
        
        self.ninetyDegreePositionButton.isHidden = true
        self.ninetyDegreePositionButton.isEnabled = true
        
        self.oppositePositionButton.isHidden = true
        self.oppositePositionButton.isEnabled = true
        
        self.changeTaskButton.isHidden = true
        self.changeTaskButton.isEnabled = true
        
        self.sharedARInfoLabel.isHidden = true
        
        
        // Create a new scene
        let scene = PenScene(named: "art.scnassets/ship.scn")!
        scene.markerBox = MarkerBox()
        self.arSceneView.pointOfView?.addChildNode(scene.markerBox)
        
        self.pluginManager = PluginManager(penScene: scene, sceneView: self.arSceneView)
        self.pluginManager.delegate = self
        self.arSceneView.session.delegate = self.pluginManager.arManager
        self.arSceneView.delegate = self
        
        self.arSceneView.autoenablesDefaultLighting = true
        self.arSceneView.pointOfView?.name = "iDevice Camera"
        
        // Set the scene to the view
        arSceneView.scene = scene
        
        // Setup tap gesture recognizer for plugin instructions
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(ViewController.imageForPluginInstructionsTapped(_:)))
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.addGestureRecognizer(tapGestureRecognizer)
        
        // Hide plugin instructions
        self.imageForPluginInstructions.isHidden = true
        //self.displayPluginInstructions(forPluginID: currentActivePluginID)
        //check if it is the first app launch. If so, display the app instructions
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "HasLaunchedBefore") {
            self.imageForPluginInstructions.image = UIImage.init(named: "AppInstructions")
            self.imageForPluginInstructions.isUserInteractionEnabled = true
            self.imageForPluginInstructions.alpha = 0.75
            self.imageForPluginInstructions.isHidden = false
            
            userDefaults.set(true, forKey: "HasLaunchedBefore")
        }

        
        // Set the user study record manager reference in the app delegate (for saving state when leaving the app)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.userStudyRecordManager = self.userStudyRecordManager
        } else {
            print("Record manager was not set up in App Delegate")
        }
        
        // Read in any already saved map to see if we can load one
        if mapDataFromFile != nil {
            self.loadModelButton.isHidden = false
        }
        
        // Observe camera's tracking state and session information
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(_:)), name: Notification.Name.cameraDidChangeTrackingState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(_:)), name: Notification.Name.sessionDidUpdate, object: nil)
        
        // Remove snapshot thumbnail when model has been loaded
        NotificationCenter.default.addObserver(self, selector: #selector(removeSnapshotThumbnail(_:)), name: Notification.Name.virtualObjectDidRenderAtAnchor, object: nil)
        
        // Notifcations for shared AR functions
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.shareSCNNodeData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.shareARPNodeData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.labelCommand, object:  nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.nodeCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.changeModeCommand, object : nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.changeTaskMode, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.changeSceneCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.changePositionCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.infoLabelCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.measurementCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.alertCommand, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.sequenceData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedStateChange(_:)), name: Notification.Name.trialLogConfirmation, object: nil)
        
//        // Enable host-guest sharing to share ARWorldMap
//        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        
        self.menuViewNavigationController = UINavigationController(rootViewController: menuTableViewController)
        self.menuViewNavigationController?.view.frame = CGRect(x: 0, y: 0, width: self.menuView.frame.width, height: self.menuView.frame.height)
        self.menuViewNavigationController?.setNavigationBarHidden(true, animated: false)
        self.setupPluginMenuFrom(PluginArray: self.pluginManager.plugins)
        self.menuTableViewController.tableView.rowHeight = UITableView.automaticDimension
        self.menuTableViewController.tableView.estimatedRowHeight = 40
        self.menuTableViewController.tableView.backgroundColor = UIColor(white: 0.5, alpha: 0.35)
        
        self.menuView.addSubview(self.menuViewNavigationController!.view)
        
        // Configure PiPView
        guard let device = MTLCreateSystemDefaultDevice() else{
            fatalError("Unable to get system default device!")
        }
        
        pipView.device = device
        pipView.backgroundColor = .clear
        pipView.colorPixelFormat = .bgra8Unorm
        pipView.depthStencilPixelFormat = .depth32Float_stencil8
        
        // configure renderer for the PiPView
        videoRenderer = Renderer(device: device, renderDestination: pipView)
        videoRenderer.mtkView(pipView, drawableSizeWillChange: pipView.bounds.size)
        pipView.delegate = videoRenderer
    }
    
    /**
     viewWillAppear. Init the ARSession
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Config for image tracking to keep content synchronized between devices
        guard let arImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)
        else{
            return
        }
        configuration.detectionImages = arImages
        configuration.maximumNumberOfTrackedImages = 1
        

        // Run the view's session
        arSceneView.session.run(configuration)
        
        // Use key-value observation to monitor ARSession identifiers, might be useful to track anchors later on aswell as actions
        sessionIDObservation = observe(\.arSceneView.session.identifier,options: [.new]) {object, change in print ("SessionID changed to: \(change.newValue!)")
            guard let multipeerSession = self.multipeerSession else {
                return
            }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }
        
        // Start looking for other devices
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData, peerJoinedHandler: peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //if no plugin is currently selected, select the base plugin
        if self.pluginManager.activePlugin == nil {
            let indexPath = IndexPath(row: 0, section: 0)
            self.menuTableViewController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self.tableView(self.menuTableViewController.tableView, didSelectRowAt: indexPath)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arSceneView.session.pause()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // Prepare the SettingsViewController by passing the scene
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        if segueIdentifier == "ShowSettingsSegue" {
            let destinationVC = segue.destination as! UINavigationController
            guard let destinationSettingsController = destinationVC.viewControllers.first as? SettingsTableViewController else {
                return
                
            }
            destinationSettingsController.scene = self.arSceneView.scene as? PenScene
            //pass reference to the record manager (to show active user ID and export data)
            destinationSettingsController.userStudyRecordManager = self.userStudyRecordManager
            destinationSettingsController.bluetoothARPenConnected = self.bluetoothARPenConnected
            //pass reference to view controller so that the scene can be reset
            destinationSettingsController.mainViewController = self
        }
        
    }
    
    // MARK: - Plugins
    
    func setupPluginMenuFrom(PluginArray pluginArray : [Plugin]) {
        menuTableViewController.tableView.register(UINib(nibName: "ARPenPluginTableViewCell", bundle: nil), forCellReuseIdentifier: "arpenplugincell")
        tableViewDataSource = UITableViewDiffableDataSource<Int, Plugin>(tableView: menuTableViewController.tableView){
            (tableView: UITableView, indexPath: IndexPath, item: Plugin) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "arpenplugincell", for: indexPath)
            if let cell = cell as? ARPenPluginTableViewCell {
                // If plugin needs bluetooth ARPen, but it is not found, then disable the button, use a different image, and grey out the plugin label.
                var pluginImage : UIImage?
                if (item.needsBluetoothARPen && !self.bluetoothARPenConnected) {
                    pluginImage = item.pluginDisabledImage
                    cell.cellLabel.textColor = UIColor.init(white: 0.4, alpha: 1)
                    cell.selectionStyle = .none
                } else {
                    pluginImage = item.pluginImage
                    cell.selectionStyle = .default
                    cell.cellLabel.textColor = .label
                }
                cell.updateCellWithImage(pluginImage, andText:item.pluginIdentifier)
                cell.backgroundColor = .clear
                return cell
            } else {
                return cell
            }
        }
        
        menuTableViewController.tableView.delegate = self
        
        self.menuGroupingInfo = self.createMenuGroupingInfo(fromPluginArray: pluginArray)
        
        var pluginMenuSnap = NSDiffableDataSourceSnapshot<Int, Plugin>()
        for (index, element) in self.menuGroupingInfo!.enumerated() {
            pluginMenuSnap.appendSections([index])
            pluginMenuSnap.appendItems(element.1, toSection: index)
        }
//        pluginMenuSnap.appendSections([0])
//        pluginMenuSnap.appendItems(pluginArray, toSection: 0)
        tableViewDataSource?.apply(pluginMenuSnap)
            
    }
    
    func createMenuGroupingInfo(fromPluginArray plugins: [Plugin]) -> [(String, [Plugin])] {
        var groupingInfo = [(String, [Plugin])]()
        var sectionTitles = [String]()
        for currentPlugin in plugins {
            if let index = sectionTitles.firstIndex(of: currentPlugin.pluginGroupName) {
                groupingInfo[index].1.append(currentPlugin)
            } else {
                groupingInfo.append((currentPlugin.pluginGroupName, [currentPlugin]))
                sectionTitles.append(currentPlugin.pluginGroupName)
            }
        }
        return groupingInfo
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let currentActivePlugin = self.pluginManager.activePlugin {
            //remove custom view elements from view
            currentActivePlugin.customPluginUI?.removeFromSuperview()
            //currentActivePlugin.deactivatePlugin()
        }
        //activate plugin in plugin manager and update currently active plugin property
        guard let newActivePlugin = self.menuGroupingInfo?[indexPath.section].1[indexPath.row] else {return}
        self.pluginManager.activePlugin = newActivePlugin
        //if the new plugin conforms to the user study record plugin protocol, then pass a reference to the record manager (allowing to save data to it)
        if var pluginConformingToUserStudyProtocol = newActivePlugin as? UserStudyRecordPluginProtocol {
            pluginConformingToUserStudyProtocol.recordManager = self.userStudyRecordManager
        }
        if !(newActivePlugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
            if let customPluginUI = newActivePlugin.customPluginUI {
                customPluginUI.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: viewForCustomPluginView.frame.size)
                viewForCustomPluginView.addSubview(customPluginUI)
            }
        }
        
        //if the new plugin is an experimental plugin, hide the undo and redo button, otherwise show them
        if newActivePlugin.isExperimentalPlugin {
            self.undoButton.isHidden = true
            self.redoButton.isHidden = true
            
            if newActivePlugin is SharedARPlugin{
                self.raySettingButton.isHidden = false
                self.opacitySettingButton.isHidden = false
                self.baseSettingButton.isHidden = false
                self.videoSettingButton.isHidden = false
                self.demoSceneButton.isHidden = false
                self.sceneOneButton.isHidden = false
                self.sceneTwoButton.isHidden = false
                self.sceneThreeButton.isHidden = false
                self.sceneFourButton.isHidden = false
                self.sceneFiveButton.isHidden = false
                self.sceneSixButton.isHidden = false
                self.sceneSevenButton.isHidden = false
                self.sceneEightButton.isHidden = false
                self.sceneNineButton.isHidden = false
                self.sceneTenButton.isHidden = false
                self.sceneElevenButton.isHidden = false
                self.sceneTwelveButton.isHidden = false
                self.sharedARInfoLabel.isHidden = false
                self.sideBySidePositionButton.isHidden = false
                self.ninetyDegreePositionButton.isHidden = false
                self.oppositePositionButton.isHidden = false
                self.changeTaskButton.isHidden = false
                self.toggleSharedARHelp.isHidden = false
                self.settingsButton.isHidden = true
                self.pluginInstructionsLookupButton.isHidden = true
                self.menuToggleButton.isHidden = true
                self.menuView.isHidden = true

            }
            if newActivePlugin is SpectatorSharedARPlugin{
                self.toggleSharedARHelpLabel.isHidden = false
                self.toggleSharedARHelp.isHidden = true
                self.settingsButton.isHidden = true
                self.pluginInstructionsLookupButton.isHidden = true
                self.softwarePenButton.isHidden = true
                self.menuToggleButton.isHidden = true
                self.menuView.isHidden = true
            }
        } else {
            self.undoButton.isHidden = false
            self.redoButton.isHidden = false
            self.toggleSharedARHelp.isHidden = false
            
            self.raySettingButton.isHidden = true
            self.opacitySettingButton.isHidden = true
            self.baseSettingButton.isHidden = true
            self.videoSettingButton.isHidden = true
            
            self.demoSceneButton.isHidden = true
            self.sceneOneButton.isHidden = true
            self.sceneTwoButton.isHidden = true
            self.sceneThreeButton.isHidden = true
            self.sceneFourButton.isHidden = true
            self.sceneFiveButton.isHidden = true
            self.sceneSixButton.isHidden = true
            self.sceneSevenButton.isHidden = true
            self.sceneEightButton.isHidden = true
            self.sceneNineButton.isHidden = true
            self.sceneTenButton.isHidden = true
            self.sceneElevenButton.isHidden = true
            self.sceneTwelveButton.isHidden = true
            self.sharedARInfoLabel.isHidden = true
            
            self.sharedARInfoLabel.isHidden = true
            self.sideBySidePositionButton.isHidden = true
            self.ninetyDegreePositionButton.isHidden = true
            self.oppositePositionButton.isHidden = true
            self.changeTaskButton.isHidden = true
            self.toggleSharedARHelpLabel.isHidden = true
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPlugin = self.menuGroupingInfo?[indexPath.section].1[indexPath.row] else {return indexPath}
        
        if (selectedPlugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
            self.displayPluginInstructions(withBluetoothErrorMessage: true)
            return nil
        } else {
            self.imageForPluginInstructions.isHidden = true
            
            //check if the next plugin is an experimental plugin and the current one is a modeling plugin
            guard let currentActivePlugin = self.pluginManager.activePlugin else {return indexPath}
            if selectedPlugin.isExperimentalPlugin && !currentActivePlugin.isExperimentalPlugin {
                //display warning alert that the scene will be reset
                let alertController = UIAlertController(title: "Experimental Plugin", message: "You are switching to an experimental plugin. All objects in your current scene will be removed. This cannot be undone.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let deleteAction = UIAlertAction(title: "Proceed and reset scene", style: .destructive, handler: {action in
                    self.resetScene()
                    self.menuTableViewController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    self.tableView(self.menuTableViewController.tableView, didSelectRowAt: indexPath)
                })
                
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
                
                present(alertController, animated: true, completion: nil)
                
                return nil
            } else {
                return indexPath
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionTitleName = self.menuGroupingInfo?[section].0 {
            let sectionTitle = UILabel()
            sectionTitle.text = sectionTitleName
            sectionTitle.backgroundColor = UIColor(white: 1, alpha: 0.5)
            sectionTitle.font = .boldSystemFont(ofSize: 20)
            
            return sectionTitle
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    @IBAction func toggleMenuPosition(_ sender: Any) {
        if self.menuView.frame.minX >= 0 {
            UIView.animate(withDuration: 0.1){
                self.menuView.transform = CGAffineTransform(translationX: self.menuView.frame.width * -1, y: 0)
                self.menuView.alpha = 0.0
            }
            self.menuToggleButton.setTitle("Show Plugins", for: .normal)
        } else {
            UIView.animate(withDuration: 0.1) {
                self.menuView.transform = .identity
                self.menuView.alpha = 1.0
            }
            self.menuToggleButton.setTitle("Hide Plugins", for: .normal)
        }
    }
    
    // Display the instructions for plugin by setting imageForPluginInstructions
    func displayPluginInstructions(withBluetoothErrorMessage showBluetoothMissingInstruction : Bool) {
        if  showBluetoothMissingInstruction {
            self.imageForPluginInstructions.image = UIImage.init(named: "BluetoothARPenMissingInstructions")
        } else if let plugin = self.pluginManager.activePlugin {
            self.imageForPluginInstructions.image = plugin.pluginInstructionsImage
        }
        
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.alpha = 0.75
        self.imageForPluginInstructions.isHidden = false
        
    }
    
    @objc func imageForPluginInstructionsTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        tappedImage.isHidden = true
        self.pluginInstructionsLookupButton.isHidden = false
    }
    
    @IBAction func showPluginInstructions(_ sender: Any) {
        self.displayPluginInstructions(withBluetoothErrorMessage: false)
    }
    
    func resetScene() {
        guard let penScene = self.arSceneView.scene as? PenScene else {return}
        //remove all child nodes from drawing node
        penScene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
        //reset recorded actions of undo redo manager
        self.pluginManager.undoRedoManager.resetUndoRedoManager()
    }
    
    // MARK: - ARManager delegate
    
    // Mark: - PenManager delegate
    /**
     Callback from PenManager
     */
    func penConnected() {
        self.bluetoothARPenConnected = true
    }
    
    func penFailed() {

        self.bluetoothARPenConnected = false
    }
    
    
    //Software Pen Button Actions
    @IBAction func softwarePenButtonPressed(_ sender: Any) {
        //next line is the direct way possible here, but we'll show the way how the button states can be send from everywhere in the map
        //self.pluginManager.button(.Button1, pressed: true)
        //sent notification of button press to the pluginManager
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button1, "buttonState" : true]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: Any) {
        //next line is the direct way possible here, but we'll show the way how the button states can be send from everywhere in the map
        //self.pluginManager.button(.Button1, pressed: false)
        //sent notification of button release to the pluginManager
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button1, "buttonState" : false]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    
    
    
    
    @IBAction func undoButtonPressed(_ sender: Any) {
        self.pluginManager.undoPreviousStep()
    }

    @IBAction func redoButtonPressed(_ sender: Any) {
        self.pluginManager.redoPreviousStep()
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pluginManager.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pluginManager.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pluginManager.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pluginManager.touchesCancelled(touches, with: event)
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    
    
    /*
    // Invoked when new anchors are added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        switch anchor {
        case anchor as ARPlaneAnchor:
            self.horizontalSurfacePosition = node.worldPosition
        default:
            guard let anchorName = anchor.name else {
                return
            }
            
            if (anchorName == persistenceSavePointAnchorName) {
                // Save the reference to the virtual object anchor when the anchor is added from relocalizing
                if persistenceSavePointAnchor == nil {
                    persistenceSavePointAnchor = anchor
                }
                
                DispatchQueue.main.async {
                    self.storedNode = SCNReferenceNode(url: self.sceneSaveURL) // Fetch models saved earlier
                    self.storedNode!.load()
                    
                    let scene = self.arSceneView.scene as! PenScene
                    for child in self.storedNode!.childNodes {
                        scene.drawingNode.addChildNode(child)
                    }
                }
            } //else if (anchorName == sharePointAnchorName) {
    //            // Perform rendering operations asynchronously
    //            DispatchQueue.main.async {
    //                guard let sharedNode = self.sharedNode else {
    //                    return
    //                }
    //
    //                let scene = self.arSceneView.scene as! PenScene
    //                scene.drawingNode.addChildNode(sharedNode)
    //                print("Adding storedNode to sharePointAnchor")
    //            }
    //        }
            else {
                print("An unknown ARAnchor has been added!")
                return
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        switch anchor {
        case anchor as ARPlaneAnchor:
            self.horizontalSurfacePosition = node.worldPosition
        default:
            print("A differnt ARAnchor has been updated!")
        }
    }*/
    
    // MARK: - Persistence: Save and load ARWorldMap
    
    // Receives notification on when session or camera tracking state changes and updates label
    @objc func handleStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print("notification.userInfo is empty")
            return
        }
        switch notification.name {
        case .sessionDidUpdate:
            updateStatusLabel(for: userInfo["frame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
            
            // Enable Save button only when the mapping status is good and
            // drawingNode has at least one object
            let frame = userInfo["frame"] as! ARFrame
            switch frame.worldMappingStatus {
                case .extending, .mapped:
                    let scene = self.arSceneView.scene as! PenScene
                    saveModelButton.isEnabled = scene.drawingNode.childNodes.count > 0
                default:
                    saveModelButton.isEnabled = false
            }
            
            let trackingState = userInfo["trackingState"] as! ARCamera.TrackingState
            
            if !joinedMessageDisplayed && !(multipeerSession?.connectedPeers.isEmpty)! && trackingState.description == "Normal"{
                let peerName = multipeerSession!.connectedPeers.map({$0.displayName}).joined(separator:", ")
                messageLabel.displayMessage("Connected with \(peerName).",duration: 6)
                joinedMessageDisplayed = true
            }
            break
        case .cameraDidChangeTrackingState:
            updateStatusLabel(for: userInfo["currentFrame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
            break
        default:
            print("Received unknown notification: \(notification.name)")
        }
    }
    
    // Setup ARAnchor that serves as the point of reference for all drawings
    func setupPersistenceAnchor() {
        // Remove existing anchor if it exists
        if let existingPersistenceAnchor = persistenceSavePointAnchor {
            self.arSceneView.session.remove(anchor: existingPersistenceAnchor)
        }
        
        // Add ARAnchor for save point
        persistenceSavePointAnchor = ARAnchor(name: persistenceSavePointAnchorName, transform: matrix_identity_float4x4)
    }
    
    // Create URL for storing WorldMap in a lazy manner
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // Create URL for storing all models in the current AR scence in a lazy manner
    lazy var sceneSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("scene.scn")
        } catch {
            fatalError("Can't get scene save URL: \(error.localizedDescription)")
        
        }
    }()
    
    // Save the world map and models
    @IBAction func saveCurrentScene(_ sender: Any) {
        self.setupPersistenceAnchor()
        
        self.arSceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    self.showAlert(title: "Can't get current world map", message: error!.localizedDescription)
                    return
                }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.arSceneView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            map.anchors.append(self.persistenceSavePointAnchor!)
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])

                DispatchQueue.main.async {
                    self.loadModelButton.isHidden = false
                    self.loadModelButton.isEnabled = true
                    
                    // Save the current PenScene to sceneSaveURL
                    let scene = self.arSceneView.scene as! PenScene
                    let savedNode = SCNReferenceNode(url: self.sceneSaveURL)
                    var nodesCreatedWithOpenCascade: [SCNNode] = []
                    
                    if savedNode!.isLoaded == false {
                        print("No prior save found, saving current PenScene.")
                        scene.pencilPoint.removeFromParentNode() // Remove pencilPoint before saving
                        
                        // Remove all geometries created via Open Cascade
                        scene.drawingNode.childNodes(passingTest: { (node, stop) -> Bool in
                            let geometryType = type(of: node)
                            
                            // If the geometry created by Open Cascade, remove before sharing (but store them locally for retrieval).
                            if ((geometryType == ARPSphere.self) || (geometryType == ARPGeomNode.self) || (geometryType == ARPRevolution.self) ||
                                (geometryType == ARPBox.self) || (geometryType == ARPNode.self) || (geometryType == ARPSweep.self) ||
                                (geometryType == ARPCylinder.self) || (geometryType == ARPLoft.self) || (geometryType == ARPPath.self) ||
                                (geometryType == ARPBoolNode.self) || (geometryType == ARPPathNode.self)) {
                                
                                nodesCreatedWithOpenCascade.append(node)
                                node.removeFromParentNode()
                                return false
                            } else {
                                return true
                            }
                        })
                        
                        if scene.write(to: self.sceneSaveURL, options: nil, delegate: nil, progressHandler: nil) {
                            // Handle save if needed
                            scene.reinitializePencilPoint()
                            nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
                            
                            self.saveIsSuccessful = true
                            
                            // Reset the value after two seconds so that the label disappears
                            _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                                self.saveIsSuccessful = false
                            } // Todo: See if there is a more elegant way to do this
                        } else {
                            scene.reinitializePencilPoint()
                            nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
                            
                            return
                        }
                    }
                }
                self.statusLabel.text = "Write successful!"
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    
    // Called opportunistically to verify that map data can be loaded from filesystem
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    // Called opportunistically to verify that scene data can be loaded from filesystem
    var sceneDataFromFile: Data? {
        return try? Data(contentsOf: sceneSaveURL)
    }
    
    // Load the world map and models
    @IBAction func loadScene(_ sender: Any) {
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
            let snapshot = UIImage(data: snapshotData) {
            snapshotThumbnail.isHidden = false
            snapshotThumbnail.image = snapshot

        } else {
            print("No snapshot image in world map")
        }
        
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        configuration.planeDetection = .horizontal
        self.arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isRelocalizingMap = true
        persistenceSavePointAnchor = nil
        
        self.setupPersistenceAnchor()
        self.arSceneView.session.add(anchor: persistenceSavePointAnchor!) // Add anchor to the current scene
    }
    
    var isRelocalizingMap = false
    
    // Provide feedback and instructions to the user about saving and loading the map and models respectively
    // TODO: This needs to be updated for sharing
    func updateStatusLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        var message: String = ""
        self.snapshotThumbnail.isHidden = true
        
        switch (trackingState) {
        case (.limited(.relocalizing)) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            self.snapshotThumbnail.isHidden = false
        case .normal, .notAvailable:
//            if !multipeerSession.connectedPeers.isEmpty && mapProvider == nil {
//                let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//                message = "Connected with \(peerNames)."
//
//                let scene = self.arSceneView.scene as! PenScene
//                if (scene.drawingNode.childNodes.count > 0) {
//                    self.shareModelButton.isHidden = false
//                }
//            }
//            else
            if (self.saveIsSuccessful) {
                message = "Save successful"
            }
            else {
                message = ""
            }
//            case .limited(.initializing) where mapProvider != nil,
//             .limited(.relocalizing) where mapProvider != nil:
//                message = "Received map from \(mapProvider!.displayName)."
            default:
                message = ""
        }
        
        statusLabel.text = message
    }
    
    // Remove snapshot thumbnail
    @objc func removeSnapshotThumbnail(_ notification: Notification) {
        self.snapshotThumbnail.isHidden = true
    }
    
    
    
    
    // MARK: - Delegate and functions for Shared Session
    
    func sendARSessionIDTo(peers: [MCPeerID]){
        guard let multipeerSession = multipeerSession else {
            return
        }
        let idString = arSceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8){
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)}
    }
    
    func receivedData(_ data: Data, from peer: MCPeerID){
        if let receivedNode = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data){
            switch receivedNode.name {
            case "cylinderLine":
                (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                break
            case "currentDragSphereNode":
                if ((arSceneView.scene as! PenScene).drawingNode.childNodes.contains(where: {$0.name == "currentDragSphereNode"})){
                    (arSceneView.scene as! PenScene).drawingNode.childNodes.first(where: {$0.name == "currentDragSphereNode"})?.geometry = receivedNode.geometry
                    break
                }
                else {
                    (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                    break
                }
            case "currentDragBoxNode":
                if ((arSceneView.scene as! PenScene).drawingNode.childNodes.contains(where: {$0.name == "currentDragBoxNode"})){
                    (arSceneView.scene as! PenScene).drawingNode.childNodes.first(where: {$0.name == "currentDragBoxNode"})?.geometry = receivedNode.geometry
                    break
                }
                else{
                    (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                    break
                }
            case "currentExtractionBoxNode":
                if ((arSceneView.scene as! PenScene).drawingNode.childNodes.contains(where: {$0.name == "currentExtractionBoxNode"})){
                    (arSceneView.scene as! PenScene).drawingNode.childNodes.first(where: {$0.name == "currentExtractionBoxNode"})?.geometry = receivedNode.geometry
                    break
                }
                else{
                    (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                    break
                }
            case "currentDragCylinderNode":
                if ((arSceneView.scene as! PenScene).drawingNode.childNodes.contains(where: {$0.name == "currentDragCylinderNode"})){
                    (arSceneView.scene as! PenScene).drawingNode.childNodes.first(where: {$0.name == "currentDragCylinderNode"})?.geometry = receivedNode.geometry
                    break
                }
                else{
                    (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                    break
                }
            case "currentDragPyramidNode":
                if ((arSceneView.scene as! PenScene).drawingNode.childNodes.contains(where: {$0.name == "currentDragPyramidNode"})){
                    (arSceneView.scene as! PenScene).drawingNode.childNodes.first(where: {$0.name == "currentDragPyramidNode"})?.geometry = receivedNode.geometry
                    break
                }
                else{
                    (arSceneView.scene as! PenScene).drawingNode.addChildNode(receivedNode)
                    break
                }
            case "renderedRay":
                if self.rayToggledOn{
                    if(pluginManager.penScene.drawingNode.childNodes.contains(where: {$0.name == "renderedRay"})){
                        pluginManager.penScene.drawingNode.childNodes.first(where: {$0.name == "renderedRay"})?.transform = receivedNode.transform
                        pluginManager.penScene.drawingNode.childNodes.first(where: {$0.name == "renderedRay"})?.position = receivedNode.position
                        pluginManager.penScene.drawingNode.childNodes.first(where: {$0.name == "renderedRay"})?.geometry = receivedNode.geometry
                    }
                    else{
                        pluginManager.penScene.drawingNode.addChildNode(receivedNode)
                    }
                }
                else if !self.rayToggledOn {
                    if(pluginManager.penScene.drawingNode.childNodes.contains(where: ({$0.name == "renderedRay"}))){
                        pluginManager.penScene.drawingNode.childNodes.first(where: {$0.name == "renderedRay"})?.removeFromParentNode()
                    }
                }
            default:
                messageLabel.displayMessage("Unknown Node-Type received!")
            }
        }
        else if let receivedARPNodeData = try? JSONDecoder().decode(ARPNodeData.self, from: data){
            switch receivedARPNodeData.pluginName {
            case "Sphere":
                (arSceneView.scene as! PenScene).drawingNode.childNodes.filter({$0.name == "currentDragSphereNode"}).forEach({$0.removeFromParentNode()})
                let sphere = ARPSphere(radius: receivedARPNodeData.radius!)
                sphere.localTranslate(by: receivedARPNodeData.positon!)
                sphere.applyTransform()
                sphere.geometryColor = UIColor.init(hue: receivedARPNodeData.hue!, saturation: receivedARPNodeData.saturation, brightness: receivedARPNodeData.brightness, alpha: receivedARPNodeData.alpha)
                DispatchQueue.main.async {
                    (self.arSceneView.scene as! PenScene).drawingNode.addChildNode(sphere)
                }
            case "Cube":
                (arSceneView.scene as! PenScene).drawingNode.childNodes.filter({$0.name == "currentDragBoxNode"}).forEach({$0.removeFromParentNode()})
                let cube = ARPBox(width: receivedARPNodeData.width!, height: receivedARPNodeData.height!, length: receivedARPNodeData.length!)
                cube.localTranslate(by: receivedARPNodeData.positon!)
                cube.applyTransform()
                cube.geometryColor = UIColor.init(hue: receivedARPNodeData.hue!, saturation: receivedARPNodeData.saturation, brightness: receivedARPNodeData.brightness, alpha: receivedARPNodeData.alpha)
                DispatchQueue.main.async {
                    (self.arSceneView.scene as! PenScene).drawingNode.addChildNode(cube)
                }
            case "CubeExtraction":
                (arSceneView.scene as! PenScene).drawingNode.childNodes.filter({$0.name == "currentExtractionBoxNode"}).forEach({$0.removeFromParentNode()})
                let cube = ARPBox(width: receivedARPNodeData.width!, height: receivedARPNodeData.height!, length: receivedARPNodeData.length!)
                cube.localTranslate(by: receivedARPNodeData.positon!)
                cube.applyTransform()
                cube.geometryColor = UIColor.init(hue: receivedARPNodeData.hue!, saturation: receivedARPNodeData.saturation, brightness: receivedARPNodeData.brightness, alpha: receivedARPNodeData.alpha)
                DispatchQueue.main.async {
                    (self.arSceneView.scene as! PenScene).drawingNode.addChildNode(cube)
                }
            case "Cylinder":
                (arSceneView.scene as! PenScene).drawingNode.childNodes.filter({$0.name == "currentDragCylinderNode"}).forEach({$0.removeFromParentNode()})
                let cylinder = ARPCylinder(radius: receivedARPNodeData.radius!, height: receivedARPNodeData.height!)
                cylinder.localTranslate(by: receivedARPNodeData.positon!)
                cylinder.applyTransform()
                cylinder.geometryColor = UIColor.init(hue: receivedARPNodeData.hue!, saturation: receivedARPNodeData.saturation, brightness: receivedARPNodeData.brightness, alpha: receivedARPNodeData.alpha)
                DispatchQueue.main.async {
                    (self.arSceneView.scene as! PenScene).drawingNode.addChildNode(cylinder)
                }
            case "Pyramid":
                (arSceneView.scene as! PenScene).drawingNode.childNodes.filter({$0.name == "currentDragPyramidNode"}).forEach({$0.removeFromParentNode()})
                let pyramid = ARPPyramid(width: receivedARPNodeData.width!, height: receivedARPNodeData.height!, length: receivedARPNodeData.length!)
                pyramid.localTranslate(by: receivedARPNodeData.positon!)
                pyramid.applyTransform()
                pyramid.geometryColor = UIColor.init(hue: receivedARPNodeData.hue!, saturation: receivedARPNodeData.saturation, brightness: receivedARPNodeData.brightness, alpha: receivedARPNodeData.alpha)
                DispatchQueue.main.async {
                    (self.arSceneView.scene as! PenScene).drawingNode.addChildNode(pyramid)
                }
            default:
                messageLabel.displayMessage("Received ARPNodeData of an unknown Plugin!")
                fatalError("Received ARPNodeData of an unknown Plugin!")
            }
        }
        else if let videoFrameData = try? JSONDecoder().decode(VideoFrameData.self, from: data){
            let sampleBuffer = (videoFrameData.makeSampleBuffer())
            videoProcessor.decompress(sampleBuffer){[self] imageBuffer,presentationTimeStamp in
                let width = CGFloat(CVPixelBufferGetWidth(imageBuffer))
                let height = CGFloat(CVPixelBufferGetHeight(imageBuffer))
                setPipViewConstraints(width: width, height: height)
                
                videoRenderer.enqueueFrame(pixelBuffer: imageBuffer, presentationTimeStamp: presentationTimeStamp, inverseProjectionMatrix: videoFrameData.inverseProjectionMatrix, inverseViewMatrix: videoFrameData.inverseViewMatrix)
            }
        }
        else if let sequenceData = try? JSONDecoder().decode([String].self, from: data){
            if self.pluginManager.activePlugin is SpectatorSharedARPlugin{
                let currentPlugin = self.pluginManager.activePlugin as! SpectatorSharedARPlugin
                currentPlugin.currentSequence = sequenceData
                messageLabel.displayMessage("", duration: 1)
            }
        }
        else if let stringCommandData = try? JSONDecoder().decode(String.self, from: data){
            if self.pluginManager.activePlugin is SharedARPlugin{
                let currentPlugin = self.pluginManager.activePlugin as! SharedARPlugin
                switch stringCommandData {
                case "ChangeTask" :
                    DispatchQueue.main.async {
                        currentPlugin.relocationTask?.toggle()
                        currentPlugin.highlightedNode = nil
                        if currentPlugin.sequenceNumber == 6{
                        self.messageLabel.displayMessage("Now swap to next setup.")
                        }
                    }
                case "Confirm sequence?":
                    DispatchQueue.main.async {
                        let confirmationController = UIAlertController(title: stringCommandData, message: nil, preferredStyle: .alert)
                        let confirmAction = UIAlertAction(title: "Save", style: .default, handler: {
                            action in
                            let confirmationData = "WriteOut"
                            if !(self.multipeerSession?.connectedPeers.isEmpty)!{
                                guard let encodedConfirmationData = try? JSONEncoder().encode(confirmationData) else{
                                    self.messageLabel.displayMessage("Could not encode confirmation data!")
                                    fatalError("Could not encode confirmation data!")
                                }
                                self.multipeerSession?.sendToAllPeers(encodedConfirmationData, reliably: true)
                            }
                        })
                        let cancelAction = UIAlertAction(title: "Delete", style: .default, handler: {
                            action in
                            currentPlugin.logger?.removeLastRow()
                            currentPlugin.sequenceNumber -= 1
                            let confirmationData = "Delete"
                            if !(self.multipeerSession?.connectedPeers.isEmpty)!{
                                guard let encodedConfirmationData = try? JSONEncoder().encode(confirmationData) else{
                                    self.messageLabel.displayMessage("Could not encode confirmation data!")
                                    fatalError("Could not encode confirmation data!")
                                }
                                self.multipeerSession?.sendToAllPeers(encodedConfirmationData, reliably: true)
                            }
                        })
                        confirmationController.addAction(confirmAction)
                        confirmationController.addAction(cancelAction)
                        self.present(confirmationController, animated: true, completion: nil)
                    }
                default:
                    return
                }
            }
            else if self.pluginManager.activePlugin is SpectatorSharedARPlugin{
                let currentPlugin = self.pluginManager.activePlugin as? SpectatorSharedARPlugin
                switch stringCommandData {
                case "Base":
                    DispatchQueue.main.async {
                        self.toggleSharedARHelpLabel.isHidden = false
                        self.toggleSharedARHelp.isHidden = true
                        self.pipView.isHidden = true
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemGreen
                        self.rayToggledOn = true
                        currentPlugin?.helpToggled = true
                        currentPlugin?.currentMode = stringCommandData
                        currentPlugin?.setupScene(sceneNumber: self.currentScene)
                    }
                case "Ray","Opacity":
                    DispatchQueue.main.async{
                        self.toggleSharedARHelpLabel.isHidden = false
                        self.toggleSharedARHelp.isHidden = false
                        self.pipView.isHidden = true
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemGreen
                        self.rayToggledOn = true
                        currentPlugin?.helpToggled = true
                        currentPlugin?.currentMode = stringCommandData
                        currentPlugin?.setupScene(sceneNumber: self.currentScene)
                    }
                case "Video":
                    DispatchQueue.main.async {
                        self.toggleSharedARHelpLabel.isHidden = false
                        self.toggleSharedARHelp.isHidden = false
                        self.pipView.isHidden = false
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemGreen
                        self.rayToggledOn = true
                        currentPlugin?.helpToggled = true
                        currentPlugin?.currentMode = stringCommandData
                        currentPlugin?.setupScene(sceneNumber: self.currentScene)
                    }
                case "Demo":
                    DispatchQueue.main.async{
                        self.currentScene = 0
                        currentPlugin?.setupScene(sceneNumber: 0)
                    }
                case "Scene1","Scene2","Scene3","Scene4","Scene5","Scene6","Scene7","Scene8","Scene9","Scene10","Scene11","Scene12":
                    DispatchQueue.main.async{
                        self.currentScene = self.sceneDict[stringCommandData]!
                        currentPlugin?.setupScene(sceneNumber: self.sceneDict[stringCommandData]!)
                    }
                case "Opposite", "SideBySide", "NinetyDegree":
                    DispatchQueue.main.async {
                        currentPlugin?.userPosition = stringCommandData
                        currentPlugin?.setupScene(sceneNumber: self.currentScene)
                    }
                case "ChangeTask":
                    DispatchQueue.main.async {
                        currentPlugin?.relocationTask?.toggle()
                        currentPlugin?.highlightedNode = nil
                        self.pipView.isHidden = true
                        if currentPlugin?.relocationTask! == true {
                            self.toggleSharedARHelp.isHidden = true
                            currentPlugin?.pluginManager?.penScene.drawingNode.childNodes.first(where: {$0.name == "renderedRay"})?.removeFromParentNode()
                            let alertController = UIAlertController(title: "Start Relocation Task", message: nil, preferredStyle: .alert)
                            let defaultAlertAction = UIAlertAction(title: "START!", style: .default, handler: {action in currentPlugin?.startDeviceUpdate()})
                            alertController.addAction(defaultAlertAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                case "Start":
                    DispatchQueue.main.async {
                        currentPlugin?.startDeviceUpdate()
                    }
                case "Log":
                    currentPlugin?.logCurrent()
                case "ResetCurrentNodeTime":
                    currentPlugin?.resetTimeForCurrentNode()
                    messageLabel.displayMessage("Please say when you found/memorized the cube and its position.", duration: 60)
                case "WriteOut":
                    return
                case "Delete":
                    currentPlugin?.logger?.removeLastRow()
                    currentPlugin?.relocationTaskLogger?.removeLastRow()
                    currentPlugin?.sequenceNumber -= 1
                default:
                    DispatchQueue.main.async {
                        if let highlightedNode = self.pluginManager.penScene.drawingNode.childNodes.filter({$0.name == stringCommandData}).first as? ARPenStudyNode{
                            currentPlugin?.highlightedNode = highlightedNode
                        }
                        else{
                            currentPlugin?.highlightedNode = nil
                        }
                    }
                }
            }
        }
    }

    
    func peerDiscovered(_peer: MCPeerID) -> Bool{
        guard let multipeerSession = multipeerSession else {
            return false
        }
        if multipeerSession.connectedPeers.count > 1 {
            // Do not allow more than two devices in the session (one person drawing and one person spectating)
            messageLabel.displayMessage("A third peer wants to join the experience.\n This app is limited to two users.",duration: 6)
            return false
        }
        else{
            return true
        }
    }
    
    func peerJoined(_ peer: MCPeerID){
        //messageLabel.displayMessage("A peer wants to join the experience. Hold the phones next to each other", duration: 6)
        sendARSessionIDTo(peers: [peer])
        
    }
    
    func peerLeft(_ peer: MCPeerID){
        messageLabel.displayMessage("A peer has left the shared session.", duration: 6)
        // could be used later on to save and restore if connection is lost during study!!!
        peerSesssionIDs.removeValue(forKey: peer)
    }
    
    @objc func handleSharedStateChange(_ notification: Notification){
        guard let userInfo = notification.userInfo else{
            print("notification.userINfo is empty")
            return
        }
        switch notification.name{
        case .shareSCNNodeData:
            let receivedNode = userInfo["nodeData"] as! SCNNode
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedSCNNodeData = try? NSKeyedArchiver.archivedData(withRootObject: receivedNode , requiringSecureCoding: true) else {
                    messageLabel.displayMessage("Could not encode SCNNode!")
                    fatalError("Could not encode SCNNode!")
                }
                multipeerSession?.sendToAllPeers(encodedSCNNodeData, reliably: true)
            }
        case .shareARPNodeData:
            let arpNodeData = userInfo["arpNodeData"] as! ARPNodeData
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedARPNodeData = try? JSONEncoder().encode(arpNodeData) else{
                    messageLabel.displayMessage("Failed to encode ARPNodeData!")
                    fatalError("Failed to encode ARNodeData!")
                }
                multipeerSession?.sendToAllPeers(encodedARPNodeData, reliably: true)
            }
        case .labelCommand:
            let receivedLabelString = userInfo["labelStringData"] as! String
            messageLabel.displayMessage(receivedLabelString,duration: 6)
        case .nodeCommand:
            let receivedNodeCommand = userInfo["nodeHighlightData"] as? String
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedNodeCommandData = try? JSONEncoder().encode(receivedNodeCommand) else {
                    messageLabel.displayMessage("Could not encode node highlight command!")
                    fatalError("Could not encode node highlight command!")
                }
                multipeerSession?.sendToAllPeers(encodedNodeCommandData, reliably: true)
            }
        case .changeModeCommand:
            let receivedModeChange = userInfo["modeChangeData"] as? String
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedModeChangeData = try? JSONEncoder().encode(receivedModeChange) else{
                    messageLabel.displayMessage("Could not encode mode change command!")
                    fatalError("Could not encode mode change command!")
                }
                multipeerSession?.sendToAllPeers(encodedModeChangeData, reliably: true)
            }
        case .changeSceneCommand:
            let receivedSceneChange = userInfo["sceneChangeData"] as? String
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedSceneChangeData = try? JSONEncoder().encode(receivedSceneChange) else{
                    messageLabel.displayMessage("Could not encode scene change command!")
                    fatalError("Could not encode scene change command!")
                }
                multipeerSession?.sendToAllPeers(encodedSceneChangeData, reliably: true)
            }
        case .changePositionCommand:
            let receivedPositionChange = userInfo["positionChangeData"] as? String
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedPositionChangeData = try? JSONEncoder().encode(receivedPositionChange) else{
                    messageLabel.displayMessage("Could not encode position change command!")
                    fatalError("Could not encode position change command!")
                }
                multipeerSession?.sendToAllPeers(encodedPositionChangeData, reliably: true)
            }
        case .changeTaskMode:
            let receivedTaskChange = userInfo["taskChangeData"] as? String
            if self.pluginManager.activePlugin is SpectatorSharedARPlugin {
                self.toggleSharedARHelp.isHidden = false
            }
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedTaskChangeData = try? JSONEncoder().encode(receivedTaskChange) else{
                    messageLabel.displayMessage("Could not encode task change command!")
                    fatalError("Could not encode task change command!")
                }
                multipeerSession?.sendToAllPeers(encodedTaskChangeData, reliably: true)
            }
        case .infoLabelCommand:
            let receivedMessage = userInfo["sharedARInfoLabelData"] as? String
            sharedARInfoLabel.text = receivedMessage
        case .measurementCommand:
            let receivedMeasurementCommand = userInfo["measurementCommandData"] as? String
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedMeasurementCommandData = try? JSONEncoder().encode(receivedMeasurementCommand) else{
                    messageLabel.displayMessage("Could not encode measurement command data!")
                    fatalError("Could not encode measurement command data!")
                }
                multipeerSession?.sendToAllPeers(encodedMeasurementCommandData, reliably: true)
            }
        case .alertCommand:
            if pluginManager.activePlugin is SpectatorSharedARPlugin{
                let currentPlugin = pluginManager.activePlugin as! SpectatorSharedARPlugin
                let confirmAlertController = UIAlertController(title: "Confirm", message: nil, preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: "Confirm Node \(currentPlugin.highlightedNode!.name!)", style: .default, handler: {
                    action in
                    currentPlugin.logCurrent()
                    currentPlugin.highlightedNode = nil
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                confirmAlertController.addAction(confirmAction)
                confirmAlertController.addAction(cancelAction)
                self.present(confirmAlertController, animated: true,completion: nil)
            }
        case .sequenceData:
            let sequenceData = userInfo["sequenceData"] as? [String]
            if !(multipeerSession?.connectedPeers.isEmpty)!{
                guard let encodedSequenceData = try? JSONEncoder().encode(sequenceData) else{
                    messageLabel.displayMessage("Could not encode sequence data!")
                    fatalError("Could not encode sequence data!")
                }
                multipeerSession?.sendToAllPeers(encodedSequenceData, reliably: true)
            }
        case .trialLogConfirmation:
            if pluginManager.activePlugin is SpectatorSharedARPlugin{
                let confirmationString = userInfo["confirmData"] as? String
                print(confirmationString)
                if !(self.multipeerSession?.connectedPeers.isEmpty)!{
                    guard let encodedConfirmationData = try? JSONEncoder().encode(confirmationString) else{
                        self.messageLabel.displayMessage("Could not encode confirmation data!")
                        fatalError("Could not encode confirmation data!")
                    }
                    self.multipeerSession?.sendToAllPeers(encodedConfirmationData, reliably: true)
                }
            }
        default:
            break
        }
    }
    
    //Turn current help on or off
    @IBAction func toggleSharedARHelp(_ sender: UIButton) {
        if let currentPlugin = pluginManager.activePlugin as? SpectatorSharedARPlugin{
            if currentPlugin.currentMeasurement != nil{
                
                currentPlugin.currentMeasurement?.buttonPressesForCurrentNode += 1
                
                switch currentPlugin.currentMode{
                case "Base":
                    return
                case "Ray":
                    self.rayToggledOn.toggle()
                    currentPlugin.helpToggled.toggle()
                    if currentPlugin.helpTimer.isValid{
                        currentPlugin.stopHelpTimer()
                    }
                    else{
                        currentPlugin.startHelpTimer()
                    }
                case "Opacity":
                    currentPlugin.helpToggled.toggle()
                    if currentPlugin.helpTimer.isValid{
                        currentPlugin.stopHelpTimer()
                    }
                    else{
                        currentPlugin.startHelpTimer()
                    }
                case "Video":
                    currentPlugin.helpToggled.toggle()
                    if currentPlugin.helpTimer.isValid{
                        currentPlugin.stopHelpTimer()
                    }
                    else{
                        currentPlugin.startHelpTimer()
                    }
                    DispatchQueue.main.async {
                        self.pipView.isHidden.toggle()
                    }
                default:
                    self.messageLabel.displayMessage("Unknown mode set.")
                }
                DispatchQueue.main.async {
                    if currentPlugin.helpToggled{
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemGreen
                    }
                    else{
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemRed
                    }
                }
            }
            else {
                currentPlugin.buttonPressesOutsideOfTrial += 1
                switch currentPlugin.currentMode{
                case "Base":
                    return
                case "Ray":
                    self.rayToggledOn.toggle()
                    currentPlugin.helpToggled.toggle()
                case "Opacity":
                    currentPlugin.helpToggled.toggle()
                case "Video":
                    currentPlugin.helpToggled.toggle()
                    self.pipView.isHidden.toggle()
                default:
                    self.messageLabel.displayMessage("Unknown mode set.")
                }
                print(currentPlugin.helpToggled)
                DispatchQueue.main.async {
                    if currentPlugin.helpToggled{
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemGreen
                    }
                    else{
                        self.toggleSharedARHelpLabel.backgroundColor = UIColor.systemRed
                    }
                }
            }
        }/*
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let log = CSVLogFile(name: "Scene12", inDirectory: URL(fileURLWithPath:documentsPath), options: .lineNumbering)
        log.header = "PosX,PosY,PosZ"
        let currentPlugin = self.pluginManager.activePlugin as! StudyPlugin
        let i = currentPlugin.sceneConstructionResults!.studyNodes.count
        for k in 0...i/2 - 1 {
            log.logObjects(in: [currentPlugin.sceneConstructionResults?.studyNodes[k].position.x,currentPlugin.sceneConstructionResults?.studyNodes[k].position.y,currentPlugin.sceneConstructionResults?.studyNodes[k].position.z])
        }*/
    }
    
    //Set the pipViewConstraints to keep the correct aspect ratio between devices
    func setPipViewConstraints(width: CGFloat, height: CGFloat){
        DispatchQueue.main.async {
            [self] in
            pipViewWidthConstraint.constant = width / pipView.contentScaleFactor
            pipViewHeightConstraint.constant = height / pipView.contentScaleFactor
        }
    }

    
    // Invoked once when a new anchor is added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARImageAnchor{
            let coordinateSystem = SCNGeometry.generateCoordinateSystemAxes(color: 1)
            node.addChildNode(coordinateSystem)
            //let rotationAroundX = SCNMatrix4(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 0, m23: -1, m24: 0, m31: 0, m32: 1, m33: 0, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)
          //  let worldTransformMatrix = anchor.transform * simd_float4x4.init(rotationAroundX)
            arSceneView.session.setWorldOrigin(relativeTransform: anchor.transform)
            //(arSceneView.scene as! PenScene).drawingNode.addChildNode(SCNGeometry.generateCoordinateSystemAxes(color: 2))
        }
    }
    
    // Invoked when an anchor changes , i.e. tracking status
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imgAnchor = anchor as? ARImageAnchor else { return }
        if imgAnchor.isTracked && !lastTrackingState{
            arSceneView.session.setWorldOrigin(relativeTransform: imgAnchor.transform)
            latestKnownWorldTransform = imgAnchor.transform
            lastTrackingState = true
        }
        else if !imgAnchor.isTracked && lastTrackingState{
           // arSceneView.session.setWorldOrigin(relativeTransform: latestKnownWorldTransform)
            lastTrackingState = false
        }
    }
    
    
    @IBAction func enableBaseSetting(_ sender: UIButton) {
        if pluginManager.activePlugin is SharedARPlugin {
            if RPScreenRecorder.shared().isRecording {
                RPScreenRecorder.shared().stopCapture{ error in
                    guard let _ = error else{
                        self.messageLabel.displayMessage("\(error?.localizedDescription ?? "Stopped ScreenShare")")
                        return
                    }
                }
            }
            
            let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
            currentPlugin?.currentMode = "Base"
            currentPlugin?.setupScene(sceneNumber: currentScene)
            let informationPackage : [String : Any] = ["modeChangeData": "Base"]
            NotificationCenter.default.post(name: .changeModeCommand, object: nil, userInfo: informationPackage)
        }
    }
    
    @IBAction func enableOpacitySetting(_ sender: UIButton) {
        if pluginManager.activePlugin is SharedARPlugin {
            if RPScreenRecorder.shared().isRecording {
                RPScreenRecorder.shared().stopCapture{ error in
                    guard let _ = error else{
                        self.messageLabel.displayMessage("\(error?.localizedDescription ?? "Stopped ScreenShare")")
                        return
                    }
                }
            }
            
            let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
            currentPlugin?.currentMode = "Opacity"
            currentPlugin?.setupScene(sceneNumber: self.currentScene)
            
            let informationPackage : [String : Any] = ["modeChangeData": "Opacity"]
            NotificationCenter.default.post(name: .changeModeCommand, object: nil, userInfo: informationPackage)
            
        }
    }
    
    
    @IBAction func enableRaySetting(_ sender: UIButton) {
        if pluginManager.activePlugin is SharedARPlugin {
            if RPScreenRecorder.shared().isRecording {
                RPScreenRecorder.shared().stopCapture{ error in
                    guard let _ = error else{
                        self.messageLabel.displayMessage("\(error?.localizedDescription ?? "Stopped ScreenShare")")
                        return
                    }
                }
            }
            
            let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
            currentPlugin?.currentMode = "Ray"
            currentPlugin?.setupScene(sceneNumber: currentScene)
            let informationPackage : [String : Any] = ["modeChangeData": "Ray"]
            NotificationCenter.default.post(name: .changeModeCommand, object: nil, userInfo: informationPackage)
        }

    }
    
    @IBAction func enableVideoSetting(_ sender: UIButton) {
        if pluginManager.activePlugin is SharedARPlugin {
            let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
            currentPlugin?.currentMode = "Video"
            currentPlugin?.setupScene(sceneNumber: currentScene)
            let informationPackage : [String : Any] = ["modeChangeData": "Video"]
            NotificationCenter.default.post(name: .changeModeCommand, object: nil, userInfo: informationPackage)
        }
    
        
        if RPScreenRecorder.shared().isRecording {
            RPScreenRecorder.shared().stopCapture{ error in
                guard let _ = error else{
                    self.messageLabel.displayMessage("\(error?.localizedDescription ?? "Stopped ScreenShare")")
                    return
                }
            }
        }
        else{
            RPScreenRecorder.shared().startCapture{
                [self] (sampleBuffer, type, error) in
                if type == .video {
                    guard let currentFrame = arSceneView.session.currentFrame else {
                        self.messageLabel.displayMessage("Could not get currentFrame")
                        return
                    }
                    videoProcessor.compressAndSend(sampleBuffer, arFrame: currentFrame) {
                        (data) in
                        self.multipeerSession?.sendToAllPeers(data, reliably: false)
                    }
                }
            }
        }
    }
    
    @IBAction func changeToDemoScene(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 0)
        self.currentScene = 0
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Demo"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneOne(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 1)
        self.currentScene = 1
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene1"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneTwo(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 2)
        self.currentScene = 2
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene2"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneThree(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 3)
        self.currentScene = 3
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene3"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneFour(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 4)
        self.currentScene = 4
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene4"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    
    @IBAction func changeToSceneFive(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 5)
        self.currentScene = 5
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene5"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneSix(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 6)
        self.currentScene = 6
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene6"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneSeven(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 7)
        self.currentScene = 7
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene7"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneEight(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 8)
        self.currentScene = 8
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene8"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneNine(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 9)
        self.currentScene = 9
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene9"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneTen(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 10)
        self.currentScene = 10
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene10"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneEleven(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 11)
        self.currentScene = 11
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene11"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSceneTwelve(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.setupScene(sceneNumber: 12)
        self.currentScene = 12
        
        let informationPackage : [String : Any] = ["sceneChangeData" : "Scene12"]
        NotificationCenter.default.post(name: .changeSceneCommand, object: nil, userInfo: informationPackage)
    }
    
    
    
    @IBAction func changeToOppositePosition(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.userPosition = "Opposite"
        
        self.messageLabel.displayMessage("Position changed to opposite.")
        
        let informationPackage : [String : Any] = ["positionChangeData" : "Opposite"]
        NotificationCenter.default.post(name: .changePositionCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToSideBySidePosition(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.userPosition = "SideBySide"
        
        self.messageLabel.displayMessage("Position changed to side-by-side.")
        
        let informationPackage : [String : Any] = ["positionChangeData" : "SideBySide"]
        NotificationCenter.default.post(name: .changePositionCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeToNinetyDegreePosition(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.userPosition = "NinetyDegree"
        
        self.messageLabel.displayMessage("Position changed to 90-degree")
        
        let informationPackage : [String : Any] = ["positionChangeData" : "NinetyDegree"]
        NotificationCenter.default.post(name: .changePositionCommand, object: nil, userInfo: informationPackage)
    }
    
    @IBAction func changeTask(_ sender: UIButton) {
        let currentPlugin = pluginManager.activePlugin as? SharedARPlugin
        currentPlugin?.relocationTask?.toggle()
        
        let informationPackage : [String : Any] = ["taskChangeData" : "ChangeTask"]
        NotificationCenter.default.post(name: .changeTaskMode, object: nil, userInfo: informationPackage)
    }
    
    
    
    // MARK: - Share ARWorldMap with other users
   
    func setupAndShareAnchor() {
//        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
//       let transform = self.arSceneView.scene.rootNode.simdTransform
//       let anchor = ARAnchor(name: sharePointAnchorName, transform: transform)
//       self.arSceneView.session.add(anchor: anchor)
//
//       // Send the anchor info to peers, so they can place the same content.
//       guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
//           else { fatalError("can't encode anchor") }
//       self.multipeerSession.sendToAllPeers(data)
    }
    
    
    @IBAction func shareModelButtonPressed(_ sender: Any) {
//        self.arSceneView.session.getCurrentWorldMap { worldMap, error in
//            guard let map = worldMap
//                else {
//                    print("Error: \(error!.localizedDescription)")
//                    return
//                }
//
//            DispatchQueue.main.async {
//                let scene = self.arSceneView.scene as! PenScene
//                scene.pencilPoint.removeFromParentNode() // Remove pencilPoint before sharing
//                var nodesCreatedWithOpenCascade: [SCNNode] = []
//
//                // Remove all geometries created via Open Cascade
//                scene.drawingNode.childNodes(passingTest: { (node, stop) -> Bool in
//                    let geometryType = type(of: node)
//                    print("geometryType:\(geometryType)")
//
//                    if ((geometryType == ARPSphere.self) || (geometryType == ARPGeomNode.self) || (geometryType == ARPRevolution.self) ||
//                        (geometryType == ARPBox.self) || (geometryType == ARPNode.self) || (geometryType == ARPSweep.self) ||
//                        (geometryType == ARPCylinder.self) || (geometryType == ARPLoft.self) || (geometryType == ARPPath.self) ||
//                        (geometryType == ARPBoolNode.self) || (geometryType == ARPPathNode.self)) {
//                        print("Detected geometry created via Open Cascade.\n")
//
//                        nodesCreatedWithOpenCascade.append(node)
//                        node.removeFromParentNode()
//                        return false
//                    } else {
//                        print("Detected geometry *not* created via Open Cascade.\n")
//                        return true
//                    }
//                })
//
//                // Share content first so that the content is not duplicated for this device
//                guard let sceneData = try? NSKeyedArchiver.archivedData(withRootObject: scene.drawingNode, requiringSecureCoding: true)
//                    else { fatalError("can't encode scene data") }
//                self.multipeerSession.sendToAllPeers(sceneData)
//                scene.reinitializePencilPoint()
//                nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
//
//                self.setupAndShareAnchor()
//
//                // Send the WorldMap to all peers
//                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
//                    else { fatalError("can't encode map") }
//                self.multipeerSession.sendToAllPeers(data)
//            }
//        }
    }
    
//    var mapProvider: MCPeerID?
//
//    /// - Tag: ReceiveData
//    func receivedData(_ data: Data, from peer: MCPeerID) {
//
//        if let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data){
//
//            if unarchivedData is ARWorldMap, let worldMap = unarchivedData as? ARWorldMap {
//                // Run the session with the received world map.
//                let configuration = ARWorldTrackingConfiguration()
//                configuration.planeDetection = .horizontal
//                configuration.initialWorldMap = worldMap
//                self.arSceneView.session.run(configuration, options: [.resetTracking])
//
//                // Remember who provided the map for showing UI feedback.
//                mapProvider = peer
//            } else if unarchivedData is ARAnchor, let anchor = unarchivedData as? ARAnchor {
//                self.arSceneView.session.add(anchor: anchor)
//                print("added the anchor (\(anchor.name ?? "(can't parse)")) received from peer: \(peer)")
//            } else if unarchivedData is SCNNode, let sceneData = unarchivedData as? SCNNode {
////                scene.write(to: self.sceneStoreURL, options: nil, delegate: nil, progressHandler: nil)
//                self.sharedNode = sceneData
//                print("saved scene data into sharedNode")
//            }
//            else {
//              print("Unknown Data Recieved From = \(peer)")
//            }
//        } else {
//            print("can't decode data received from \(peer)")
//        }
//    }
}

