//
//  Config.swift
//  eoshub
//
//  Created by kein on 2018. 7. 14..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation

enum ChainMode {
    case mainnet, junglenet, regnet
}

struct Config {
    
    static let mode = ChainMode.junglenet

    
    static var eosInfo: TokenInfo {
        switch mode {
        case .junglenet:
            return TokenInfo(contract: "eosio.token", symbol: "EOS", name: "EOS")
        default:
            preconditionFailure()
        }
    }
    
    static var pandoraInfo: TokenInfo {
        switch mode {
        case .junglenet:
            return TokenInfo(contract: "eoshubtokenz", symbol: "PDR", name: "Pandora")
        default:
            preconditionFailure("Not implemented")
        }
    }
}