//
//  PlayerViewController.swift
//  AVPlayer
//
//  Created by Kurs on 31/08/2021.
//

import Foundation
import UIKit
import AVKit
import SnapKit
import RxSwift

class PlayerViewController: UIViewController {
    private let videoURL: String
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private let disposeBag = DisposeBag()

    private let playPauseButton: UIButton = {
        let button = UIButton()
        let imageSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .large)
        let image = UIImage(systemName: "play.fill", withConfiguration: imageSize)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray6
        return button
    }()

    private let forwardButton: UIButton = {
        let button = UIButton()
        let imageSize = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let image = UIImage(systemName: "forward.fill", withConfiguration: imageSize)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray6
        return button
    }()

    private let backwardButton: UIButton = {
        let button = UIButton()
        let imageSize = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let image = UIImage(systemName: "backward.fill", withConfiguration: imageSize)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray6
        return button
    }()

    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 70
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        return stackView
    }()

    private let videoProgressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .red
        slider.thumbTintColor = .red
        slider.maximumTrackTintColor = .gray
        return slider
    }()

    init(videoURL: String) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preparePlayerLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerLayer.frame = self.view.layer.bounds
    }

    private func preparePlayerLayout() {
        self.view.backgroundColor = .black
        guard let url = URL(string: videoURL) else { return }
        self.player = AVPlayer(url: url)
        self.playerLayer = AVPlayerLayer(player: player)
        self.view.layer.addSublayer(playerLayer)
        setUpButtonsStackView()
        setUpButtonsGesture()
        setUpSliderConstraints()
        setUpSliderProgressBar()
        setUpSliderAction()
        setUpPlayerGesture()
        dismissWhenVideoEnds()
    }
}

//MARK: - SnapKit
extension PlayerViewController {
    private func setUpButtonsStackView() {
        self.view.addSubview(buttonsStackView)
        buttonsStackView.addArrangedSubview(backwardButton)
        buttonsStackView.addArrangedSubview(playPauseButton)
        buttonsStackView.addArrangedSubview(forwardButton)
        buttonsStackView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    private func setUpSliderConstraints() {
        self.view.addSubview(videoProgressSlider)
        videoProgressSlider.snp.makeConstraints {
            $0.leading.equalTo(self.view).offset(40)
            $0.trailing.equalTo(self.view).offset(-40)
            $0.bottom.equalTo(self.view).offset(-50)
        }
    }
}

//MARK: - RxGesture
extension PlayerViewController {
    private func setUpPlayerGesture() {
        self.view.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext:  { [weak self] _ in
                self?.hideAndShowControlsOnTap()
            }).disposed(by: disposeBag)
    }

    private func setUpButtonsGesture() {
        playPauseButton.rx.tap
            .subscribe(onNext:  { [weak self] _ in
                self?.playPauseVideo()
            }).disposed(by: disposeBag)

        forwardButton.rx.tap
            .subscribe(onNext:  { [weak self] _ in
                self?.buttonsVideoSeek(doForwardJump: true)
            }).disposed(by: disposeBag)

        backwardButton.rx.tap
            .subscribe(onNext:  { [weak self] _ in
                self?.buttonsVideoSeek(doForwardJump: false)
            }).disposed(by: disposeBag)
    }

    private func setUpSliderAction() {
        videoProgressSlider.rx.value
            .subscribe(onNext: { [weak self] newTime in
                self?.sliderVideoSeek(newTime: newTime)
            }).disposed(by: disposeBag)
    }

    private func hideAndShowControlsOnTap() {
        if buttonsStackView.isHidden {
            buttonsStackView.isHidden = false
            videoProgressSlider.isHidden = false
        } else {
            buttonsStackView.isHidden = true
            videoProgressSlider.isHidden = true
        }
    }
}

//MARK: - Media Controls Features
extension PlayerViewController {
    private func playPauseVideo() {
        if self.player.rate == 0 {
            self.player.play()
            let imageSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .large)
            let image = UIImage(systemName: "pause.fill", withConfiguration: imageSize)
            playPauseButton.setImage(image, for: .normal)
        } else {
            self.player.pause()
            let imageSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .large)
            let image = UIImage(systemName: "play.fill", withConfiguration: imageSize)
            playPauseButton.setImage(image, for: .normal)
        }
    }

    private func buttonsVideoSeek(doForwardJump: Bool) {
        let interval = CMTimeMake(value: 30, timescale: 1)
        let currentTime = player.currentTime()
        let targetTime = doForwardJump ? CMTimeAdd(interval, currentTime) : CMTimeSubtract(currentTime, interval)
        self.player.seek(to: targetTime)
    }

    private func sliderVideoSeek(newTime: Float) {
        let newTimeInSeconds = Int64(newTime)
        let targetTime = CMTimeMake(value: newTimeInSeconds, timescale: 1)
        player.seek(to: targetTime)
    }

    private func setUpSliderProgressBar() {
        let interval = CMTimeMake(value: 1, timescale: 10)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] progressTime in
            if self?.player.currentItem?.status == .readyToPlay {
                guard let duration = self?.player.currentItem?.duration.seconds else { return }
                self?.videoProgressSlider.maximumValue = Float(duration)
                let currentTime = CMTimeGetSeconds(progressTime)
                self?.videoProgressSlider.value = Float(currentTime)
            }
        })
    }
}

//MARK: - Notification handler
extension PlayerViewController {
    private func dismissWhenVideoEnds() {
        NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemDidPlayToEndTime)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
}
