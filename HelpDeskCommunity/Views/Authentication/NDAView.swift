//
//  NDAView.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import SwiftUI

struct NDAView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Non-Disclosure Agreement")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // NDA Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("By using this application, you agree to the following terms:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        NDAItem(text: "You will maintain confidentiality of all information shared within the community.")
                        NDAItem(text: "You will not share, distribute, or misuse any personal or sensitive information.")
                        NDAItem(text: "You will respect the privacy and rights of all community members.")
                        NDAItem(text: "You will use the platform only for its intended purpose of seeking and providing help.")
                        NDAItem(text: "Violation of these terms may result in removal from the community.")
                    }
                    
                    Text("By clicking 'I Accept', you acknowledge that you have read, understood, and agree to be bound by this Non-Disclosure Agreement.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            
            // Accept Button
            Button(action: {
                authViewModel.acceptNDA()
            }) {
                Text("I Accept")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

struct NDAItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            
            Text(text)
                .font(.body)
        }
    }
}
