import Flutter
import UIKit

public class SwiftDiskSpacePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "disk_space", binaryMessenger: registrar.messenger())
    let instance = SwiftDiskSpacePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getFreeDiskSpace":
      result(UIDevice.current.freeDiskSpaceInMB)
    case "getTotalDiskSpace":
      result(UIDevice.current.totalDiskSpaceInMB)
    case "getFreeDiskSpaceForPath":
      if let args = call.arguments as? [String: Any],
         let path = args["path"] as? String {
        result(UIDevice.current.freeDiskSpaceForPathInMB(path: path))
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension UIDevice {
  var totalDiskSpaceInMB: Double {
    return Double(totalDiskSpaceInBytes) / (1024 * 1024)
  }

  var freeDiskSpaceInMB: Double {
    return Double(freeDiskSpaceInBytes) / (1024 * 1024)
  }

  var usedDiskSpaceInMB: Double {
    return Double(usedDiskSpaceInBytes) / (1024 * 1024)
  }

  func freeDiskSpaceForPathInMB(path: String) -> Double {
    return Double(freeDiskSpaceForPathInBytes(path: path)) / (1024 * 1024)
  }

  // MARK: - Raw Disk Space Values
  var totalDiskSpaceInBytes: Int64 {
    guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
          let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else {
      return 0
    }
    return space
  }

  var freeDiskSpaceInBytes: Int64 {
    if #available(iOS 11.0, *) {
      if let space = try? URL(fileURLWithPath: NSHomeDirectory())
                      .resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey])
                      .volumeAvailableCapacityForImportantUsage {
        return space ?? 0
      } else {
        return 0
      }
    } else {
      if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
         let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
        return freeSpace
      } else {
        return 0
      }
    }
  }

  var usedDiskSpaceInBytes: Int64 {
    return totalDiskSpaceInBytes - freeDiskSpaceInBytes
  }

  func freeDiskSpaceForPathInBytes(path: String) -> Int64 {
    if #available(iOS 11.0, *) {
      if let space = try? URL(fileURLWithPath: path)
                      .resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey])
                      .volumeAvailableCapacityForImportantUsage {
        return space ?? 0
      } else {
        return 0
      }
    } else {
      if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
         let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
        return freeSpace
      } else {
        return 0
      }
    }
  }
}
