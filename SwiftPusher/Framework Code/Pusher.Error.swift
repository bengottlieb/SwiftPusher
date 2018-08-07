//
//  Pusher.Error.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Pusher {
	public enum Error: String, Swift.Error {
		case outOfMemory, unableToConstructNotificationData, noActiveConnection, noCertificateAvailable, missingContext
		
		case APNSProcessing, APNSMissingDeviceToken, APNSMissingTopic, APNSMissingPayload, APNSInvalidTokenSize, APNSInvalidTopicSize, APNSInvalidPayloadSize, APNSInvalidTokenContent, APNSUnknownReason, APNSShutdown
		
		case socketCreate, socketConnect, socketResolveHostName, socketFileControl, socketOptions
		
		case SSLConnection, SSLContext, SSLIOFuncs, SSLPeerDomainName, SSLCertificate, SSLDroppedByServer, SSLAuthFailed, SSLHandshakeFail, SSLHandshakeUnknownRootCert, SSLHandshakeNoRootCert, SSLHandshakeCertExpired, SSLHandshakeXCertChainInvalid, SSLHandshakeClientCertRequested, SSLHandshakeServerAuthCompleted, SSLHandshakePeerCertExpired, SSLHandshakePeerCertRevoked, SSLHandshakePeerCertUnknown, SSLInDarkWake, SSLHandshakeClosedAbort, SSLHandshakeTimeout
		
		case readDroppedByServer, readClosedAbort, readClosedGraceful, readFail
		case writeDroppedByServer, writeClosedAbort, writeClosedGraceful, writeFail
		
		case pkcs12Import, pkcs12EmptyData, pkcs12Decode, pkcs12AuthFailed, pkcs12Password, pkcs12NoItems, pkcs12MultipleItems
		
		case keychainCopyMatching, keychainItemNotFound, keychainCreateIdentity
		
	}
}
