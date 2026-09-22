// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_links", path: "../.packages/app_links-6.4.0"),
        .package(name: "file_picker", path: "../.packages/file_picker-10.2.0"),
        .package(name: "local_auth_darwin", path: "../.packages/local_auth_darwin-1.4.3"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.1"),
        .package(name: "sqlite3_flutter_libs", path: "../.packages/sqlite3_flutter_libs-0.5.34"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-links", package: "app_links"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "sqlite3-flutter-libs", package: "sqlite3_flutter_libs"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
