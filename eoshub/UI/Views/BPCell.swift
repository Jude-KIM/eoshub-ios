//
//  BPCell.swift
//  eoshub
//
//  Created by kein on 2018. 7. 10..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import UIKit

class BPCell: UITableViewCell {
    @IBOutlet fileprivate weak var btnSelect: UIButton!
    @IBOutlet fileprivate weak var lbIndex: UILabel!
    @IBOutlet fileprivate weak var lbAccountBP: UILabel!
    @IBOutlet fileprivate weak var btnLink: UIButton!
    @IBOutlet fileprivate weak var lbVotedPercentage: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        btnSelect.isSelected = selected
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(viewModel: BPCellViewModel) {
        setSelected(viewModel.selected, animated: false)
        lbIndex.text = "\(viewModel.index + 1)"
        lbAccountBP.text = viewModel.name
        btnLink.setTitle(viewModel.url, for: .normal)
        lbVotedPercentage.text = String(format: "%.03f %%", viewModel.votesRatio * 100)
        
        if viewModel.index >= 21 {
            backgroundColor = Color.baseGray.uiColor
        } else {
            backgroundColor = Color.white.uiColor
        }
    }
}


protocol BPCellViewModel {
    var index: Int { get }
    var selected: Bool { get set }
    var name: String { get }
    var url: String { get }
    var votesRatio: Double { get set }
    var isActive: Bool { get }
}
