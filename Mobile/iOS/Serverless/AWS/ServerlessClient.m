/*
 Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License").
 You may not use this file except in compliance with the License.
 A copy of the License is located at

 http://aws.amazon.com/apache2.0

 or in the "license" file accompanying this file. This file is distributed
 on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 express or implied. See the License for the specific language governing
 permissions and limitations under the License.
 */
 

#import "ServerlessClient.h"
#import <AWSCore/AWSSignature.h>
#import <AWSCore/AWSSynchronizedMutableDictionary.h>
#import <AWSCognitoIdentityProvider/AWSCognitoIdentityProvider.h>





@implementation SeverlessModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{};
}

@end



@interface AWSAPIGatewayClient()

// Networking
@property (nonatomic, strong) NSURLSession *session;

// For requests
@property (nonatomic, strong) NSURL *baseURL;

// For responses
@property (nonatomic, strong) NSDictionary *HTTPHeaderFields;
@property (nonatomic, assign) NSInteger HTTPStatusCode;

- (AWSTask *)invokeHTTPRequest:(NSString *)HTTPMethod
                     URLString:(NSString *)URLString
                pathParameters:(NSDictionary *)pathParameters
               queryParameters:(NSDictionary *)queryParameters
              headerParameters:(NSDictionary *)headerParameters
                          body:(id)body
                 responseClass:(Class)responseClass;

@end

@interface ServerlessClient()

@property (nonatomic, strong) AWSServiceConfiguration *configuration;

@end

@interface AWSServiceConfiguration()

@property (nonatomic, strong) AWSEndpoint *endpoint;

@end

@implementation ServerlessClient

@synthesize configuration = _configuration;

static AWSSynchronizedMutableDictionary *_serviceClients = nil;
static NSString *url = nil;

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"`- init` is not a valid initializer. Use `+ defaultClient` or `+ clientForKey:` instead."
                                 userInfo:nil];
    return nil;
}

+ (void)setEndPoint:(NSString*)defaultEndpoint
{
    url = defaultEndpoint;
}


+ (instancetype)defaultClient{
    AWSServiceConfiguration *serviceConfiguration = nil;
    if ([AWSServiceManager defaultServiceManager].defaultServiceConfiguration) {
        serviceConfiguration = AWSServiceManager.defaultServiceManager.defaultServiceConfiguration;
    } else {
        serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUnknown
                                                           credentialsProvider:nil];
    }

    static ServerlessClient *_defaultClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultClient = [[ServerlessClient alloc] initWithConfiguration:serviceConfiguration endpoint:url];
    });

    return _defaultClient;
}

+ (void)registerClientWithConfiguration:(AWSServiceConfiguration *)configuration
                                 forKey:(NSString *)key
                               endpoint:(NSString*)endpoint
{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _serviceClients = [AWSSynchronizedMutableDictionary new];
    });
    [_serviceClients setObject:[[ServerlessClient alloc] initWithConfiguration:configuration endpoint:endpoint]
                        forKey:key];
}


- (instancetype)initWithConfiguration:(AWSServiceConfiguration *)configuration
                            endpoint:(NSString*)endpoint
{
    if (self = [super init]) {
        _configuration = [configuration copy];

        NSString *URLString = endpoint;
        if ([URLString hasSuffix:@"/"]) {
            URLString = [URLString substringToIndex:[URLString length] - 1];
        }
        _configuration.endpoint = [[AWSEndpoint alloc] initWithRegion:_configuration.regionType
                                                              service:AWSServiceAPIGateway
                                                                  URL:[NSURL URLWithString:URLString]];

        AWSSignatureV4Signer *signer = [[AWSSignatureV4Signer alloc] initWithCredentialsProvider:_configuration.credentialsProvider endpoint:_configuration.endpoint];

        _configuration.baseURL = _configuration.endpoint.URL;
        _configuration.requestInterceptors = @[[AWSNetworkingRequestInterceptor new], signer];
    }
    
    return self;
}

+ (instancetype)clientForKey:(NSString *)key {
    return [_serviceClients objectForKey:key];
}

+ (void)removeClientForKey:(NSString *)key {
    [_serviceClients removeObjectForKey:key];
}

- (AWSTask *)Get:(NSString *)path
            param:(NSDictionary *)param
      queryParam:(NSDictionary*)queryParam
{
    
    NSDictionary *headerParameters = @{
                                       @"Content-Type": @"application/json",
                                       @"Accept": @"application/json",
                                       };
    
    
    
    NSDictionary *queryParameters = @{};
    
    if(queryParam != nil){
        queryParameters = queryParam;
    }
    
    NSDictionary *pathParameters = @{};
    
    
    SeverlessModel* model = [[SeverlessModel alloc] init];
    model.param = param;
    
    
    return [self invokeHTTPRequest:@"GET"
                         URLString:path
                    pathParameters:pathParameters
                   queryParameters:queryParameters
                  headerParameters:headerParameters
                              body:model
                     responseClass:nil];
}



- (AWSTask *)Post:(NSString *)path
            param:(NSDictionary *)param
       queryParam:(NSDictionary*)queryParam
{
    
    NSDictionary *headerParameters = @{
                                       @"Content-Type": @"application/json",
                                       @"Accept": @"application/json",
                                       };
    
    
    
    NSDictionary *queryParameters = @{};
    
    if(queryParam != nil){
        queryParameters = queryParam;
    }
    
    NSDictionary *pathParameters = @{};
    
    
    SeverlessModel* model = [[SeverlessModel alloc] init];
    model.param = param;
    
    
    return [self invokeHTTPRequest:@"POST"
                           URLString:path
                      pathParameters:pathParameters
                     queryParameters:queryParameters
                    headerParameters:headerParameters
                                body:model
                       responseClass:nil];
  
    
}

- (AWSTask *)onetimeUrl:(NSString *)path
{
    NSDictionary *headerParameters = @{
                                       @"Content-Type": @"application/json",
                                       @"Accept": @"application/json",
                                       };
    
    
    NSDictionary *queryParameters = @{
                                      
                                      
                                      };
    NSDictionary *pathParameters = @{
                                     
                                     };
    
    
    SeverlessModel* model = [[SeverlessModel alloc] init];
    model.param = @{@"url":path};
    
    return [self invokeHTTPRequest:@"POST"
                         URLString:@"/onetime"
                    pathParameters:pathParameters
                   queryParameters:queryParameters
                  headerParameters:headerParameters
                              body:model
                     responseClass:nil];
}

+(NSDictionary *) dictionaryFromQueryString:(NSString*)query
{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSArray *params = [query componentsSeparatedByString:@"?"];
    NSArray *pairs = [params[1] componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}


@end
