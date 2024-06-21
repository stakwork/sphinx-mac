//
//  AudioRecorderHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVFoundation

protocol AudioHelperDelegate: AnyObject {
    func didStartRecording(_ success: Bool)
    func didFinishRecording(_ success: Bool)
    func permissionDenied()
    func audioTooShort()
    func recordingProgress(minutes: String, seconds: String)
}

class AudioRecorderHelper : NSObject {
    
    weak var delegate: AudioHelperDelegate?
    
    var audioRecorder: AVAudioRecorder? = nil
    var recordingTimer : Timer? = nil
    var startRecordingTime = Date()
    
    public var bitRate = 192000
    public var sampleRate = 44100.0
    public var channels = 1
    
    @objc public enum State: Int {
        case None, Record
    }
    
    var state = State.None
    
    func configureAudioSession(delegate: AudioHelperDelegate) {
        self.delegate = delegate
    }
    
    func requestAudioRecordingPermission(completion: @escaping () -> ()) {
        if #available(OSX 10.14, *) {
            let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
            if audioPermission == .notDetermined {
                AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                    DispatchQueue.main.async {
                        if granted {
                            completion()
                        } else {
                            self.delegate?.permissionDenied()
                            NewMessageBubbleHelper().showGenericMessageView(text: "microphone.permission.denied".localized)
                        }
                    }
                })
            }
        } else {
            completion()
        }
    }
    
    func isPermissionGranted() -> Bool {
        if #available(OSX 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        } else {
            return true
        }
    }
    
    func isPermissionDenied() -> Bool {
        if #available(OSX 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .denied
        } else {
            return false
        }
    }
    
    func shouldStartRecording() {
        if isPermissionGranted() {
            startRecording()
        } else {
            requestAudioRecordingPermission(completion: {
                self.startRecording()
            })
        }
    }
    
    func shouldFinishRecording() {
        finishRecording(success: true)
    }
    
    func shouldCancelRecording() {
        state = .None
        finishRecording(success: false)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getAudioData() -> Data? {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
        return MediaLoader.getDataFromUrl(url: audioFilename)
    }
    
    func getAudioDataAndDuration() -> (Data?, Double?) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
        
        var lengthAudioPlayer : AVAudioPlayer?
        do  {
            lengthAudioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
        } catch {
            lengthAudioPlayer = nil
        }
        
        return (MediaLoader.getDataFromUrl(url: audioFilename), lengthAudioPlayer?.duration)
    }
    
    func prepare() throws {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")

        do {
            try FileManager.default.removeItem(at: audioFilename)
        } catch let error {
            print(error)
        }

        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVEncoderBitRateKey: bitRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVSampleRateKey: sampleRate
            ] as [String : Any]

        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
    }
    
    func startRecording() {
        if state != .None {
            return
        }
        
        startRecordingTime = Date()
        recordingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateRecordingTime), userInfo: nil, repeats: true)

        do {
            if audioRecorder == nil {
                try prepare()
            }
        } catch {
            recordingDidFail()
        }
        
        audioRecorder?.record()
        state = .Record
        delegate?.didStartRecording(true)
    }
    
    func recordingDidFail() {
        state = .None
        audioRecorder?.stop()
        delegate?.didStartRecording(false)
    }
    
    func finishRecording(success: Bool) {
        if let _ = audioRecorder {
            audioRecorder?.stop()

            recordingTimer?.invalidate()
            recordingTimer = nil

            if Date().timeIntervalSince(startRecordingTime) <= 1 {
                delegate?.audioTooShort()
            }
        }
    }
    
    @objc func updateRecordingTime() {
        let timeInterval = Date().timeIntervalSince(startRecordingTime)
        let minutes: Int = Int(timeInterval) / 60
        let seconds: Int = Int(timeInterval) % 60
        delegate?.recordingProgress(minutes: "\(minutes)", seconds: seconds.timeString)
    }
}

extension AudioRecorderHelper : AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let didCancel = state == .None
        delegate?.didFinishRecording(flag && !didCancel)
        state = .None
    }
}
