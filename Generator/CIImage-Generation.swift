//
//  CIImage-Generation.swift
//  SwiftUI Core Image
//
//  Created by Dan Wood on 4/27/23.
//
// When executed, this outputs Swift code that can be pasted into the file "CIImage+Generated.swift".
//
// This will run under iOS or macOS and the resulting code is almost the same. Notably in affineClamp and affineTile the default values are not
// the same. Also as noted in the documentation that we generate, the `cubeDimension` parameter has a different range between iOS and macOS.

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

#if canImport(UIKit)
private typealias AffineTransform = CGAffineTransform
#elseif canImport(AppKit)
private typealias AffineTransform = NSAffineTransform
#endif

private var unknownProperties: [String: [String: String]] = [:]

func dumpFilters() {

	/*

	 New documentation base found at
	 https://developer.apple.com/documentation/coreimage
	 or
	 https://developer.apple.com/documentation/coreimage/cifilter

	 15 categories. Open each in tab. Select all, copy, paste into rich text TextEdit doc. Save as HTML.

	 Copy this source, then in terminal, grep out the lines I want:

	 pbpaste | grep 'class func' | grep 'any CIFilter ' | sort | uniq > ~/Desktop/AllFunctions.html

	 (There are a few duplicated functions; gonna not worry about right now)

	 In BBEdit, remove the stuff before the

	 From that, in BBEdit, grep replace all lines:

	 ^.+<a href="https://developer.apple.com/documentation/coreimage/cifilter/([^"]+)">class func <span class="[^"]+">([^>]+)</span><span class="[^"]+">\(\) -&gt; any CIFilter &amp; ([^>]+)</span></a></span></p>
	 to:

	 "\2": "\1",

	 and then…

	 ^.+<a href="https://developer.apple.com/documentation/coreimage/cifilter/([^"]+)">class func ([^(]+).+? any CIFilter &amp; ([^<]+)<span class="[^"]+"></span></a></span></p>

	 to:

	 "\2": "\1",


	 Save as RawLookup.json to Desktop

	 cat ~/Desktop/RawLookup.json | sort | uniq > ~/Desktop/docLookup.json

	 Now edit to include { and } and remove last comma

	 This file lets us know the documentation URL fragment to append to https://developer.apple.com/documentation/coreimage/cifilter/
	 */

	guard let url = Bundle.main.url(forResource: "docLookup", withExtension: "json"),
		  let data = try? Data(contentsOf: url),
		  let json = try? JSONSerialization.jsonObject(with: data, options: []),
		  let docLookup: [String: String] = json as? [String: String]
	else { print("// 🛑 can't load docLookup.json"); return }

	
	/*
	 Load abstracts for all functions that are documented on the OLD reference page. Still, some of these descriptions are a bit more descriptive than the built-in descriptions.

	 Possible improvement, scrape the same pages that are used above to generate docLookup.json to get the most up-to-date abstracts from the web.

	 Start with
	 https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/

	 auto-expand all symbols

	 get HTML source
	 in BBEdit change all instances (with Grep) of:
	 +href="#//apple_ref/doc/filter/ci/([^"]+)"\n +title="([^"]+)">
	 to:
	 •"\1": "\2",

	 Sort, extract lines starting with •
	 Paste and preserve formatting into abstracts.json; fix the last line.
	 Look for any little tweaks that may be needed.

	 */
	guard let url = Bundle.main.url(forResource: "abstracts", withExtension: "json"),
		  let data = try? Data(contentsOf: url),
		  let json = try? JSONSerialization.jsonObject(with: data, options: []),
		  let abstractLookup: [String: String] = json as? [String: String]
	else { print("// 🛑 can't load abstracts.json"); return }

	/*
	 A dictionary mapping filters (pretty function names) to override iOS versions  when we have noted that the core image functions (or occasionally parameters of them) required newer OSs.

	 Not sure where we got this originally! We may need to update some of these.

	 */
	guard let url = Bundle.main.url(forResource: "FunctionMinima", withExtension: "json"),
		  let data = try? Data(contentsOf: url),
		  let json = try? JSONSerialization.jsonObject(with: data, options: []),
		  let functionMinima: [String: String] = json as? [String: String]
	else { print("// 🛑 can't load FunctionMinima.json"); return }

	/* Generate this list by running the code; it finds inputs missing documentation replacing with "_____TODO_____". Update the MissingParameterDocumentation.json file as this is improved. Documentation can come from whatever sources can be scrapped together; use "_NOTE" key just to notate how we found the information.
	 */
	guard let url = Bundle.main.url(forResource: "MissingParameterDocumentation", withExtension: "json"),
		  let data = try? Data(contentsOf: url),
		  let json = try? JSONSerialization.jsonObject(with: data, options: []),
		  let forUnknownProperties = json as? [String: [String: String]]
	else { print("// 🛑 can't load MissingParameterDocumentation.json"); return }
	unknownProperties = forUnknownProperties

	let ciFilterList = CIFilter.filterNames(inCategories: nil)

	var generators: [String: CIFilter] = [:]
	var imageToImage: [String: CIFilter] = [:]

	for filterName in ciFilterList {

		guard let filter = CIFilter(name: filterName) else { print("// 🛑 can't instantiate \(filterName)"); continue }

		if !filter.inputKeys.contains(kCIInputImageKey) {
			generators[filterName] = filter
		} else if filter.outputKeys.contains(kCIOutputImageKey) {
			imageToImage[filterName] = filter
		} else {
			print("// 🛑 Don't know what to do with \(filterName) - outputKeys = \(filter.outputKeys)")
		}
	}

	print("//")
	print("// Automatically generated by CIImage-Generation.swift - do not edit")
	print("//")
	print("")
	print("import Foundation")
	print("import CoreImage")
	print("import CoreImage.CIFilterBuiltins")
	print("import CoreML")
	print("import AVFoundation")
	print("")
	print("public extension CIImage {")
	print("")
	print("//")
	print("// MARK: IMAGE-TO-IMAGE FILTERS")
	print("//")
	for filterName in imageToImage.keys.sorted() {
		guard let filter: CIFilter = imageToImage[filterName] else { continue }
		outputImageToImage(filter, abstractLookup: abstractLookup, docLookup: docLookup, functionMinima: functionMinima)
	}
	print("")
	print("//")
	print("// MARK: GENERATORS")
	print("//")
	for filterName in generators.keys.sorted() {
		guard let filter: CIFilter = generators[filterName] else { continue }
		outputGeneratorFilter(filter, abstractLookup: abstractLookup, docLookup: docLookup, functionMinima: functionMinima)
	}

	// End of class extension
	print("}")
	print("\n\n\n\n\n\n\n")
}

// Use this to start collecting properties needing some documentation, to then put into MissingParameterDocumentation.json
func dumpUnknownProperties() {
	do {
		let theJSONData = try JSONSerialization.data(
			withJSONObject: unknownProperties,
			options: [.sortedKeys, .prettyPrinted]
		)
		if let theJSONText = String(data: theJSONData,
									encoding: String.Encoding.utf8) {
			print("\n\n\n_________________________\n\nDumped properties missing documentation = \n\n\n\(theJSONText)")
		} else {
			print("Unable to convert data to JSON")
		}
	}
	catch {
		print(error)
	}
}

private func outputGeneratorFilter(_ filter: CIFilter, abstractLookup: [String: String], docLookup: [String: String], functionMinima: [String: String]) {
	let filterName = filter.name

	let filtersThatAlreadyHaveInitializer: [String: String] = ["CIConstantColorGenerator": "init(color: CIColor)"]

	if let existingFunction: String = filtersThatAlreadyHaveInitializer[filterName] {
		print("// ℹ️ \(filterName) already has a CIImage initializer: \(existingFunction)")
		return
	}

	outputDocumentation(filter, isGenerator: true, abstractLookup: abstractLookup, docLookup: docLookup)
	outputOSVersion(filter, functionMinima: functionMinima)
	outputImageFunction(filter, isGenerator: true)
}

private func outputDocumentation(_ filter: CIFilter, isGenerator: Bool, abstractLookup: [String: String], docLookup: [String: String]) {

	let filterName = filter.name
	let description: String? = CIFilter.localizedDescription(forFilterName: filterName)
	let categories: Array<String> = filter.attributes[kCIAttributeFilterCategories] as? Array<String> ?? []
	let filterDisplayName: String = filter.attributes[kCIAttributeFilterDisplayName] as? String ?? ""
	let documentationURL: URL? = filter.attributes[kCIAttributeReferenceDocumentation] as? URL

	// https://developer.apple.com/documentation/xcode/writing-symbol-documentation-in-your-source-files
	print("\n/// \(filterDisplayName)")
	print("///")
	if let description {
		if let abstract = abstractLookup[filterName], !abstract.hasPrefix("Returns "), abstract.count > description.count {
			// Replace description with longer abstract scraped from the website, unless it starts with 'Returns ' since we use that for the output.
			print("/// \(abstract)")
		} else {
			print("/// \(description)")
		}
		print("///")
	}

	// Convert, for example, CIAccordionFoldTransition to accordionFoldTransition
	let functionFilterNameCapitalized = filterName.dropFirst(2)
	var functionFilterName = (functionFilterNameCapitalized.first?.lowercased() ?? "") + functionFilterNameCapitalized.dropFirst()

	let manualNameLookup = ["CICMYKHalftone": "cmykHalftone", "CIPDF417BarcodeGenerator": "pdf417BarcodeGenerator", "CIQRCodeGenerator": "qrCodeGenerator"]
	if let foundManualLookup = manualNameLookup[filterName] {
		functionFilterName = foundManualLookup
	}

	// These are still in beta, so I'm not seeing them on the main category lists. https://developer.apple.com/documentation/coreimage/cifilter
	let manualURLLookup = ["CIAreaBoundsRed": "4401847-areaboundsred",
						   "CIMaximumScaleTransform": "4401870-maximumscaletransform",
						   "CIToneMapHeadroom": "4401878-tonemapheadroom",
						   "CIAreaAlphaWeightedHistogram": "4401846-areaalphaweightedhistogram"
	]

	let newDocURLFragment: String?
	if let manualURLFragment = manualURLLookup[filterName] {
		newDocURLFragment = manualURLFragment
	} else {
		newDocURLFragment = docLookup[functionFilterName]
	}

	if let newDocURLFragment {
		print("/// [Documentation](https://developer.apple.com/documentation/coreimage/cifilter/\(newDocURLFragment))")
	} else {
		let withoutSuffix = functionFilterName.replacingOccurrences(of: "Filter", with: "", options: [.backwards, .anchored])
		if let newDocURLFragment = docLookup[withoutSuffix] {
			print("/// [Documentation](https://developer.apple.com/documentation/coreimage/cifilter/\(newDocURLFragment))")
		} else {
			print("/// ⚠️ No documentation available for \(filterName)")
		}
	}

	if let documentationURL {
		if nil != abstractLookup[filterName] {
			let urlFragment: String
#if canImport(UIKit)
			urlFragment = "http://developer.apple.com/library/ios"
#elseif canImport(AppKit)
			urlFragment = "http://developer.apple.com/library/mac"
#endif

			var urlString: String = documentationURL.absoluteString.replacingOccurrences(of: urlFragment,
																						 with: "https://developer.apple.com/library/archive",
																						 options: .anchored)
			urlString = urlString.replacingOccurrences(of: "https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html", with: "https://t.ly/Gyd6")



			print("/// [Classic Documentation](\(urlString))")
		}

		// Special cases for documentation
		if filterName == "CIDepthBlurEffect" {
			// Some helpful hints since this is otherwise undocumented
			print("/// [WWDC Video](https://devstreaming-cdn.apple.com/videos/wwdc/2017/508wdyl5rm2jy9z8/508/508_hd_image_editing_with_depth.mp4)")
			print("/// [WWDC Slides](https://devstreaming-cdn.apple.com/videos/wwdc/2017/508wdyl5rm2jy9z8/508/508_image_editing_with_depth.pdf)")
		} else if filterName == "CICoreMLModelFilter" {
			print("/// [WWDC Video](https://developer.apple.com/videos/play/wwdc2018-719/?time=2378)")
		}
		print("///")
	}
	if categories.count == 1, let category = categories.first {
		print("/// Category: \(CIFilter.localizedName(forCategory: category))")
		print("///")
	} else if categories.count > 1 {
		let prettyList: String = categories.map { CIFilter.localizedName(forCategory: $0) }.joined(separator: ", ")
		print("/// Categories: \(prettyList)")
		print("///")
	}
	print("///")
	print("/// - Parameters:")

	var adjustedInputKeys = filter.inputKeys.filter { $0 != kCIInputImageKey }
	if !isGenerator && filter.identityInputKeys.isEmpty && !filter.inputKeys.contains("inputBackgroundImage") {
		adjustedInputKeys.append("active")
	}
	for inputKey in adjustedInputKeys {
		guard inputKey != "active" else {
			print("///   - active: should this filter be applied")
			continue
		}
		guard let attributes = filter.attributes[inputKey] as? [String: AnyObject],
			  let attributeClass = attributes[kCIAttributeClass] as? String
		else {
			print("///   - \(inputKey): 🛑 couldn't get input attributes")
			continue
		}

		let displayName: String = attributes[kCIAttributeDisplayName] as? String ?? ""	// space-separated
		let longerInput: String = parameterName(displayName: displayName, filterName: filterName)
		var description:  String = attributes[kCIAttributeDescription] as? String ?? "[unknown]"

		if nil == attributes[kCIAttributeDescription] {
			
			// TEMPORARY CODE TO COLLECT UNKNOWN PROPERTIES
			var foundUnknownPropertiesForFilter: [String: String] = unknownProperties[filterName] ?? [:]
			if nil == foundUnknownPropertiesForFilter[longerInput] {
				foundUnknownPropertiesForFilter[longerInput] = "_____TODO_____"
			}
			unknownProperties[filterName] = foundUnknownPropertiesForFilter
			
			if let missingParameters: [String: String] = unknownProperties[filterName],
			   let replacementDocumentation: String = missingParameters[longerInput] {
				description = replacementDocumentation
			}
		}
		// Remove rounding information since we are passing in integers directly.
		description = description.replacing(" The value will be rounded to the nearest odd integer.", with: "")
		description = description.replacing(" Set to nil for automatic.", with: "")
		// Fix this weird ObjC style documentation
		description = description.replacing("Force a compact style Aztec code to @YES or @NO.",
											with: "A Boolean that specifies whether to force a compact style Aztec code.")
		description = description.replacing("Force compaction style to @YES or @NO.",
											with: "A Boolean value specifying whether to force compaction style.")

		print("///   - \(longerInput): \(description)", terminator: "")

		// For numbers, show the range on the same line
		switch attributeClass {
		case "NSNumber":
			guard attributes[kCIAttributeType] as? String != kCIAttributeTypeBoolean, longerInput != "extrapolate" else { break }
			guard longerInput != "cubeDimension" else {
				// Special case. MacOS and iOS report different values so show that here
				print("(2...64 iOS; 2...128 macOS)", terminator: "")
				break
			}
			let minimumValue: Float? = (attributes[kCIAttributeMin] as? NSNumber)?.floatValue
			let maximumValue: Float? = (attributes[kCIAttributeMax] as? NSNumber)?.floatValue
			// Ignore very large maximum value since it's not practical
			if let minimumValue, let maximumValue, maximumValue < 0x0800_0000_00000_0000 {
				print(" (\(minimumValue.format5)...\(maximumValue.format5))", terminator: "")
			} else if let minimumValue {
				print(" (\(minimumValue.format5)...)", terminator: "")
			} else if let maximumValue, maximumValue < 0x0800_0000_00000_0000 {
				print(" (...\(maximumValue.format5))", terminator: "")
			}

		default:
			break
		}
		print("")	// finish up the line

	}


	if filter.outputKeys.contains(kCIOutputImageKey) {
		if isGenerator {
			if let abstract: String = abstractLookup[filterName],
			   let match = abstract.firstMatch(of: /^Generates*\h/) {
				let abstractWithoutReturnsPrefix = abstract[match.range.upperBound...]
				let sentences = Array(abstractWithoutReturnsPrefix.split(separator: /\./))
				let firstSentence = sentences.first ?? abstractWithoutReturnsPrefix
				print("/// - Returns: \(firstSentence)")
			} else if let description,
			   let match = description.firstMatch(of: /^Generates*\h/) {
				let descriptionWithoutReturnsPrefix = description[match.range.upperBound...]
				let sentences = Array(descriptionWithoutReturnsPrefix.split(separator: /\./))
				let firstSentence = sentences.first ?? descriptionWithoutReturnsPrefix
				print("/// - Returns: \(firstSentence)")
			} else {
				print("/// - Returns: new `CIImage`")
			}
		} else {
			var returnInfo: String
			if var abstract = abstractLookup[filterName], abstract.hasPrefix("Returns ") {
				abstract = String(abstract.dropFirst(8))
				abstract = abstract.replacingOccurrences(of: ".", with: "", options: [.anchored, .backwards])	// remove any ending period
				returnInfo = abstract
			} else {
				returnInfo = "processed new `CIImage`"
			}
			if filter.identityInputKeys.isEmpty && filter.inputKeys.contains("inputBackgroundImage") {
				// Append info about when active is false
				returnInfo += ", or identity if `backgroundImage` is nil"
			} else if filter.identityInputKeys.isEmpty {
					// Append info about when active is false
					returnInfo += ", or identity if `active` is false"
			} else {
				// Append info about identity parameters
				returnInfo += " or identity if parameters result in no operation applied"

				// TODO: colorCrossPolynomial broken
			}
			print("/// - Returns: \(returnInfo)")

		}
	}
}

private func outputOSVersion(_ filter: CIFilter, functionMinima: [String: String]) {

	let filterName = filter.name
	var macOSVersion: String? = filter.attributes[kCIAttributeFilterAvailable_Mac]  as? String
	if nil == Float(macOSVersion ?? "") {
		if filterName == "CIHistogramDisplayFilter" {
			macOSVersion = "10.9"		// repair "10.?" with 10.9 from documentation
		}
	}

	if nil != macOSVersion?.firstMatch(of: /10\.[0-9]+/) && macOSVersion != "10.15" {
		macOSVersion = "10.15"		// For minimum version of SwiftUI and most filter functions
	}

	var iOSVersion: String? = filter.attributes[kCIAttributeFilterAvailable_iOS]  as? String
	if Float(iOSVersion ?? "") ?? 0 < 13 {
		iOSVersion = "13"	// minimum version for SwiftUI and most filter functions
	}

	// Override versions of our functions when we have noted that the core image functions (or occasionally parameters of them) required newer OSs
	if let functionMinimum = functionMinima[filter.name.prettyFunction] {
		macOSVersion = functionMinimum
		if let convertedFromMacVersion = ["11.0": "14", "12.0": "15", "13.0": "16"][functionMinimum] {
			iOSVersion = convertedFromMacVersion
		}
	}

	if let macOSVersion, let iOSVersion {
		print("@available(iOS \(iOSVersion), macOS \(macOSVersion), *)")
	}
}

private func outputImageFunctionHeader(_ filter: CIFilter, isGenerator: Bool) {
	let filterName: String = filter.name
	let filterFunction: String = filterName.prettyFunction

	print("\(isGenerator ? "static " : "")func \(filterFunction)(", terminator: "")

	var inputParams: [String] = filter.inputKeys
		.filter { $0 != kCIInputImageKey }
		.map { inputKey in
			(inputKey, (filter.attributes[inputKey] as? [String: AnyObject] ?? [:])) }	// tuple of the inputKey and its attributes
		.compactMap { (inputKey: String, inputAttributes: [String: AnyObject]) in
			parameterStatement(inputKey: inputKey, inputAttributes: inputAttributes, filterName: filterName)
		}

	if !isGenerator && filter.identityInputKeys.isEmpty && !filter.inputKeys.contains("inputBackgroundImage"),
	   let attributesForActiveParam: [String: AnyObject] = .some([kCIAttributeDisplayName: "Active" as NSString,
																	   kCIAttributeClass: "NSNumber" as NSString,
																		kCIAttributeType: kCIAttributeTypeBoolean  as NSString,
																	 kCIAttributeDefault: true as AnyObject,
																	kCIAttributeIdentity: true as AnyObject]),
		let activeParameterStatement: String = parameterStatement(inputKey: "active", inputAttributes: attributesForActiveParam, filterName: filterName) {
		inputParams.append(activeParameterStatement)
	}
	let inputParamsOnOneLine = inputParams.joined(separator: ", ")
	let forceMultiLines: Bool = inputParamsOnOneLine.contains("//")
	if inputParamsOnOneLine.count + filterFunction.count >= 100 || forceMultiLines {
		print(inputParams.joined(separator: ",\n        "), terminator: forceMultiLines ? "\n" : "")
	} else {
		print(inputParamsOnOneLine, terminator: "")
	}
	print(") -> CIImage {")
}

private func outputImageDictionaryFunction(_ filter: CIFilter, isGenerator: Bool) {

	assert(!isGenerator)		// not supported for generators; none known to be needed
	let filterName: String = filter.name

	outputImageFunctionHeader(filter, isGenerator: isGenerator)

	outputIdentityGuards(filter)

	print("    // Filter not included in CoreImage.CIFilterBuiltins; using dictionary-based method.")
	print("    guard let filter = CIFilter(name: \"\(filter.name)\", parameters: [", terminator: "")
	
	let otherInputSettingStatements: [String] = filter.inputKeys
		.filter { $0 != kCIInputImageKey }
		.map { inputKey in
			(inputKey, (filter.attributes[inputKey] as? [String: AnyObject] ?? [:])) }	// tuple of the inputKey and its attributes
		.compactMap { (inputKey: String, inputAttributes: [String: AnyObject]) in
			guard let displayName: String = inputAttributes[kCIAttributeDisplayName] as? String
			else { return nil }
			let inputName: String = parameterName(displayName: displayName, filterName: filterName)
			return "    \"\(inputKey)\": \(inputName),"
		}

	if !otherInputSettingStatements.isEmpty {
		print("\n")
		print(otherInputSettingStatements.joined(separator: "\n"))
		print("    ", terminator: "")
	} else {
		print(":", terminator: "")
	}

	print("]) else { return self }")
	print("    return filter.outputImage ?? CIImage.empty()")

	print("}")

}

private func outputIdentityGuards(_ filter: CIFilter) {
	let filterName: String = filter.name
	// doesn't make sense to have an identity function for generators
	// Guards for identity/inert values
	let identityComparisons: String

	if filter.identityInputKeys.isEmpty {
		if filter.inputKeys.contains("inputBackgroundImage") {
			identityComparisons = "let backgroundImage"
		} else {
			identityComparisons = "active"
		}
	} else {
		identityComparisons = filter.inputKeys
			.filter { $0 != kCIInputImageKey }
			.map { inputKey in
				(inputKey, (filter.attributes[inputKey] as? [String: AnyObject] ?? [:])) }	// tuple of the inputKey and its attributes
			.compactMap { (inputKey: String, inputAttributes: [String: AnyObject]) in
				guard let displayName: String = inputAttributes[kCIAttributeDisplayName] as? String,
					  let identityValue: Any = inputAttributes[kCIAttributeIdentity]
				else { return nil }

				let attributeType: String? = inputAttributes[kCIAttributeType] as? String
				let inputName: String = parameterName(displayName: displayName, filterName: filterName)
				guard hasReasonableDefaultValue(identityValue, attributeType: attributeType, inputName: inputName)
				else { return nil }

				let identityValueFormatted: String = formatSmart(identityValue, attributeType: attributeType, inputName: inputName, filterName: filterName)
				return "\(inputName) != \(identityValueFormatted)"
			}
			.joined(separator: " || ")
	}
	if !identityComparisons.isEmpty {
		print("    guard \(identityComparisons) else { return self }")
		print("")
	}
}

private func outputImageFunction(_ filter: CIFilter, isGenerator: Bool) {
	let filterName: String = filter.name
	let filterFunction: String = filterName.prettyFunction

	outputImageFunctionHeader(filter, isGenerator: isGenerator)

	if !isGenerator {
		outputIdentityGuards(filter)
	}
	print("    let filter = CIFilter.\(filterFunction)() // \(filterName)")
	if !isGenerator {
		print("    filter.inputImage = self")
	}

	let otherInputSettingStatements: String = filter.inputKeys
		.filter { $0 != kCIInputImageKey }
		.map { inputKey in
			(inputKey, (filter.attributes[inputKey] as? [String: AnyObject] ?? [:])) }	// tuple of the inputKey and its attributes
		.compactMap { (inputKey: String, inputAttributes: [String: AnyObject]) in
			guard let displayName: String = inputAttributes[kCIAttributeDisplayName] as? String
			else { return nil }
			let inputName: String = parameterName(displayName: displayName, filterName: filterName)
			let attributeType: String? = inputAttributes[kCIAttributeType] as? String

			// Special case - barcode generators, for some reason, want all their parameters as Float. Let's upgrade it here to keep the API simple.
			if nil != filterFunction.firstMatch(of: /(?i)codeGenerator$/),
			   let className = inputAttributes[kCIAttributeClass] as? String,
			   let attributeType = inputAttributes[kCIAttributeType] as? String,
			   className == "NSNumber" {
				if attributeType == kCIAttributeTypeBoolean {
					return "    filter.\(inputName) = Float(\(inputName) ? 1 : 0)"
				} else {
					return "    filter.\(inputName) = Float(\(inputName))"
				}
			}

			// Annoying to have these negative cases, but the instances where
			// we need to wrap in a float are much more numerous!
			if !(filterFunction == "kMeans" && inputName == "count"),	// this function's parameter wants an integer so leave alone
			   !(filterFunction == "cannyEdgeDetector" && inputName == "hysteresisPasses"),
			   !(filterFunction == "personSegmentation" && inputName == "qualityLevel"),

				attributeType == kCIAttributeTypeInteger || attributeType == kCIAttributeTypeCount {
				return "    filter.\(inputName) = Float(\(inputName))"	// We pass in Int, but function wants a Float
			}
			// fall through
			return "    filter.\(inputName) = \(inputName)"
		}
		.joined(separator: "\n")

	print(otherInputSettingStatements)
	print("    return filter.outputImage ?? CIImage.empty()")
	print("}")
}

private func outputImageToImage(_ filter: CIFilter, abstractLookup: [String: String], docLookup: [String: String], functionMinima: [String: String]) {

	let filterName = filter.name

	let filtersWithoutSwiftAPI: Set<String> = ["CICameraCalibrationLensCorrection", "CIGuidedFilter"]
	let filtersThatAlreadyHaveImageExtension: [String: String] = ["CIAffineTransform": "transformed(by: CGAffineTransform)",
																  "CICrop": "cropped(to: CGRect)",
																  "CIClamp": "clamped(to: CGRect)",
																  "CISampleNearest": "samplingNearest()",
																  // https://developer.apple.com/documentation/coreimage/ciimage/2867429-samplingnearest
	"CIDepthBlurEffect": "depthBlurEffectFilter(for...)"
																  // https://developer.apple.com/documentation/coreimage/cicontext#4375374
]

	let filtersThatAlreadyHaveImageExtensionDoc: [String: String] = ["CISampleNearest": "https://developer.apple.com/documentation/coreimage/ciimage/2867429-samplingnearest",
																  "CIDepthBlurEffect": "https://developer.apple.com/documentation/coreimage/cicontext#4375374"]

	if let existingFunction: String = filtersThatAlreadyHaveImageExtension[filterName] {
		print("")
		print("// ℹ️ \(filterName) already has a CIImage method: func \(existingFunction) -> CIImage")
		if let existingFunctionURL = filtersThatAlreadyHaveImageExtensionDoc[filterName] {
			print("// \(existingFunctionURL)")
		}
		print("")
		return
	}
	outputDocumentation(filter, isGenerator: false, abstractLookup: abstractLookup, docLookup: docLookup)
	outputOSVersion(filter, functionMinima: functionMinima)

	if filtersWithoutSwiftAPI.contains(filterName) {
		outputImageDictionaryFunction(filter, isGenerator: false)
	} else {
		outputImageFunction(filter, isGenerator: false)
	}
}


// convert long name like "Gray Component Replacement" to input name used in CoreImage.CIFilterBuiltins. And fix a bunch of inconsistencies.
private func parameterName(displayName: String, filterName: String) -> String {
	let words: [String] = displayName.components(separatedBy: " ").map { $0.capitalized }
	let removeSpaces: String = words.joined(separator: "")
	var result: String = removeSpaces.prefix(1).lowercased() + removeSpaces.dropFirst()
	if result == "texture" {
		result = "textureImage"
	} else if result == "b" {
		result = "parameterB"
	} else if result == "c" {
		result = "parameterC"
	} else if result == "means" {
		result = "inputMeans"
	} else if result == "redVector" {
		result = "rVector"
	} else if result == "greenVector" {
		result = "gVector"
	} else if result == "blueVector" {
		result = "bVector"
	} else if result == "alphaVector" {
		result = "aVector"
	} else if result == "maximumStriationRadius" {
		result = "maxStriationRadius"
	} else if result == "color1" {
		result = "color0"
	} else if result == "color2" {
		result = "color1"
	} else if result == "radius1" {
		result = "radius0"
	} else if result == "radius2" {
		result = "radius1"
	} else if result == "image2" && filterName == "CIColorAbsoluteDifference" {	// only substitute for this function
		result = "inputImage2"
	} else if result.hasSuffix(".") {
		result = String(result.dropLast(1))	// to deal with data anomoly where "." is at end of parameter
	}
	return result
}

private func parameterStatement(inputKey: String, inputAttributes: [String: AnyObject], filterName: String) -> String? {

	guard let displayName: String = inputAttributes[kCIAttributeDisplayName] as? String,
		  let attributeClass: String = inputAttributes[kCIAttributeClass] as? String
	else { return nil }

	let inputName: String = parameterName(displayName: displayName, filterName: filterName)
	let attributeType: String? = inputAttributes[kCIAttributeType] as? String
	var convertedClass: String
	switch attributeClass {
	case "NSNumber":

		if attributeType == kCIAttributeTypeBoolean
			|| inputName == "extrapolate" { // Hack - missing info
			convertedClass = "Bool"
		} else if attributeType == kCIAttributeTypeInteger || attributeType == kCIAttributeTypeCount
					|| inputName == "qualityLevel" || inputName == "count" { 	// Hack - missing or misleading info
			convertedClass = "Int"
		} else if [kCIAttributeTypeScalar, kCIAttributeTypeAngle, kCIAttributeTypeDistance, kCIAttributeTypeTime].contains(attributeType)
			|| inputName == "preferredAspectRatio"	// missing info
		{
			convertedClass = "Float"
		} else {
			print("\n// 🛑 unknown number type \(inputName): \(attributeType ?? "")")
			convertedClass = "Float"		// seems to be when no type is specified
		}
	case "CIVector":
		guard filterName != "CITemperatureAndTint" && filterName != "CIDepthBlurEffect" else {	// special case, should remain a CIVector
			convertedClass = "CIVector"
			break
		}
		convertedClass = attributeType == kCIAttributeTypeRectangle
		? "CGRect"
		: attributeType == kCIAttributeTypePosition || attributeType == kCIAttributeTypeOffset
		? "CGPoint"
		: "CIVector"		// CIVector tends to have no attribute type
	case "NSAffineTransform":
		convertedClass = "CGAffineTransform"
	case "NSData":
		convertedClass = "Data"
	case "NSString":
		convertedClass = "String"
	case "NSArray":
		convertedClass = "[Any]"
	case "CGImageMetadataRef":
		convertedClass = "CGImageMetadata"
	case "NSObject":
		if inputName == "colorSpace" {
			convertedClass = "CGColorSpace"
		} else {
			convertedClass = attributeClass		// Unexpected case
			print("\n// 🛑 unknown attributeClass \(attributeClass) with \(inputName), \(attributeType ?? "")")
		}
	case "NSValue":
		if attributeType == kCIAttributeTypeTransform {
			convertedClass = "CGAffineTransform"
		} else {
			convertedClass = attributeClass	// Unexpected case
			print("\n// 🛑 unknown attributeClass \(attributeClass) with \(inputName), \(attributeType ?? "")")
		}
	default:
		// Other cases where the class is the same: CIImage, CIColor, etc.
		convertedClass = attributeClass
	}
	if inputName == "backgroundImage" && convertedClass == "CIImage" {
		convertedClass = "CIImage?"		// make optional, for our special identity handling
	}
	var defaultStatement: String = ""
	if let defaultValue: AnyObject = inputAttributes[kCIAttributeDefault] {

		if hasReasonableDefaultValue(defaultValue, attributeType: attributeType, inputName: inputName) {
			let defaultValueString = formatSmart(defaultValue, attributeType: attributeType, inputName: inputName, filterName: filterName)
			if !defaultValueString.isEmpty {
				defaultStatement = " = \(defaultValueString)"
			}
		}
	}
	return "\(inputName): \(convertedClass)\(defaultStatement)"
}

// Look at value and/or context.
private func hasReasonableDefaultValue(_ value: Any, attributeType: String?, inputName: String) -> Bool {
	if nil != value as? Data {
		return false	// Not feasible to have data anyhow
	} else if let number = value as? NSNumber {
		if attributeType == kCIAttributeTypeDistance {
			return number == 0
		} else if attributeType == kCIAttributeTypeInteger {
			return false
		} else if attributeType == kCIAttributeTypeCount {
			return false
		} else if attributeType == kCIAttributeTypeBoolean {
			return true
		} else if attributeType == kCIAttributeTypeAngle {
			return number.doubleValue <= Double.pi	// avoid those weird angles that don't make any sense
		} else if attributeType == kCIAttributeTypeScalar {
			return true	// not sure
		}
	} else if let defaultVector = value as? CIVector {

		if defaultVector.count > 4 {
			return false
		}
		if attributeType == kCIAttributeTypeRectangle {
			return defaultVector == CIVector(x: 0, y: 0, z: 0, w: 0)	// only keep zero rectangle
		} else if attributeType == kCIAttributeTypePosition3 {
			return false
		} else if attributeType == kCIAttributeTypePosition {
			return defaultVector.x < 50 && defaultVector.y < 50		// seems like 50+ values are arbitrary coordinates
		} else if attributeType == kCIAttributeTypeOffset {
			return defaultVector.x != 0 && defaultVector.y != 0		// any non-zero points seem pretty arbitrary
		}
	} else if let color = value as? CIColor {
		return color == CIColor.black
		|| color == CIColor.white
		|| color == CIColor.clear
	} else if nil != value as? AffineTransform {
		return true
	} else if nil != value as? String {
		return true
	} else if inputName == "colorSpace" {	// it's a CFType so not so easy to compare
		return true
	} else {
		print("\n🛑 \(attributeType ?? "") \(inputName) -> \(value) \((value as? AnyObject)?.className)")
		return true	// not sure yet
	}
	return false
}


private func formatSmart(_ value: Any, attributeType: String?, inputName: String, filterName: String?) -> String {
	var result: String = ""
	if let number = value as? NSNumber {
		if attributeType == kCIAttributeTypeBoolean || inputName == "extrapolate" { // Hack - missing info
			result = number.boolValue.description
		} else {
			result = number.formatSmart
		}
	} else if let defaultVector = value as? CIVector {

		if attributeType == kCIAttributeTypeRectangle {
			result = defaultVector.formatRectSmart
		} else if attributeType == kCIAttributeTypePosition {
			result = defaultVector.formatPointSmart
		} else {
			result = defaultVector.formatVectorSmart
		}
	} else if let color = value as? CIColor {
		result = color.formatSmart
	} else if let string = value as? String {
		result = "\"" + string.replacingOccurrences(of: "\"", with: "\\\"") + "\""
	} else if inputName == "colorSpace" {
		if CFGetTypeID(value as AnyObject) == CGColorSpace.typeID {
			let colorspace: CGColorSpace = value as! CGColorSpace
			if let name: String = colorspace.name as? String {
				var newName = name.replacing(/^kCGColorSpace/, with: "")
				newName = newName.prefix(1).lowercased() + newName.dropFirst()
				result = "CGColorSpace(name: CGColorSpace." + newName + ")!"
			}
		}
	} else if let transform = value as? AffineTransform {
		let transformIdentity: AffineTransform
#if canImport(UIKit)
		transformIdentity = CGAffineTransform.identity
#elseif canImport(AppKit)
		transformIdentity = NSAffineTransform()
#endif

		// Special case these filters to default to identity. Their default values are weird!
		if transform == transformIdentity || filterName == "CIAffineClamp" || filterName == "CIAffineTile" {
			result = "CGAffineTransform.identity"
		} else {
#if canImport(UIKit)
			let t: CGAffineTransform = transform
			result = "CGAffineTransform(a: \(t.a.format5), b: \(t.b.format5), c: \(t.c.format5), d: \(t.d.format5), tx: \(t.tx.format5), ty: \(t.tx.format5))"
#elseif canImport(AppKit)
			let t: NSAffineTransformStruct = transform.transformStruct
			result = "CGAffineTransform(a: \(t.m11.format5), b: \(t.m12.format5), c: \(t.m21.format5), d: \(t.m22.format5), tx: \(t.tX.format5), ty: \(t.tY.format5))"
#endif
		}
	} else {
		print("\n🛑 \(attributeType ?? "") \(inputName) -> \(value) \((value as? AnyObject)?.className)")
		result = String(describing: value)
	}
	return result
}

// https://unicode-org.github.io/icu/userguide/strings/regexp.html

private extension String {
	var prettyFunction: String {
		let result: String = self.replacing(/^CI/, with: "").replacing(/Filter$/, with: "")
		return result.fixingCamelCase
	}

	// AbcDef -> abcDef but ABcdef -> aBcdef, ABCDEF -> abcDef - keep the last
	var fixingCamelCase: String {
		if nil != self.firstMatch(of: /^[A-Z][^A-Z]/)
			|| self.hasPrefix("SRGB")	// special case
		{
				// Just one uppercase characters, so make it lowercase and append the rest
			return self.prefix(1).lowercased() + self.dropFirst()
		} else if let foundUppercaseMatch: Regex<Regex<Substring>.RegexOutput>.Match = self.firstMatch(of: /^[A-Z]{2,}/) {
			// FIXME: Might need some tweaking to deal with complex characters. But since we are just modifying ASCII, this simple case is fine.
			// More than one, so make all but the last character lowercased, so that the last character there stays capitalized.
			let lowercasedPrefix = self[foundUppercaseMatch.range].lowercased()
			let remaining = self.dropFirst(lowercasedPrefix.count)
			if nil != remaining.firstMatch(of: /^[a-z]/) {	// lowercase letter after uppercase, the usual. Keep last uppercase from prefix
				return String(lowercasedPrefix.dropLast()) + self.dropFirst(lowercasedPrefix.count - 1)
			} else {
				// Unusual; characters after uppercase is not a lowercase character, e.g. a number. Keep all the uppercase characters.
				return String(lowercasedPrefix) + self.dropFirst(lowercasedPrefix.count)
			}
		}
		return self

	}
}

// Format numbers with UP TO five decimal places

private extension Float {
	var format5: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
#if canImport(UIKit)
		formatter.numberStyle = .none
#elseif canImport(AppKit)
		formatter.hasThousandSeparators = false
#endif
		formatter.maximumFractionDigits = 5
		let number = NSNumber(value: self)
		return formatter.string(from: number) ?? ""
	}
}
private extension Double {
	var format5: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
#if canImport(UIKit)
		formatter.numberStyle = .none
#elseif canImport(AppKit)
		formatter.hasThousandSeparators = false
#endif
		formatter.maximumFractionDigits = 5
		let number = NSNumber(value: self)
		return formatter.string(from: number) ?? ""
	}
}
private extension CGFloat {
	var format5: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
#if canImport(UIKit)
		formatter.numberStyle = .none
#elseif canImport(AppKit)
		formatter.hasThousandSeparators = false
#endif
		formatter.maximumFractionDigits = 5
		let number = NSNumber(value: self)
		return formatter.string(from: number) ?? ""
	}
}

private extension NSNumber {

	var format5: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
#if canImport(UIKit)
		formatter.numberStyle = .none
#elseif canImport(AppKit)
		formatter.hasThousandSeparators = false
#endif
		formatter.maximumFractionDigits = 5
		return formatter.string(from: self) ?? ""
	}

	var formatSmart: String {
		let result: String
		switch self.doubleValue {
		case Double.pi:
			result = ".pi"
		case Double.pi/2:
			result = ".pi/2"
		case Double.pi * 18:
			result = ".pi*18"	// for vortexDistortion

			// What about triangleKaleidoscope 5.924285296593801
		default:
			result = self.format5
		}
		return result
	}
}
private extension CIVector {
	var formatPointSmart: String {
		if x == 0 && y == 0 {
			return ".zero"
		} else {
			return ".init(x: \(x.format5), y: \(y.format5))"
		}
	}

	// The CGRect structure’s X, Y, height and width values are stored in the vector’s X, Y, Z and W properties.
	var formatRectSmart: String {
		if x == 0 && y == 0 && z == 0 && w == 0 {
			return ".zero"
		} else {
			return ".init(x: \(x.format5), y: \(y.format5), width: \(w.format5), height: \(z.format5))"
		}
	}
	var formatVectorSmart: String {
		switch count {
		case 0:
			return ".init()"
		case 1:
			return ".init(x: \(x.format5))"
		case 2:
			return ".init(x: \(x.format5), y: \(y.format5))"
		case 3:
			return ".init(x: \(x.format5), y: \(y.format5), z: \(z.format5))"
		case 4:
			return ".init(x: \(x.format5), y: \(y.format5), z: \(z.format5), w: \(w.format5))"
		default:
			return "🛑 no vector initializer for count > 4"
		}
	}
}
private extension CIColor {
	var formatSmart: String {

		switch self {
		case CIColor.black:    return "CIColor.black"	// Include "CIColor." so it's compatible with older OS
		case CIColor.white:    return "CIColor.white"
		case CIColor.gray:     return "CIColor.gray"
		case CIColor.red:      return "CIColor.red"
		case CIColor.green:    return "CIColor.green"
		case CIColor.blue:     return "CIColor.blue"
		case CIColor.cyan:     return "CIColor.cyan"
		case CIColor.magenta:  return "CIColor.magenta"
		case CIColor.yellow:   return "CIColor.yellow"
		case CIColor.clear:    return "CIColor.clear"
		default:
			let colorSpaceName: String = colorSpace.name as? String ?? ""	// e.g. kCGColorSpaceDeviceRGB
			let colorSpaceNameSuffix: String = colorSpaceName.replacing(/^kCGColorSpace/, with: "")
			let colorSpaceNameFormatted = "CGColorSpace." +  colorSpaceNameSuffix.prefix(1).lowercased() + colorSpaceNameSuffix.dropFirst()
			let colorSpaceSRGB: String = CGColorSpace.sRGB as String

			// Some issues with kCGColorSpaceDeviceRGB since we would have to create that. Let's just ignore.
			if alpha != 1.0 && colorSpaceName != colorSpaceSRGB
			&& colorSpaceName != "kCGColorSpaceDeviceRGB" {
				return "CIColor(red: \(red), green: \(green), blue: \(blue), alpha: \(alpha), colorSpace: \(colorSpaceNameFormatted))"
			} else if alpha == 1.0 && colorSpaceName != colorSpaceSRGB
						&& colorSpaceName != "kCGColorSpaceDeviceRGB" {
				return "CIColor(red: \(red), green: \(green), blue: \(blue), colorSpace: \(colorSpaceNameFormatted))"
			} else
			if alpha != 1.0 {
				return "CIColor(red: \(red), green: \(green), blue: \(blue), alpha: \(alpha))"
			} else {
				return "CIColor(red: \(red), green: \(green), blue: \(blue))"
			}
		}
	}

}

private extension CIFilter {
	var identityInputKeys: [String] {
		inputKeys
			.filter { $0 != kCIInputImageKey }
			.map { inputKey in
				(inputKey, (attributes[inputKey] as? [String: AnyObject] ?? [:])) }	// tuple of the inputKey and its attributes
			.compactMap { (inputKey: String, inputAttributes: [String: AnyObject]) in
				guard let displayName: String = inputAttributes[kCIAttributeDisplayName] as? String,
					  let identityValue: Any = inputAttributes[kCIAttributeIdentity]
				else { return nil }

				let attributeType: String? = inputAttributes[kCIAttributeType] as? String
				let inputName: String = parameterName(displayName: displayName, filterName: self.name)
				guard hasReasonableDefaultValue(identityValue, attributeType: attributeType, inputName: inputName)
				else { return nil }

				return inputKey
			}
	}
}

