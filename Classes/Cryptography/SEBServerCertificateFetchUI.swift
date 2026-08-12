//
//  SEBServerCertificateFetchUI.swift
//  SafeExamBrowser
//
//  SwiftUI sheet for embedding a server's certificate(s) by entering its URL.
//  Fetches the presented chain via SEBServerCertificateFetcher, lets the admin
//  review each certificate (common name, validity, SHA-256 fingerprint, whether
//  the chain is trusted by default) and choose which to embed and as which type
//  (TLS/SSL public-key pin vs. CA trust anchor). Selected certificates are handed
//  back to the (ObjC) PrefsNetworkViewController, which adds them to the existing
//  embedded-certificates settings.
//
//  Config-time only. macOS 12+ (SwiftUI); the caller gates on availability.
//

#if os(macOS)
import AppKit
import SwiftUI

/// A certificate the admin chose to embed, in the shape the settings model expects.
/// `type` matches the certificateTypes enum in Constants.h (SSL = 0, CA = 2).
@objc public class SEBEmbeddableCertificate: NSObject {
    @objc public let certificateDataBase64: String
    @objc public let name: String
    @objc public let type: Int

    init(certificateDataBase64: String, name: String, type: Int) {
        self.certificateDataBase64 = certificateDataBase64
        self.name = name
        self.type = type
        super.init()
    }
}

/// Presents the fetch sheet from an existing AppKit window and returns the chosen
/// certificates via the completion handler ([] when cancelled). @objc so the ObjC
/// preferences controller can drive it.
@available(macOS 12.0, *)
@objc public class SEBServerCertificateFetchPresenter: NSObject {

    private var retainedSelf: SEBServerCertificateFetchPresenter?
    private weak var parentWindow: NSWindow?
    private var sheetWindow: NSWindow?
    private var completion: (([SEBEmbeddableCertificate]) -> Void)?

    @objc public func present(from parentWindow: NSWindow,
                              startURLString: String?,
                              completion: @escaping ([SEBEmbeddableCertificate]) -> Void) {
        self.parentWindow = parentWindow
        self.completion = completion
        self.retainedSelf = self   // keep alive for the sheet's lifetime

        let rootView = ServerCertificateFetchView(
            startURLString: startURLString,
            onEmbed: { [weak self] certificates in self?.finish(with: certificates) },
            onCancel: { [weak self] in self?.finish(with: []) })

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled]
        window.title = NSLocalizedString("Embed Server Certificate", comment: "Title of the fetch-server-certificate sheet window")
        self.sheetWindow = window

        parentWindow.beginSheet(window, completionHandler: nil)
    }

    private func finish(with certificates: [SEBEmbeddableCertificate]) {
        if let sheetWindow = sheetWindow {
            parentWindow?.endSheet(sheetWindow)
        }
        sheetWindow = nil
        completion?(certificates)
        completion = nil
        retainedSelf = nil
    }
}

@available(macOS 12.0, *)
private struct ServerCertificateFetchView: View {

    /// The exam's configured start URL (if any); powers the "Use Start URL" shortcut.
    let startURLString: String?
    let onEmbed: ([SEBEmbeddableCertificate]) -> Void
    let onCancel: () -> Void

    /// Host (or host:port for non-standard ports) extracted from the start URL, or nil.
    private var startURLHostSuggestion: String? {
        guard let startURLString = startURLString, !startURLString.isEmpty,
              let parsed = SEBServerCertificateFetcher.parseHostAndPort(startURLString) else {
            return nil
        }
        return parsed.port == 443 ? parsed.host : "\(parsed.host):\(parsed.port)"
    }

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var trustedByDefault = true
    @State private var items: [ChainItem] = []

    private struct ChainItem: Identifiable {
        let id = UUID()
        let certificate: SEBFetchedCertificate
        var isSelected: Bool
        /// Determined by chain position: the leaf (index 0) is embedded as a TLS/SSL
        /// public-key pin; every issuer above it (intermediate CA) as a CA anchor.
        /// This is the only meaningful mapping — a leaf can't act as a CA anchor, and
        /// pinning an intermediate as TLS/SSL would never match the server leaf's key.
        let isCA: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fetch a certificate presented by an HTTPS server and embed it into the settings. Verify the SHA-256 fingerprint out of band before embedding.",
                 comment: "Explanation at the top of the fetch-server-certificate sheet (Network / Certificates settings)")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TextField("Server URL or host (e.g. exam.example.org)", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(fetch)
                    Button("Fetch", action: fetch)
                        .disabled(isLoading || urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if let suggestion = startURLHostSuggestion {
                    Button {
                        urlString = suggestion
                    } label: {
                        Text("Use Start URL",
                             comment: "Link that fills the URL field with the exam's start URL host")
                            .font(.footnote)
                            .underline()
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Fill in the domain of the exam's start URL (\(suggestion))",
                                 comment: "Tooltip for the Use Start URL link; the argument is the host that will be inserted"))
                }
            }

            if isLoading {
                HStack(spacing: 8) { ProgressView().controlSize(.small); Text("Connecting…", comment: "Shown while connecting to the server to fetch its certificate") }
            }

            if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !items.isEmpty && !trustedByDefault {
                Label {
                    Text("The presented chain does NOT pass normal trust validation. This may indicate interception — only embed if you can verify the fingerprint independently.",
                         comment: "Warning shown when a fetched certificate chain fails normal system trust validation")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .foregroundColor(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }

            if !items.isEmpty {
                Text("Select the certificate(s) to embed and choose their type:",
                     comment: "Heading above the list of fetched certificates")
                    .font(.subheadline)
                List {
                    ForEach($items) { $item in
                        certificateRow($item)
                    }
                }
                .frame(minHeight: 200)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                Button("Embed", action: embed)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!items.contains { $0.isSelected })
            }
        }
        .padding(20)
        .frame(width: 640, height: 480)
    }

    @ViewBuilder
    private func certificateRow(_ item: Binding<ChainItem>) -> some View {
        let certificate = item.wrappedValue.certificate
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: item.isSelected).labelsHidden()
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(certificate.commonName
                         ?? String(localized: "(no common name)",
                                   comment: "Placeholder shown for a certificate without a common name"))
                        .fontWeight(.semibold)
                    if certificate.isSelfSigned {
                        // A self-signed CA is a root; a self-signed leaf is a self-signed server cert.
                        // Use separate Text values so both strings are localized (a ternary of
                        // String literals would collapse to the non-localized verbatim initializer).
                        (item.wrappedValue.isCA
                         ? Text("root", comment: "Badge for a self-signed root CA certificate")
                         : Text("self-signed", comment: "Badge for a self-signed (non-CA) server certificate"))
                            .font(.caption2).padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.2)).cornerRadius(3)
                    }
                }
                Text(verbatim: "SHA-256: \(certificate.sha256Fingerprint)")
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundColor(.secondary)
                validityText(certificate)
            }
            Spacer()
            Label {
                (item.wrappedValue.isCA
                 ? Text("CA anchor", comment: "Certificate embed type: a CA trust anchor")
                 : Text("TLS/SSL pin", comment: "Certificate embed type: a TLS/SSL public-key pin"))
            } icon: {
                Image(systemName: item.wrappedValue.isCA ? "building.columns" : "lock.shield")
            }
            .labelStyle(.titleAndIcon)
            .font(.callout)
            .frame(width: 130, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func validityText(_ certificate: SEBFetchedCertificate) -> some View {
        if let notAfter = certificate.notAfter {
            let expired = notAfter < Date()
            let formatted = DateFormatter.localizedString(from: notAfter, dateStyle: .medium, timeStyle: .none)
            Text(expired
                 ? String(localized: "Expired \(formatted)", comment: "Certificate validity: expired on the given date")
                 : String(localized: "Valid until \(formatted)", comment: "Certificate validity: valid until the given date"))
                .font(.caption)
                .foregroundColor(expired ? .red : .secondary)
        }
    }

    private func fetch() {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        items = []
        isLoading = true
        SEBServerCertificateFetcher.fetchCertificateChain(fromURLString: trimmed, timeout: 15) { chain, trusted, error in
            isLoading = false
            if let error = error {
                errorMessage = Self.message(for: error)
                return
            }
            trustedByDefault = trusted
            let certificates = chain ?? []
            items = certificates.enumerated().map { index, certificate in
                // Leaf (index 0) → TLS/SSL pin; issuers above it → CA anchor.
                // Select the leaf by default.
                ChainItem(certificate: certificate, isSelected: index == 0, isCA: index > 0)
            }
            if items.isEmpty {
                errorMessage = NSLocalizedString("The server did not present any certificates.", comment: "Error when a fetched TLS connection returned no certificates")
            }
        }
    }

    private func embed() {
        // certificateTypes (Constants.h): SSL = 0, CA = 2.
        let selected = items.filter { $0.isSelected }.map { item -> SEBEmbeddableCertificate in
            let name = item.certificate.commonName ?? urlString.trimmingCharacters(in: .whitespaces)
            return SEBEmbeddableCertificate(
                certificateDataBase64: item.certificate.certificateData.base64EncodedString(),
                name: name,
                type: item.isCA ? 2 : 0)
        }
        onEmbed(selected)
    }

    private static func message(for error: Error) -> String {
        if let fetchError = error as? SEBServerCertificateFetchError {
            switch fetchError {
            case .invalidURL:
                return NSLocalizedString("Please enter a valid server URL or host name.", comment: "Error when the entered server URL / host is not valid")
            case .noCertificatesPresented:
                return NSLocalizedString("The server did not present any certificates.", comment: "Error when a fetched TLS connection returned no certificates")
            case .connectionFailed:
                return NSLocalizedString("Could not connect to the server.", comment: "Error when the connection to the entered server failed")
            }
        }
        return error.localizedDescription
    }
}
#endif
