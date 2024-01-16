import Foundation
import InfrastructureDependencyContainer

public struct NetworkServiceRegister: ServiceRegister 
{
    public init() 
    {
        
    }
    
    public func register(on container: DependencyContainer) 
    {
        container.register {
            NetworkProviderImplementation(
                logger: NetworkLoggerImplementation(),
                networkSession: URLSession.shared
            ) as NetworkProvider
        }
    }
}
