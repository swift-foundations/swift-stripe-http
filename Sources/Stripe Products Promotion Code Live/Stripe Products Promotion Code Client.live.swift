import Dependencies
import Foundation
//
//  Stripe Products Promotion Code Client.live.swift
//  swift-stripe-live
//
//  Created on 14/01/2025.
//
import Stripe_Live_Shared
import Stripe_Products_Promotion_Codes_Types
import Stripe_Types_Models

extension Stripe.Products.PromotionCodes.Client {
    public static func live(
        makeRequest:
            @escaping @Sendable (_ route: Stripe.Products.PromotionCodes.API) throws -> URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handleRequest

        return Self(
            create: { request in
                try await handleRequest(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.Products.PromotionCode.self
                )
            },

            retrieve: { id in
                try await handleRequest(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.Products.PromotionCode.self
                )
            },

            update: { id, request in
                try await handleRequest(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.Products.PromotionCode.self
                )
            },

            list: { request in
                try await handleRequest(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.Products.PromotionCodes.List.Response.self
                )
            }
        )
    }
}

extension Stripe.Products.PromotionCodes {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.Products.PromotionCodes.API,
        Stripe.Products.PromotionCodes.API.Router,
        Stripe.Products.PromotionCodes.Client
    >
}

// The `Dependency.Key` conformances for `Stripe.Products.PromotionCodes` and
// `Stripe.Products.PromotionCodes.API.Router` are NOT declared here — this directory
// is unreferenced by any target (see the Package.swift note at the top of `targets:`)
// and `Stripe.Products.PromotionCodes` is also composed by the wired
// `Stripe Products Live/Stripe Products Promotion Code Live` sources under the
// `Stripe Products Live` target. Declaring both was a duplicate `@retroactive`
// conformance on the same type; the wired target is the sole owner (issue #15).
