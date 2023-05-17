//
//  CIImage-Extensions.swift
//  SwiftUI Core Image
//
//  Created by Dan Wood on 5/9/23.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public extension CIImage {

	// Pretty fast. Subsequent invocations are cached.
	convenience init(_ name: String, bundle: Bundle? = nil) {
#if canImport(UIKit)
		if let uiImage = UIImage(named: name, in: bundle, with: nil) {
			self.init(uiImage: uiImage)
		} else {
			self.init()
		}
#elseif canImport(AppKit)
		let nsImage: NSImage?
		if let bundle {
			nsImage = bundle.image(forResource: name)
		} else {
			nsImage = NSImage(named: name)
		}
		if let nsImage {
			self.init(nsImage: nsImage)
		} else {
			self.init()
		}
#endif
	}

#if canImport(UIKit)
	convenience init(uiImage: UIImage) {
		if let cgImage = uiImage.cgImage {
			self.init(cgImage: cgImage)
		} else {
			self.init()
		}
	}
#elseif canImport(AppKit)
	convenience init(nsImage: NSImage) {
		if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {	// TODO: Maybe consider NSGraphicsContext
			self.init(cgImage: cgImage)
		} else {
			self.init()
		}
	}
#endif

	/// Useful for debugging when chaining multiple CIImage modifiers together.
	func logExtent(file: String = #file, line: Int = #line) -> CIImage {
		NSLog("\(file):\(line) \(self.extent)")
		return self
	}

}

// MARK: USEFUL EXTENSIONS FOR WORKING IN A SWIFTUI-LIKE FASHION

public extension CIImage {

	/// Save the extent and then re-crop to that extent after applying whatever is in the closure
	func recropping(apply: (CIImage) -> CIImage) -> CIImage {
		let savedExtent: CGRect = extent
		let newCIImage = apply(self)
		let cropped = newCIImage.cropped(to: savedExtent)
		return cropped
	}

	/// Apply to whatever is in the closure. Useful if the current image is used as a parameter to a new image process.
	func replacing(apply: (CIImage) -> CIImage) -> CIImage {
		let newCIImage = apply(self)
		return newCIImage
	}

	/// Resize an image down so it fully fills the container, cropping in the center as needed.
	@available(macOS 10.15, *)
	func scaledToFill(_ size: CGSize?) -> CIImage {
		guard let size else { return self }
		let currentSize = extent.size
		let largerRatio: CGFloat = max(size.width / currentSize.width, size.height / currentSize.height)
		let newSize: CGSize = CGSize(width: currentSize.width * largerRatio, height: currentSize.height * largerRatio)
		// Scale to the larger of two ratios so it fills
		let scaled = self.lanczosScaleTransform(scale: Float(largerRatio))
		let clamped = scaled.clampedToExtent()
		let cropped = clamped.cropped(to: CGRect(x: (newSize.width - size.width) / 2,
												 y: (newSize.height - size.height) / 2,
												 width: size.width, height: size.height))
		return cropped
	}

	/// Resize an image down so it fully fits in container, centered as needed. No cropping.
	@available(macOS 10.15, *)
	func scaledToFit(_ size: CGSize?) -> CIImage {
		guard let size else { return self }
		let currentSize = extent.size
		let smallerRatio: CGFloat = min(size.width / currentSize.width, size.height / currentSize.height)
		let newSize: CGSize = CGSize(width: currentSize.width * smallerRatio, height: currentSize.height * smallerRatio)
		// Scale to the smaller of two ratios so it fits
		let scaled = self.lanczosScaleTransform(scale: Float(smallerRatio))
		let clamped = scaled.clampedToExtent()
		let cropped = clamped.cropped(to: CGRect(origin: .zero, size: newSize))
		return cropped
	}

	/// convenience, to be similar to SwiftUI view offset
	func offset(by offset: CGSize) -> CIImage {
		guard offset != .zero else { return self }
		return self.transformed(by: CGAffineTransform(translationX: offset.width, y: offset.height))
	}

}

// MARK: OVERLOADS OF EXISTING CIIMAGE OPERATIONS SO WE CAN PASS IN 'ACTIVE' BOOLEAN TO BE ABLE TO HAVE INERT MODIFIER

public extension CIImage {

	// Don't overload these; already a way to pass in arguments to get an inert modifier
	//open func transformed(by matrix: CGAffineTransform) -> CIImage // pass in CGAffineTransform.identity
	//open func transformed(by matrix: CGAffineTransform, highQualityDownsample: Bool) -> CIImage // pass in CGAffineTransform.identity
	//open func composited(over dest: CIImage) -> CIImage // pass in empty image
	//open func cropped(to rect: CGRect) -> CIImage // Pass in CGRect.infinite
	//open func clamped(to rect: CGRect) -> CIImage // Pass in CGRect.infinite
	//open func settingProperties(_ properties: [AnyHashable : Any]) -> CIImage // Pass in empty to add no properties

	// Maybe not worth dealing with.
	//open func oriented(forExifOrientation orientation: Int32) -> CIImage
	//open func oriented(_ orientation: CGImagePropertyOrientation) -> CIImage
	//open func matchedToWorkingSpace(from colorSpace: CGColorSpace) -> CIImage?
	//open func matchedFromWorkingSpace(to colorSpace: CGColorSpace) -> CIImage?
	//open func insertingIntermediate() -> CIImage
	//open func insertingIntermediate(cache: Bool) -> CIImage
	//open func convertingWorkingSpaceToLab() -> CIImage
	//open func convertingLabToWorkingSpace() -> CIImage

	// Doesn't really apply since the whole point is to have image modifiers for all the filters.
	//open func applyingFilter(_ filterName: String, parameters params: [String : Any]) -> CIImage
	//open func applyingFilter(_ filterName: String) -> CIImage

	// Don't implement because we have an equivalent operation already. Sigma is just the pixel radius.
	//open func applyingGaussianBlur(sigma: Double) -> CIImage

	// OK these get an active overload.

	/* Return a new infinite image by replicating the edge pixels of the receiver image. */
	@available(macOS 10.10, *)
	func clampedToExtent(active: Bool = true) -> CIImage {
		guard active else { return self }
		return clampedToExtent()
	}

	/* Return a new image by multiplying the receiver's RGB values by its alpha. */
	@available(macOS 10.12, *)
	func premultiplyingAlpha(active: Bool = true) -> CIImage {
		guard active else { return self }
		return premultiplyingAlpha()
	}

	/* Return a new image by dividing the receiver's RGB values by its alpha. */
	@available(macOS 10.12, *)
	func unpremultiplyingAlpha(active: Bool = true) -> CIImage {
		guard active else { return self }
		return unpremultiplyingAlpha()
	}

	/* Return a new image with alpha set to 1 within the rectangle and 0 outside. */
	@available(macOS 10.12, *)
	func settingAlphaOne(in extent: CGRect, active: Bool = true) -> CIImage {
		guard active else { return self }
		return settingAlphaOne(in: extent)
	}

	/* Returns a new image by changing the receiver's sample mode to bilinear interpolation. */
	@available(macOS 10.13, *)
	func samplingLinear(active: Bool = true) -> CIImage {
		guard active else { return self }
		return samplingLinear()
	}

	/* Returns a new image by changing the receiver's sample mode to nearest neighbor. */
	@available(macOS 10.13, *)
	func samplingNearest(active: Bool = true) -> CIImage {	// equivalent to CISampleNearest filter
		guard active else { return self }
		return samplingNearest()
	}
}

