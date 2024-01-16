import Foundation

public final class NetworkProviderImplementation: NetworkProvider 
{
    private let logger: NetworkLogger?
    private let networkSession: NetworkSession
    
    public init(
        logger: NetworkLogger? = nil,
        networkSession: NetworkSession
    ) {
        self.logger = logger
        self.networkSession = networkSession
    }
    
    public func request<ResponseType: Decodable, EndpointType: Endpoint>(_ endpoint: EndpointType) async throws -> ResponseType
    {
        do
        {
            let urlRequest = try prepareUrlRequest(for: endpoint)
            logger?.log(request: urlRequest)
            let (data, urlResponse) = try await networkSession.data(for: urlRequest)
            logger?.log(
                response: urlResponse,
                data: data
            )
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else
            {
                throw NetworkError.nonHTTResponse
            }
            
            switch httpResponse.statusCode
            {
                case 404:
                    throw NetworkError.notFound
                    
                case 403:
                    throw NetworkError.unauthorized
                    
                case 408:
                    throw NetworkError.timeout
                    
                case 400...499:
                    throw NetworkError.invalidRequest
                    
                case 500...599:
                    throw NetworkError.serverError
                    
                case 200...299:
                    guard !data.isEmpty else
                    {
                        throw NetworkError.noData
                    }
                    break
                    
                default:
                    throw NetworkError.other
            }
            
            do
            {
                return try JSONDecoder().decode(
                    ResponseType.self,
                    from: data
                )
            }
            catch
            {
                logger?.log(error: error)
                throw NetworkError.parsingError
            }
        }
        catch let error as URLError where error.code == .timedOut
        {
            logger?.log(error: error)
            throw NetworkError.timeout
        }
        catch
        {
            logger?.log(error: error)
            throw error
        }
    }
    
    private func prepareUrlRequest<EndpointType: Endpoint>(for endpoint: EndpointType) throws -> URLRequest
    {
        let urlString = endpoint.baseURL + endpoint.path

        guard let url = URL(string: urlString) else
        {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)

        endpoint.headers?.forEach { (key, value) in
            urlRequest.addValue(
                value,
                forHTTPHeaderField: key
            )
        }
        
        urlRequest.httpMethod = endpoint.method.rawValue

        switch endpoint.body
        {
            case .plain:
                break
                
            case let .encodable(parameters):
                urlRequest.httpBody = try JSONEncoder().encode(parameters)
                urlRequest.addValue(
                    HTTPHeader.Value.applicationJSON,
                    forHTTPHeaderField: HTTPHeader.Key.contentType
                )
            
            case let .queryParameter(parameters):
                guard var urlComponents = URLComponents(string: urlString) else
                {
                    return urlRequest
                }

                let queryItems = parameters.map { (key, value) in
                    let value: String? = if let value {
                        "\(value)"
                    } else {
                        nil
                    }
                    return URLQueryItem(
                        name: key,
                        value: value
                    )
                }
                urlComponents.queryItems = queryItems
                urlRequest.url = urlComponents.url
        }
        
        return urlRequest
    }
}
