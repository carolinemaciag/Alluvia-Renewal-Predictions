//
//  ModelSelectionView.swift
//  Alluvia
//
// This is the model selection page
// It enables the user to choose between the renewal likelihood model and the time to renewal model

import SwiftUI

struct ModelSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var showRenewalProbability = false
    @State private var showTimeToRenewal = false

    var body: some View {
        ZStack {
            SimpleGradientBackground()
            // This is the z stack for model selction
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Choose a Model")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Which model would you like to evaluate?")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // This is the button that lets you select the renewal probability model
                VStack(spacing: 16) {
                    Button {
                        showRenewalProbability = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Renewal Probability")
                                    .font(.headline)
                                Text("Predict the likelihood that a plan will renew.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                            // Adds the right arrow as a visual
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(white: 0.16))
                        )
                    }
                    
                    // This is the button that lets you select the time to renwal model
                    Button {
                        showTimeToRenewal = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time to Renewal")
                                    .font(.headline)
                                Text("Predict months until the next renewal event.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            // Adds the right arrow as a visual
                            Spacer()
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(white: 0.16))
                        )
                    }
                }
                .foregroundStyle(.white)

                Spacer()
                // Allows the user to escape back to the home screen
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(white: 0.20))
                    )
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        // Present each model screen as a fullscreen page
        .fullScreenCover(isPresented: $showRenewalProbability) {
            RenewalLikelihoodInputView()
        }
        .fullScreenCover(isPresented: $showTimeToRenewal) {
            TimeToRenewalInputView()
        }
    }
}


#Preview {
    ModelSelectionView()
}
