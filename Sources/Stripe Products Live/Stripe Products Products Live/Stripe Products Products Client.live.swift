//
//  Products Client.live.swift
//  coenttb-stripe
//
//  Created by Coen ten Thije Boonkkamp on 05/01/2025.
//
import Foundation
import Stripe_Live_Shared
import Stripe_Products_Types

extension Stripe.Products.Products.Client {
    public static func live(
        makeRequest:
            @escaping @Sendable (_ route: Stripe.Products.Products.API) throws -> URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handler

        return Self(
            create: { request in
                try await handler(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.Products.Product.self
                )
            },

            update: { id, request in
                try await handler(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.Products.Product.self
                )
            },

            retrieve: { id in
                try await handler(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.Products.Product.self
                )
            },

            list: { request in
                try await handler(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.Products.Products.List.Response.self
                )
            },

            delete: { id in
                try await handler(
                    for: makeRequest(.delete(id: id)),
                    decodingTo: DeletedObject.self
                )
            },

            search: { request in
                try await handler(
                    for: makeRequest(.search(request: request)),
                    decodingTo: Stripe.Products.Products.Search.Response.self
                )
            }
        )
    }
}

extension Stripe.Products.Products {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.Products.Products.API,
        Stripe.Products.Products.API.Router,
        Stripe.Products.Products.Client
    >
}

/// `Stripe.Products.Products` is a caseless namespace enum (vacuously Sendable) whose
/// home-module declaration — unlike its siblings in Stripe Namespaces.swift — omits the
/// `Sendable` annotation. `Dependency.Key` (= `Witness.Key`) inherits `Sendable`, so this
/// retroactive conformance must supply it; `@unchecked` is the compiler-prescribed spelling
/// for the retroactive case and is honest here (no state exists to check).
extension Stripe.Products.Products: @retroactive @unchecked Sendable {}

extension Stripe.Products.Products: @retroactive Dependency.Key {
    public static var liveValue: Stripe.Products.Products.Authenticated {
        .liveValue { .live(makeRequest: $0) }
    }
    public static let testValue: Stripe.Products.Products.Authenticated = liveValue
}

extension Stripe.Products.Products.API.Router: @retroactive Dependency.Key {
    public static let liveValue: Self = .init()
    public static let testValue: Self = .init()
}
