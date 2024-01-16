public struct HTTPHeader
{
    private init()
    {
        
    }
    
    public struct Key
    {
        static var contentType = "Content-Type"
        static var authorization = "Authorization"
    }
    
    public struct Value
    {
        static var applicationJSON = "application/json"
    }
}
