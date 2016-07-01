package com.example.teraidaiki.serverless;

import android.os.AsyncTask;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.CognitoCredentialsProvider;
import com.amazonaws.mobileconnectors.apigateway.ApiClientFactory;
import com.amazonaws.mobileconnectors.apigateway.annotation.Operation;
import com.amazonaws.mobileconnectors.apigateway.annotation.Service;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUser;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserAttributes;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserCodeDeliveryDetails;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserPool;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserSession;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.AuthenticationContinuation;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.AuthenticationDetails;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.MultiFactorAuthenticationContinuation;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.AuthenticationHandler;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.GenericHandler;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.SignUpHandler;
import com.amazonaws.regions.Regions;
import com.google.gson.Gson;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;


public class MainActivity extends AppCompatActivity {

    //////////////////////
    // Config Param
    //////////////////////
    private static final String userPoolId = "us-east-1_<userpool-id>";
    private static final String clientId = "<userpool-client-id>";
    private static final String clientSecret = "<userpool-client-secret>";
    private static final String identityPoolId = "us-east-1:<identity-pool-id>";
    private static final String EndPoint = "https://<apigateway-id>.execute-api.us-east-1.amazonaws.com/<stage>";
    private static final String CloudFront = "https://<cloudfront-id>.cloudfront.net";
    private static final String api = "<api path>";


    //////////////////////

    private EditText nameEdit;
    private EditText passwordEdit;
    private EditText emailEdit;
    private Button signUpButton;

    private EditText verifyNameEdit;
    private EditText activateCodeEdit;
    private Button verifyButton;

    private EditText loginNameEdit;
    private EditText loginPasswordEdit;
    private Button loginButton;

    private static CognitoUserPool userPool;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        nameEdit = (EditText) this.findViewById(R.id.name);
        passwordEdit = (EditText) this.findViewById(R.id.password);
        emailEdit = (EditText) this.findViewById(R.id.email);
        signUpButton = (Button) this.findViewById(R.id.signUp);

        verifyNameEdit = (EditText) this.findViewById(R.id.verifyName);
        activateCodeEdit = (EditText) this.findViewById(R.id.activateCode);
        verifyButton = (Button) this.findViewById(R.id.verify);

        loginNameEdit = (EditText) this.findViewById(R.id.loginName);
        loginPasswordEdit = (EditText) this.findViewById(R.id.loginPassword);
        loginButton = (Button) this.findViewById(R.id.login);


        userPool = new CognitoUserPool(this, userPoolId, clientId, clientSecret, new ClientConfiguration());

        signUpButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                // Read user data and register
                CognitoUserAttributes userAttributes = new CognitoUserAttributes();

                String name = nameEdit.getText().toString();
                String password = passwordEdit.getText().toString();
                String email = emailEdit.getText().toString();
                userAttributes.addAttribute("email", email);

                userPool.signUpInBackground(name, password, userAttributes, null, new SignUpHandler() {
                    @Override
                    public void onSuccess(CognitoUser user, boolean signUpConfirmationState,
                                          CognitoUserCodeDeliveryDetails cognitoUserCodeDeliveryDetails) {
                        // Check signUpConfirmationState to see if the user is already confirmed
                        Boolean regState = signUpConfirmationState;
                        if (signUpConfirmationState) {
                            // User is already confirmed
                            Toast.makeText(getApplicationContext(), "すでにConfirmedされています", Toast.LENGTH_LONG).show();
                        }
                        else {
                            // User is not confirmed
                            Toast.makeText(getApplicationContext(), "認証コードを入力してアクティベートしてください", Toast.LENGTH_LONG).show();
                        }
                    }

                    @Override
                    public void onFailure(Exception exception) {
                        Toast.makeText(getApplicationContext(), "ユーザ登録に失敗しました", Toast.LENGTH_LONG).show();
                    }
                });

            }
        });

        verifyButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                String verifyName = verifyNameEdit.getText().toString();
                String activateCode = activateCodeEdit.getText().toString();

                userPool.getUser(verifyName).confirmSignUpInBackground(activateCode, true, new GenericHandler() {
                    @Override
                    public void onSuccess() {
                        Toast.makeText(getApplicationContext(), "アクティベートされました", Toast.LENGTH_LONG).show();
                    }

                    @Override
                    public void onFailure(Exception exception) {

                    }
                });

            }
        });

        loginButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String loginName = loginNameEdit.getText().toString();
                final String loginPassword = loginPasswordEdit.getText().toString();


                userPool.getUser(loginName).getSessionInBackground(new AuthenticationHandler() {
                    @Override
                    public void onSuccess(CognitoUserSession cognitoUserSession) {
                        Toast.makeText(getApplicationContext(), "ログイン成功", Toast.LENGTH_LONG).show();

                        CognitoCredentialsProvider credentialsProvider = new CognitoCredentialsProvider(
                                identityPoolId,Regions.US_EAST_1);
                        //credentialsProvider.clear();

                        Map<String, String> logins = new HashMap<String, String>();
                        String userPoolProvider = "cognito-idp.us-east-1.amazonaws.com/" + userPoolId;
                        logins.put(userPoolProvider, cognitoUserSession.getIdToken().getJWTToken());
                        credentialsProvider.setLogins(logins);
                        //credentialsProvider.getCredentials();

                        callAPI(credentialsProvider);
                    }

                    @Override
                    public void getAuthenticationDetails(AuthenticationContinuation authenticationContinuation, String username) {

                        AuthenticationDetails authenticationDetails = new AuthenticationDetails(username, loginPassword, null);
                        authenticationContinuation.setAuthenticationDetails(authenticationDetails);
                        authenticationContinuation.continueTask();

                    }

                    @Override
                    public void getMFACode(MultiFactorAuthenticationContinuation multiFactorAuthenticationContinuation) {
                        // MFAの設定がない場合は不要
                    }

                    @Override
                    public void onFailure(Exception e) {
                        Toast.makeText(getApplicationContext(), "ログインに失敗しました", Toast.LENGTH_LONG).show();
                    }
                });
            }
        });

    }

    ///////////////// One Time //////////////////

    @Service(
            endpoint = EndPoint
    )
    public interface OneTimeClient {
        @Operation(
                path = "/onetime",
                method = "POST"
        )
        OneTimeResponseData Post(OneTimeRequestData param);
    }
    public class OneTimeRequestData {
        public class Param{
            String url;
        }
        Param param = new Param();

    }
    public class OneTimeResponseData {
        String url;
    }

    ////////////////////////////////////////////

    class RequestData {

        public class Param {
            public class Data{
                String name;
                String type;
            }

            Data data = new Data();
        }

        Param param = new Param();
    }
    class ResponseData {
        class Data{
            String app_name;
            String app_type;
        }

        Data data;
        Integer status_cd;
    }



    private void callAPI(final CognitoCredentialsProvider credentialsProvider)
    {


        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
                ApiClientFactory factory = new ApiClientFactory();

                if(credentialsProvider != null){
                    factory.credentialsProvider(credentialsProvider);
                }

                // Build
                final OneTimeClient client = factory.build(OneTimeClient.class);


                OneTimeRequestData onetimeRequest = new OneTimeRequestData();
                onetimeRequest.param.url = CloudFront + api;
                OneTimeResponseData onetimeUrl = client.Post(onetimeRequest);


                Gson gson = new Gson();
                RequestData apiRequest = new RequestData();
                apiRequest.param.data.name = "user";
                apiRequest.param.data.type = "primium";


                String url = onetimeUrl.url;
                String requestJSON = gson.toJson(apiRequest);
                try {
                    Request request =  new Request.Builder()
                            .url(url)
                            .post(RequestBody.create(MediaType.parse("application/json; charset=utf-8"), requestJSON))
                            .build();

                    Response response = new OkHttpClient().newCall(request).execute();
                    if (response.isSuccessful()){
                        ResponseData res = gson.fromJson(response.body().string(),ResponseData.class);
                        Log.i("200", res.toString());
                    }
                }catch(IOException e){
                    Log.e("500", "error:" + e.getMessage(), e);
                }



                return null;
            }


        }.execute();


    }



}
