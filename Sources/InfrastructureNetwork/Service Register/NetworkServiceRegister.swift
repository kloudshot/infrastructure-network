import Foundation
import InfrastructureDependencyContainer

public struct NetworkServiceRegister: ServiceRegister 
{
    public init() 
    {
        
    }
    
    public func register(on container: DependencyContainer) 
    {
        container.register(service: NetworkProvider.self) {
            NetworkProviderImplementation(
                logger: NetworkLoggerImplementation(),
                networkSession: URLSession.shared
            )
        }
    }
}
