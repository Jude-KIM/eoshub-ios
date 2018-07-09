//
//  WalletAddCell.swift
//  eoshub
//
//  Created by kein on 2018. 7. 9..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import UIKit

class WalletAddCell: UITableViewCell {
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private func setupUI() {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}


enum WalletAddCellType: CellType {
    case add
    
    var nibName: String {
        return "WalletAddCell"
    }
}
