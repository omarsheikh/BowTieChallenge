//
//  BTDeviceTreeDisk.swift
//  BowtieChallenge
//
//  Created by Omar Sheikh on 6/9/24.
//

import TINUIORegistry
import Foundation

#if os(macOS)
public struct BTDeviceTreeDisk: DiskProtocol{
    ///The disk/partition BSD name, this object provvides useful methods to gather some extra info about this device.
    public var DeviceIdentifier: BSDID
    ///Let's you know if the current device/partition can be ejected.
    public let ejectable: Bool
    ///Let's you know if the current device/partition can be removed from the computer (aka hot swapped).
    public let removable: Bool
    ///Returns, if available, more info about the current device/partition, like the file system name.
    public let Content: String?
    ///The size in bytes of the current device/partition.
    public let Size: UInt64
    ///Let's you know if the current object is a whole disk (and so not a partition).
    public let whole: Bool
    ///Let's you know if the current disk/partition can be written on.
    public let writable: Bool
    ///Let's you know if the disk is encrypted.
    public let encrypted: Bool?
    ///Let's you know what encryption type.
    public let encryptionType: String?
    ///Let's you know if the disk is open.
    public let open: Bool
    ///The disk/partition UUID.
    public let uuid: UUID?
    ///The name (or tag, if available) of the current disk/partition.
    public let name: String?
    ///Let's you know if this disk/partition is a subdevice
    public let leaf: Bool
    
    private(set) var backupID: UUID? = UUID()
    
    ///This object's UUID to be used for the `Identifiable` protocol
    public var id: UUID{
        return uuid ?? backupID!
    }
    
    ///Returns a list of disks and partitions and relative info
    public static func simpleList() -> [Self]{
        let iterator = IORecursiveIterator()
        var disks = [Self]()
        
        while iterator.next(){
            guard let bsdNameString = iterator.entry?.getString("BSD Name") else{
                continue
            }
            
            guard BSDID.isValid(bsdNameString) else {
                continue
            }
            
            let bsdName = BSDID(bsdNameString)
            
            guard let ejectable = iterator.entry?.getBool("Ejectable"),
                  let removable = iterator.entry?.getBool("Removable"),
                  let content = iterator.entry?.getString("Content"),
                  let size: UInt64 = iterator.entry?.getInteger("Size"),
                  let whole = iterator.entry?.getBool("Whole"),
                  let open = iterator.entry?.getBool("Open"),
                  let writable = iterator.entry?.getBool("Writable"),
                  let leaf = iterator.entry?.getBool("Leaf")
            else{
                continue
            }
            
            let name = iterator.entry?.getString("FullName") ?? iterator.entry?.getName()
            let encrypted = iterator.entry?.getBool("Encrypted")
            let encryptionType = iterator.entry?.getString("EncryptionType")
            
            var uuid: UUID? = nil
            
            if let tuuid = iterator.entry?.getString("UUID"){
                uuid = UUID(uuidString: tuuid)
            }
            
            disks.append(.init(DeviceIdentifier: bsdName, ejectable: ejectable, removable: removable, Content: content, Size: size, whole: whole, writable: writable, encrypted: encrypted, encryptionType: encryptionType, open: open, uuid: uuid, name: name, leaf: leaf))
        }
        
        return disks.sorted(by: { ($0.DeviceIdentifier.driveNumber ?? 0 <= $1.DeviceIdentifier.driveNumber ?? 0) && ($0.DeviceIdentifier.partitionNumber ?? 0 <= $1.DeviceIdentifier.partitionNumber ?? 0) && ($0.DeviceIdentifier.driveNumbers().count <= $1.DeviceIdentifier.driveNumbers().count ) })
    }
}

@available(macOS 10.14, *) extension BTDeviceTreeDisk: Identifiable{
    
}

#endif
