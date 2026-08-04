//
//  Compat_Swift_6_3.swift
//  swift-stripe-live — Stripe Live Shared
//
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │  6.3.x-COMPAT PATH — §A9-CLASS — RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.    │
//  └───────────────────────────────────────────────────────────────────────────┘
//
//  The live half of the §A9 avoidance path. swift-stripe-standard vends create-only
//  routers (`<API>.Router.Compat_Swift_6_3`) that omit the `{id}` path parsers whose
//  `Tagged`-closing witness tables SIGSEGV on Swift 6.3.x; this file supplies the
//  base request data (base URL + auth/protocol headers) those routers print into,
//  and the `URLRequest` bridge.
//
//  BEHAVIOR IDENTITY
//  -----------------
//  ``baseRequestData()`` is a line-for-line reproduction of the two steps the
//  ordinary path performs:
//
//    1. `Authentication.Client.base(url:credential:credentialRouter:)`
//       (swift-url-routing, Sources/URL Routing Foundation Integration/
//       Authentication.Client.swift:102-119) —
//       parse the base URL into request data, then print the credential into it.
//    2. The credential and router the Stripe `Authenticated` wrapper supplies
//       (`AuthenticatedClient.swift:42-47`) — `RFC_6750.Bearer(token: secretKey)` printed
//       by ``StripeAuthRouter``, which emits `Authorization: Bearer <key>`,
//       `Stripe-Version: 2024-12-18.acacia`, and
//       `Content-Type: application/x-www-form-urlencoded`.
//
//  ``makeRequest(router:base:route:)`` then runs the SAME
//  `baseRequestData(_:).request(for:)` pipeline the generated router runs through,
//  so the base-URL merge (scheme/host/port/path-prepend/header-merge) and the
//  `URLRequestData → URLRequest` bridge are shared code, not a reimplementation.
//
//  The ONLY thing that differs from the ordinary path is WHICH router prints the
//  route — and the compat routers' route bodies are verbatim copies of the
//  generated routers' `.create` branches. Wire shape is therefore identical by
//  construction.
//
//  Grep token: `Compat_Swift_6_3`.
//  Catalog: swift-institute/Research/swift-compiler-bug-catalog.md §A9.
//

import Dependencies
import Foundation
import URLRouting

/// 6.3.x-compat (§A9) namespace — see the file header.
///
/// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
package enum Compat_Swift_6_3 {}

// MARK: - Error

extension Compat_Swift_6_3 {
    /// Failures of the 6.3.x-compat request-construction path.
    package enum Error: Swift.Error, CustomStringConvertible {
        /// A route outside the compat path's two supported endpoints was requested.
        ///
        /// The compat path deliberately does NOT fall through to the generated router:
        /// that router SIGSEGVs on 6.3.x, and a crash is not an error report.
        case unsupportedRoute(String)

        /// `STRIPE_SECRET_KEY` is not set.
        case missingSecretKey

        /// The configured Stripe base URL does not parse as request data.
        case invalidBaseURL(String)

        /// The secret key is not a well-formed RFC 6750 bearer token.
        case credential(String)

        /// The credential could not be printed into the `Authorization` header.
        case authorization(String)

        /// The route could not be printed into a `URLRequest`.
        case request(String)

        package var description: String {
            switch self {
            case .unsupportedRoute(let route):
                return """
                    [6.3.x-compat / §A9] The Stripe 6.3.x-compat request path constructs requests for \
                    `customers.create` and `checkoutSessions.create` ONLY — it cannot construct one for \
                    '\(route)'. Every other Stripe endpoint requires the generated API router, whose \
                    `{id}` path parsers SIGSEGV under Swift 6.3.x (lazy protocol-witness-table \
                    instantiation over `Tagged<…, String>`; see \
                    swift-institute/Research/swift-compiler-bug-catalog.md §A9). The fix travels with the \
                    6.4 compiler binary — this endpoint is restored by moving to Swift 6.4 and deleting \
                    the `Compat_Swift_6_3` path, not by extending it.
                    """
            case .missingSecretKey:
                return "[6.3.x-compat / §A9] STRIPE_SECRET_KEY environment variable not set."
            case .invalidBaseURL(let url):
                return "[6.3.x-compat / §A9] Stripe base URL is not valid request data: '\(url)'."
            case .credential(let reason):
                return "[6.3.x-compat / §A9] STRIPE_SECRET_KEY is not a valid bearer token: \(reason)"
            case .authorization(let reason):
                return "[6.3.x-compat / §A9] Could not print the Authorization header: \(reason)"
            case .request(let reason):
                return "[6.3.x-compat / §A9] Could not print the route into a URLRequest: \(reason)"
            }
        }
    }
}

// MARK: - Base request data

extension Compat_Swift_6_3 {
    /// The base request data every compat request is printed into: the Stripe base URL
    /// plus the `Authorization` / `Stripe-Version` / `Content-Type` headers.
    ///
    /// Reproduces `Authentication.Client.base(url:credential:credentialRouter:)` with the
    /// credential and credential-router the Stripe ``Authenticated`` wrapper supplies —
    /// see the file header's BEHAVIOR IDENTITY note.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    package static func baseRequestData() throws(Compat_Swift_6_3.Error) -> URLRequestData {
        @Dependency(\.envVars.stripe.baseUrl) var baseUrl
        @Dependency(\.envVars.stripe.secretKey) var secretKey

        guard let secretKey else { throw .missingSecretKey }

        // Step 1 — `Authentication.Client.base`, first half.
        guard var base = try? URLRequestData(uriString: baseUrl.absoluteString)
        else { throw .invalidBaseURL(baseUrl.absoluteString) }

        // Step 2 — the credential the `Authenticated` wrapper builds.
        let bearer: RFC_6750.Bearer
        do {
            // swift-linter:disable:next raw value access
            // REASON: wire/env boundary extraction (ruling class 3, item-4 lead
            // ruling 2026-07-23) — the EnvVars secret-key newtype is unwrapped
            // exactly once here to construct the RFC 6750 credential, mirroring
            // AuthenticatedClient.swift's ordinary path.
            bearer = try RFC_6750.Bearer(token: secretKey.rawValue)
        } catch {
            throw .credential("\(error)")
        }

        // Step 3 — `Authentication.Client.base`, second half: print the credential.
        // `StripeAuthRouter` prints `Authorization`, `Stripe-Version` and `Content-Type`.
        do {
            try StripeAuthRouter().print(bearer, into: &base)
        } catch {
            throw .authorization("\(error)")
        }

        return base
    }
}

// MARK: - Request construction

extension Compat_Swift_6_3 {
    /// Prints `route` through `router` into a `URLRequest`, merging `base`.
    ///
    /// This is the SAME `baseRequestData(_:).request(for:)` pipeline the generated
    /// routers run through — only the router differs.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    package static func makeRequest<Router: Parser.Bidirectional & Sendable>(
        router: Router,
        base: URLRequestData,
        route: Router.Output
    ) throws(Compat_Swift_6_3.Error) -> URLRequest where Router.Input == URLRequestData {
        do {
            return try router.baseRequestData(base).request(for: route)
        } catch {
            throw .request("\(error)")
        }
    }
}
