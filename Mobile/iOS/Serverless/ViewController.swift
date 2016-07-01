//
//  ViewController.swift
//  Serverless
//
//  Created by 寺井 大樹 on 2016/05/12.
//  Copyright © 2016年 寺井 大樹. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITextFieldDelegate {

    var pool: AWSCognitoIdentityUserPool?
    
    @IBOutlet weak var signupName: UITextField!
    @IBOutlet weak var signupPassword: UITextField!
    @IBOutlet weak var signupEmail: UITextField!
    
    @IBOutlet weak var verifyName: UITextField!
    @IBOutlet weak var verifyCode: UITextField!
    
    @IBOutlet weak var loginName: UITextField!
    @IBOutlet weak var loginPassword: UITextField!
    
    /////////////////// Config ////////////////////////////////
    // Cognito User Pool
    let ClientId = "<user-pool-client-id>" // Cognito User Pool Client Id
    let ClientSecret = "<user-pool-secret>" // Cognito User Pool Client Secret
    let PoolId = "us-east-1_<user-pool-id>" // Cognito User Pool Id
    // Congnito Identity Pool
    let IdentityId = "us-east-1:<identity-pool-id>" // Cognito Identity Pool Id
    // API Gateway
    let EndPoint = "https://<apigateway-id>.execute-api.us-east-1.amazonaws.com/<stage>"
    let CloudFront = "https://<cloudfront-id>.cloudfront.net"
    let api = "<api path>"
    ///////////////////////////////////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        

        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
            identityPoolId:IdentityId)
        
        let configuration: AWSServiceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        let userPoolConfigration: AWSCognitoIdentityUserPoolConfiguration =
            AWSCognitoIdentityUserPoolConfiguration(clientId: ClientId, clientSecret: ClientSecret, poolId: PoolId)
        
        // 名前をつけておくことで、このプールのインスタンスを取得することができます
        AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithUserPoolConfiguration(userPoolConfigration, forKey: "AmazonCognitoIdentityProvider")
        
        pool = AWSCognitoIdentityUserPool(forKey: "AmazonCognitoIdentityProvider")
        
        

        
        signupName.delegate = self
        signupPassword.delegate = self
        signupEmail.delegate = self
        verifyName.delegate = self
        verifyCode.delegate = self
        loginName.delegate = self
        loginPassword.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
        
        //self.callAPI(ServerlessClient.defaultClient())

    }
    
    

    @IBAction func SignUp(sender: AnyObject) {
        
        // Sign Up
        let email: AWSCognitoIdentityUserAttributeType = AWSCognitoIdentityUserAttributeType()
        email.name = "email"
        email.value = signupEmail.text!
        
        pool!.signUp(self.signupName.text!, password: self.signupPassword.text!, userAttributes: [email], validationData: nil).continueWithBlock({ task in
            if((task.error) != nil) {
                print(task.error?.code)
            } else {
                print(task.result)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.verifyName.text = self.signupName.text
                    
                })
            }
            return nil
        })
        
    }
    
    

    
    @IBAction func Verify(sender: AnyObject) {
        
        let user: AWSCognitoIdentityUser = pool!.getUser(self.verifyName.text!)
        
        // Verify
        user.confirmSignUp(self.verifyCode.text!).continueWithBlock({ task in
            if((task.error) != nil) {
                print(task.error?.code)
            } else {
                print(task.result)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loginName.text = self.verifyName.text
                    self.loginPassword.text = self.signupPassword.text
                })
                
            }
            return nil
        })

    }
    
    
    
    @IBAction func Login(sender: AnyObject) {
        
        
        let user: AWSCognitoIdentityUser = pool!.getUser(self.loginName.text!)
        
        // 未認証（APIコール失敗）
        //self.callAPI(nil)
        

        // ログイン
        user.getSession(self.loginName.text!, password: self.loginPassword.text!, validationData: nil, scopes: nil).continueWithBlock({task in
            if((task.error) != nil) {
                print(task.error)
            } else {
                print(task.result)
                
                let cognitoIdentityPoolId = self.IdentityId
                let ret = task.result as! AWSCognitoIdentityUserSession
                let IdToken : String =  ret.idToken!.tokenString
                
                let userpoolProvider = UserPoolProvider()
                let credentialprovider = "cognito-idp.us-east-1.amazonaws.com/" + self.PoolId
                userpoolProvider.setting(credentialprovider, token: IdToken)
                let credentialsProvider = AWSCognitoCredentialsProvider(
                    regionType: .USEast1,
                    identityPoolId: cognitoIdentityPoolId,
                    identityProviderManager: userpoolProvider
                )
                // credentialのキャッシュ削除
                credentialsProvider.clearKeychain()
                
                
                let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider:credentialsProvider)
                AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
                // credential取得（Authロールにロール切り替えし、API認可）
                credentialsProvider.credentials().continueWithBlock { (task: AWSTask!) -> AnyObject! in
                    
                    if (task.error != nil) {
                        print(task.error)
                        
                    } else {
                        print(task.result)
                        
                        
                        // Cognito identityPoolIdによるAPI認可
                        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
                        ServerlessClient.registerClientWithConfiguration(configuration,forKey: "Auth",endpoint:self.EndPoint)
                        ServerlessClient.registerClientWithConfiguration(configuration,forKey: "CloudFront",endpoint:self.CloudFront)
                        
                        self.callAPI(ServerlessClient(forKey: "CloudFront"),client: ServerlessClient(forKey: "Auth"))

                    }
                    return nil
                }

                

                
            }
            
            return nil
        })
        
    }
    
    func callAPI(onetime:ServerlessClient,client:ServerlessClient){
        
        let path = CloudFront + self.api
        client.onetimeUrl(path).continueWithBlock { (task: AWSTask!) -> AnyObject! in
            
            var url:String
            ///////////////////////API認可されたAPIの呼び出し///////////////////////////
            if (task.error != nil) {
                print(task.error)
                return nil
            } else {
                print(task.result)
                url = (task.result as! NSDictionary)["url"] as! String
            }
            
            // JSON送信データ
            let param = [
                "": ""
            ]
            
            let queryParam = ServerlessClient.dictionaryFromQueryString(url)
            
            
            onetime.Post(self.api,param: param,queryParam:queryParam).continueWithBlock { (task: AWSTask!) -> AnyObject! in
                
                if (task.error != nil) {
                    print(task.error)
                    
                } else {
                    print(task.result)
                    
                }
                return nil
            }
            
            return nil

        }
        
        
        
    }
    
    


    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        
        // キーボードを閉じる
        textField.resignFirstResponder()
        
        return true
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }


}

