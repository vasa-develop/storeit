//
//  OAuth2Google2.swift
//  StoreIt
//
//  Created by Romain Gjura on 06/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
//import p2_OAuth2

/*class OAuth2Google : OAuth2 {
    
    fileprivate let oauth2: OAuth2CodeGrant
    
    // TODO: do not stock ids like this !
    init() {
        self.oauth2 = OAuth2CodeGrant(settings: [
                "client_id": "279687106087-jljuo1c0a5lbic9lkkpau1qitr4bioum.apps.googleusercontent.com",
                "authorize_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://www.googleapis.com/oauth2/v3/token",
                "scope": "profile email",
                "redirect_uris": ["com.googleusercontent.apps.279687106087-jljuo1c0a5lbic9lkkpau1qitr4bioum:/oauth-storeit"],
            ])
        onFailureOrAuthorizeAddEvents()
    }
    
    func authorize(_ context: AnyObject) {
  		self.oauth2.authorizeEmbeddedFrom(context)
    }
    
    func handleRedirectUrl(_ url: URL) {
        self.oauth2.handleRedirectURL(url)
    }
    
    func forgetTokens() {
        self.oauth2.forgetTokens()
    }
    
    func accessToken() -> String? {
        return self.oauth2.accessToken
    }
    
    func onFailureOrAuthorizeAddEvents() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navigationController = appDelegate.window?.rootViewController as! UINavigationController
        let loginView = navigationController.viewControllers[0] as! LoginView

        oauth2.onAuthorize = { parameters in
            print("[ConnexionManager] Did authorize with parameters: \(parameters)")
            loginView.initConnection(loginView.host, port: loginView.port, path: "/Users/gjura_r/Desktop/demo/", allItems: [:])
            loginView.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)

        }
        oauth2.onFailure = { error in
            if let error = error {
                print("[ConnexionManager] Authorization failure: \(error)")
                loginView.logout()
            }
        }
    }
    
}*/
