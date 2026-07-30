import Foundation
import Stripe_Live_Shared
import Stripe_Products_Types

extension Stripe.Products.Coupons.Client {
    public static func live(
        makeRequest: @escaping @Sendable (_ route: Stripe.Products.Coupons.API) throws -> URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handleRequest

        return Self(
            create: { request in
                try await handleRequest(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.Products.Coupon.self
                )
            },

            update: { id, request in
                try await handleRequest(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.Products.Coupon.self
                )
            },

            retrieve: { id in
                try await handleRequest(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.Products.Coupon.self
                )
            },

            list: { request in
                try await handleRequest(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.Products.Coupons.List.Response.self
                )
            },

            delete: { id in
                try await handleRequest(
                    for: makeRequest(.delete(id: id)),
                    decodingTo: DeletedObject.self
                )
            }
        )
    }
}

extension Stripe.Products.Coupons {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.Products.Coupons.API,
        Stripe.Products.Coupons.API.Router,
        Stripe.Products.Coupons.Client
    >
}

extension Stripe.Products.Coupons: @retroactive Dependency.Key {
    public static var liveValue: Stripe.Products.Coupons.Authenticated {
        .liveValue { .live(makeRequest: $0) }
    }
    public static let testValue: Stripe.Products.Coupons.Authenticated = liveValue
}

extension Stripe.Products.Coupons.API.Router: @retroactive Dependency.Key {
    public static let liveValue: Self = .init()
    public static let testValue: Self = .init()
}
