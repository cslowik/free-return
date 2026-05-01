//
//  StarfieldBackground.swift
//  Free Return
//

import SpriteKit
import simd

enum StarfieldBackground {

    static func make(size: CGSize,
                     zoneTint: vector_float3 = vector_float3(0.03, 0.03, 0.12),
                     zoneSeed: Float = 0.0) -> SKSpriteNode {
        let node = SKSpriteNode(color: .black, size: size)
        node.anchorPoint = .zero
        node.position = .zero
        node.zPosition = -100

        let shader = SKShader(fileNamed: "Starfield.fsh")
        shader.uniforms = [
            SKUniform(name: "u_zoneTint", vectorFloat3: zoneTint),
            SKUniform(name: "u_zoneSeed", float: zoneSeed),
            SKUniform(name: "u_size",
                      vectorFloat2: vector_float2(Float(size.width),
                                                  Float(size.height)))
        ]
        node.shader = shader
        return node
    }
}
