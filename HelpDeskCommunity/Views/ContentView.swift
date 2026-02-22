//
//  ContentView.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        ZStack {
            if authViewModel.showNDA {
                NDAView()
            } else if authViewModel.showEmailVerification {
                EmailVerificationView()
            } else if authViewModel.isSignedIn {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            locationService.requestLocationPermission()
        }
    }
}
