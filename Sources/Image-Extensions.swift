//
//  Image-Extensions.swift
//  SwiftUI Core Image
//
//  Created by Dan Wood on 5/9/23.
//

import Foundation
import CoreGraphics
import CoreImage
import SwiftUI

public extension Image {
    private static let context = CIContext(options: nil)

	init(ciImage: CIImage) {

#if canImport(UIKit)
		// Note that making a UIImage and then using that to initialize the Image doesn't seem to work, but CGImage is fine.
		if let cgImage = Self.context.createCGImage(ciImage, from: ciImage.extent) {
			self.init(cgImage, scale: 1.0, orientation: .up, label: Text(""))
		} else {
			self.init(systemName: "unknown")
		}
#elseif canImport(AppKit)
		// Looks like the NSCIImageRep is slightly better optimized for repeated runs,
		// I'm guessing that it doesn't actually render the bitmap unless it needs to.
		let rep = NSCIImageRep(ciImage: ciImage)
		guard rep.size.width <= 10000, rep.size.height <= 10000 else {		// simple test to make sure we don't have overflow extent
			self.init(nsImage: NSImage())
			return
		}
		let nsImage = NSImage(size: rep.size)	// size affects aspect ratio but not resolution
		nsImage.addRepresentation(rep)
		self.init(nsImage: nsImage)
#endif
	}
}
