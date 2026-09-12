import Flutter
import UIKit
import UserNotifications

/// Public-API iOS bridge for the same method channel Android uses.
/// Does not use Family Controls, Managed Settings, or private APIs.
final class FgMethodChannelHandler: NSObject, FlutterPlugin {
  static let channelName = "com.comrade.android.methodchannel.fg"

  private let defaults = UserDefaults.standard
  private let usageKey = "comrade.ios.usageByDay"
  private let launchCountKey = "comrade.ios.launchCounts"
  private let shortsTimeKey = "comrade.ios.shortsTimeMs"
  private let restrictionsKey = "comrade.ios.appRestrictions"
  private let wellbeingKey = "comrade.ios.wellbeing"
  private let bedtimeKey = "comrade.ios.bedtime"
  private let pendingOpenPackageKey = "comrade.ios.pendingOpenPackage"
  private let focusUntilKey = "comrade.ios.focusUntil"
  private let emergencyUntilKey = "comrade.ios.emergencyUntil"

  private var pendingOpenStartedAt: Date?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = FgMethodChannelHandler()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.observeLifecycle()
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "FgMethodChannelHandler") else {
      return
    }
    register(with: registrar)
  }

  private func observeLifecycle() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appBecameActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
  }

  @objc private func appBecameActive() {
    finalizePendingOpenUsage()
    remindIfLimitsActive()
  }

  @objc private func appWillResignActive() {
    pendingOpenStartedAt = Date()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateLocale":
      result(true)
    case "updateExcludedApps":
      defaults.set(call.arguments as? String, forKey: "comrade.ios.excludedApps")
      result(true)
    case "getDeviceInfo":
      result(deviceInfo())
    case "getDeviceAppsInfo":
      result(IosAppCatalog.installedApps())
    case "getAppsUsageForInterval":
      result(usageForInterval(call.arguments))
    case "getAppsLaunchCount":
      result(defaults.dictionary(forKey: launchCountKey) ?? [:])
    case "getShortsScreenTimeMs":
      result(defaults.integer(forKey: shortsTimeKey))
    case "getNativeCrashLogs":
      result("[]")
    case "clearNativeCrashLogs":
      result(true)
    case "presentScreenTimePicker":
      result(false)
    case "updateAppRestrictions":
      defaults.set(call.arguments as? String, forKey: restrictionsKey)
      result(true)
    case "updateRestrictionsGroups":
      defaults.set(call.arguments as? String, forKey: "comrade.ios.restrictionGroups")
      result(true)
    case "updateInternetBlockedApps":
      defaults.set(call.arguments as? String, forKey: "comrade.ios.internetBlocked")
      result(true)
    case "updateWellBeingSettings":
      defaults.set(call.arguments as? String, forKey: wellbeingKey)
      result(true)
    case "updateBedtimeSchedule":
      defaults.set(call.arguments as? String, forKey: bedtimeKey)
      remindIfLimitsActive()
      result(true)
    case "updateNotificationSettings":
      defaults.set(call.arguments as? String, forKey: "comrade.ios.notificationSettings")
      result(true)
    case "updateFocusSession":
      startFocusSession(call.arguments as? String)
      result(true)
    case "giveUpOrFinishFocusSession":
      finishFocusSession()
      result(true)
    case "activeEmergencyPause":
      beginEmergencyPause()
      result(true)
    case "getAndAskNotificationPermission":
      notificationPermission(ask: boolArg(call), result: result)
    case "getAndAskUsageAccessPermission",
         "getAndAskAccessibilityPermission",
         "getAndAskVpnPermission",
         "getAndAskDisplayOverlayPermission",
         "getAndAskExactAlarmPermission",
         "getAndAskIgnoreBatteryOptimizationPermission",
         "getAndAskDndPermission":
      result(true)
    case "getAndAskAdminPermission",
         "getAndAskNotificationAccessPermission":
      result(false)
    case "disableDeviceAdmin":
      result(true)
    case "openDeviceDndSettings",
         "openAppSettingsForPackage":
      openSettings()
      result(true)
    case "openAutoStartSettings":
      result(false)
    case "openAppWithPackage":
      result(openApp(package: call.arguments as? String ?? ""))
    case "openAppWithNotificationThread":
      result(true)
    case "restartApp":
      result(true)
    case "parseHostFromUrl":
      result(Self.host(from: call.arguments as? String ?? ""))
    case "launchUrl":
      result(openUrlString(call.arguments as? String ?? ""))
    case "promptForQuickTile":
      result(false)
    default:
      result(false)
    }
  }

  private func deviceInfo() -> [String: Any] {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    return [
      "manufacturer": "Apple",
      "model": UIDevice.current.name,
      "androidVersion": UIDevice.current.systemVersion,
      "sdkVersion": 0,
      "comradeVersion": version,
    ]
  }

  private func boolArg(_ call: FlutterMethodCall) -> Bool {
    if let value = call.arguments as? Bool { return value }
    return false
  }

  private func notificationPermission(ask: Bool, result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      let granted = settings.authorizationStatus == .authorized
        || settings.authorizationStatus == .provisional
        || settings.authorizationStatus == .ephemeral
      if !ask {
        DispatchQueue.main.async { result(granted) }
        return
      }
      if settings.authorizationStatus == .notDetermined {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
          DispatchQueue.main.async { result(ok) }
        }
        return
      }
      if !granted {
        DispatchQueue.main.async {
          self.openSettings()
          result(false)
        }
        return
      }
      DispatchQueue.main.async { result(true) }
    }
  }

  private func openApp(package: String) -> Bool {
    incrementLaunchCount(package)
    defaults.set(package, forKey: pendingOpenPackageKey)
    pendingOpenStartedAt = Date()

    if package == "com.apple.Preferences" {
      openSettings()
      return true
    }

    if let timer = timerSeconds(for: package), timer > 0 {
      scheduleNotification(
        title: "Time limit reminder",
        body: "Your Comrade timer for this app is up.",
        after: TimeInterval(timer)
      )
    }

    if let scheme = IosAppCatalog.scheme(for: package),
       let url = URL(string: scheme),
       UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
      return true
    }
    return false
  }

  private func openUrlString(_ raw: String) -> Bool {
    guard let url = URL(string: raw), UIApplication.shared.canOpenURL(url) else {
      return false
    }
    UIApplication.shared.open(url)
    return true
  }

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  static func host(from raw: String) -> String {
    var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if !value.contains("://") {
      value = "https://\(value)"
    }
    return URL(string: value)?.host ?? ""
  }

  private func incrementLaunchCount(_ package: String) {
    var counts = defaults.dictionary(forKey: launchCountKey) as? [String: Int] ?? [:]
    counts[package] = (counts[package] ?? 0) + 1
    defaults.set(counts, forKey: launchCountKey)
  }

  private func finalizePendingOpenUsage() {
    guard let started = pendingOpenStartedAt,
          let package = defaults.string(forKey: pendingOpenPackageKey) else { return }
    let seconds = max(0, Int(Date().timeIntervalSince(started)))
    pendingOpenStartedAt = nil
    defaults.removeObject(forKey: pendingOpenPackageKey)
    guard seconds > 0 else { return }
    addUsage(package: package, seconds: seconds)
  }

  private func addUsage(package: String, seconds: Int) {
    let day = Self.dayStamp(Date())
    var root = defaults.dictionary(forKey: usageKey) as? [String: [String: Int]] ?? [:]
    var dayMap = root[day] ?? [:]
    dayMap[package] = (dayMap[package] ?? 0) + seconds
    root[day] = dayMap
    defaults.set(root, forKey: usageKey)
  }

  private func usageForInterval(_ arguments: Any?) -> [[String: Any]] {
    guard let map = arguments as? [String: Any],
          let startMs = map["startDateTime"] as? Int,
          let endMs = map["endDateTime"] as? Int else { return [] }
    let start = Date(timeIntervalSince1970: Double(startMs) / 1000)
    let end = Date(timeIntervalSince1970: Double(endMs) / 1000)
    let root = defaults.dictionary(forKey: usageKey) as? [String: [String: Int]] ?? [:]
    var totals: [String: Int] = [:]
    var cursor = Calendar.current.startOfDay(for: start)
    while cursor <= end {
      let stamp = Self.dayStamp(cursor)
      if let dayMap = root[stamp] {
        for (pkg, sec) in dayMap {
          totals[pkg] = (totals[pkg] ?? 0) + sec
        }
      }
      cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? end.addingTimeInterval(1)
    }
    return totals.map { package, seconds in
      [
        "packageName": package,
        "screenTime": seconds,
        "mobileData": 0,
        "wifiData": 0,
      ]
    }
  }

  private func timerSeconds(for package: String) -> Int? {
    guard let raw = defaults.string(forKey: restrictionsKey),
          let data = raw.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return nil
    }
    return json.first { $0["appPackage"] as? String == package }?["timerSec"] as? Int
  }

  private func beginEmergencyPause() {
    defaults.set(Date().timeIntervalSince1970 + 5 * 60, forKey: emergencyUntilKey)
    scheduleNotification(
      title: "Comrade",
      body: "Emergency pause is active. Reminders will resume when you turn limits back on.",
      after: 1
    )
  }

  private func startFocusSession(_ json: String?) {
    var duration = 25 * 60
    if let raw = json, let data = raw.data(using: .utf8),
       let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      duration = map["durationSeconds"] as? Int ?? duration
    }
    defaults.set(Date().timeIntervalSince1970 + Double(max(1, duration)), forKey: focusUntilKey)
    scheduleNotification(
      title: "Focus session complete",
      body: "Nice work. Your Comrade focus session has finished.",
      after: TimeInterval(max(1, duration)),
      identifier: "comrade.focus"
    )
  }

  private func finishFocusSession() {
    defaults.removeObject(forKey: focusUntilKey)
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["comrade.focus"]
    )
  }

  private func remindIfLimitsActive() {
    guard let raw = defaults.string(forKey: bedtimeKey),
          let data = raw.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          (json["isScheduleOn"] as? Bool) == true else { return }
    scheduleNotification(
      title: "Bedtime",
      body: "Your Comrade bedtime schedule is on. Stay off distracting apps until morning.",
      after: 1,
      identifier: "comrade.bedtime.active"
    )
  }

  private func scheduleNotification(
    title: String,
    body: String,
    after: TimeInterval,
    identifier: String? = nil
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, after), repeats: false)
    let request = UNNotificationRequest(
      identifier: identifier ?? "comrade.\(title).\(Int(Date().timeIntervalSince1970))",
      content: content,
      trigger: trigger
    )
    UNUserNotificationCenter.current().add(request)
  }

  static func dayStamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}

enum IosAppCatalog {
  struct Item {
    let name: String
    let bundleId: String
    let scheme: String
    let system: Bool
    let alwaysPresent: Bool
    let symbol: String
    let color: UIColor
  }

  static let items: [Item] = [
    Item(name: "Phone", bundleId: "com.apple.mobilephone", scheme: "tel://", system: true, alwaysPresent: true, symbol: "phone.fill", color: .systemGreen),
    Item(name: "Messages", bundleId: "com.apple.MobileSMS", scheme: "sms://", system: true, alwaysPresent: true, symbol: "message.fill", color: .systemGreen),
    Item(name: "Mail", bundleId: "com.apple.mobilemail", scheme: "mailto://", system: true, alwaysPresent: true, symbol: "envelope.fill", color: .systemBlue),
    Item(name: "Safari", bundleId: "com.apple.mobilesafari", scheme: "http://", system: false, alwaysPresent: true, symbol: "safari.fill", color: .systemBlue),
    Item(name: "Photos", bundleId: "com.apple.mobileslideshow", scheme: "photos-redirect://", system: false, alwaysPresent: true, symbol: "photo.fill", color: .systemOrange),
    Item(name: "Music", bundleId: "com.apple.Music", scheme: "music://", system: false, alwaysPresent: true, symbol: "music.note", color: .systemPink),
    Item(name: "Settings", bundleId: "com.apple.Preferences", scheme: "app-settings:", system: true, alwaysPresent: true, symbol: "gearshape.fill", color: .systemGray),
    Item(name: "App Store", bundleId: "com.apple.AppStore", scheme: "itms-apps://", system: true, alwaysPresent: true, symbol: "bag.fill", color: .systemBlue),
    Item(name: "Maps", bundleId: "com.apple.Maps", scheme: "maps://", system: false, alwaysPresent: true, symbol: "map.fill", color: .systemGreen),
    Item(name: "Calendar", bundleId: "com.apple.mobilecal", scheme: "calshow://", system: false, alwaysPresent: true, symbol: "calendar", color: .systemRed),
    Item(name: "FaceTime", bundleId: "com.apple.facetime", scheme: "facetime://", system: false, alwaysPresent: true, symbol: "video.fill", color: .systemGreen),
    Item(name: "Instagram", bundleId: "com.burbn.instagram", scheme: "instagram://", system: false, alwaysPresent: false, symbol: "camera.fill", color: .systemPurple),
    Item(name: "WhatsApp", bundleId: "net.whatsapp.WhatsApp", scheme: "whatsapp://", system: false, alwaysPresent: false, symbol: "phone.fill", color: .systemGreen),
    Item(name: "Telegram", bundleId: "ph.telegra.Telegraph", scheme: "tg://", system: false, alwaysPresent: false, symbol: "paperplane.fill", color: .systemBlue),
    Item(name: "Snapchat", bundleId: "com.toyopagroup.picaboo", scheme: "snapchat://", system: false, alwaysPresent: false, symbol: "bolt.fill", color: .systemYellow),
    Item(name: "YouTube", bundleId: "com.google.ios.youtube", scheme: "youtube://", system: false, alwaysPresent: false, symbol: "play.rectangle.fill", color: .systemRed),
    Item(name: "Facebook", bundleId: "com.facebook.Facebook", scheme: "fb://", system: false, alwaysPresent: false, symbol: "person.2.fill", color: .systemBlue),
    Item(name: "Messenger", bundleId: "com.facebook.Messenger", scheme: "fb-messenger://", system: false, alwaysPresent: false, symbol: "message.fill", color: .systemBlue),
    Item(name: "X", bundleId: "com.atebits.Tweetie2", scheme: "twitter://", system: false, alwaysPresent: false, symbol: "at", color: .black),
    Item(name: "TikTok", bundleId: "com.zhiliaoapp.musically", scheme: "tiktok://", system: false, alwaysPresent: false, symbol: "music.note", color: .black),
    Item(name: "Netflix", bundleId: "com.netflix.Netflix", scheme: "nflx://", system: false, alwaysPresent: false, symbol: "play.tv.fill", color: .systemRed),
    Item(name: "Spotify", bundleId: "com.spotify.client", scheme: "spotify://", system: false, alwaysPresent: false, symbol: "music.note.list", color: .systemGreen),
    Item(name: "Discord", bundleId: "com.hammerandchisel.discord", scheme: "discord://", system: false, alwaysPresent: false, symbol: "bubble.left.and.bubble.right.fill", color: .systemIndigo),
    Item(name: "LinkedIn", bundleId: "com.linkedin.LinkedIn", scheme: "linkedin://", system: false, alwaysPresent: false, symbol: "briefcase.fill", color: .systemBlue),
    Item(name: "Reddit", bundleId: "com.reddit.Reddit", scheme: "reddit://", system: false, alwaysPresent: false, symbol: "text.bubble.fill", color: .systemOrange),
    Item(name: "Chrome", bundleId: "com.google.chrome.ios", scheme: "googlechrome://", system: false, alwaysPresent: false, symbol: "globe", color: .systemGreen),
    Item(name: "Gmail", bundleId: "com.google.Gmail", scheme: "googlegmail://", system: false, alwaysPresent: false, symbol: "envelope.fill", color: .systemRed),
    Item(name: "Threads", bundleId: "com.burbn.barcelona", scheme: "barcelona://", system: false, alwaysPresent: false, symbol: "at", color: .black),
  ]

  static func scheme(for bundleId: String) -> String? {
    items.first { $0.bundleId == bundleId }?.scheme
  }

  static func installedApps() -> [[String: Any]] {
    items.compactMap { item in
      if !item.alwaysPresent {
        guard let url = URL(string: item.scheme), UIApplication.shared.canOpenURL(url) else {
          return nil
        }
      }
      return [
        "appName": item.name,
        "packageName": item.bundleId,
        "appIcon": iconBase64(symbol: item.symbol, color: item.color),
        "isImpSysApp": item.system,
      ]
    }
  }

  private static func iconBase64(symbol: String, color: UIColor) -> String {
    let size = CGSize(width: 128, height: 128)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
      color.setFill()
      UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 28).fill()
      let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .semibold)
      if let symbolImage = UIImage(systemName: symbol, withConfiguration: config)?
        .withTintColor(.white, renderingMode: .alwaysOriginal) {
        let side: CGFloat = 64
        let rect = CGRect(
          x: (size.width - side) / 2,
          y: (size.height - side) / 2,
          width: side,
          height: side
        )
        symbolImage.draw(in: rect)
      }
    }
    return image.pngData()?.base64EncodedString() ?? ""
  }
}
