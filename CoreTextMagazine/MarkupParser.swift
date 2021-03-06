//
//  MarkupParser.swift
//  CoreTextMagazine
//
//  Created by Sumit Ghosh on 02/08/18.
//  Copyright © 2018 Sumit Ghosh. All rights reserved.
//

import UIKit
import CoreText

class MarkupParser: NSObject {
    var color: UIColor = .black
    var fontName: String = "Arial"
    var attrString: NSMutableAttributedString!
    var images: [[String: Any]] = []
    
    override init() {
        super.init()
    }
    
    func parseMarkup(_ markup: String) -> Void {
        attrString = NSMutableAttributedString(string: "")
        
        do {
            let regex = try NSRegularExpression(pattern: "(.*?)(<[^>]+>|\\Z)", options: [.caseInsensitive, .dotMatchesLineSeparators])
            
            let chunks = regex.matches(in: markup, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: markup.characters.count))
            
            let defaultFont:UIFont = .systemFont(ofSize: UIScreen.main.bounds.height / 40)
            
            for chunk in chunks {
                guard let markupRange = markup.range(from: chunk.range) else { continue }
                
                let parts = markup[markupRange].components(separatedBy: "<")
                let font = UIFont(name: fontName, size: UIScreen.main.bounds.size.height / 40) ?? defaultFont
                
                let attrs = [NSAttributedStringKey.foregroundColor: color,
                NSAttributedStringKey.font: font] as [NSAttributedStringKey: Any]
                
                let text = NSMutableAttributedString(string: parts[0], attributes: attrs)
                attrString.append(text)
                
                if parts.count <= 1 {
                    continue
                }
                
                let tag = parts[1]
                
                if tag.hasPrefix("font") {
                    let colorRegex = try NSRegularExpression(pattern: "(?<=color=\")\\w+", options:
                    NSRegularExpression.Options(rawValue: 0))
                    colorRegex.enumerateMatches(in: tag,
                    options: NSRegularExpression.MatchingOptions(rawValue: 0),range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                        if let match = match,
                            let range = tag.range(from: match.range) {
                            let colorSel = NSSelectorFromString(tag[range]+"Color")
                            color = UIColor.perform(colorSel).takeRetainedValue() as? UIColor ?? .black
                        }
                    }
                    
                    let faceRegex = try NSRegularExpression(pattern: "(?<=face=\")[^\"]+",
                                                            options: NSRegularExpression.Options(rawValue: 0))
                    faceRegex.enumerateMatches(in: tag,
                                               options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                               range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                                
                                                if let match = match,
                                                    let range = tag.range(from: match.range) {
                                                    fontName = String(tag[range])
                        }
                    }
                }
                else if tag.hasPrefix("img") {
                    var filename:String = ""
                    let imageRegex = try NSRegularExpression(pattern: "(?<=src=\")[^\"]+",
                                                             options: NSRegularExpression.Options(rawValue: 0))
                    imageRegex.enumerateMatches(in: tag,
                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                                    
                                                    if let match = match,
                                                        let range = tag.range(from: match.range) {
                                                        filename = String(tag[range])
                                                    }
                    }
                    
                    let settings = CTSettings()
                    var width:CGFloat = settings.columnRect.width
                    var height:CGFloat = 0
                    
                    if let image = UIImage(named: filename) {
                        height = width * (image.size.height / image.size.width)
                        
                        if height > settings.columnRect.height - font.lineHeight {
                            height = settings.columnRect.height - font.lineHeight
                            width = height * (image.size.width / image.size.height)
                        }
                    }
                    
                    images += [["width": NSNumber(value: Float(width)),
                                "height": NSNumber(value: Float(height)),
                                "filename":filename,
                                "location":NSNumber(value: attrString.length)]]
                    
                    struct RunStruct {
                        let ascent: CGFloat
                        let descent: CGFloat
                        let width: CGFloat
                    }
                    
                    let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
                    extentBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
                    
                    var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
                    }, getAscent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.ascent
                    }, getDescent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.descent
                    }, getWidth: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.width
                    })
                    
                    let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
                    
                    let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedStringKey):(delegate as Any)]
                    attrString.append(NSAttributedString(string: "", attributes: attrDictionaryDelegate))
                }
            }
        }catch _ {
            
        }
    }
}

// MARK: - String
extension String {
    func range(from range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex,
                                       offsetBy: range.location,
                                       limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }
        
        return from ..< to
    }
}
