//
//  MetadataProvider.swift
//  BsLogging
//
//  Created by Runze Chang on 2024/5/7.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import Darwin

#if compiler(>=5.6)
@preconcurrency protocol _SwiftLogSendable: Sendable {}
#else
protocol _SwiftLogSendable {}
#endif

extension Logger {
    public struct MetadataProvider: _SwiftLogSendable {
#if swift(>=5.5) && canImport(_Concurrency)
        @usableFromInline
        let provideMetadata: @Sendable() -> Metadata
        
        public init(_ provideMetadata: @escaping @Sendable() -> Metadata) {
            self.provideMetadata = provideMetadata
        }
#else
        @usableFromInline
        let provideMetadata: () -> Metadata
        
        public init(_ provideMetadata: @escaping () -> Metadata) {
            self.provideMetadata = provideMetadata
        }
#endif
        public var metadata: Metadata {
            provideMetadata()
        }
    }
}
