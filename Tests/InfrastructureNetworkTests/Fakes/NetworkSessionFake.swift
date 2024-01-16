@testable import InfrastructureNetwork
import Foundation

final class NetworkSessionFake: NetworkSession
{
    func data(for request: URLRequest) async throws -> (Data, URLResponse) 
    {
        (Data(), URLResponse())
    }
}
