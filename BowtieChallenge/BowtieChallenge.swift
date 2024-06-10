//
//  main.swift
//  BowtieChallenge
//
//  Created by Omar Sheikh on 6/8/24.
//

import Foundation
import ArgumentParser
import AppKit
import BrowserAvailability
import TINUIORegistry
import Darwin

@main
struct BowtieChallenge: ParsableCommand {
    
    @Flag(name: .shortAndLong, help: "Print All Info.")
    var allInfo = false
    
    @Flag(name: .shortAndLong, help: "Print Disk Info.")
    var diskInfo = false

    @Flag(name: .shortAndLong, help: "Print Browser Info.")
    var browserInfo = false
    
    @Flag(name: .shortAndLong, help: "Print Operating System Info.")
    var OSInfo = false
    
    @Flag(name: .shortAndLong, help: "Print Processes Info.")
    var processesInfo = false
    
    mutating func run() throws {
        if CommandLine.arguments.count < 2 {
            print(Self.helpMessage())
        }
        
        if allInfo {
            diskInfo = true
            browserInfo = true
            OSInfo = true
            processesInfo = true
        }
        
        if diskInfo {
            retrieveDiskInfo()
        }
        if browserInfo {
            retrieveBrowserInfo()
        }
        if OSInfo {
            retrieveOSInfo()
        }
        if processesInfo {
            retrieveAllProcessesInfo()
        }
    }
    
    func retrieveOSInfo() {
        // For the operating system
        // What major/minor version number?
        let OSVersion: OperatingSystemVersion = ProcessInfo().operatingSystemVersion
        print("Operating System: \(OSVersion.majorVersion).\(OSVersion.minorVersion)_\(OSVersion.patchVersion)\n")
    }
    
    func retrieveDiskInfo() {
        // For every disk
        // Serial Number, Label, Filesystem Type & Encryption status (is it using OS encryption, and is it currently in accessible state?)
        // NOTE: THIS IS INCOMPLETE
        print("Disk Info:")
        retrieveaDiskSerialInfo() // NOTE: this may only work for NVMe controllers

        let list = BTDeviceTreeDisk.simpleList()

        for item in list {
            var printString = "BSD Name: \(item.DeviceIdentifier.rawValue)"
            if item.whole {
                if let content = item.Content {
                    printString.append(", Label: \(content)")
                }
            } else {
                if let uuid = item.uuid {
                    printString.append(", UUID: \(uuid)")
                }
            }
            if let encrypted = item.encrypted {
                printString.append(", Encrypted: \(encrypted)")
                if encrypted, let encryptionType = item.encryptionType {
                    printString.append(", EncryptionType: \(encryptionType)")
                    
                }
            } else {
                printString.append(", Encrypted: false")
            }
            printString.append(", Open: \(item.open), Writable: \(item.writable)")
            
//            print(item)
            print("    \(printString)")
        }
        print("")
    }
    
    func retrieveBrowserInfo() {
        // For every browser (ok to use an allow list of strings like chrome, edge, safari, brave, etc)
        // What is installed, what version is it
        print("Browsers Installed:")
        let bundles = NSWorkspace.shared.bundlesForBrowsers()
        for bundle in bundles {
            let dictionary = bundle.infoDictionary
            if let dictionary = dictionary,
               let version = dictionary["CFBundleVersion"]
            {
                print("    \(bundle.applicationName), v\(version), path: \"\(bundle.bundlePath)\"")
            }
        }
        print("")
    }
    
    func retrieveAllProcessesInfo() {
        // List of running processes and their location

        // Call proc_listallpids once with nil/0 args to get the current number of pids
        let initialNumPids = proc_listallpids(nil, 0)

        print("All Running Processes (Total: \(Int(initialNumPids))):")
        // Allocate a buffer of these number of pids.
        // Make sure to deallocate it as this class does not manage memory for us.
        let buffer = UnsafeMutablePointer<pid_t>.allocate(capacity: Int(initialNumPids))
        defer {
            buffer.deallocate()
        }

        // Calculate the buffer's total length in bytes
        let bufferLength = initialNumPids * Int32(MemoryLayout<pid_t>.size)

        // Call the function again with our inputs now ready
        let numPids = proc_listallpids(buffer, bufferLength)

        // Loop through each pid
        for i in 0..<numPids {

            let pid = buffer[Int(i)]
                        
            let pathBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
            defer {
                pathBuffer.deallocate()
            }
            let pathLength = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))
            if pathLength > 0 {
                let path = URL(fileURLWithPath: String(cString: pathBuffer))
                print("    \(pid): \(path.lastPathComponent), path=\(path.path())")
            }
        }
    }
    
    func retrieveaDiskSerialInfo() {
        var serialPortIterator = io_iterator_t()
        var object: io_object_t
        let port: mach_port_t
        if #available(macOS 12.0, *) {
            port = kIOMainPortDefault // New name in macOS 12 and higher
        } else {
            port = kIOMasterPortDefault // Old name in macOS 11 and lower
        }
//        IOEmbeddedNVMeBlockDevice
        let matchingDict : CFDictionary = IOServiceMatching("AppleANS3NVMeController")
        let kernResult = IOServiceGetMatchingServices(port, matchingDict, &serialPortIterator)

        if KERN_SUCCESS == kernResult {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                if object != 0, let serial = IORegistryEntryCreateCFProperty(object, "Serial Number" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String {
                    print("    Serial Number:", serial)
                }
                
            } while object != 0
            IOObjectRelease(object)
        }
        IOObjectRelease(serialPortIterator)
    }
}
    
extension Bundle {
    // Used for getting the names of the browsers installed
    var applicationName: String {

        if let displayName: String = self.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        } else if let name: String = self.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "No Name Found"
    }
}
