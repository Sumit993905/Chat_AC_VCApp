//
//  UserModel.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import Foundation

struct UserModel: Identifiable {
    var id = UUID()
    let name: String
    let email: String
    let password: String
    
}

