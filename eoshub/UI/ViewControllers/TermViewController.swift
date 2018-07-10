//
//  TermViewController.swift
//  eoshub
//
//  Created by kein on 2018. 7. 8..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class TermViewController: BaseViewController {
    
    @IBOutlet fileprivate var lbTitle: UILabel!
    @IBOutlet fileprivate var btnPrivacy: UIButton!
    @IBOutlet fileprivate var lbPrivacyDesc: UILabel!
    @IBOutlet fileprivate var btnStart: UIButton!
    
    var flowDelegate: TermFlowEventDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
    }
    
    private func setupUI() {
        lbTitle.text = LocalizedString.Term.title
        btnPrivacy.setTitle(LocalizedString.Term.goPrivacy, for: .normal)
        btnStart.setTitle(LocalizedString.Term.start, for: .normal)
    }
    
    private func bindActions() {
        btnStart.rx.singleTap
            .bind { [weak self](_) in
                guard let nc = self?.navigationController else { return }
                self?.flowDelegate?.goToCreate(from: nc)
            }
            .disposed(by: bag)
    }
}


//MARK: Layout
extension TermViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}