//
//  TimeToRenewalInputView.swift
//  Alluvia
//

import SwiftUI
import UIKit

// Input screen for the "Time to Renewal" regression model.
// Users toggle boolean features and enter numerical values,
// then receive an estimate of months until renewal.
struct TimeToRenewalInputView: View {
    @Environment(\.dismiss) private var dismiss

    // Boolean feature toggles (top-10 predictors)
    @State private var expense_created_flag: Bool = false
    @State private var up_for_first_renewal: Bool = false
    @State private var phone_support_flag: Bool = false
    @State private var first_unlock_journey_TRY_PREGNANT: Bool = false
    @State private var first_unlock_journey_PREGNANT: Bool = false
    @State private var first_unlock_journey_PRESERVATION: Bool = false
    @State private var first_unlock_journey_EXPLORING: Bool = false

    // Numeric feature inputs as strings (parsed to Double)
    @State private var trunc_employee_age: String = ""
    @State private var trunc_current_lifetime_benefit_maximum: String = ""
    @State private var trunc_current_annual_benefit_maximum: String = ""

    // Prediction result and UI state
    @State private var predictedMonths: Double?
    @State private var errorText: String?
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            // Background gradient and scrollable content
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.9), Color(white: 0.12, opacity: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with title and subtitle
                        VStack(spacing: 8) {
                            Text("Time to Renewal")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("Set inputs to estimate the expected months until renewal.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Card with all input controls: toggles & numeric fields
                        VStack(spacing: 16) {
                            // Boolean toggles for key regression features
                            Group {
                                timeToggle(isOn: $expense_created_flag, label: "Expense Was Created")
                                timeToggle(isOn: $up_for_first_renewal, label: "User Up for First Renewal")
                                timeToggle(isOn: $phone_support_flag, label: "Phone Support Accessed")
                                timeToggle(isOn: $first_unlock_journey_TRY_PREGNANT, label: "First Unlock Journey: Category Try for Pregnancy")
                                timeToggle(isOn: $first_unlock_journey_PREGNANT, label: "First Unlock Journey: Category Pregnant")
                                timeToggle(isOn: $first_unlock_journey_PRESERVATION, label: "First Unlock Journey: Category Preservation")
                                timeToggle(isOn: $first_unlock_journey_EXPLORING, label: "First Unlock Journey: Category Exploring")
                            }

                            // Numeric inputs for employee age and benefit amounts
                            VStack(alignment: .leading, spacing: 12) {
                                numericField(
                                    title: "Employee age",
                                    systemImage: "person.fill",
                                    text: $trunc_employee_age,
                                    placeholder: "Enter age in years"
                                )

                                numericField(
                                    title: "Current lifetime benefit maximum",
                                    systemImage: "dollarsign",
                                    text: $trunc_current_lifetime_benefit_maximum,
                                    placeholder: "Enter amount in $"
                                )

                                numericField(
                                    title: "Current annual benefit maximum",
                                    systemImage: "calendar",
                                    text: $trunc_current_annual_benefit_maximum,
                                    placeholder: "Enter amount in $"
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(white: 0.12))
                                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
                        )

                        Spacer(minLength: 0)

                        // Button to trigger the prediction calculation
                        Button {
                            errorText = nil
                            let overrides: [String: Double] = [
                                "expense_created_flag": expense_created_flag ? 1 : 0,
                                "up_for_first_renewal": up_for_first_renewal ? 1 : 0,
                                "trunc_employee_age": Double(trunc_employee_age) ?? 0,
                                "phone_support_flag": phone_support_flag ? 1 : 0,
                                "trunc_current_lifetime_benefit_maximum": Double(trunc_current_lifetime_benefit_maximum) ?? 0,
                                "first_unlock_journey_TRY_PREGNANT": first_unlock_journey_TRY_PREGNANT ? 1 : 0,
                                "first_unlock_journey_PREGNANT": first_unlock_journey_PREGNANT ? 1 : 0,
                                "trunc_current_annual_benefit_maximum": Double(trunc_current_annual_benefit_maximum) ?? 0,
                                "first_unlock_journey_PRESERVATION": first_unlock_journey_PRESERVATION ? 1 : 0,
                                "first_unlock_journey_EXPLORING": first_unlock_journey_EXPLORING ? 1 : 0
                            ]
                            Task {
                                do {
                                    let m = try TimeToRenewalMLService.shared.predictMonthsToRenewal(overrides: overrides)
                                    await MainActor.run {
                                        predictedMonths = m
                                        withAnimation(.spring()) { showToast = true }
                                    }
                                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                                    await MainActor.run { withAnimation(.easeOut) { showToast = false } }
                                } catch {
                                    await MainActor.run { errorText = error.localizedDescription }
                                }
                            }
                        } label: {
                            Text("Predict Months to Renewal")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.orange)
                                )
                        }

                        // Button to go back to previous screen
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

                        // Display error messages if prediction or assets fail
                        if let e = errorText {
                            Text("Error: \(e)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                }

                // Toast overlay with prediction result shown at top
                if showToast, let m = predictedMonths {
                    ToastView(text: String(format: "Expected months to renewal: %.1f", m))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
            .navigationTitle("Time to Renewal")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Verify required model and feature files exist in bundle
                let hasModel = Bundle.main.url(forResource: "RenewalGBRegressor_Top10", withExtension: "mlmodelc") != nil
                let hasFeatures = Bundle.main.url(forResource: "features_reg", withExtension: "json") != nil
                if !hasModel { errorText = "Compiled regression model not found in bundle." }
                else if !hasFeatures { errorText = "features_reg.json not found in bundle." }
            }
        }
    }

    // Custom toggle button styled consistently for boolean features
    private func timeToggle(isOn: Binding<Bool>, label: String) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundStyle(Color.orange)
                    .imageScale(.large)
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
    }

    // Numeric input field with icon, placeholder, and done button
    private func numericField(
        title: String,
        systemImage: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 10) {
                Image(systemImage)
                    .foregroundStyle(Color.orange)

                // UIKit-backed text field for numeric input with done button
                NumberTextField(text: text, placeholder: placeholder) { }
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

    // Dismiss the keyboard when tapping outside or pressing done
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// Floating toast showing prediction result clearly at the top
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

#Preview {
    TimeToRenewalInputView()
}
