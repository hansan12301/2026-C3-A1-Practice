//
//  ImmersiveView.swift
//  SpaceTest
//
//  Created by Saerom on 5/19/26.
//
import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    // 공전 상태를 관리하는 변수
    @State private var isOrbiting = false
    @State private var orbitPivot: Entity?
    @State private var orbitController: AnimationPlaybackController?
    
    var body: some View {
        RealityView { content in
            
            // 1. 기준점 정육면체 (Cube) 생성
            let cube = ModelEntity(mesh: .generateBox(size: 0.2), materials: [SimpleMaterial(color: .blue, isMetallic: true)])
            cube.position = [0, 1.5, -1.5]
            
            // 상호작용 3신기 장착!
            cube.components.set(CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])])) // 1. 시선 과녁
            cube.components.set(InputTargetComponent()) // 2. 클릭 허락
            
            // ⭐️ 3. 시선이 닿았을 때 빛나는 호버 효과 추가!
            cube.components.set(HoverEffectComponent())
            
            cube.name = "control_cube"
            content.add(cube)
            
            
            // 2. [계층 1] 공전용 중심축 (Orbit Pivot)
            let pivot = Entity()
            pivot.position = [0, 1.5, -1.5] // 큐브와 같은 위치
            content.add(pivot)
            self.orbitPivot = pivot
            
            // 3. [계층 2] 위아래용 둥둥축 (Bobbing Pivot)
            let bobbingPivot = Entity()
            bobbingPivot.position = [0.5, 0, 0] // 큐브에서 0.5m 옆으로 띄움 (궤도 반지름)
            pivot.addChild(bobbingPivot)
            
            // 4. [계층 3] 실제 캐릭터 (USDC)
            // ⭐️ 파일명을 "bakbak2"로 변경 적용 완료!
            if let character = try? await Entity(named: "bakbak2", in: realityKitContentBundle) {
                
                // ⭐️ 찾아내신 최적의 수치 0.005배로 축소 적용!
                character.scale = [0.001, 0.001, 0.001]
                
                // (참고: 스케일이 더 작아졌으므로, 만약 터치가 잘 안 먹히면 radius 값을 5.0에서 더 키워주시면 됩니다)
                character.components.set(CollisionComponent(shapes: [.generateSphere(radius: 5.0)]))
                character.components.set(InputTargetComponent())
                
                bobbingPivot.addChild(character) // 둥둥축에 매달기
                
                // --- [기본 애니메이션] 위아래 둥둥 (항상 실행) ---
                var bobbingAnim = FromToByAnimation<Transform>(
                    name: "bobbing",
                    from: .init(translation: [0.5, -0.1, 0]), // 둥둥축의 로컬 위치 기준
                    to: .init(translation: [0.5, 0.1, 0]),
                    duration: 1.2,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
                bobbingAnim.repeatMode = .autoReverse
                if let resource = try? AnimationResource.generate(with: bobbingAnim) {
                    bobbingPivot.playAnimation(resource) // 둥둥축만 위아래로 무빙
                }
            }
        }
        // 5. 정육면체 클릭 시 공전 토글 제스처
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { event in
                    if event.entity.name == "control_cube" {
                        toggleOrbit()
                    }
                }
        )
    }
    
    // 공전 시작/정지/이어서 재생 로직
    private func toggleOrbit() {
        guard let pivot = orbitPivot else { return }
        
        if isOrbiting {
            // 멈춤 ➔ stop()이 아니라 pause(일시정지)로 바꿉니다!
            orbitController?.pause()
            isOrbiting = false
            print("⏸️ 공전 얼음 (일시정지)")
        } else {
            // ⭐️ 이미 한 번 만들어둔 애니메이션(컨트롤러)이 있다면? ➔ 이어서 재생(땡!)
            if let controller = orbitController {
                controller.resume()
                isOrbiting = true
                print("▶️ 공전 땡 (이어서 재생)")
            }
            // ⭐️ 만들어둔 게 없다면? (앱 켜고 처음 큐브를 누를 때) ➔ 새로 만듭니다.
            else {
                let cp: SIMD3<Float> = [0, 1.5, -1.5]
                
                // (이전 답변에서 고르신 정주행 방향 축 설정)
                let q1 = simd_quatf(angle: 0, axis: [0, -1, 0])
                let q2 = simd_quatf(angle: .pi / 2, axis: [0, -1, 0])
                let q3 = simd_quatf(angle: .pi, axis: [0, -1, 0])
                let q4 = simd_quatf(angle: .pi * 1.5, axis: [0, -1, 0])
                let q5 = simd_quatf(angle: .pi * 2, axis: [0, -1, 0])
                
                let anim1 = FromToByAnimation<Transform>(name: "1", from: .init(scale: .init(repeating: 1), rotation: q1, translation: cp), to: .init(scale: .init(repeating: 1), rotation: q2, translation: cp), duration: 1.0, timing: .linear, bindTarget: .transform)
                let anim2 = FromToByAnimation<Transform>(name: "2", from: .init(scale: .init(repeating: 1), rotation: q2, translation: cp), to: .init(scale: .init(repeating: 1), rotation: q3, translation: cp), duration: 1.0, timing: .linear, bindTarget: .transform)
                let anim3 = FromToByAnimation<Transform>(name: "3", from: .init(scale: .init(repeating: 1), rotation: q3, translation: cp), to: .init(scale: .init(repeating: 1), rotation: q4, translation: cp), duration: 1.0, timing: .linear, bindTarget: .transform)
                let anim4 = FromToByAnimation<Transform>(name: "4", from: .init(scale: .init(repeating: 1), rotation: q4, translation: cp), to: .init(scale: .init(repeating: 1), rotation: q5, translation: cp), duration: 1.0, timing: .linear, bindTarget: .transform)
                
                if let r1 = try? AnimationResource.generate(with: anim1),
                   let r2 = try? AnimationResource.generate(with: anim2),
                   let r3 = try? AnimationResource.generate(with: anim3),
                   let r4 = try? AnimationResource.generate(with: anim4),
                   let sequence = try? AnimationResource.sequence(with: [r1, r2, r3, r4]) {
                    
                    // 애니메이션 컨트롤러를 변수에 잘 저장해 둡니다. (나중에 resume 하려고)
                    self.orbitController = pivot.playAnimation(sequence.repeat())
                    isOrbiting = true
                    print("🚀 공전 최초 출발")
                }
            }
        }
    }
}
    
#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
