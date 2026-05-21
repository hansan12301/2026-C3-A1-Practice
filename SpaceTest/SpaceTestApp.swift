//
//  SpaceTestApp.swift
//  SpaceTest
//
//  Created by Saerom on 5/19/26.
//

import SwiftUI

@main
struct SpaceTestApp: App {

    @State private var appModel = AppModel() // 1. 상태 관리를 위한 App Model 생성

    var body: some Scene {
        WindowGroup {
            ContentView() // 2. 초기 2D 화면
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) { // 3. 버튼을 통해 immersive 환경 진입 할래말래
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
