//
//  CTSettings.swift
//  CoreTextMagazine
//
//  Created by Sumit Ghosh on 03/08/18.
//  Copyright © 2018 Sumit Ghosh. All rights reserved.
//

import Foundation
import UIKit

class CTSettings {
    
    //MARK: Properties
    let margin:CGFloat = 20
    var columnPerPage:CGFloat!
    var pageRect:CGRect!
    var columnRect:CGRect!
    
    //MARK: Initializers
    init() {
        columnPerPage = UIDevice.current.userInterfaceIdiom == .phone ?1 :2
        
        pageRect = UIScreen.main.bounds.insetBy(dx: margin, dy: margin)
        
        columnRect = CGRect(x: 0, y: 0, width: pageRect.width/columnPerPage, height: pageRect.height).insetBy(dx: margin, dy: margin)
    }
    
}
