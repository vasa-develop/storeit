//
//  ViewController.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import ObjectMapper
import FBSDKLoginKit
import GoogleSignIn

class LoginView: UIViewController, FBSDKLoginButtonDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    
    let networkManager = NetworkManager.sharedInstance
    
    @IBOutlet weak var FBLoginButton: FBSDKLoginButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        FBLoginButton.readPermissions = ["public_profile", "email"]
        FBLoginButton.delegate = self
        
        if let connectionType = SessionManager.getConnectionType() {
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().signInSilently()
            } else if connectionType == ConnectionType.facebook {
                processFacebookLogin()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: FACEBOOK
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil) {
            print(error)
            self.logout()
        }
        else if result.isCancelled {
            print(result)
            self.logout()
        }
        else {
            if result.grantedPermissions.contains("email"){
				processFacebookLogin()
            }
        }
    }
    
    // do something for fb token refresh
    func processFacebookLogin() {
        _ = SessionManager.set(token: FBSDKAccessToken.current().tokenString)
        
        networkManager.initConnection(loginFunction: loginFunction, logoutFunction: logoutToLoginView)
        
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        SessionManager.set(connectionType: ConnectionType.facebook)
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        self.logout()
    }
    
    // MARK: GOOGLE
    
    func sign(_ signIn: GIDSignIn!,
              present viewController: UIViewController!) {
        SessionManager.set(connectionType: ConnectionType.google)
        self.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!,
              dismiss viewController: UIViewController!) {
        SessionManager.removeConnectionType()
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            print("[LoginView] \(error)")
            SessionManager.removeConnectionType()
            return
        }
        
        _ = SessionManager.set(token: user.authentication.accessToken)
        SessionManager.set(connectionType: ConnectionType.google)
        
        networkManager.initConnection(loginFunction: loginFunction, logoutFunction: logoutToLoginView)
        
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        self.logout()
    }

    // MARK: Utils
    
    @IBAction func logoutSegue(_ segue: UIStoryboardSegue) {
        self.logout()
    }
    
    func loginFunction() {
        if let token = SessionManager.getToken() {
            if let connectionType = SessionManager.getConnectionType() {
                self.networkManager.join(connectionType.rawValue, accessToken: token) { _ in
                    print("[LoginView] JOIN succeeded")
                }
            }
        }
    }
    
    func logout() {
        if let connectionType = SessionManager.getConnectionType() {
            print("[LoginView] Logging out...")
            
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().disconnect()
            } else if connectionType == ConnectionType.facebook {
                FBSDKLoginManager().logOut()
            }
            
            networkManager.close()
            SessionManager.resetSession()
        }
    }
    
    func logoutToLoginView() {
        _ = self.navigationController?.popToRootViewController(animated: true)
        self.logout()
    }

}




