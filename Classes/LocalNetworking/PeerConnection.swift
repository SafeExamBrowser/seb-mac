/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implement a connection that supports the custom framing protocol.
*/

import Foundation
import Network

// Create parameters for use in PeerConnection and PeerListener with app services.
func applicationServiceParameters() -> NWParameters {
    let parameters = NWParameters.applicationService

    // Add your custom game protocol to support game messages.
    let gameOptions = NWProtocolFramer.Options(definition: GameProtocol.definition)
    parameters.defaultProtocolStack.applicationProtocols.insert(gameOptions, at: 0)

    return parameters
}

var sharedConnection: PeerConnection?

protocol PeerConnectionDelegate: AnyObject {
	func connectionReady()
	func connectionFailed()
	func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
	func displayAdvertiseError(_ error: NWError)
}

class PeerConnection {

	weak var delegate: PeerConnectionDelegate?
	var connection: NWConnection?
    let endpoint: NWEndpoint?
	let initiatedConnection: Bool

	// Create an outbound connection when the user initiates a game.
	init(endpoint: NWEndpoint, interface: NWInterface?, passcode: String, delegate: PeerConnectionDelegate) {
		self.delegate = delegate
        self.endpoint = nil
		self.initiatedConnection = true

		let connection = NWConnection(to: endpoint, using: NWParameters(passcode: passcode))
		self.connection = connection

		startConnection()
	}
    
    // Create an outbound connection when the user initiates a game via DeviceDiscoveryUI.
    init(endpoint: NWEndpoint, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.endpoint = endpoint
        self.initiatedConnection = true

        // Create the NWConnection to the supplied endpoint.
        let connection = NWConnection(to: endpoint, using: applicationServiceParameters())
        self.connection = connection

        startConnection()
    }

	// Handle an inbound connection when the user receives a game request.
	init(connection: NWConnection, delegate: PeerConnectionDelegate) {
		self.delegate = delegate
        self.endpoint = nil
		self.connection = connection
		self.initiatedConnection = false

		startConnection()
	}

	// Handle the user exiting the game.
	func cancel() {
		if let connection = self.connection {
			connection.cancel()
			self.connection = nil
		}
	}

	// Handle starting the peer-to-peer connection for both inbound and outbound connections.
	func startConnection() {
		guard let connection = connection else {
			return
		}

        connection.stateUpdateHandler = { [weak self] newState in
			switch newState {
			case .ready:
				print("\(connection) established")

                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    print("Connected to", "\(host):\(port)") // Here, I have the host/port information
                }

				// When the connection is ready, start receiving messages.
                self?.receiveNextMessage()

				// Notify the delegate that the connection is ready.
				if let delegate = self?.delegate {
					delegate.connectionReady()
				}
			case .failed(let error):
				print("\(connection) failed with \(error)")

				// Cancel the connection upon a failure.
				connection.cancel()

                if let endpoint = self?.endpoint, let initiated = self?.initiatedConnection,
                   initiated && error == NWError.posix(.ECONNABORTED) {
                    // Reconnect if the user suspends the app on the nearby device.
                    let connection = NWConnection(to: endpoint, using: applicationServiceParameters())
                    self?.connection = connection
                    self?.startConnection()
                } else if let delegate = self?.delegate {
                    // Notify the delegate when the connection fails.
                    delegate.connectionFailed()
                }
            case .preparing:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    print("Connected to", "\(host):\(port)") // Here, I have the host/port information
                }

            default:
				break
			}
		}

		// Start the connection establishment.
		connection.start(queue: .main)
	}

	// Handle sending a "select character" message.
	func selectCharacter(_ character: String) {
		guard let connection = connection else {
			return
		}

		// Create a message object to hold the command type.
		let message = NWProtocolFramer.Message(gameMessageType: .selectedCharacter)
		let context = NWConnection.ContentContext(identifier: "SelectCharacter",
												  metadata: [message])

		// Send the app content along with the message.
		connection.send(content: character.data(using: .utf8), contentContext: context, isComplete: true, completion: .idempotent)
	}

	// Handle sending a "move" message.
	func sendMove(_ move: String) {
		guard let connection = connection else {
			return
		}

		// Create a message object to hold the command type.
		let message = NWProtocolFramer.Message(gameMessageType: .move)
		let context = NWConnection.ContentContext(identifier: "Move",
												  metadata: [message])

		// Send the app content along with the message.
		connection.send(content: move.data(using: .utf8), contentContext: context, isComplete: true, completion: .idempotent)
	}

	// Receive a message, deliver it to your delegate, and continue receiving more messages.
	func receiveNextMessage() {
		guard let connection = connection else {
			return
		}

		connection.receiveMessage { (content, context, isComplete, error) in
			// Extract your message type from the received context.
			if let gameMessage = context?.protocolMetadata(definition: GameProtocol.definition) as? NWProtocolFramer.Message {
				self.delegate?.receivedMessage(content: content, message: gameMessage)
			}
			if error == nil {
				// Continue to receive more messages until you receive an error.
				self.receiveNextMessage()
			}
		}
	}
}
