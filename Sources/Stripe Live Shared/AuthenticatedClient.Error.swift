//
//  AuthenticatedClient.Error.swift
//  swift-stripe-live — Stripe Live Shared
//

import URL_Routing_Foundation_Integration

/// Namespace for the failure domain of composing a Stripe ``Authenticated`` client
/// from environment variables — see `AuthenticatedClient.swift`.
public enum AuthenticatedClient {}

extension AuthenticatedClient {
    /// Failures composing a Stripe ``Authenticated`` client from environment variables.
    public enum Error: Swift.Error {
        /// `STRIPE_SECRET_KEY` is not set.
        case missingSecretKey

        /// The underlying ``Authentication/Client`` composition failed — the base URL
        /// did not parse as request data, or the credential failed to print into the
        /// `Authorization` header.
        case composition(Authentication.Error<StripeAuthRouter.Failure>)
    }
}
