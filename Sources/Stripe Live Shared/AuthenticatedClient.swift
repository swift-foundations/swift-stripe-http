//
//  AuthenticatedClient.swift
//  swift-stripe-live — Stripe Live Shared
//

import Dependencies
import Foundation
import URLRouting
import URL_Routing_Foundation_Integration

public typealias Authenticated<
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable,
    Client: Sendable
> = Authentication.Client<
    RFC_6750.Bearer,
    StripeAuthRouter,
    API,
    APIRouter,
    Client
> where APIRouter.Output == API, APIRouter.Input == RFC_3986.URI.Request.Data

extension Authenticated where APIRouter: Sendable {
    public init(
        router: APIRouter,
        buildClient:
            @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> Consumer
    ) throws where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        @Dependency(\.envVars.stripe.baseUrl) var baseUrl
        @Dependency(\.envVars.stripe.secretKey) var secretKey

        guard let secretKey else {
            throw NSError(
                domain: "StripeAuth",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "STRIPE_SECRET_KEY environment variable not set"
                ]
            )
        }

        self = try .init(
            baseURL: baseUrl,
            credential: .init(token: secretKey.rawValue),
            apiRouter: router,
            credentialRouter: .init(),
            client: buildClient
        )
    }
}

extension Authenticated where APIRouter: Sendable {
    package static func fromEnvironmentVariables(
        router: APIRouter,
        buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Consumer
    ) throws -> Self where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        try .init(
            router: router,
            buildClient: { buildClient($0) }
        )
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    package init(
        buildClient: @escaping @Sendable () -> Consumer
    ) throws where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        @Dependency(APIRouter.self) var router
        self = try .fromEnvironmentVariables(
            router: router
        ) { _ in buildClient() }
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    package init(
        _ buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Consumer
    ) throws where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        @Dependency(APIRouter.self) var router
        self = try .fromEnvironmentVariables(
            router: router,
            buildClient: buildClient
        )
    }
}

public struct StripeAuthRouter: Sendable {
    public init() {}
}

extension StripeAuthRouter: ParserPrinter {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Buffer = RFC_3986.URI.Request.Data
    public typealias Output = RFC_6750.Bearer
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    /// The fixed Stripe protocol headers (pinned API version + form content type).
    /// Kept as an opaque computed member so the router stays a stateless `Sendable`
    /// value; `Headers` unifies its field parsers' failures into the routing error
    /// domain, so this member's `Failure` is the plain domain error.
    private var stripeHeaders: some Parser.Bidirectional<RFC_3986.URI.Request.Data, Void, Failure> {
        Headers {
            Field("Stripe-Version") { "2024-12-18.acacia" }

            ContentType { "application/x-www-form-urlencoded" }
        }
    }

    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try stripeHeaders.parse(&input)
        return try RFC_6750.Bearer.Router().parse(&input)
    }

    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        // Reverse order, mirroring the sequential combinator's printer.
        try RFC_6750.Bearer.Router().print(output, into: &input)
        try stripeHeaders.print((), into: &input)
    }

    public borrowing func serialize(_ output: Output, into buffer: inout Input) throws(Failure) {
        // Forward order — the serializer world appends in parse order.
        try stripeHeaders.serialize((), into: &buffer)
        try RFC_6750.Bearer.Router().serialize(output, into: &buffer)
    }
}
