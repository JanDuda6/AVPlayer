//
//  ViewController.swift
//  AVPlayer
//
//  Created by Kurs on 31/08/2021.
//

import UIKit
import SnapKit
import RxGesture
import RxSwift
import AVKit

class HomeViewController: UIViewController {

    private let disposeBag = DisposeBag()

    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Go to Player", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemOrange
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGray6
        setUpButton()
        setUpButtonGesture()
    }

    private func goToPlayer() {
        let playerVC = PlayerViewController(videoURL: VideoURL.parkourVideo)
        self.present(playerVC, animated: false)
    }

    private func setUpButton() {
        self.view.addSubview(button)
        button.snp.makeConstraints {
            $0.height.equalTo(50)
            $0.trailing.equalTo(self.view).offset(-50)
            $0.leading.equalTo(self.view).offset(50)
            $0.centerX.centerY.equalTo(self.view)
        }
    }

    private func setUpButtonGesture() {
        button.rx.tap
            .subscribe(onNext:  { [weak self] _ in
                self?.goToPlayer()
            }).disposed(by: disposeBag)
    }
}
