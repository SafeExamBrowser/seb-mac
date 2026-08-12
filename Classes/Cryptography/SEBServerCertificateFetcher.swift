//
//  SEBServerCertificateFetcher.swift
//  SafeExamBrowser
//
//  Fetches the TLS certificate chain a server presents, so an admin can embed a
//  server's certificate into SEB settings by entering its URL (instead of only
//  picking from the Keychain). Config-time only — this runs in the preferences /
//  Config Tool, never inside a locked-down exam.
//
//  SECURITY: fetching pins whatever the network returns at that moment. The caller
//  MUST show the certificate details / SHA-256 fingerprint and require explicit
//  confirmation before embedding, and should surface `trustedByDefault` so the
//  admin notices if the presented chain does not even pass normal validation
//  (a sign of interception). See the CWE-295 discussion in SEBBrowserController.
//

import Foundation
import Security
import CommonCrypto

/// One certificate from a fetched chain, with the details needed to review and embed it.
@objc public class SEBFetchedCertificate: NSObject {
    /// DER-encoded certificate (what gets base64-encoded into the embedded-certificates settings).
    @objc public let certificateData: Data
    /// Human-readable subject summary (usually the common name), if available.
    @objc public let commonName: String?
    /// Colon-separated uppercase hex SHA-256 of the DER bytes, for out-of-band verification.
    @objc public let sha256Fingerprint: String
    @objc public let notBefore: Date?
    @objc public let notAfter: Date?
    /// True if subject == issuer (a self-signed / likely root or standalone server cert).
    @objc public let isSelfSigned: Bool

    init(certificate: SecCertificate) {
        let der = SecCertificateCopyData(certificate) as Data
        self.certificateData = der
        self.commonName = SecCertificateCopySubjectSummary(certificate) as String?
        self.sha256Fingerprint = SEBServerCertificateFetcher.sha256Hex(of: der)

        let subject = SecCertificateCopyNormalizedSubjectSequence(certificate) as Data?
        let issuer = SecCertificateCopyNormalizedIssuerSequence(certificate) as Data?
        self.isSelfSigned = (subject != nil && subject == issuer)

        let validity = SEBServerCertificateFetcher.validityDates(of: certificate)
        self.notBefore = validity.notBefore
        self.notAfter = validity.notAfter
        super.init()
    }
}

@objc public enum SEBServerCertificateFetchError: Int, Error {
    case invalidURL
    case noCertificatesPresented
    case connectionFailed
}

@objc public class SEBServerCertificateFetcher: NSObject {

    /// Fetches the certificate chain presented by the server addressed by `urlString`.
    ///
    /// `urlString` may be a bare host (`exam.example.org`), `host:port`, or a full URL
    /// (`https://exam.example.org`). The connection is aborted as soon as the server
    /// trust is captured — no application data is exchanged.
    ///
    /// The completion handler is always called on the main queue. On success it returns
    /// the presented chain (leaf first), and `trustedByDefault` = whether that chain
    /// passes normal system trust evaluation for the host. On failure `chain` is nil and
    /// `error` is set.
    @objc public static func fetchCertificateChain(fromURLString urlString: String,
                                                   timeout: TimeInterval,
                                                   completionHandler: @escaping (_ chain: [SEBFetchedCertificate]?,
                                                                                 _ trustedByDefault: Bool,
                                                                                 _ error: Error?) -> Void) {
        guard let (host, port) = parseHostAndPort(urlString),
              var components = URLComponents() as URLComponents?,
              !host.isEmpty else {
            deliver(nil, false, SEBServerCertificateFetchError.invalidURL, completionHandler)
            return
        }
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = "/"
        guard let url = components.url else {
            deliver(nil, false, SEBServerCertificateFetchError.invalidURL, completionHandler)
            return
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        // Don't reuse a pooled connection whose trust we couldn't observe.
        configuration.urlCache = nil

        // The delegate captures the server trust during the TLS handshake, then cancels
        // the challenge so no request body is ever sent. The session retains the delegate;
        // we invalidate it once done to break that retain cycle.
        let delegate = TrustCapturingDelegate(host: host) { chain, trustedByDefault, error in
            deliver(chain, trustedByDefault, error, completionHandler)
        }
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        delegate.session = session
        session.dataTask(with: url).resume()
    }

    // MARK: - Parsing

    /// Returns (host, port) from a bare host, host:port, or full URL. Defaults port to 443.
    static func parseHostAndPort(_ urlString: String) -> (host: String, port: Int)? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: withScheme), let host = components.host, !host.isEmpty else {
            return nil
        }
        return (host, components.port ?? 443)
    }

    // MARK: - Certificate detail helpers

    static func sha256Hex(of data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    static func validityDates(of certificate: SecCertificate) -> (notBefore: Date?, notAfter: Date?) {
        #if os(macOS)
        let keys = [kSecOIDX509V1ValidityNotBefore, kSecOIDX509V1ValidityNotAfter] as CFArray
        guard let values = SecCertificateCopyValues(certificate, keys, nil) as? [CFString: Any] else {
            return (nil, nil)
        }
        func date(for key: CFString) -> Date? {
            guard let entry = values[key] as? [CFString: Any],
                  let seconds = entry[kSecPropertyKeyValue] as? Double else {
                return nil
            }
            // Certificate validity values are CFAbsoluteTime (seconds since 2001-01-01).
            return Date(timeIntervalSinceReferenceDate: seconds)
        }
        return (date(for: kSecOIDX509V1ValidityNotBefore), date(for: kSecOIDX509V1ValidityNotAfter))
        #else
        // SecCertificateCopyValues is macOS-only; validity is best-effort elsewhere.
        return (nil, nil)
        #endif
    }

    // MARK: - Internals

    private static func deliver(_ chain: [SEBFetchedCertificate]?,
                                _ trustedByDefault: Bool,
                                _ error: Error?,
                                _ completionHandler: @escaping ([SEBFetchedCertificate]?, Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            completionHandler(chain, trustedByDefault, error)
        }
    }

    private final class TrustCapturingDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        weak var session: URLSession?
        private let host: String
        private let completion: ([SEBFetchedCertificate]?, Bool, Error?) -> Void
        private var didComplete = false

        init(host: String, completion: @escaping ([SEBFetchedCertificate]?, Bool, Error?) -> Void) {
            self.host = host
            self.completion = completion
        }

        private func finish(_ chain: [SEBFetchedCertificate]?, _ trustedByDefault: Bool, _ error: Error?) {
            if didComplete { return }
            didComplete = true
            completion(chain, trustedByDefault, error)
            session?.finishTasksAndInvalidate()
        }

        func urlSession(_ session: URLSession,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let trust = challenge.protectionSpace.serverTrust else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let trustedByDefault = Self.evaluateDefaultTrust(trust)
            let certificates = Self.certificateChain(from: trust).map { SEBFetchedCertificate(certificate: $0) }

            // We have what we need — abort before any request body is sent.
            completionHandler(.cancelAuthenticationChallenge, nil)

            if certificates.isEmpty {
                finish(nil, false, SEBServerCertificateFetchError.noCertificatesPresented)
            } else {
                finish(certificates, trustedByDefault, nil)
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            // If we cancelled after capturing the trust, we've already finished. Otherwise the
            // connection failed before any server-trust challenge (DNS/TCP/TLS failure).
            if didComplete { return }
            finish(nil, false, error ?? SEBServerCertificateFetchError.connectionFailed)
        }

        private static func evaluateDefaultTrust(_ trust: SecTrust) -> Bool {
            if #available(macOS 10.14, iOS 12.0, *) {
                var cfError: CFError?
                return SecTrustEvaluateWithError(trust, &cfError)
            } else {
                var result = SecTrustResultType.invalid
                let status = SecTrustEvaluate(trust, &result)
                return status == errSecSuccess && (result == .proceed || result == .unspecified)
            }
        }

        private static func certificateChain(from trust: SecTrust) -> [SecCertificate] {
            if #available(macOS 12.0, iOS 15.0, *) {
                return (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
            } else {
                var certificates: [SecCertificate] = []
                let count = SecTrustGetCertificateCount(trust)
                for index in 0..<count {
                    if let certificate = SecTrustGetCertificateAtIndex(trust, index) {
                        certificates.append(certificate)
                    }
                }
                return certificates
            }
        }
    }
}
