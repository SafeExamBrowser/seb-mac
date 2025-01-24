//
//  SEBGCMCryptor.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 22.01.2025.
//

import Foundation
import CryptoKit

public class SEBGCMCryptor {

    @available(macOS 10.15, iOS 13.0, *)
    class func encryptData(data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    @available(macOS 10.15, iOS 13.0, *)
    class func decryptData(ciphertext: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: key)
    }

    @available(macOS 10.15, iOS 13.0, *)
    class func symmetricKey(string: String) -> SymmetricKey? {
        guard let keyData = string.data(using: .utf8) else {
            return nil
        }
        return SymmetricKey(data: keyData)
    }
}

