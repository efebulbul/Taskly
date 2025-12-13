//
//  LoginViewController+Apple.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit
import AuthenticationServices
import CryptoKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

extension LoginViewController {

    @available(iOS 13.0, *)
    func startSignInWithAppleFlow() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status != errSecSuccess {
                fatalError("Nonce üretilemedi. OSStatus: \(status)")
            }
            for b in bytes where remaining > 0 {
                if b < charset.count {
                    result.append(charset[Int(b)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
