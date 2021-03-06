//
//  TokenManager.swift
//  eoshub
//
//  Created by kein on 2018. 7. 14..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Alamofire

class TokenManager {
    static let shared = TokenManager()

    private let bag = DisposeBag()
    
    var knownTokens: Results<TokenInfo> = {
       return DB.shared.getTokens()
    }()
    
    init() {
    
    }
    
    func load() {
        Log.d("Download tokens")
        EOSHubAPI.Token.list
            .responseJSON(method: .get, parameter: nil, encoding: URLEncoding.default)
            .subscribe(onNext: { [weak self] (json) in
                self?.syncTokens(json: json)
                }, onError: { (error) in
                    Log.e(error)
            })
            .disposed(by: bag)
    }
    
    func syncTokens(json: JSON) {
        let data = json.json(for: "resultData")
        guard let list = data?.arrayJson(for: "tokenList") else { return }
        
        let tokens: [TokenInfo] = list.compactMap(TokenInfo.create)
            .filter { (info) -> Bool in
                return info.token.stringValue != "EOS@eosio.token"
            }
        
        DB.shared.addOrUpdateObjects(tokens)
    }

}
