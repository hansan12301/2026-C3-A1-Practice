//
//  AppModel.swift
//  SpaceTest
//
//  Created by Saerom on 5/19/26.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace" // id로 다른 view에서 immersive space 구분
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
