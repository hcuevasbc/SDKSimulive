//
//  ControlsViewController.swift
//  CustomControls
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK

fileprivate struct ControlConstants {
    static let VisibleDuration: TimeInterval = 5.0
    static let AnimateInDuration: TimeInterval = 0.1
    static let AnimateOutDuraton: TimeInterval = 0.2
}

public class SimuliveControlsViewController: UIViewController {
    
    public weak var delegate: ControlsViewControllerFullScreenDelegate?
    private weak var currentPlayer: AVPlayer?
    
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak private var controlsContainer: UIView!
    @IBOutlet weak private var playPauseButton: UIButton!
    @IBOutlet weak private var playheadLabel: UILabel!
    @IBOutlet weak private var playheadSlider: UISlider!
    @IBOutlet weak private var durationLabel: UILabel!
    @IBOutlet weak private var fullscreenButton: UIButton!
    @IBOutlet weak private var externalScreenButton: MPVolumeView!
    @IBOutlet weak private var closedCaptionButton: UIButton!
    
    
    @IBOutlet weak var backSimuliveView: UIView!
    
    private var controlTimer: Timer?
    private var playingOnSeek: Bool = false
    
    var closedCaptionEnabled: Bool = false {
        didSet {
            closedCaptionButton.isEnabled = closedCaptionEnabled
        }
    }
    
    func dateStringToDate(date:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone.current
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: date)
        return date
    }
    func dateToDateString(date:Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone.current
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.string(from: date)
        return date
    }
    
    public init() {
        super.init(nibName: "SimuliveControlsViewController", bundle: Bundle(identifier: "com.brightcove.CustomCC"))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var ccMenuController: ClosedCaptionMenuController = {
        let _ccMenuController = ClosedCaptionMenuController(style: .grouped)
        _ccMenuController.controlsView = self
        return _ccMenuController
    }()
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.paddingCharacter = "0"
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Used for hiding and showing the controls.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
        externalScreenButton.showsRouteButton = true
        externalScreenButton.showsVolumeSlider = false
        
        closedCaptionButton.isEnabled = false
    }
    
    // MARK: - Misc
    public var playList:NSFastEnumeration?  {
        didSet {
            configurePlayList()
        }
    }
    
    
    public func configurePlayList() {
        guard let playList = playList else {
            return
        }
        let newPlayList = (playList as! Array<BCOVVideo>)
        for (itemId, item) in newPlayList.enumerated() {
            if let id =  item.properties["id"] as? String,
               let name = item.properties["name"] as? String,
               let customFields = item.properties["custom_fields"] as? Dictionary<String,Any>{
                if let startTime = customFields[self.conf?.customStartFieldName ?? ""] as? String {
                    if let conf = conf, conf.playlistInSuccession == false, itemId > 0 {
                        let beforeVideo = self.playListSimulive[itemId - 1]
                        guard let endDate =  beforeVideo.endDate, let starttime = dateToDateString(date:endDate) else {return}
                        
                        let simuliveItem = SimuliveItem(id: id, title: name, start: starttime, video: item)
                        self.playListSimulive.append(simuliveItem)
                    } else {
                        let simuliveItem = SimuliveItem(id: id, title: name, start: startTime, video: item)
                        self.playListSimulive.append(simuliveItem)
                    }
                } else {
                    if (itemId > 0 && self.playListSimulive.count >= itemId) {
                        let beforeVideo = self.playListSimulive[itemId - 1]
                        guard let endDate =  beforeVideo.endDate, let starttime = dateToDateString(date:endDate) else {
                            return
                        }
                        
                        let simuliveItem = SimuliveItem(id: id, title: name, start: starttime, video: item)
                        self.playListSimulive.append(simuliveItem)
                        
                    } else {
                        self.messageText.text = "failed to load"
                    }
                }
                
            } else {
                
            }
        }
        currentItemGet()
    }
    
    var playListSimulive:[SimuliveItem] = [SimuliveItem]()
    var conf:SimuliveConf?
    
    private weak var playBackController:BCOVPlaybackController?
    
    public func setVideos(playList: NSFastEnumeration, playBackController: BCOVPlaybackController?, conf:SimuliveConf) {
        self.conf = conf
        self.playBackController = playBackController
        self.playBackController?.isAutoPlay = false
        self.playList = playList
        
        self.currentItemGet()
    }
    
    @objc private func tapDetected() {
        if playPauseButton.isSelected {
            if controlsContainer.alpha == 0.0 {
                fadeControlsIn()
            } else if (controlsContainer.alpha == 1.0) {
                fadeControlsOut()
            }
        }
    }
    var currentItem:SimuliveItem? {
        didSet {
            if let video = currentItem?.video {
                self.playBackController?.setVideos([video] as? NSFastEnumeration)
            }
        }
    }
    
    func seekToSimlulive(_ pause:Bool = false) {
        guard let item = currentItem else {
            return
        }
        if let start = item.startDate, let end = item.endDate {
            let elapsed = Date().timeIntervalSince(start)
            let elapsedAfterEnd = Date().timeIntervalSince(end)
            if elapsedAfterEnd > 0 {
                self.currentItemGet()
            } else {
            let time = TimeInterval(elapsed)
            let cmtime = CMTimeMakeWithSeconds(time, preferredTimescale: 600)
            self.currentPlayer?.seek(to:cmtime)
            }
        }
        if !pause {
            self.currentPlayer?.play()
        }
    }
    
    func currentItemGet() {
        let now = Date()
        if  let current =  playListSimulive.last(where: {($0.startDate ?? now) < now && ($0.endDate ?? now) > now}) {
            currentItem = current
            validateMessage(item: current)

        } else {
            if let current = playListSimulive.first(where: {($0.startDate ?? now) > now}) {
                currentItem = current
                validateMessage(item: current)
            } else {
                self.backSimuliveView.isHidden = false
                self.messageText.isHidden = false
                self.messageText.text = "\(self.conf?.labels?.ended ?? "")"
                self.messageText.font = UIFont(name: "Lato-Bold", size: 16)
            }
        }
    }
    
    func validateMessage(item:SimuliveItem) {
        let now = Date()
//        timer?.invalidate()
        guard let startDate = item.startDate else {
            return
        }
//        self.audioPlayer.isHidden = true
        if startDate > now {
            self.messageText.isHidden = false
            self.backSimuliveView.isHidden = false
            let diffComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: startDate)
            
            var text = ""
            if diffComponents.hour ?? 0 > 0 {
                text = text + "\(diffComponents.hour ?? 0)h "
            }
            
            if diffComponents.minute ?? 0 > 0 {
                text = text + "\(diffComponents.minute ?? 0)m "
            }
            
            if diffComponents.second ?? 0 > 0 {
                text = text + "\(diffComponents.second ?? 0)s"
            }
            
            self.messageText.text = "\(conf?.labels?.countdown?.live ?? "") \(text)"
            self.messageText.font = UIFont(name: "Lato-Bold", size: 16)
//            self.messageText.sizeToFit()
            
            let diff = startDate.timeIntervalSince(now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if (diff > 1)  {
                self.validateMessage(item: item)
                } else {
                    self.messageText.isHidden = true
                    self.backSimuliveView.isHidden = true
                }
            }
        } else {
            self.messageText.isHidden = true
            self.backSimuliveView.isHidden = true
        }
    }
    
    private func fadeControlsIn() {
        UIView.animate(withDuration: ControlConstants.AnimateInDuration, animations: {
            self.showControls()
        }) { [weak self](finished: Bool) in
            if finished {
                self?.reestablishTimer()
            }
        }
    }
    
    @objc private func fadeControlsOut() {
        UIView.animate(withDuration: ControlConstants.AnimateOutDuraton) {
            self.hideControls()
        }
        
    }
    
    private func reestablishTimer() {
        controlTimer?.invalidate()
        controlTimer = Timer.scheduledTimer(timeInterval: ControlConstants.VisibleDuration, target: self, selector: #selector(fadeControlsOut), userInfo: nil, repeats: false)
    }
    
    private func hideControls() {
        controlsContainer.alpha = 0.0
    }
    
    private func showControls() {
        controlsContainer.alpha = 1.0
    }
    
    private func invalidateTimerAndShowControls() {
        controlTimer?.invalidate()
        showControls()
    }
    
    private func formatTime(timeInterval: TimeInterval) -> String? {
        if (timeInterval.isNaN || !timeInterval.isFinite || timeInterval == 0) {
            return "00:00"
        }
        
        let hours  = floor(timeInterval / 60.0 / 60.0)
        let minutes = (timeInterval / 60).truncatingRemainder(dividingBy: 60)
        let seconds = timeInterval.truncatingRemainder(dividingBy: 60)
        
        guard let formattedMinutes = numberFormatter.string(from: NSNumber(value: minutes)), let formattedSeconds = numberFormatter.string(from: NSNumber(value: seconds)) else {
            return nil
        }
        
        return hours > 0 ? "\(hours):\(formattedMinutes):\(formattedSeconds)" : "\(formattedMinutes):\(formattedSeconds)"
    }
    
    // MARK: - IBActions
    
    @IBAction func handleFullScreenButtonPressed(_ button: UIButton) {
        if button.isSelected {
            button.isSelected = false
            delegate?.handleExitFullScreenButtonPressed()
        } else {
            button.isSelected = true
            delegate?.handleEnterFullScreenButtonPressed()
        }
    }
    
    @IBAction func handlePlayheadSliderTouchEnd(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let newCurrentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            let seekToTime = CMTimeMakeWithSeconds(newCurrentTime, preferredTimescale: 600)
            
            currentPlayer?.seek(to: seekToTime, completionHandler: { [weak self] (finished: Bool) in
                self?.playingOnSeek = false
                self?.currentPlayer?.play()
            })
        }
    }
    
    @IBAction func handlePlayheadSliderTouchBegin(_ slider: UISlider) {
        playingOnSeek = playPauseButton.isSelected
        currentPlayer?.pause()
    }
    
    @IBAction func handlePlayheadSliderValueChanged(_ slider: UISlider) {
        if let currentTime = currentPlayer?.currentItem {
            let currentTime = Float64(slider.value) * CMTimeGetSeconds(currentTime.duration)
            playheadLabel.text = formatTime(timeInterval: currentTime)
        }
    }
    
    @IBAction func handlePlayPauseButtonPressed(_ button: UIButton) {
        if button.isSelected {
            currentPlayer?.pause()
        } else {
            currentPlayer?.play()
        }
    }
    
    @IBAction func handleClosedCaptionButtonPressed(_ button: UIButton) {
        let navController = UINavigationController(rootViewController: ccMenuController)
        present(navController, animated: true, completion: nil)
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension SimuliveControlsViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // This makes sure that we don't try and hide the controls if someone is pressing any of the buttons
        // or slider.
        
        guard let view = touch.view else {
            return true
        }
        
        if ( view.isKind(of: UIButton.classForCoder()) || view.isKind(of: UISlider.classForCoder()) ) {
            return false
        }
        
        return true
    }
    
}

// MARK: - BCOVPlaybackSessionConsumer

extension SimuliveControlsViewController: BCOVPlaybackSessionConsumer {
    
    public func didAdvance(to session: BCOVPlaybackSession!) {
        currentPlayer = session.player
        
        // Reset State
        playingOnSeek = false
        playheadLabel.text = formatTime(timeInterval: 0)
        playheadSlider.value = 0.0
        
        invalidateTimerAndShowControls()
    }
    
    public func playbackSession(_ session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
        durationLabel.text = formatTime(timeInterval: duration)
    }
    
    public func playbackSession(_ session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
        playheadLabel.text = formatTime(timeInterval: progress)
        
        guard let currentItem = session.player.currentItem else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        let percent = Float(progress / duration)
        playheadSlider.value = percent.isNaN ? 0.0 : percent
        if percent.isInfinite {
            currentItemGet()
        }
    }
    
    public func playbackSession(_ session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        switch lifecycleEvent.eventType {
        case kBCOVPlaybackSessionLifecycleEventPlay:
            playPauseButton?.isSelected = true
            reestablishTimer()
            seekToSimlulive()
        case kBCOVPlaybackSessionLifecycleEventPause:
            playPauseButton.isSelected = false
            invalidateTimerAndShowControls()
        case kBCOVPlaybackSessionLifecycleEventReady:
            ccMenuController.currentSession = session
            
            
        default:
            break
        }
    }
}

// MARK: - ControlsViewControllerFullScreenDelegate

public protocol ControlsViewControllerFullScreenDelegate: AnyObject {
    func handleEnterFullScreenButtonPressed()
    func handleExitFullScreenButtonPressed()
}
