//
//  TimeToRenewalPredicting.swift
//  Alluvia
//
//  Provides a regression model to predict months until renewal based on feature inputs.
//

import Foundation
import CoreML

// Predicts months to renewal from feature inputs (overrides take precedence).
protocol TimeToRenewalPredicting {
    func predictMonthsToRenewal(overrides: [String: Double]) throws -> Double
    var modelVersion: String { get }
    var featureNames: [String] { get }
    var defaultValues: [String: Double] { get }
}

// Errors when loading model assets or predictions.
enum TimeToRenewalMLError: Error, LocalizedError {
    case featuresMissing
    case modelOutputMissing
    case defaultsMissing
    
    var errorDescription: String? {
        switch self {
        case .featuresMissing:
            return "features_reg.json missing from bundle."
        case .modelOutputMissing:
            return "Regression model output not found."
        case .defaultsMissing:
            return "feature_defaults_reg.json missing or invalid."
        }
    }
}

// Provides regression predictions for months to renewal.
final class TimeToRenewalMLService: TimeToRenewalPredicting {
    static let shared = try! TimeToRenewalMLService()
    
    private let regressor: RenewalGBRegressor_Top10
    private let model: MLModel
    
    let featureNames: [String]
    let defaultValues: [String: Double]
    let modelVersion: String = "RenewalGBRegressor_Top10"
    
    init() throws {
        // Load Core ML model
        self.regressor = try RenewalGBRegressor_Top10(configuration: .init())
        self.model = regressor.model
        
        // Load feature names from JSON
        guard
            let url = Bundle.main.url(forResource: "features_reg", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let names = try? JSONSerialization.jsonObject(with: data) as? [String]
        else {
            throw TimeToRenewalMLError.featuresMissing
        }
        self.featureNames = names
        
        // Load default feature values from JSON
        guard
            let defURL = Bundle.main.url(forResource: "feature_defaults_reg", withExtension: "json"),
            let defData = try? Data(contentsOf: defURL),
            let defObj = try? JSONSerialization.jsonObject(with: defData) as? [String: Double]
        else {
            throw TimeToRenewalMLError.defaultsMissing
        }
        self.defaultValues = defObj
    }
    
    // Runs regression and returns months to renewal from feature values (overrides take precedence).
    func predictMonthsToRenewal(overrides: [String: Double]) throws -> Double {
        // Merge overrides with defaults in feature order.
        var merged: [String: Double] = [:]
        for name in featureNames {
            let base = defaultValues[name] ?? 0.0
            let overridden = overrides[name] ?? base
            merged[name] = overridden
        }
        
        // Prepare ML input
        let dict: [String: MLFeatureValue] = Dictionary(
            uniqueKeysWithValues: merged.map { key, value in
                (key, MLFeatureValue(double: value))
            }
        )
        
        let provider = try MLDictionaryFeatureProvider(dictionary: dict)
        let out = try model.prediction(from: provider)
        
        // Debug output printed once
        let debugKey = "printedTimeToRenewalOutputs_v1"
        if UserDefaults.standard.bool(forKey: debugKey) == false {
            print("[TimeToRenewal/CoreML] Output names:", out.featureNames)
            for name in out.featureNames {
                if let fv = out.featureValue(for: name) {
                    print("[TimeToRenewal/CoreML] \(name): type=\(fv.type) value=\(fv)")
                }
            }
            UserDefaults.standard.set(true, forKey: debugKey)
        }
        
        // Return first recognized double output
        let likelyKeys = ["months_between_unlocks", "output", "prediction", "target", "yhat"]
        for key in likelyKeys {
            if let fv = out.featureValue(for: key), fv.type == .double {
                return fv.doubleValue
            }
        }
        
        for name in out.featureNames {
            if let fv = out.featureValue(for: name), fv.type == .double {
                return fv.doubleValue
            }
        }
        
        throw TimeToRenewalMLError.modelOutputMissing
    }
}
