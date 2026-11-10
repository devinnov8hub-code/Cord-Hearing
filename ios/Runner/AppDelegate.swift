import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var pendingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerOtaFilePicker(messenger: controller.binaryMessenger)
    }
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerOtaFilePicker(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.cordhearingaid.app/ota_file_picker",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "pickFirmwareFile" {
        if self.pendingResult != nil {
          result(FlutterError(code: "BUSY", message: "File picker is already active", details: nil))
          return
        }
        self.pendingResult = result
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
          picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .item], asCopy: true)
        } else {
          picker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.item"], in: .import)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false
        self.window?.rootViewController?.present(picker, animated: true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let callback = pendingResult else { return }
    pendingResult = nil
    guard let url = urls.first else {
      callback(nil)
      return
    }
    do {
      let data = try Data(contentsOf: url)
      callback([
        "name": url.lastPathComponent,
        "bytes": FlutterStandardTypedData(bytes: data)
      ])
    } catch {
      callback(FlutterError(code: "READ_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    guard let callback = pendingResult else { return }
    pendingResult = nil
    callback(nil)
  }
}
