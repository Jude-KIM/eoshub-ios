//
//  SendCurrencyViewController.swift
//  eoshub
//
//  Created by kein on 2018. 7. 12..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class SendCurrencyViewController: TextInputViewController {
    
    var flowDelegate: SendFlowEventDelegate?
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var btnSend: UIButton!
    @IBOutlet fileprivate weak var btnHistory: UIButton!
    
    var account: AccountInfo!
    var balance: Currency!
    
    fileprivate let sendForm = SendForm()
    
    deinit {
        Log.d("deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = LocalizedString.Wallet.send
        showNavigationBar(with: .white)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
    }
    
    private func setupUI() {
        contentsScrollView = tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        
        btnSend.setTitle(LocalizedString.Wallet.Transfer.transfer, for: .normal)
        btnHistory.setTitle(LocalizedString.Wallet.Transfer.history, for: .normal)
    }
    
    private func bindActions() {
        btnHistory.rx.singleTap
            .bind { [weak self] in
                self?.goToTxHistory()
            }
            .disposed(by: bag)
        
        btnSend.rx.singleTap
            .bind { [weak self] in
                self?.validateInputForm()
            }
            .disposed(by: bag)

        let quantityCheck = sendForm.quantity.asObservable()
            .flatMap(isValidQuantity(max: balance.quantity))

        let accountCheck = sendForm.account.asObservable()
            .flatMap(isValidAccount)
        
        Observable.combineLatest([quantityCheck, accountCheck])
                .flatMap(isValid)
                .bind(to: btnSend.rx.isEnabled)
                .disposed(by: bag)
        
    }
    
    func configure(account: AccountInfo, balance: Currency) {
        self.account = account
        self.balance = balance
    }
    
    fileprivate func goToTxHistory() {
        guard let nc = navigationController else { return }
        flowDelegate?.goToTx(from: nc, account: account, filter: balance.symbol)
    }
    
    fileprivate func validateInputForm() {
        confirmTransfer()
    }

    private func isValidQuantity(max: Double) -> (String) -> Observable<Bool> {
        return { inputString in
            let input = Double(inputString) ?? 0
            if input > 0 && input <= max {
                return Observable.just(true)
            } else {
                return Observable.just(false)
            }
        }
    }
    
    private func isValidAccount(accountName: String) -> Observable<Bool> {
        let available = Validator.accountName(name: accountName)
        return Observable.just(available)
    }
    
    private func isValid(checklist: [Bool]) -> Observable<Bool> {
        
        for valid in checklist {
            if valid == false {
                return Observable.just(false)
            }
        }
        
        return Observable.just(true)
    }
    
    fileprivate func confirmTransfer() {
        
        
        TransferPopup.show(account: sendForm.account.value, memo: sendForm.memo.value,
                           quantity: sendForm.quantity.value.dot4String,
                           symbol: balance.symbol)
            .subscribe(onNext: { [weak self] (accept) in
                if accept {
                    self?.transfer()
                }
            }, onCompleted: {
                
            })
            .disposed(by: bag)
        
    }
    
    fileprivate func transfer() {
        //TODO: validation account
        //TODO: validate available EOS
        authentication(showAt: self)
            .flatMap { [weak self](validated) -> Observable<JSON> in
                
                WaitingView.shared.start()
                
                guard let strongSelf = self else { return  Observable.error(EOSErrorType.invalidState) }
                
                let wallet = Wallet(key: strongSelf.account.pubKey)
                
                return RxEOSAPI.sendCurrency(from: strongSelf.account.account,
                                             to: strongSelf.sendForm.account.value,
                                             quantity: strongSelf.sendForm.quantityCurrency(symbol: strongSelf.balance.symbol),
                                             memo: strongSelf.sendForm.memo.value,
                                             wallet: wallet)
            }
            .flatMap({ (_) -> Observable<Void> in
                WaitingView.shared.stop()
                //clear form
                self.sendForm.clear()
                //pop
                return Popup.show(style: .success, description: LocalizedString.Tx.success)
            })
            .flatMap({ (_) -> Observable<Void> in
                return AccountManager.shared.loadAccounts()
            })
            .subscribe(onNext: { (_) in
                self.flowDelegate?.finish(viewControllerToFinish: self, animated: true, completion: nil)
            }, onError: { (error) in
                Log.e(error)
                WaitingView.shared.stop()
                Popup.present(style: .failed, description: "\(error)")
            })
            .disposed(by: bag)
        
    }
}

extension SendCurrencyViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellId = ""
        if indexPath.row == 0 {
            cellId = "SendMyAccountCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? SendMyAccountCell else { preconditionFailure() }
            cell.configure(account: account, balance: balance)
            return cell
            
        } else {
            cellId = "SendInputFormCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? SendInputFormCell else { preconditionFailure() }
            cell.configure(form: sendForm, symbol: balance.symbol)
            return cell
        }
    }
    
}


class SendMyAccountCell: UITableViewCell {
    @IBOutlet fileprivate weak var lbAccount: UILabel!
    @IBOutlet fileprivate weak var lbAvailable: UILabel!
    @IBOutlet fileprivate weak var lbBalance: UILabel!
    @IBOutlet fileprivate weak var lbSymbol: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    func configure(account: AccountInfo, balance: Currency) {
        lbAvailable.text = LocalizedString.Wallet.Transfer.available + balance.symbol
        lbAccount.text = account.account
        lbBalance.text = balance.balance
        lbSymbol.text = balance.symbol
    }
    
}

class SendInputFormCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet fileprivate weak var lbSendTo: UILabel!
    @IBOutlet fileprivate weak var btnPaste: UIButton!
    @IBOutlet fileprivate weak var btnQRCode: UIButton!
    @IBOutlet fileprivate weak var txtAcount: UITextField!
    @IBOutlet fileprivate weak var lbMemo: UILabel!
    @IBOutlet fileprivate weak var lbMemoDesc: UILabel!
    @IBOutlet fileprivate weak var txtMemo: UITextField!
    @IBOutlet fileprivate weak var lbQuantity: UILabel!
    @IBOutlet fileprivate weak var txtQuantity: UITextField!
    @IBOutlet fileprivate weak var lbSymbol: UILabel!
    
    var bag: DisposeBag? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lbSendTo.text = LocalizedString.Wallet.Transfer.sendTo
        lbMemo.text = LocalizedString.Wallet.Transfer.memo
        lbMemoDesc.text = LocalizedString.Wallet.Transfer.memoDesc
        lbQuantity.text = LocalizedString.Wallet.Transfer.quantity
        
        
        txtAcount.delegate = self
        txtMemo.placeholder = LocalizedString.Wallet.Transfer.memo
        txtMemo.delegate = self
        txtQuantity.delegate = self
        txtQuantity.addDoneButtonToKeyboard(myAction: #selector(self.txtQuantity.resignFirstResponder))
        btnPaste.setTitle(LocalizedString.Common.paste, for: .normal)
        
        clearForm()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = nil
    }
    
    fileprivate func configure(form: SendForm, symbol: String) {
        let placeHolder = String(format: LocalizedString.Wallet.Transfer.accountPlaceholder, symbol)
        txtAcount.placeholder = placeHolder
        lbSymbol.text = symbol
        
        let bag = DisposeBag()
        txtAcount.rx.text
            .subscribe( { (text) in
                if let input = text.element as? String {
                    form.account.value = input
                }
        })
        .disposed(by: bag)
   
        txtMemo.rx.text
            .subscribe( { (text) in
                if let input = text.element as? String {
                    form.memo.value = input
                }
            })
            .disposed(by: bag)
   
        txtQuantity.rx.text
            .subscribe( { (text) in
                if let input = text.element as? String {
                    form.quantity.value = input.plainFormatted
                }
            })
            .disposed(by: bag)
        
        self.bag = bag
    }
    
    fileprivate func clearForm() {
        txtAcount.text = nil
        txtMemo.text = nil
        txtQuantity.text = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txtAcount:
            txtMemo.becomeFirstResponder()
        default:
            break//endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == txtQuantity {
            Log.d(textField.text!)
        }
    }
}

fileprivate struct SendForm {
    let quantity = Variable<String>("")
    let account = Variable<String>("")
    let memo = Variable<String>("")
    
    func quantityCurrency(symbol: String) -> Currency {
        let currency = String(quantity.value) + " " + symbol
        return Currency(currency: currency)!
    }
    
    func clear() {
        quantity.value = ""
        account.value = ""
        memo.value = ""
    }
}


