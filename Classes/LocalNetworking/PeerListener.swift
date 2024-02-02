/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implement a listener that advertises your game's app service,
        or a TLS listener that advertises your game's Bonjour service.
*/

import Network

var bonjourListener: PeerListener?
var applicationServiceListener: PeerListener?

class PeerListener {
    enum ServiceType {
        case bonjour
        case applicationService
    }

	weak var delegate: PeerConnectionDelegate?
	var listener: NWListener?
	var name: String?
	let passcode: String?
    let type: ServiceType

	// Create a listener with a name to advertise, a passcode for authentication,
	// and a delegate to handle inbound connections.
	init(name: String, passcode: String, delegate: PeerConnectionDelegate) {
        self.type = .bonjour
		self.delegate = delegate
		self.name = name
		self.passcode = passcode
		setupBonjourListener()
	}

    // Create a listener that advertises the game's app service
    // and has a delegate to handle inbound connections.
    init(delegate: PeerConnectionDelegate) {
        self.type = .applicationService
        self.delegate = delegate
        self.name = nil
        self.passcode = nil
        setupApplicationServiceListener()
    }

    func setupApplicationServiceListener() {
        do {
            // Create the listener object.
            let listener = try NWListener(using: applicationServiceParameters())
            self.listener = listener

            // Set the service to advertise.
            listener.service = NWListener.Service(applicationService: "SEBServerLight")

            startListening()
        } catch {
            print("Failed to create application service listener")
            abort()
        }
    }

	// Start listening and advertising.
	func setupBonjourListener() {
		do {
            // When hosting a game via Bonjour, use the passcode and advertise the _sebserverlight._tcp service.
            guard let name = self.name, let passcode = self.passcode else {
                print("Cannot create Bonjour listener without name and passcode")
                return
            }

            // Create the listener object.
            let listener = try NWListener(using: NWParameters(passcode: passcode))
            self.listener = listener

            // Set the service to advertise.
            listener.service = NWListener.Service(name: name, type: "_sebserverlight._tcp")

           startListening()
		} catch {
			print("Failed to create bonjour listener")
			abort()
		}
	}

    func bonjourListenerStateChanged(newState: NWListener.State) {
        switch newState {
        case .ready:
            print("Listener ready on \(String(describing: self.listener?.port))")
        case .failed(let error):
            if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                print("Listener failed with \(error), restarting")
                self.listener?.cancel()
                self.setupBonjourListener()
            } else {
                print("Listener failed with \(error), stopping")
                self.delegate?.displayAdvertiseError(error)
                self.listener?.cancel()
            }
        case .cancelled:
            bonjourListener = nil
        default:
            break
        }
    }
    
    func applicationServiceListenerStateChanged(newState: NWListener.State) {
        switch newState {
        case .ready:
            print("Listener ready for nearby devices")
        case .failed(let error):
            print("Listener failed with \(error), stopping")
            self.delegate?.displayAdvertiseError(error)
            self.listener?.cancel()
        case .cancelled:
            applicationServiceListener = nil
        default:
            break
        }
    }
    
    func listenerStateChanged(newState: NWListener.State) {
        switch self.type {
        case .bonjour:
            bonjourListenerStateChanged(newState: newState)
        case .applicationService:
            applicationServiceListenerStateChanged(newState: newState)
        }
    }

    func startListening() {
        self.listener?.stateUpdateHandler = listenerStateChanged

        // The system calls this when a new connection arrives at the listener.
        // Start the connection to accept it, cancel to reject it.
        self.listener?.newConnectionHandler = { newConnection in
            if let delegate = self.delegate {
                if sharedConnection == nil {
                    // Accept a new connection.
                    sharedConnection = PeerConnection(connection: newConnection, delegate: delegate)
                } else {
                    // If a game is already in progress, reject it.
                    newConnection.cancel()
                }
            }
        }

        // Start listening, and request updates on the main queue.
        self.listener?.start(queue: .main)
    }

    // Stop listening.
    func stopListening() {
        if let listener = listener {
            listener.cancel()
            switch self.type {
            case .bonjour:
                bonjourListener = nil
            case .applicationService:
                applicationServiceListener = nil
            }
        }
    }
    
	// If the user changes their name, update the advertised name.
	func resetName(_ name: String) {
        guard self.type == .bonjour else {
            return
        }

        self.name = name
        if let listener = listener {
            // Reset the service to advertise.
            listener.service = NWListener.Service(name: self.name, type: "_sebserverlight._tcp")
        }
	}
}
