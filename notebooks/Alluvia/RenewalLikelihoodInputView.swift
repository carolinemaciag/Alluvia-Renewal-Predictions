//
//  ModelSelectionView.swift
//  Alluvia
//
// Renewal likelihood input screen where the user toggles flags and enters a value, then taps Predict.

import SwiftUI
import UIKit
import CoreML

// Main input screen for renewal likelihood prediction
struct RenewalLikelihoodInputView: View {
    @Environment(\.dismiss) private var dismiss

    //These are the flags the are the top 10 most influential variables
    @State private var expense_created_flag: Bool = false
    @State private var support_message_thread_flag: Bool = false
    @State private var up_for_first_renewal: Bool = false
    @State private var benefit_guide_views_flag: Bool = false
    @State private var first_unlock_journey_PREGNANT: Bool = false
    @State private var provider_finder_flag: Bool = false
    @State private var logins_flag: Bool = false
    @State private var first_unlock_journey_TRY_PREGNANT: Bool = false
    @State private var pregnancy_article_views_flag: Bool = false
    @State private var trunc_current_lifetime_benefit_maximum: String = ""
    @State private var probability: Double?
    @State private var errorText: String?
    @State private var showToast = false

    // This si the actual input slection part
    var body: some View {
        NavigationStack {
            // Another zstack for input selection buttons
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.9), Color(white: 0.12, opacity: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.overlay)
                .ignoresSafeArea()
                
                // Since all of the selections cant easily fit on a page, its scrollable
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Renewal Likelihood Prediction Flags")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("Set flags and values to generate a renewal likelihood predcition probability.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // These are all of the buttons
                        VStack(spacing: 16) {
                            Group {
                                ToggleRow(isOn: $expense_created_flag, label: "Expense Was Created")
                                ToggleRow(isOn: $support_message_thread_flag, label: "Support Message Thread Accessed")
                                ToggleRow(isOn: $up_for_first_renewal, label: "User Up for First Renewal")
                                ToggleRow(isOn: $benefit_guide_views_flag, label: "Benefit Guide Viewed")
                                ToggleRow(isOn: $first_unlock_journey_PREGNANT, label: "First Unlock Journey: Category Pregnant")
                                ToggleRow(isOn: $provider_finder_flag, label: "Provider Finder Accessed")
                                ToggleRow(isOn: $logins_flag, label: "User Logged in At Least Once")
                                ToggleRow(isOn: $first_unlock_journey_TRY_PREGNANT, label: "First Unlock Journey: Category Try for Pregnancy")
                                ToggleRow(isOn: $pregnancy_article_views_flag, label: "Pregnancy Article Viewed")
                            }
                            // This is the keyboard input for lifetime benefit maximum
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Lifetime Benefit Maximum")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                HStack(spacing: 10) {
                                    Image(systemName: "dollarsign")
                                        .foregroundStyle(Color.orange)

                                    NumberTextField(text: $trunc_current_lifetime_benefit_maximum, placeholder: "Enter amount in $") { }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(height: 20)
                                        .padding(.vertical, 6)

                                    Button { dismissKeyboard() } label: {
                                        Image(systemName: "keyboard.chevron.compact.down")
                                            .imageScale(.large)
                                            .foregroundStyle(Color.orange)
                                    }
                                }
                                .padding(14)
                                .background(Color(white: 0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(white: 0.12))
                                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
                        )

                        Spacer(minLength: 0)

                        // This sets the default values for when the page is accessed for the first time
                        Button {
                            errorText = nil
                            let overrides: [String: Double] = [
                                "expense_created_flag": expense_created_flag ? 1 : 0,
                                "support_message_thread_flag": support_message_thread_flag ? 1 : 0,
                                "up_for_first_renewal": up_for_first_renewal ? 1 : 0,
                                "benefit_guide_views_flag": benefit_guide_views_flag ? 1 : 0,
                                "first_unlock_journey_PREGNANT": first_unlock_journey_PREGNANT ? 1 : 0,
                                "provider_finder_flag": provider_finder_flag ? 1 : 0,
                                "logins_flag": logins_flag ? 1 : 0,
                                "first_unlock_journey_TRY_PREGNANT": first_unlock_journey_TRY_PREGNANT ? 1 : 0,
                                "trunc_current_lifetime_benefit_maximum": Double(trunc_current_lifetime_benefit_maximum) ?? 0,
                                "pregnancy_article_views_flag": pregnancy_article_views_flag ? 1 : 0,
                            ]
                            Task {
                                do {
                                    let p = try RenewalMLService.shared.predictProbabilityRenewal(overrides: overrides)
                                    await MainActor.run {
                                        probability = p
                                        withAnimation(.spring()) { showToast = true }
                                    }
                                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                                    await MainActor.run { withAnimation(.easeOut) { showToast = false } }
                                } catch {
                                    await MainActor.run { errorText = error.localizedDescription }
                                }
                            }
                        } label: {
                            Text("Predict Renewal Probability")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.orange)
                                )
                        }

                        Button { dismiss() } label: {
                            Text("Back")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color(white: 0.18))
                                )
                        }

                        // Error display for debugging
                        if let e = errorText {
                            Text("Error: \(e)").foregroundColor(.red)
                        }
                    }
                    .padding()
                }

                // Show result as a popup
                if showToast, let p = probability {
                    let pct = p * 100.0
                    ToastView(text: String(format: "Probability of renewal: %.1f%%", pct))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }

            }
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
            .navigationTitle("Prediction Input")
            .navigationBarTitleDisplayMode(.inline)
            // More model error handeling
            .onAppear {
                let hasModel = Bundle.main.url(forResource: "RenewalGBClassifier_Top10", withExtension: "mlmodelc") != nil
                let hasFeatures = Bundle.main.url(forResource: "features", withExtension: "json") != nil
                if !hasModel {
                    print("[Info] Compiled Core ML model not found at launch; ensure the .mlmodel is added to the app target.")
                }
                if !hasFeatures {
                    errorText = "features.json not found in bundle."
                }
            }

        }
    }

    // Dismiss the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Sets the Checkmarks
fileprivate struct ToastView: View {
    let text: String
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .imageScale(.large)
                Text(text).font(.headline)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(.ultraThinMaterial.opacity(0.9))
            .clipShape(Capsule())
            .shadow(radius: 8)
            Spacer().frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}
fileprivate struct ToggleRow: View {
    @Binding var isOn: Bool
    let label: String

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(Color.orange)
                    .imageScale(.large)
                    .accessibilityHidden(true)
                Text(label)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(Color(white: 0.18))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(isOn ? "On" : "Off"))
        .accessibilityAddTraits(.isButton)
    }
}

// Numeric text field for SwiftUI
// This allows the user to open up the keyboard for a text input
// It is complex to add a done button
struct NumberTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String?
    var onCommit: (() -> Void)? = nil

    // Handles text field events
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumberTextField
        init(_ parent: NumberTextField) { self.parent = parent }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            if string.isEmpty { return true }
            return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
        func textFieldDidChangeSelection(_ textField: UITextField) { parent.text = textField.text ?? "" }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
        func textFieldDidEndEditing(_ textField: UITextField) { parent.onCommit?() }
        @objc func doneTapped(_ sender: UIBarButtonItem) { sender.target = nil }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.keyboardType = .numberPad
        tf.delegate = context.coordinator
        tf.text = text
        tf.textColor = .white
        tf.tintColor = .orange
        tf.backgroundColor = .clear
        tf.borderStyle = .none

        if let placeholder = placeholder {
            tf.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.35)]
            )
        }

        let toolbar = UIToolbar()
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // This add the done button
        let done = UIBarButtonItem(title: "Done", style: .plain, target: tf, action: #selector(UIResponder.resignFirstResponder))
        toolbar.tintColor = .systemOrange
        toolbar.items = [flex, done]
        tf.inputAccessoryView = toolbar
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
}

#Preview { RenewalLikelihoodInputView() }
