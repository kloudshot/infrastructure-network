import Foundation
import InfrastructureNetworkAPI

final class NetworkProviderImplementation {
	// MARK: - Properties
	
	private let logger: NetworkLogger?
	private let networkSession: NetworkSession
	
	// MARK: - Initializer
	
	init(
		logger: NetworkLogger? = nil,
		networkSession: NetworkSession
	) {
		self.logger = logger
		self.networkSession = networkSession
	}
}

// MARK: - NetworkProvider

extension NetworkProviderImplementation: NetworkProvider {
    func request<ResponseType: Decodable, EndpointType: Endpoint>(_ endpoint: EndpointType) async throws -> ResponseType {
        do {
            let urlRequest = try prepareUrlRequest(for: endpoint)
            logger?.log(request: urlRequest)
            let (data, urlResponse) = try await networkSession.data(for: urlRequest)
            logger?.log(
                response: urlResponse,
                data: data
            )
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw NetworkProviderError.nonHTTResponse
            }
            
			try handle(statusCode: httpResponse.statusCode, and: data)

            do {
                return try JSONDecoder().decode(
                    ResponseType.self,
                    from: data
                )
            }
            catch {
                logger?.log(error: error)
                throw NetworkProviderError.parsingError
            }
        }
        catch let error as URLError where error.code == .timedOut {
            logger?.log(error: error)
            throw NetworkProviderError.timeout
        }
        catch let error as URLError where error.code == .notConnectedToInternet {
            logger?.log(error: error)
            throw NetworkProviderError.noNetworkConnection
        }
        catch {
            logger?.log(error: error)
            throw error
        }
    }
}

// MARK: - Private Methods

extension NetworkProviderImplementation {
	private func prepareUrlRequest<EndpointType: Endpoint>(for endpoint: EndpointType) throws -> URLRequest {
		let urlString = endpoint.baseURL + endpoint.path

		guard let url = URL(string: urlString) else {
			throw NetworkProviderError.invalidURL
		}

		var urlRequest = URLRequest(url: url)

		endpoint.headers?.forEach { (key, value) in
			urlRequest.addValue(
				value,
				forHTTPHeaderField: key
			)
		}
		
		urlRequest.httpMethod = endpoint.method.rawValue

		switch endpoint.body {
			case .plain:
				break
				
			case let .encodable(parameters):
				urlRequest.httpBody = try JSONEncoder().encode(parameters)
				urlRequest.addValue(
					HTTPHeader.Value.applicationJSON,
					forHTTPHeaderField: HTTPHeader.Key.contentType
				)
			
			case let .queryParameter(parameters):
				guard var urlComponents = URLComponents(string: urlString) else {
					return urlRequest
				}

				urlComponents.queryItems = parameters.map(URLQueryItem.init)
				urlRequest.url = urlComponents.url
		}
		
		return urlRequest
	}
	
	private func handle(statusCode: Int, and data: Data) throws {
		switch statusCode {
			case 404:
				throw NetworkProviderError.notFound
				
			case 403:
				throw NetworkProviderError.unauthorized
				
			case 408:
				throw NetworkProviderError.timeout
				
			case 400...499:
				throw NetworkProviderError.invalidRequest
				
			case 500...599:
				throw NetworkProviderError.serverError
				
			case 200...299:
				guard !data.isEmpty else {
					throw NetworkProviderError.noData
				}
				break
				
			default:
				throw NetworkProviderError.other
		}
	}
}
