//
//  FirebaseConfig.swift
//  Notea
//
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("GoogleService-Info.plist not found")
            return
        }
        
        guard let options = FirebaseOptions(contentsOfFile: path) else {
            print("Failed to load Firebase options")
            return
        }
        
        FirebaseApp.configure(options: options)
        print("Firebase successfully configured")
    }
}
