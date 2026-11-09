//
//  SEBBrowserControllerTrustTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge that exposes the server-trust authorization decision
//  (+[SEBBrowserController shouldAuthorizeServerTrust:...]) to the Swift unit test
//  target. Builds a server SecTrust from a leaf certificate (DER) and an SSL policy
//  for the given host — mirroring what URLSession hands to the challenge handler —
//  then runs the production decision against the supplied embedded certificate
//  stores. Regression coverage for the removed authorizedHosts substring bypass
//  (CWE-295). Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation
import Security

@objc public final class SEBBrowserControllerTrustTestSupport: NSObject {

    private static func certificates(fromDER ders: [Data]) -> [SecCertificate] {
        ders.compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
    }

    /// Runs the production server-trust authorization decision for a server that
    /// presents `leafDER`, connecting to `host`:`port`, with the given embedded
    /// certificate stores. Returns whether SEB would authorize the connection.
    ///
    /// The SecTrust is built with an SSL policy bound to `host`, so hostname
    /// mismatch and expiry are enforced by the OS trust evaluation exactly as they
    /// are for a real TLS connection.
    @objc public static func authorizeServerPresentingLeaf(_ leafDER: Data,
                                                           host: String,
                                                           port: Int,
                                                           caCertsDER: [Data],
                                                           tlsCertsDER: [Data],
                                                           debugCertsDER: [Data],
                                                           debugCertNames: [String],
                                                           pinEmbeddedCertificates: Bool) -> Bool {
        guard let leaf = SecCertificateCreateWithData(nil, leafDER as CFData) else {
            return false
        }
        let policy = SecPolicyCreateSSL(true, host as CFString)
        var trust: SecTrust?
        guard SecTrustCreateWithCertificates(leaf as CFTypeRef, policy, &trust) == errSecSuccess,
              let serverTrust = trust else {
            return false
        }
        return SEBBrowserController.shouldAuthorizeServerTrust(serverTrust,
                                                              host: host,
                                                              port: port,
                                                              caCerts: certificates(fromDER: caCertsDER),
                                                              tlsCerts: certificates(fromDER: tlsCertsDER),
                                                              debugCerts: certificates(fromDER: debugCertsDER),
                                                              debugCertNames: debugCertNames,
                                                              pinEmbeddedCertificates: pinEmbeddedCertificates)
    }
}
#endif
