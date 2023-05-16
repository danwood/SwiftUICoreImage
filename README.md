# SwiftUICoreImage

Help for using Core Image within the context of SwiftUI. Also useful even without SwiftUI.

## Introduction

Core Image is a wonderful image-processsing toolkit in macOS and iOS, but it's a bit clunky to use. Even after Apple added Swift APIs to many of the filters (CoreImage.CIFilterBuiltins), it's still pretty tedious to chain filters to images.

The purpose of this package is to provide an easier way to chain multiple filters to CIImage instances and then render them into SwiftUI (or any other context — SwiftUI is not needed).

```Swift
	Image(ciImage: CIImage("Bernie.jpeg")
		.sepiaTone(intensity: sepia)
		.recropping { image in
			image
				.clampedToExtent(active: clamped)
				.gaussianBlur(radius: gaussianBlurRadius)
		}
	)
		.resizable()
		.aspectRatio(contentMode: .fit)
```

## Manifest

Included in this package is:

 * CIImage+Generated.swift
	* 208 modifiers on `CIImage` that return a new modified `CIImage` (or the original if unmodified)
	* 20 static functions that return a newly generated `CIImage`
* CIImage-Extensions.swift
	* Convenience initializers for `CIImage` from a resource name and from an `NSImage`/`UIImage`
	* Modifiers for `CIImage` to return cropped, scaled, etc. to be easier to work with SwiftUI
	* Overloads of several built-in `CIImage` modifier functions that take an `active` boolean parameter
* Image-Extensions.swift
	* Convenience initializer to create a SwiftUI `Image` from a `CIImage`

## How This Works

Similarly to how SwiftUI view modifiers each return a modified `View` instance, these modifiers on `CIImage` take care of the core image chaining by creating a corresponding `CIFilter`, hooking up the `inputImage` for you, and returning the resulting `outputImage`. 

When creating SwiftUI code, I think it's important that you can use [Inert Modifiers](https://developer.apple.com/videos/play/wwdc2021/10022/?time=2303) in which you pass in some parameter that causes the modifier to have no effect. (For instance, specifying opacity of 1.0 or padding of 0.0 to a view.)  

In this code, I've made sure that each of our image modifiers come with inert modifiers: in some cases it's passing in a parameter that clearly has no effect (e.g. zero intensity, zero radius); or it's a nil background image when combining with another image; or a boolean `active` parameter. If the parameter(s) specified would cause no change in the image, then the identity (self) is returned forthwith.

The contents of CIImage+Generated.swift are, not surprisingly, generated source code, using code that I've included in this repository (but won't be included in the package import). This loops through the core image metadata that Apple provides (`CIFilter.filterNames(inCategories: nil)`). Unfortunately this list is somewhat out of date and contains a number of inconsistencies that I've done by best to overcome.  There are some JSON files that provide additional metadata such as a list of the functions that actually do have online documentation — 56 functions aren't documented so some guesswork is needed — or repairs to missing or obsolete documentation. You probably won't need to run this code unless you have some special requirements or the list has been updated in a future (post-Ventura, post iOS-16) OS release.

## Using

