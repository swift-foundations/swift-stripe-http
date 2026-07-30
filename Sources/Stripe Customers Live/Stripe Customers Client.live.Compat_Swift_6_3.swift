//
//  Stripe Customers Client.live.Compat_Swift_6_3.swift
//  swift-stripe-live
//
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │  6.3.x-COMPAT PATH — §A9-CLASS — RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.    │
//  └───────────────────────────────────────────────────────────────────────────┘
//
//  A `Stripe.Customers.Authenticated` whose client constructs requests WITHOUT the
//  generated `Stripe.Customers.API.Router` — see
//  `Stripe Live Shared/Compat_Swift_6_3.swift` and the §A9 catalog entry.
//
//  `create` works and is wire-identical to the ordinary path. EVERY OTHER ENDPOINT
//  THROWS `Compat_Swift_6_3.Error.unsupportedRoute` — it does not silently fall
//  through to the crashing router, and it does not trap. On 6.3.x those endpoints
//  do not work through the ordinary path either; they SIGSEGV. This path converts
//  an unrecoverable crash into a named, catchable error.
//
//  Grep token: `Compat_Swift_6_3`.
//  Catalog: swift-institute/Research/swift-compiler-bug-catalog.md §A9.
//

import Foundation
import Stripe_Customers_Types
import Stripe_Live_Shared

extension Stripe.Customers.Client {
    // REASON: lowercase-initial mirror of the `Compat_Swift_6_3` namespace and the §A9
    // retirement grep token; renaming would break the cross-repository sweep that retires
    // this path at the 6.4 flip. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// 6.3.x-compat (§A9) live client — `create` only.
    ///
    /// Identical to ``live(makeRequest:)`` in every respect except the request-maker:
    /// the same `Self.live(makeRequest:)` factory, the same `URLRequest.Handler.Stripe`
    /// transport, and the same response-decode types. Only the route → `URLRequest`
    /// step bypasses the generated router.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    package static func compat_Swift_6_3() throws(Compat_Swift_6_3.Error) -> Self {
        let base = try Compat_Swift_6_3.baseRequestData()
        let router = Stripe.Customers.API.Router.Compat_Swift_6_3()

        return .live(makeRequest: { route in
            // Reject every non-`create` route BEFORE the router sees it: the compat
            // router cannot print them, and the generated router would crash.
            guard case .create = route else {
                throw Compat_Swift_6_3.Error.unsupportedRoute("Stripe.Customers.API.\(route)")
            }
            return try Compat_Swift_6_3.makeRequest(router: router, base: base, route: route)
        })
    }
}

extension Stripe.Customers {
    // REASON: lowercase-initial mirror of the `Compat_Swift_6_3` namespace and the §A9
    // retirement grep token; renaming would break the cross-repository sweep that retires
    // this path at the 6.4 flip. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    // swift-format-ignore: AlwaysUseLowerCamelCase
    /// 6.3.x-compat (§A9) `Authenticated` value — register this in the composition root
    /// in place of ``liveValue`` while on a 6.3.x toolchain.
    ///
    /// The wrapper still STORES the generated `Stripe.Customers.API.Router` (the
    /// `Authenticated` type is parameterized on it), but never PRINTS through it —
    /// constructing the router value is a no-op `init()`; §A9 fires on witness-table
    /// instantiation at print time, which this path never reaches.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    ///   At the 6.4 flip, drop the composition-root registration and this member; the
    ///   ordinary ``liveValue`` is then correct again.
    public static func compat_Swift_6_3() throws -> Stripe.Customers.Authenticated {
        // Build the compat client BEFORE composing the wrapper, so a configuration
        // failure is thrown rather than trapped. The supplied router-based
        // `makeRequest` is still deliberately DISCARDED (`_`) — calling it is
        // exactly what crashes on 6.3.x.
        let client = try Stripe.Customers.Client.compat_Swift_6_3()
        return try Stripe.Customers.Authenticated { _ in client }
    }
}
