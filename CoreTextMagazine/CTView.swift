//
//  CTView.swift
//  CoreTextMagazine
//
//  Created by Sumit Ghosh on 02/08/18.
//  Copyright © 2018 Sumit Ghosh. All rights reserved.
//

import UIKit
import CoreText

//class CTView: UIView {
//
//    var attrString:NSAttributedString!
//
//    func importAttrString(_ attrString: NSAttributedString) -> Void {
//        self.attrString = attrString
//    }
//
//    override func draw(_ rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext() else { return }
//        context.textMatrix = .identity
//        context.translateBy(x: 0, y: bounds.size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//
//        let path = CGMutablePath()
//        path.addRect(bounds)
//
//
//
//        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
//
//        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
//
//        CTFrameDraw(frame, context)
//    }
//}

class CTView: UIScrollView {
    
    var imageIndex:Int!
    
    func buildFrames(withAttrString attrString: NSAttributedString, andImages images: [[String: Any]]) -> Void {
        
        imageIndex = 0
        isPagingEnabled = true
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        
        var pageView = UIView()
        var textPos = 0
        var columnIndex:CGFloat = 0
        var pageIndex:CGFloat = 0
        let settings = CTSettings()
        
        while textPos < attrString.length {
            if columnIndex.truncatingRemainder(dividingBy: settings.columnPerPage) == 0 {
                columnIndex = 0
                pageView = UIView(frame: settings.pageRect.offsetBy(dx: pageIndex * bounds.width, dy: 0))
                addSubview(pageView)
                pageIndex += 1
            }
            
            let columnXOrigin = pageView.frame.size.width / settings.columnPerPage
            let columnOffset = columnIndex * columnXOrigin
            let columnFrame = settings.columnRect.offsetBy(dx: columnOffset, dy: 0)
            
            let path = CGMutablePath()
            path.addRect(CGRect(origin: .zero, size: columnFrame.size))
            let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, nil)
            let column = CTColumnView(frame: columnFrame, ctframe: ctframe)
            if images.count > imageIndex {
                attachImagesWithFrame(images, ctframe: ctframe, margin: settings.margin, columnView: column)
            }
            pageView.addSubview(column)
            
            let frameRange = CTFrameGetVisibleStringRange(ctframe)
            textPos += frameRange.length
            
            columnIndex += 1
        }
        
        contentSize = CGSize(width: CGFloat(pageIndex) * bounds.size.width, height: bounds.size.height)
    }
    
    func attachImagesWithFrame(_ images: [[String: Any]],
                               ctframe: CTFrame,
                               margin: CGFloat,
                               columnView: CTColumnView) {
        
        let lines = CTFrameGetLines(ctframe) as NSArray
        
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
        
        var nextImage = images[imageIndex]
        guard var imgLocation = nextImage["location"] as? Int else {
            return
        }
        
        for lineIndex in 0..<lines.count {
            let line = lines[lineIndex] as! CTLine
            
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
               let imageFilename = nextImage["filename"] as? String,
                let img = UIImage(named: imageFilename){
                for run in glyphRuns {
                    let runRange = CTRunGetStringRange(run)
                    if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
                        continue
                    }
                    var imgBounds: CGRect = .zero
                    var ascent: CGFloat = 0
                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                    imgBounds.size.height = ascent
                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                    imgBounds.origin.x = origins[lineIndex].x + xOffset
                    imgBounds.origin.y = origins[lineIndex].y
                    columnView.images += [(image: img, frame: imgBounds)]
                    imageIndex! += 1
                    if imageIndex < images.count {
                        nextImage = images[imageIndex]
                        imgLocation = (nextImage["location"] as AnyObject).intValue
                    }
                    
                }
            }
            
        }
    }
}
