//
//  RenewalPredicting.swift
//  Alluvia
//

import Foundation
import CoreML

/// Protocol defining renewal probability prediction capabilities.
protocol RenewalPredicting {
    /// Predicts the probability of renewal using optional feature overrides.
    /// - Parameter overrides: Feature values to override defaults.
    /// - Throws: If prediction fails.
    /// - Returns: Probability value between 0 and 1.
    func predictProbabilityRenewal(overrides: [String: Double]) throws -> Double
    
    /// Names of features expected by the model.
    var featureNames: [String] { get }
    
    /// Identifier for the model version.
    var modelVersion: String { get }
}

/// Errors that can occur during model loading or prediction.
enum RenewalMLError: Error, LocalizedError {
    /// The required features.json file was not found in the app bundle.
    case featuresMissing
    
    /// The model did not produce any valid output.
    case modelOutputMissing
    
    var errorDescription: String? {
        switch self {
        case .featuresMissing: return "features.json missing from bundle."
        case .modelOutputMissing: return "Model output not found."
        }
    }
}

/// Service to run renewal probability predictions using the CoreML model.
final class RenewalMLService: RenewalPredicting {
    /// Shared singleton instance initialized at app launch.
    static let shared = try! RenewalMLService()

    /// The CoreML-generated classifier instance.
    private let classifier: RenewalGBClassifier_Top10 
    
    /// The underlying CoreML model object.
    private let model: MLModel
    
    /// List of feature names that the model expects.
    let featureNames: [String]
    
    /// String identifying the model version.
    let modelVersion: String = "RenewalGBClassifier"

    /// The positive class label as a string, if applicable.
    private let positiveKeyString: String?
    
    /// The positive class label as a number, if applicable.
    private let positiveKeyNumber: NSNumber?

    /// Creates the service, loading the CoreML model and features list.
    /// - Throws: If features.json is missing or model initialization fails.
    init() throws {
        // Load the compiled CoreML model.
        self.classifier = try RenewalGBClassifier_Top10(configuration: .init())
        self.model = classifier.model

        // Load the list of feature names from features.json in the app bundle.
        guard
            let url  = Bundle.main.url(forResource: "features", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let names = try? JSONSerialization.jsonObject(with: data) as? [String]
        else {
            throw RenewalMLError.featuresMissing
        }
        self.featureNames = names

        // Determine the label that represents the "positive" class in the model output.
        let desc = model.modelDescription
        var posStr: String? = nil
        var posNum: NSNumber? = nil

        if let labels = desc.classLabels as? [String] {
            // Prefer "1" or "true" if present, else fallback to last or first label.
            if labels.contains("1") { posStr = "1" }
            else if labels.map({ $0.lowercased() }).contains("true") { posStr = "true" }
            else { posStr = labels.last ?? labels.first }
        } else if let labels = desc.classLabels as? [NSNumber] {
            // Use number 1 if present, else pick the largest numeric label.
            if labels.contains(where: { $0.intValue == 1 }) {
                posNum = 1
            } else {
                posNum = labels.max(by: { $0.doubleValue < $1.doubleValue }) ?? labels.first
            }
        }
        self.positiveKeyString = posStr
        self.positiveKeyNumber = posNum

        // Clear any prior debug output flag to enable one-time output on first prediction.
        UserDefaults.standard.removeObject(forKey: "printedModelOutputs_v3")
    }

    /// Runs prediction using given feature overrides.
    /// - Parameter overrides: Feature values to replace default zeros.
    /// - Throws: On prediction failure.
    /// - Returns: Probability of renewal as a double between 0 and 1.
    func predictProbabilityRenewal(overrides: [String: Double]) throws -> Double {
        // Build the input feature vector with zeros, then apply overrides.
        var dict: [String: MLFeatureValue] =
            Dictionary(uniqueKeysWithValues: featureNames.map { ($0, MLFeatureValue(double: 0)) })
        for (k, v) in overrides { dict[k] = MLFeatureValue(double: v) }

        let provider = try MLDictionaryFeatureProvider(dictionary: dict)
        let out = try model.prediction(from: provider)

        // Debug print the model's raw output once after app launch.
        let debugKey = "printedModelOutputs_v3"
        if UserDefaults.standard.bool(forKey: debugKey) == false {
            print("[CoreML] Output names:", out.featureNames)
            for name in out.featureNames {
                if let fv = out.featureValue(for: name) {
                    print("[CoreML] \(name): type=\(fv.type)")
                    switch fv.type {
                    case .dictionary:
                        let d = fv.dictionaryValue
                        let keys = Array(d.keys)
                        let sample = d.prefix(6).map { "\($0.key)=\($0.value.doubleValue)" }.joined(separator: ", ")
                        print("[CoreML]   dict keys:", keys)
                        print("[CoreML]   sample:", sample)
                    case .multiArray:
                        print("[CoreML]   multiArray shape:", fv.multiArrayValue?.shape ?? [])
                    default:
                        print("[CoreML]   value:", fv)
                    }
                }
            }
            UserDefaults.standard.set(true, forKey: debugKey)
        }

        // Try to extract probability from any dictionary output.
        if let prob = try probabilityFromAnyDictionaryOutput(out) { return prob }

        // Look for common scalar output keys.
        for key in ["probability", "output", "score", "yhat"] {
            if let fv = out.featureValue(for: key), fv.type == .double { return fv.doubleValue }
        }

        // If all else fails, derive probability from the predicted class label.
        if let lbl = out.featureValue(for: "classLabel") {
            if let pos = positiveKeyString, lbl.type == .string { return lbl.stringValue == pos ? 1 : 0 }
            if let pos = positiveKeyNumber, lbl.type == .int64 { return NSNumber(value: lbl.int64Value) == pos ? 1 : 0 }
            return 1.0
        }

        throw RenewalMLError.modelOutputMissing
    }

    // MARK: - Helpers

    /// Extracts a probability score from any dictionary-type output features.
    /// - Parameter out: The full set of model outputs.
    /// - Throws: If an error occurs during extraction.
    /// - Returns: Probability value if found, otherwise nil.
    private func probabilityFromAnyDictionaryOutput(_ out: MLFeatureProvider) throws -> Double? {
        for name in out.featureNames {
            guard let fv = out.featureValue(for: name), fv.type == .dictionary else { continue }
            let d = fv.dictionaryValue  // [AnyHashable : NSNumber]

            // Return probability using the known positive class key.
            if let pos = positiveKeyString, let p = d[pos]?.doubleValue { return p }
            if let pos = positiveKeyNumber, let p = d[pos]?.doubleValue { return p }

            // Check common positive class keys "1" as string or number.
            if let p = d["1"]?.doubleValue ?? d[1]?.doubleValue ?? d[Int64(1)]?.doubleValue { return p }

            // If only probability for class "0" present in binary, invert it.
            if d.count == 2 {
                if let p0 = d["0"]?.doubleValue ?? d[0]?.doubleValue ?? d[Int64(0)]?.doubleValue {
                    return max(0.0, min(1.0, 1.0 - p0))
                }
            }

            // Fallback: return the highest probability value found.
            if let maxVal = d.values.max(by: { $0.doubleValue < $1.doubleValue }) {
                return maxVal.doubleValue
            }
        }
        return nil
    }
}

