/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Set up parameters for secure peer-to-peer connections and listeners.
*/

import Network
import CryptoKit

extension NWParameters {

	// Create parameters for use in PeerConnection and PeerListener.
	convenience init(passcode: String) {
		// Customize TCP options to enable keepalives.
		let tcpOptions = NWProtocolTCP.Options()
		tcpOptions.enableKeepalive = true
		tcpOptions.keepaliveIdle = 2

		// Create parameters with custom TLS and TCP options.
		self.init(tls: NWParameters.tlsOptions(passcode: passcode), tcp: tcpOptions)

		// Enable using a peer-to-peer link.
		self.includePeerToPeer = true

		// Add your custom game protocol to support game messages.
		let gameOptions = NWProtocolFramer.Options(definition: GameProtocol.definition)
		self.defaultProtocolStack.applicationProtocols.insert(gameOptions, at: 0)
	}

	// Create TLS options using a passcode to derive a preshared key.
	private static func tlsOptions(passcode: String) -> NWProtocolTLS.Options {
		let tlsOptions = NWProtocolTLS.Options()

		let authenticationKey = SymmetricKey(data: passcode.data(using: .utf8)!)
		let authenticationCode = HMAC<SHA256>.authenticationCode(for: "SEBServerLight".data(using: .utf8)!, using: authenticationKey)

		let authenticationDispatchData = authenticationCode.withUnsafeBytes {
			DispatchData(bytes: $0)
		}

		sec_protocol_options_add_pre_shared_key(tlsOptions.securityProtocolOptions,
												authenticationDispatchData as __DispatchData,
												stringToDispatchData("SEBServerLight")! as __DispatchData)
		sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
													tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
		return tlsOptions
	}

	// Create a utility function to encode strings as preshared key data.
	private static func stringToDispatchData(_ string: String) -> DispatchData? {
		guard let stringData = string.data(using: .utf8) else {
			return nil
		}
		let dispatchData = stringData.withUnsafeBytes {
			DispatchData(bytes: $0)
		}
		return dispatchData
	}
}
