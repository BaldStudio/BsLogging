//
//  EmitALogFromSubDirectory.swift
//  BsLoggingTests
//
//  Created by Runze Chang on 2024/5/8.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import BsLogging

func emitLogMessage(_ message: Logger.Message, to logger: Logger) {
    logger.debug(message)
    logger.info(message)
    logger.warn(message)
    logger.error(message)
}

