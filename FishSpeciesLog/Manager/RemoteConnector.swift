import Foundation
import AppsFlyerLib

enum RemoteError: Error {
    case malformedURL
    case invalidResponse
    case decodingFailure
    case encodingFailure
}

protocol RemoteConnector {
    func getUniqueDeviceID() -> String
    func fetchOrganicData(linkParams: [String: Any]) async throws -> [String: Any]
    func discoverEndpoint(attributionData: [String: Any]) async throws -> URL
}

final class RemoteConnectorImplementation: RemoteConnector {
    
    private let client: URLSession
    private let flyerSDK: AppsFlyerLib
    
    init(
        client: URLSession = .shared,
        flyerSDK: AppsFlyerLib = .shared()
    ) {
        self.client = client
        self.flyerSDK = flyerSDK
    }
    
    func getUniqueDeviceID() -> String {
        return flyerSDK.getAppsFlyerUID()
    }
    
    func fetchOrganicData(linkParams: [String: Any]) async throws -> [String: Any] {
        let requestURL = try constructAttributionURL()
        let (responseData, httpResponse) = try await client.data(from: requestURL)
        
        try validateHTTP(httpResponse)
        
        let decoded = try decodeJSON(responseData)
        return blend(base: decoded, extra: linkParams)
    }
    
    func discoverEndpoint(attributionData: [String: Any]) async throws -> URL {
        guard let configURL = URL(string: "https://fishspecieslog.com/config.php") else {
            throw RemoteError.malformedURL
        }
        
        let requestData = assembleRequestData(from: attributionData)
        let encodedData = try encodeJSON(requestData)
        let postRequest = craftPOSTRequest(url: configURL, body: encodedData)
        
        let (responseData, _) = try await client.data(for: postRequest)
        return try extractEndpoint(from: responseData)
    }
    
    // MARK: - Private Helpers
    
    private func constructAttributionURL() throws -> URL {
        let builder = URLAssembler()
        
        guard let url = builder
            .withApp(Config.appsFlyerId)
            .withKey(Config.appsFlyerKey)
            .withDevice(getUniqueDeviceID())
            .build() else {
            throw RemoteError.malformedURL
        }
        
        return url
    }
    
    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw RemoteError.invalidResponse
        }
    }
    
    private func decodeJSON(_ data: Data) throws -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RemoteError.decodingFailure
        }
        return json
    }
    
    private func blend(base: [String: Any], extra: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in extra where result[key] == nil {
            result[key] = value
        }
        return result
    }
    
    private func assembleRequestData(from source: [String: Any]) -> [String: Any] {
        var data = source
        let metadata = DeviceMetadata()
        
        data["os"] = "iOS"
        data["af_id"] = getUniqueDeviceID()
        data["bundle_id"] = metadata.bundleIdentifier()
        data["firebase_project_id"] = metadata.firebaseProjectIdentifier()
        data["store_id"] = metadata.storeIdentifier()
        data["push_token"] = metadata.pushToken()
        data["locale"] = metadata.localeIdentifier()
        
        return data
    }
    
    private func encodeJSON(_ payload: [String: Any]) throws -> Data {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
            throw RemoteError.encodingFailure
        }
        return data
    }
    
    private func craftPOSTRequest(url: URL, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 30
        return request
    }
    
    private func extractEndpoint(from data: Data) throws -> URL {
        let json = try decodeJSON(data)
        
        guard let success = json["ok"] as? Bool,
              success,
              let urlString = json["url"] as? String,
              let url = URL(string: urlString) else {
            throw RemoteError.decodingFailure
        }
        
        return url
    }
}

struct URLAssembler {
    
    private var appID: String?
    private var devKey: String?
    private var deviceID: String?
    
    private let baseURL = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    
    func withApp(_ id: String) -> Self {
        var copy = self
        copy.appID = id
        return copy
    }
    
    func withKey(_ key: String) -> Self {
        var copy = self
        copy.devKey = key
        return copy
    }
    
    func withDevice(_ id: String) -> Self {
        var copy = self
        copy.deviceID = id
        return copy
    }
    
    func build() -> URL? {
        guard let appID = appID,
              let devKey = devKey,
              let deviceID = deviceID,
              var components = URLComponents(string: baseURL + "id" + appID) else {
            return nil
        }
        
        components.queryItems = [
            URLQueryItem(name: "devkey", value: devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        return components.url
    }
}
