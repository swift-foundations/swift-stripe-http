import Dependencies
import Foundation
//
//  Stripe Products Tax Rate Client.live.swift
//  swift-stripe-live
//
//  Created on 14/01/2025.
//
import Stripe_Live_Shared
import Stripe_Products_Tax_Rates_Types
import Stripe_Types_Models

extension Stripe.Products.TaxRates.Client {
    public static func live(
        makeRequest:
            @escaping @Sendable (_ route: Stripe.Products.TaxRates.API) throws -> URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handleRequest

        return Self(
            create: { request in
                try await handleRequest(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.Products.TaxRate.self
                )
            },

            retrieve: { id in
                try await handleRequest(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.Products.TaxRate.self
                )
            },

            update: { id, request in
                try await handleRequest(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.Products.TaxRate.self
                )
            },

            list: { request in
                try await handleRequest(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.Products.TaxRates.List.Response.self
                )
            }
        )
    }
}

extension Stripe.Products.TaxRates {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.Products.TaxRates.API,
        Stripe.Products.TaxRates.API.Router,
        Stripe.Products.TaxRates.Client
    >
}

// The `Dependency.Key` conformances for `Stripe.Products.TaxRates` and
// `Stripe.Products.TaxRates.API.Router` are NOT declared here — this directory is
// unreferenced by any target (see the Package.swift note at the top of `targets:`)
// and `Stripe.Products.TaxRates` is also composed by the wired
// `Stripe Products Live/Stripe Products Tax Rate Live` sources under the
// `Stripe Products Live` target. Declaring both was a duplicate `@retroactive`
// conformance on the same type; the wired target is the sole owner (issue #15).
