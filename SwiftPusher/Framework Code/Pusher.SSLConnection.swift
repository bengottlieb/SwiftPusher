//
//  SSLConnection.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation
import Security


extension Pusher {
	class SSLConnection {
		var sslSocket: Int32?
		var port = Pusher.defaultPort
		var host = Pusher.Host.sandbox

		var context: SSLContext!
		var certificate: Certificate
		var socketContext = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
		
		init(certificate: Certificate) {
			self.certificate = certificate
		}
		
		func connect() throws {
			self.disconnect()
			
			do {
				try self.connectSocket()
				try self.connectSSL()
				try self.handshake()
			} catch {
				self.disconnect()
				throw error
			}
		}
		
		func disconnect() {
			if let ctx = self.context { SSLClose(ctx) }
			if let skt = self.sslSocket { close(skt) }
			
			self.context = nil
			self.sslSocket = nil
		}
		
		func read(count: Int) throws -> Data {
			var readCount: size_t = 0
			guard let buffer = malloc(count) else { throw Pusher.Error.outOfMemory }
			
			if self.context == nil {
				self.disconnect()
				throw Pusher.Error.missingContext
			}
			let result = SSLRead(self.context, buffer, count, &readCount)
			
			print("Read \(readCount) bytes")
			switch result {
			case errSecSuccess, errSSLWouldBlock: return Data(bytes: buffer, count: readCount)
			case errSecIO: throw Pusher.Error.readDroppedByServer
			case errSSLClosedAbort: throw Pusher.Error.readClosedAbort
			case errSSLClosedGraceful: throw Pusher.Error.readClosedGraceful
			default: throw Pusher.Error.readDroppedByServer
			}
		}
		
		func write(_ data: Data) throws -> Int {
			var written: size_t = 0
			
			if self.context == nil {
				self.disconnect()
				throw Pusher.Error.missingContext
			}

			let result = data.withUnsafeBytes { bytes in
				SSLWrite(self.context, bytes, data.count, &written)
			}
			
			switch result {
			case errSecSuccess, errSSLWouldBlock: return Int(written)
			case errSecIO: throw Pusher.Error.SSLDroppedByServer
			case errSSLClosedAbort: throw Pusher.Error.writeClosedAbort
			case errSSLClosedGraceful: throw Pusher.Error.writeClosedGraceful
			default: throw Pusher.Error.SSLDroppedByServer
			}
		}

		private func connectSocket() throws {
			let sock = socket(AF_INET, SOCK_STREAM, 0)
			if sock < 0 { throw Pusher.Error.socketCreate }
			
			var addr = sockaddr_in()
			guard let entry = gethostbyname(self.host.name) else { throw Pusher.Error.socketResolveHostName}
			
			addr.sin_family = sa_family_t(AF_INET)
			addr.sin_port = in_port_t(htons(in_port_t(self.port)))
			addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
			memcpy(&addr.sin_addr, entry.pointee.h_addr_list[0], Int(entry.pointee.h_length))
			
			
			let connResult = withUnsafeMutablePointer(to: &addr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
					Darwin.connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
				}
			}

			if connResult != errSecSuccess { throw Pusher.Error.socketConnect }
			
			let control = fcntl(sock, F_SETFL, O_NONBLOCK)
			if control != errSecSuccess { throw Pusher.Error.socketFileControl }
			
			var set: UInt32 = 1
			let optionResult = setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &set, UInt32(MemoryLayout<UInt32>.size))
			if optionResult != errSecSuccess { throw Pusher.Error.socketOptions }
			
			self.sslSocket = sock
		}
		
		private func connectSSL() throws {
			guard let context = SSLCreateContext(nil, .clientSide, .streamType), var socket = self.sslSocket else { throw Pusher.Error.SSLContext }
			
			let setIOResponse = SSLSetIOFuncs(context, { context, data, length in
				let fd: Int32 = context.assumingMemoryBound(to: Int32.self).pointee
				let lengthRequested = length.pointee
				
				var readCount = Darwin.recv(fd, data, lengthRequested, 0)
				
				defer { length.initialize(to: readCount) }
				if readCount == 0 {
					return OSStatus(errSSLClosedGraceful)
				} else if readCount < 0 {
					readCount = 0
					
					switch errno {
					case ENOENT: return errSSLClosedGraceful
					case EAGAIN: return errSSLWouldBlock
					case ECONNRESET: return errSSLClosedAbort
					default: return errSecIO
					}
				}
				
				guard lengthRequested <= readCount else {
					return OSStatus(errSSLWouldBlock)
				}
				
				return noErr

			}) { context, data, length in
				let fd: Int32 = context.assumingMemoryBound(to: Int32.self).pointee
				let toWrite = length.pointee
				
				var writeCount = Darwin.write(fd, data, toWrite)
				defer { length.initialize(to: writeCount) }
				if writeCount == 0 {
					return errSSLClosedGraceful
				} else if writeCount < 0 {
					writeCount = 0
					guard errno == EAGAIN else { return errSecIO }
					return errSSLWouldBlock
				}
				
				if toWrite > writeCount {
					print("Didn't write enough \(toWrite) vs. \(writeCount)")
					return errSSLWouldBlock
				}
				
				return noErr
			}
			if setIOResponse != errSecSuccess { throw Pusher.Error.SSLIOFuncs }
			
			self.socketContext.pointee = socket
			let connectionResult = SSLSetConnection(context, self.socketContext)
			if connectionResult != errSecSuccess { throw Pusher.Error.SSLConnection }
			
			let peerResult = SSLSetPeerDomainName(context, self.host.name, self.host.name.count)
			if peerResult != errSecSuccess { throw Pusher.Error.SSLPeerDomainName }
			
			guard let cert = try self.certificate.buildSSLCertificate() else { throw Pusher.Error.noCertificateAvailable }
			let certResult = SSLSetCertificate(context, cert)
			if certResult != errSecSuccess { throw Pusher.Error.SSLCertificate }
			
			self.sslSocket = socket
			self.context = context
		}
		
		private func handshake() throws {
			var status = errSSLWouldBlock
			let handshakeAttempts = 1 << 26
			
			for _ in 0..<handshakeAttempts {
				status = SSLHandshake(self.context)
				if status != errSSLWouldBlock { break }
			}
			
			switch status {
			case errSecSuccess: return
			case errSSLWouldBlock: throw Pusher.Error.SSLHandshakeTimeout
			case errSecIO: throw Pusher.Error.SSLDroppedByServer
			case errSecAuthFailed: throw Pusher.Error.SSLAuthFailed
			case errSSLUnknownRootCert: throw Pusher.Error.SSLHandshakeUnknownRootCert
			case errSSLNoRootCert: throw Pusher.Error.SSLHandshakeNoRootCert
			case errSSLCertExpired: throw Pusher.Error.SSLHandshakeCertExpired
			case errSSLXCertChainInvalid: throw Pusher.Error.SSLHandshakeXCertChainInvalid
			case errSSLClientCertRequested: throw Pusher.Error.SSLHandshakeClientCertRequested
			case errSSLPeerAuthCompleted: throw Pusher.Error.SSLHandshakeServerAuthCompleted
			case errSSLPeerCertExpired: throw Pusher.Error.SSLHandshakePeerCertExpired
			case errSSLPeerCertRevoked: throw Pusher.Error.SSLHandshakePeerCertRevoked
			case errSSLPeerCertUnknown: throw Pusher.Error.SSLHandshakePeerCertUnknown
			case errSSLClosedAbort: throw Pusher.Error.SSLHandshakeClosedAbort
				
			default: break
			}
		}
		
	}
	static func htons(_ value: CUnsignedShort) -> CUnsignedShort {
		return (value << 8) + (value >> 8)
	}
}
