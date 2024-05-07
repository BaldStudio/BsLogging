//
//  ViewController.swift
//  BsLoggingDemo
//
//  Created by crzorz on 2024/05/07.
//  Copyright © 2024 BaldStudio. All rights reserved.
//

import UIKit
import BsLogging

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
                
        LoggingSystem.bootstrap { label in
            #if DEBUG
            StreamLogHandler.standardOutput(label: label)
            #else
            UnusableLogHandler()
            #endif
        }
        NSLog("NSLog Hello, world!")
        print("print Hello, world!")
        let logger = Logger(label: "ViewController")
        logger.debug("d Hello, world!")
        logger.info("i Hello, world!")
        logger.warn("w Hello, world!")
        logger.error("e Hello, world!")
    }

}

