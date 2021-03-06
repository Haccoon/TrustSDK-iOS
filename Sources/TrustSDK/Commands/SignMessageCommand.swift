// Copyright © 2018 Trust.
//
// This file is part of TrustSDK. The full TrustSDK copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Result
import TrustCore

public class SignMessageCommand: Command {
    public var name = "sign-message"

    /// Message data
    public var message: Data

    /// Optional address to use
    public var address: Address?

    /// Callback scheme
    public var callbackScheme: String

    /// Completion closure
    public var completion: (Result<Data, WalletSDKError>) -> Void

    public var callback: URL {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = name
        return components.url!
    }

    public init(message: Data, address: Address? = nil, callbackScheme: String, completion: @escaping (Result<Data, WalletSDKError>) -> Void) {
        self.message = message
        self.address = address
        self.callbackScheme = callbackScheme
        self.completion = completion
    }

    public func requestURL(scheme: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = name
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "message", value: message.base64EncodedString()))
        if let address = address {
            queryItems.append(URLQueryItem(name: "address", value: address.description))
        }
        queryItems.append(URLQueryItem(name: "callback", value: callback.absoluteString))
        components.queryItems = queryItems
        return components.url!
    }

    public  func handleCallback(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), components.host == name else {
            return false
        }
        if let value = components.queryItems?.first(where: { $0.name == "error" })?.value,
            let errorCode = Int(value),
            let error = WalletSDKError(rawValue: errorCode) {
            completion(.failure(error))
            return true
        }

        guard let result = components.queryItems?.first(where: { $0.name == "result" })?.value else {
            return false
        }
        guard let data = Data(base64Encoded: result) else {
            return false
        }
        completion(.success(data))
        return true
    }
}

public extension TrustSDK {
    public func signMessage(_ message: Data, address: Address? = nil, completion: @escaping (Result<Data, WalletSDKError>) -> Void) {
        guard WalletAppManager.hasWalletApp else {
            return fallbackToInstall()
        }
        let command = SignMessageCommand(message: message, address: address, callbackScheme: callbackScheme, completion: completion)
        execute(command: command)
    }
}
