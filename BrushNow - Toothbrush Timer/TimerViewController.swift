//
//  TimerViewController.swift
//  BrushNow - Toothbrush Timer
//
//  Created by Daniel on 10/9/18.
//  Copyright © 2018 Placeholder Interactive. All rights reserved.
//

import UIKit
import UserNotifications
import AVFoundation

var numberOfBrushes = 0
var totalTime = 0
var todayBrushes = 0
var firstBrushTiming = ""

class TimerViewController: ViewController {
    // Messy part for outlets
    
    @IBOutlet weak var timerHeadingLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var themeHeadingLabel: UILabel!
    @IBOutlet weak var themeNameLabel: UILabel!
    @IBOutlet weak var readySetLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var brushHintLabel: UILabel!
    @IBOutlet weak var teethView: UIImageView!
    
    // Music
    var audioPlayer: AVAudioPlayer?
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    var isPaused = false
    
    var time = 120
    var timer: Timer?
    var teethTimer: Timer?
    var savedDate: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playBackgroundMusic(filename: "silence.mp3")
        
        // Asking for permission for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in
        })
        
        time = timeSet
        startButton.layer.cornerRadius = 10
        startButton.clipsToBounds = true
       // UserDefaults stuff
        let loadedBrushes = UserDefaults.standard.integer(forKey: "noOfBrush")
        let loadedFirst = UserDefaults.standard.bool(forKey: "firstBrush")
        let loadedRookie = UserDefaults.standard.bool(forKey: "rookieBrush")
        let loadedDentist = UserDefaults.standard.bool(forKey: "dentistsBFF")
        let loadedManiac = UserDefaults.standard.bool(forKey: "maniac")
        let loadedForgetful = UserDefaults.standard.bool(forKey: "forgetful")
        let loadedAmnesiac = UserDefaults.standard.bool(forKey: "amnesiac")
        let loadedNotif = UserDefaults.standard.integer(forKey: "notifNo")
        let loadedEarly = UserDefaults.standard.bool(forKey: "earlyBird")
        let loadedTrack = UserDefaults.standard.string(forKey: "selectedTrack")
        
        let loadedTime = UserDefaults.standard.integer(forKey: "totalTime")
        
        let loadedDate = UserDefaults.standard.object(forKey: "savedDate") as? String ?? "00.00.0000"
        let loadedToday = UserDefaults.standard.integer(forKey: "todayBrushes")
        let loadedTiming = UserDefaults.standard.string(forKey: "firstBrushTiming") ?? "Don't be shy, brush on!"
        
        selectedTrack = loadedTrack ?? "Track 1"
        notificationNo = loadedNotif
        numberOfBrushes = loadedBrushes
        badges[0].isCompleted = loadedFirst
        badges[1].isCompleted = loadedRookie
        badges[2].isCompleted = loadedDentist
        badges[3].isCompleted = loadedManiac
        badges[4].isCompleted = loadedForgetful
        badges[5].isCompleted = loadedAmnesiac
        badges[6].isCompleted = loadedEarly
        totalTime = loadedTime
        savedDate = loadedDate
        todayBrushes = loadedToday
        firstBrushTiming = loadedTiming
        
        if let data = UserDefaults.standard.data(forKey: "selectedTheme"),
            let myTheme = NSKeyedUnarchiver.unarchiveObject(with: data) as? Theme {
            selectedTheme = myTheme
            
        } else {
            print("There is an issue with the selected theme") // NOTE FOR VIEWER: THIS WILL DEFINITELY PRINT ON FIRST LAUNCH DUE TO NOT HAVING THEMES STORED IN IT YET, BUT DON'T WORRY - IT DOESN'T DO ANYTHING
        }
        
        // Retrieving a value for a key
        if let data = UserDefaults.standard.data(forKey: "themes"),
            let myThemeList = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Theme] {
            themes = myThemeList
        } else {
            print("There is an issue with the themes array") // NOTE FOR VIEWER: THIS WILL DEFINITELY PRINT ON FIRST LAUNCH DUE TO NOT HAVING THEMES STORED IN IT YET, BUT DON'T WORRY - IT DOESN'T DO ANYTHING
        }
        
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let result = formatter.string(from: date)
        
        if result != savedDate {
            savedDate = result
            UserDefaults.standard.set(savedDate, forKey: "savedDate")
            todayBrushes = 0
            UserDefaults.standard.set(todayBrushes, forKey: "todayBrushes")
        }
    }
    

    
    // Start setup
    override func viewDidAppear(_ animated: Bool) {
        // Theme
        view.backgroundColor = selectedTheme.backgroundColour
        timerHeadingLabel.textColor = selectedTheme.textColour
        minutesLabel.textColor = selectedTheme.textColour
        timerLabel.textColor = selectedTheme.textColour
        themeHeadingLabel.textColor = selectedTheme.textColour
        themeNameLabel.textColor = selectedTheme.textColour
        themeNameLabel.text = selectedTheme.name
        startButton.backgroundColor = selectedTheme.buttonColour
        brushHintLabel.textColor = selectedTheme.textColour
        
        time = timeSet
        // Hiding and unhiding
        timerHeadingLabel.isHidden = false
        minutesLabel.isHidden = false
        themeHeadingLabel.isHidden = false
        themeNameLabel.isHidden = false
        startButton.isHidden = false
        readySetLabel.isHidden = true
        brushHintLabel.isHidden = true
        teethView.isHidden = true
        trackLabel.isHidden = true
        playButton.isHidden = true
        pauseButton.isHidden = true
        timerLabel.isHidden = true
        
        trackLabel.text = selectedTrack
        minutesLabel.text = "\(time / 60) MINUTES"
        time = timeSet
  
        timer?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
        teethTimer?.invalidate()
        time = timeSet
        minutesLabel.text = "\(time / 60) MINUTES"
        brushHintLabel.text = "BRUSH UPPER LEFT TEETH (FRONT)"
        teethView.image = UIImage(named: "upperleft")
        audioPlayer?.stop()
        mediaPlayer.stop()
        mediaPlayer.currentPlaybackTime = 0
        isPaused = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: themes)
        UserDefaults.standard.set(encodedData, forKey: "themes")
    }
    
    /* MARK: Play sound
     */
    func playBackgroundMusic(filename: String) {
        let url = Bundle.main.url(forResource: filename, withExtension: nil)
        guard let newURL = url else {
            print("Could not find file: \(filename)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: newURL)
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        if selectedTrack != "User's Track" {
        if isPaused == false {
        playBackgroundMusic(filename: "\(selectedTrack).mp3")
        } else {
            audioPlayer?.play()
        }
        } else {
            mediaPlayer.play()
        }
    }
    
    
    @IBAction func pauseButtonPressed(_ sender: Any) {
        if selectedTrack != "User's Track" {
        if audioPlayer?.isPlaying == true {
        audioPlayer?.pause()
        isPaused = true
        } else {
            print ("Player not playing yet.")
        }
        } else {
            mediaPlayer.pause()
            isPaused = true
        }
    }
    
    
    
    func goToBadges (alert: UIAlertAction) {
        tabBarController?.selectedIndex = 1
    }
    
    // Button to start timer
    @IBAction func startButtonPressed(_ sender: Any) {
        
        timerHeadingLabel.isHidden = true
        minutesLabel.isHidden = true
        themeHeadingLabel.isHidden = true
        themeNameLabel.isHidden = true
        startButton.isHidden = true
        readySetLabel.isHidden = false
        timerLabel.isHidden = true
        
        func timeFormatted(_ totalSeconds: Int) -> String {
            let seconds: Int = totalSeconds % 60
            let minutes: Int = (totalSeconds / 60) % 60
            //     let hours: Int = totalSeconds / 3600
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        // Ready set go
        let animator = UIViewPropertyAnimator(duration: 1.5, curve: .linear, animations: {
            self.readySetLabel.text = "READY"
            self.readySetLabel.textColor = selectedTheme.textColour
            self.readySetLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.readySetLabel.alpha = 0
        })
        animator.addCompletion{(_) in
            self.readySetLabel.transform = CGAffineTransform.identity
            self.readySetLabel.alpha = 1
            self.readySetLabel.text = "SET"
            let secondAnimator = UIViewPropertyAnimator(duration: 1.5, curve: .linear, animations : {
                self.readySetLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.readySetLabel.alpha = 0
                
            })
            secondAnimator.addCompletion{(_) in
                self.readySetLabel.transform = CGAffineTransform.identity
                self.readySetLabel.alpha = 1
                self.readySetLabel.text = "GO!"
                let thirdAnimator = UIViewPropertyAnimator(duration: 1.5, curve: .linear, animations : {
                    self.readySetLabel.transform = CGAffineTransform(scaleX: 2, y: 2)
                    self.readySetLabel.alpha = 0
                    
                })
                thirdAnimator.addCompletion{(_) in
                    self.readySetLabel.alpha = 1
                    self.readySetLabel.transform = CGAffineTransform.identity
                    self.readySetLabel.isHidden = true
                    
                    // Extremely messy bit for mouth (sorry not sorry)
                    let timeTakenToChange = Double(timeSet / 15)
                    let brushHints = ["BRUSH UPPER MIDDLE TEETH (FRONT)", "BRUSH UPPER RIGHT TEETH (FRONT)", "BRUSH LOWER LEFT TEETH (FRONT)", "BRUSH LOWER MIDDLE TEETH (FRONT)", "BRUSH LOWER RIGHT TEETH (FRONT)", "BRUSH UPPER LEFT TEETH (BACK)", "BRUSH UPPER MIDDLE TEETH (BACK)", "BRUSH UPPER RIGHT TEETH (BACK)", "BRUSH LOWER LEFT TEETH (BACK)", "BRUSH LOWER MIDDLE TEETH (BACK)", "BRUSH LOWER RIGHT TEETH (BACK)", "BRUSH UPPER CHEWING SURFACES", "BRUSH LOWER CHEWING SURFACES","BRUSH TONGUE"]
                    
                    let teethImages = ["uppermiddle", "upperright", "bottomleft", "bottommiddle", "bottomright", "upperleft", "uppermiddle", "upperright", "bottomleft", "bottommiddle", "bottomright", "chewtop", "chewbottom", "normal"]
                    
                    var arrayNo = -1
                    
                    self.teethTimer = Timer.scheduledTimer(withTimeInterval: timeTakenToChange, repeats: true) { (_) in
                        if arrayNo != 13 {
                        arrayNo += 1
                        } else {
                            print ("Max achieved")
                        }
                        self.brushHintLabel.text = brushHints[arrayNo]
                        self.teethView.image = UIImage(named: teethImages[arrayNo])
                        
                    }
                    
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
                        self.timerLabel.text = "\(timeFormatted(self.time))"
                        if self.time > 0 {
                        UIApplication.shared.isIdleTimerDisabled = true
                        self.time -= 1
                        self.timerLabel.isHidden = false
                        self.brushHintLabel.isHidden = false
                        self.teethView.isHidden = false
                        self.trackLabel.isHidden = false
                        self.playButton.isHidden = false
                        self.pauseButton.isHidden = false
                            
                        } else if self.time == 0 {
                            self.timer?.invalidate()
                            self.teethTimer?.invalidate()
                            UIApplication.shared.isIdleTimerDisabled = false
                            self.audioPlayer?.stop()
                            mediaPlayer.stop()
                            mediaPlayer.currentPlaybackTime = 0
                            self.trackLabel.isHidden = true
                            self.playButton.isHidden = true
                            self.pauseButton.isHidden = true
                            self.isPaused = false
                            
                            self.brushHintLabel.text = "BRUSH UPPER LEFT TEETH (FRONT)"
                            self.teethView.image = UIImage(named: "upperleft")
                            numberOfBrushes += 1
                            UserDefaults.standard.set(numberOfBrushes, forKey: "noOfBrush")
                            todayBrushes += 1
                            UserDefaults.standard.set(todayBrushes, forKey: "todayBrushes")
                            totalTime += (timeSet / 60)
                            UserDefaults.standard.set(totalTime, forKey:
                            "totalTime")
                            let date = Date(timeIntervalSinceNow: 0)
                            let currentDateComp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                            
                            if badges[6].isCompleted == false {
                            if currentDateComp.hour! < 6 {
                                badges[6].isCompleted = true
                                UserDefaults.standard.set(badges[6].isCompleted, forKey: "earlyBird")
                                let mornColour = UIColor(red:0.97, green:0.83, blue:0.34, alpha:1.0)
                                let mornButton = UIColor(red:0.89, green:0.90, blue:0.63, alpha:1.0)
                                themes.append(Theme(name: "MORNING", textColour: .black, backgroundColour: mornColour, buttonColour: mornButton, previewImage: "morningpreview"))
                                self.save()
                                
                                let alert = UIAlertController(title: "Badge Unlocked", message: "You have unlocked 'Early Bird'! View your reward at the badges page.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Badges Page", comment: "Goes to badges tab"), style: .default, handler: self.goToBadges))
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: { _ in
                                    print ("Alert has been dimissed.")
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
                            } else {
                                print ("Achievement already completed.")
                            }
                            
                            // Switch statement for unlocking achievements
                            switch numberOfBrushes {
                                
                                //First Brush
                            case 1:
                                let date = Date()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMM d, yyyy"
                                let result = formatter.string(from: date)
                                firstBrushTiming = result
                                UserDefaults.standard.set(firstBrushTiming, forKey: "firstBrushTiming")
                                
                                badges[0].isCompleted = true
                                UserDefaults.standard.set(badges[0].isCompleted, forKey: "firstBrush")
                                let oceanCol = UIColor(red:0.50, green:0.80, blue:1.00, alpha:1.0)
                                let sandCol = UIColor(red:1.00, green:0.96, blue:0.51, alpha:1.0)
                                themes.append(Theme(name: "OCEAN", textColour: .black, backgroundColour: oceanCol, buttonColour: sandCol, previewImage: "oceanpreview"))
                                self.save()
                                
                                let alert = UIAlertController(title: "Badge Unlocked", message: "You have unlocked 'First Brush'! View your reward at the badges page.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Badges Page", comment: "Goes to badges tab"), style: .default, handler: self.goToBadges))
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: { _ in
                                    print ("Alert has been dimissed.")
                                }))
                                self.present(alert, animated: true, completion: nil)
                                
                                // Rookie Brusher
                            case 10:
                                badges[1].isCompleted = true
                                UserDefaults.standard.set(badges[1].isCompleted, forKey: "rookieBrush")
                                let grassCol = UIColor(red:0.53, green:0.81, blue:0.37, alpha:1.0)
                                let brownCol = UIColor(red:0.55, green:0.44, blue:0.12, alpha:1.0)
                                themes.append(Theme(name: "GRASS", textColour: .black, backgroundColour: grassCol, buttonColour: brownCol, previewImage: "grasspreview"))
                                self.save()
                                
                                let alert = UIAlertController(title: "Badge Unlocked", message: "You have unlocked 'Rookie Brusher'! View your reward at the badges page.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Badges Page", comment: "Goes to badges tab"), style: .default, handler: self.goToBadges))
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: { _ in
                                    print ("Alert has been dimissed.")
                                }))
                                self.present(alert, animated: true, completion: nil)
                                // Dentist's BFF
                            case 25:
                                badges[2].isCompleted = true
                                UserDefaults.standard.set(badges[2].isCompleted, forKey: "dentistsBFF")
                                let tropBack = UIColor(red:0.96, green:0.96, blue:0.51, alpha:1.0)
                                let tropButton = UIColor(red:0.71, green:0.82, blue:0.60, alpha:1.0)
                                themes.append(Theme(name: "TROPICAL", textColour: .black, backgroundColour: tropBack, buttonColour: tropButton, previewImage: "tropicalpreview"))
                                self.save()
                                
                                let alert = UIAlertController(title: "Badge Unlocked", message: "You have unlocked 'Dentist's BFF'! View your reward at the badges page.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Badges Page", comment: "Goes to badges tab"), style: .default, handler: self.goToBadges))
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: { _ in
                                    print ("Alert has been dimissed.")
                                }))
                                self.present(alert, animated: true, completion: nil)
                                
                                // Maniac
                            case 50:
                                badges[3].isCompleted = true
                                UserDefaults.standard.set(badges[3].isCompleted, forKey: "maniac")
                                
                                let winterCol = UIColor(red:0.91, green:0.89, blue:0.89, alpha:1.0)
                                let winterButton = UIColor(red:0.54, green:0.78, blue:0.82, alpha:1.0)
                                
                                themes.append(Theme(name: "WINTER", textColour: .black, backgroundColour: winterCol, buttonColour: winterButton, previewImage: "winterpreview"))
                                self.save()
                                
                                let alert = UIAlertController(title: "Badge Unlocked", message: "You have unlocked 'Maniac'! View your reward at the badges page.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Badges Page", comment: "Goes to badges tab"), style: .default, handler: self.goToBadges))
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: { _ in
                                    print ("Alert has been dimissed.")
                                }))
                                self.present(alert, animated: true, completion: nil)
                            // If nothing was unlocked
                            default:
                                print ("No achievements have been unlocked from this brush.")
                            }
                            
                            
                            
                            self.timerHeadingLabel.isHidden = false
                            self.minutesLabel.isHidden = false
                            self.timerLabel.isHidden = true
                            self.themeHeadingLabel.isHidden = false
                            self.themeNameLabel.isHidden = false
                            self.startButton.isHidden = false
                            self.readySetLabel.isHidden = true
                            self.brushHintLabel.isHidden = true
                            self.teethView.isHidden = true
                            
                            self.time = timeSet
                            UserDefaults.standard.set(self.time, forKey: "time")
                            self.minutesLabel.text = "\(self.time / 60) MINUTES"
                            
                            
                        }
                    }
                }
                thirdAnimator.startAnimation()
            }
            secondAnimator.startAnimation()
        }
        
        animator.startAnimation()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
