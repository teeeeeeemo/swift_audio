//
//  ViewController.swift
//  Audio
//
//  Created by Lucia on 2017. 2. 27..
//  Copyright © 2017년 Lucia. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var audioPlayer : AVAudioPlayer! // AVAudioPlayer 인스턴스 변수 
    var audioFile : URL! // 재생할 오디오의 파일명 변수 
    let MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수 
    var progressTimer : Timer! // 타이머를 위한 변수 
    
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector: Selector = #selector(ViewController.updateRecordTime)

    @IBOutlet weak var pvProgressPlay: UIProgressView!
    @IBOutlet weak var lblCurrentTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnPause: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var slVolume: UISlider!
    
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var lblRecordTime: UILabel!
    
    
    var audioRecorder: AVAudioRecorder! // audioRecorder 인스턴스
    var isRecordMode = false // 처음 앱 실행시 '재생모드' 를 위한 false값 설정.
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        selectAudioFile()
        if !isRecordMode { // 재생모드.
            initPlay()
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
        } else { // 녹음모드.
            initRecord()
        }

    }
    
    // 재생모드와 녹음모드에 따라 다른 파일 선택.
    func selectAudioFile() {
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "orange_op", withExtension: "mp3")
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
    }
    
    // 녹음모드 초기화.
    func initRecord() {
        let recordSettings = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32), //포맷
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue, //음질
            AVEncoderBitRateKey: 320000, // 비트율 320,000bps(320kbps)
            AVNumberOfChannelsKey: 2, // 오디오 채널 : 2
            AVSampleRateKey: 44100.0] as [String: Any] // 샘플률은 44,100Hz
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self // audioRecorder의 delegate 설정.
        audioRecorder.isMeteringEnabled = true // 박자관련 isMeteringEnabled 값을 true.
        audioRecorder.prepareToRecord() // prepareToRecord 함수 실행.
        
        slVolume.value = 1.0 // 볼륨 슬라이더 값 1.0 설정
        audioPlayer.volume = slVolume.value // audioPlayer 볼륨도 slider 값과 동일하게 1.0으로 설정.
        lblEndTime.text = convertNSTimeInterval2String(0) // 총 재생시간을 0으로.
        lblCurrentTime.text = convertNSTimeInterval2String(0) // 현재 재생시간을 0으로.
        setPlayButtons(false, pause: false, stop: false) // Play, Pause, Stop 버튼들을 비활성화시킴. 
        
        
        // AVAudioSession 의 인스턴스 session을 생성하고, 
        // try-catch문을 사용하여 카테고리 설정, 액티브 설정.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("Error-setCategory : \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive : \(error)")
        }
        
    }

    // 재생모드 초기화.
    func initPlay() {
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        
        slVolume.maximumValue = MAX_VOLUME // 슬라이더의 최대 볼륨을 상수 10.0으로 초기화.
        slVolume.value = 1.0 // 슬라이더의 볼륨을 1.0으로 초기화.
        pvProgressPlay.progress = 0 // 프로그레스 뷰의 진행을 0으로 초기화.
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트를 self로 설정.
        audioPlayer.prepareToPlay() // prepareToPlay() 실행.
        audioPlayer.volume = slVolume.value // 앞에서 초기화한 슬라이더의 볼륨 값으로 초기화. 
        
        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        lblCurrentTime.text = convertNSTimeInterval2String(0) // 00:00 출력되도록. 
        
        setPlayButtons(true, pause: false, stop: false)
        
    }
    
    
    // 재생, 일시정지, 정지 버튼을 활성화 / 비활성화 함수.
    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    // 00:00 형태의 문자열로 변환하는 함수.
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // [재생] 버튼 클릭
    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play() // 오디오 재생
        setPlayButtons(false, pause: true, stop: true) // Play 버튼은 비활성화, 나머지 버튼들은 활성화.
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    // 0.1초마다 호출되며 재생 시간을 표시.
    func updatePlayTime() {
        lblCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
        // 프로그레스 뷰의 진행상황에 audioPlayer.currentTime을 audioPlayer.duration으로 나눈 값으로 표시.
    }
    
    // 0.1초마다 호출되며 녹음 시간을 표시.
    func updateRecordTime() {
        lblRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }

    // [일시정지] 버튼 클릭
    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause() // 오디오 일시정지
        setPlayButtons(true, pause: false, stop: true)
    }
    
    // [정지] 버튼 클릭
    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop() // 오디오 정지
        audioPlayer.currentTime = 0 // 정지이므로 audioPlayer.currentTime을 0으로 설정. 
        lblCurrentTime.text = convertNSTimeInterval2String(0) // 재생시간 또한 00:00 으로 초기화.
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머도 무효화.
    }
    
    // 볼륨 슬라이더 값을 audioPlayer.volume에 대입.
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
    }
    
    // 오디오 재생이 끝나면 맨 처음 상태로 돌아가도록 하는 함수. 
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate() // 타이머 무효화. 
        setPlayButtons(true, pause: false, stop: false)
    }
    
    // 스위치를 On/Off하여 녹음모드인지 재생모드인지 결정함.
    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn { // 녹음모드.
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            lblRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else { // 재생모드.
            isRecordMode = false
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = convertNSTimeInterval2String(0)
        }
        
        selectAudioFile()
        
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }
    @IBAction func btnRecord(_ sender: UIButton) {
        if sender.titleLabel?.text == "Record" { // 버튼이 "Record"일 때 녹음을 중지함.
            audioRecorder.record()
            sender.setTitle("Stop", for: UIControlState())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else { // 버튼이 "Stop"일 때 녹음을 위한 초기화를 수행. 
            audioRecorder.stop()
            progressTimer.invalidate()
            sender.setTitle("Record", for: UIControlState())
            btnPlay.isEnabled = true
            initPlay() // 녹음한 파일로 재생을 초기화. 
        }
    }
    
}

