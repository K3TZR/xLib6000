// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "xLib6000",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "xClient_macOS",
      targets: ["xClient_macOS"]),
    .library(
      name: "xClient_iOS",
      targets: ["xClient_iOS"]),
    .library(
      name: "xLib6000",
      targets: ["xLib6000"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "xClient_macOS",
      dependencies: ["xLib6000", "XCGLogger"]),
    .target(
      name: "xClient_iOS",
      dependencies: ["xLib6000", "XCGLogger"]),
    .target(
      name: "xLib6000",
      dependencies: ["CocoaAsyncSocket"]),
    .testTarget(
      name: "xLib6000Tests",
      dependencies: ["xLib6000"]),
  ]
)
