import Foundation

extension Stripe.PaymentMethods.PaymentMethods.Client {
    public static func live(
        makeRequest:
            @escaping @Sendable (_ route: Stripe.PaymentMethods.PaymentMethods.API) throws ->
            URLRequest
    ) -> Self {
        @Dependency(URLRequest.Handler.Stripe.self) var handleRequest

        return Self(
            create: { request in
                try await handleRequest(
                    for: makeRequest(.create(request: request)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            },
            retrieve: { id in
                try await handleRequest(
                    for: makeRequest(.retrieve(id: id)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            },
            retrieveCustomer: { customerId, paymentMethodId in
                try await handleRequest(
                    for: makeRequest(
                        .retrieveCustomer(customerId: customerId, paymentMethodId: paymentMethodId)
                    ),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            },
            update: { id, request in
                try await handleRequest(
                    for: makeRequest(.update(id: id, request: request)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            },
            list: { request in
                try await handleRequest(
                    for: makeRequest(.list(request: request)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethods.List.Response.self
                )
            },
            listCustomer: { customerId, request in
                try await handleRequest(
                    for: makeRequest(.listCustomer(customerId: customerId, request: request)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethods.List.Customer.Response.self
                )
            },
            attach: { id, request in
                try await handleRequest(
                    for: makeRequest(.attach(id: id, request: request)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            },

            detach: { id in
                try await handleRequest(
                    for: makeRequest(.detach(id: id)),
                    decodingTo: Stripe.PaymentMethods.PaymentMethod.self
                )
            }
        )
    }
}

extension Stripe.PaymentMethods.PaymentMethods {
    public typealias Authenticated = Stripe_Live_Shared.Authenticated<
        Stripe.PaymentMethods.PaymentMethods.API,
        Stripe.PaymentMethods.PaymentMethods.API.Router,
        Stripe.PaymentMethods.PaymentMethods.Client
    >
}

/// `Stripe.PaymentMethods.PaymentMethods` is a caseless namespace enum (vacuously
/// Sendable) whose home-module declaration omits the `Sendable` annotation its
/// Namespaces.swift siblings carry. `Dependency.Key` (= `Witness.Key`) inherits
/// `Sendable`, so this retroactive conformance must supply it; `@unchecked` is the
/// compiler-prescribed spelling for the retroactive case and is honest here.
extension Stripe.PaymentMethods.PaymentMethods: @retroactive @unchecked Sendable {}

extension Stripe.PaymentMethods.PaymentMethods: @retroactive Dependency.Key {
    public static var liveValue: Stripe.PaymentMethods.Authenticated {
        .liveValue { .live(makeRequest: $0) }
    }
    public static let testValue: Stripe.PaymentMethods.Authenticated = liveValue
}

extension Stripe.PaymentMethods.PaymentMethods.API.Router: @retroactive Dependency.Key {
    public static let liveValue: Self = .init()
    public static let testValue: Self = .init()
}
