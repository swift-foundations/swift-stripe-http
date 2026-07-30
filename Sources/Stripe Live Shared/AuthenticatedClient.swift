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
    ) throws(AuthenticatedClient.Error)
    where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        @Dependency(\.envVars.stripe.baseUrl) var baseUrl
        @Dependency(\.envVars.stripe.secretKey) var secretKey

        guard let secretKey else {
            throw .missingSecretKey
        }

        do throws(Authentication.Error<StripeAuthRouter.Failure>) {
            self = try .init(
                baseURL: baseUrl,
                credential: .init(token: secretKey.rawValue),
                apiRouter: router,
                credentialRouter: .init(),
                client: buildClient
            )
        } catch {
            throw .composition(error)
        }
    }
}

extension Authenticated where APIRouter: Sendable {
    package static func fromEnvironmentVariables(
        router: APIRouter,
        buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Consumer
    ) throws(AuthenticatedClient.Error) -> Self
    where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        try .init(
            router: router,
            buildClient: { buildClient($0) }
        )
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    package init(
        buildClient: @escaping @Sendable () -> Consumer
    ) throws(AuthenticatedClient.Error)
    where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
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
    ) throws(AuthenticatedClient.Error)
    where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        @Dependency(APIRouter.self) var router
        self = try .fromEnvironmentVariables(
            router: router,
            buildClient: buildClient
        )
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    /// The `Dependency.Key.liveValue` composition for a Stripe `Authenticated` wrapper.
    ///
    /// `Dependency.Key.liveValue` is a non-throwing static property requirement and
    /// `Authentication.Client` exposes no degraded value, so a Stripe misconfiguration —
    /// `STRIPE_SECRET_KEY` unset, or an unusable base URL — can only terminate the
    /// process. This is the ONE place in the package where that happens; every
    /// `liveValue` in every `*Live` target composes through here.
    package static func liveValue(
        _ buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Consumer
    ) -> Self where Credential == RFC_6750.Bearer, CredentialRouter == StripeAuthRouter {
        // REASON: `Dependency.Key.liveValue` is a non-throwing requirement and
        // `Authentication.Client` has no failure-carrying form, so a Stripe
        // credential or base-URL misconfiguration cannot be reported as an error
        // at this boundary. Sole authorized `try!` in the package.
        // swiftlint:disable:next force_try
        try! Self(buildClient)
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
