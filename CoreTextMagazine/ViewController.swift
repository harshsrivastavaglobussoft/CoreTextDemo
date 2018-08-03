//
//  ViewController.swift
//  CoreTextMagazine
//
//  Created by Sumit Ghosh on 02/08/18.
//  Copyright © 2018 Sumit Ghosh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard  let file = Bundle.main.path(forResource: "zombies", ofType: "txt") else {
            return
        }
        
        do {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            let parser = MarkupParser()
            parser.parseMarkup(text)
            (view as? CTView)?.buildFrames(withAttrString: parser.attrString, andImages: parser.images)
        } catch _ {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

