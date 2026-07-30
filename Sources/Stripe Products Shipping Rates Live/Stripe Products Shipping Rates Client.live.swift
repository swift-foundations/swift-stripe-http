import Dependencies
import Foundation
//
//  Stripe Products Shipping Rates Client.live.swift
//  swift-stripe-live
//
//  Created on 14/01/2025.
//
import Stripe_Live_Shared
import Stripe_Products_Shipping_Rates_Types
import Stripe_Types_Models

extension Stripe.Products.ShippingRates.Client {
    public static func live(
        makeRequest:
            @escaping @Sendable (_ route: Stripe.Products.ShippingRates.API) throws -> URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handleRequest

        return Self(
            create: { request in
                try await handleRequest(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.Products.ShippingRate.self
                )
            },

            retrieve: { id in
                try await handleRequest(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.Products.ShippingRate.self
                )
            },

            update: { id, request in
                try await handleRequest(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.Products.ShippingRate.self
                )
            },

            list: { request in
                try await handleRequest(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.Products.ShippingRates.List.Response.self
                )
            }
        )
    }
}

extension Stripe.Products.ShippingRates {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.Products.ShippingRates.API,
        Stripe.Products.ShippingRates.API.Router,
        Stripe.Products.ShippingRates.Client
    >
}

// The `Dependency.Key` conformances for `Stripe.Products.ShippingRates` and
// `Stripe.Products.ShippingRates.API.Router` are NOT declared here — this directory
// is unreferenced by any target (see the Package.swift note at the top of `targets:`)
// and `Stripe.Products.ShippingRates` is also composed by the wired
// `Stripe Products Live/Stripe Products Shipping Rates Live` sources under the
// `Stripe Products Live` target. Declaring both was a duplicate `@retroactive`
// conformance on the same type; the wired target is the sole owner (issue #15).
