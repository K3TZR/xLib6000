// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "xLib6000",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "xLibClient",
      targets: ["xLibClient"]),
    .library(
      name: "xLib6000",
      targets: ["xLib6000"]),
    .library(
      name: "CocoaAsyncSocket",
      targets: ["CocoaAsyncSocket"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "xLibClient",
      dependencies: ["xLib6000"]),
    .target(
      name: "xLib6000",
      dependencies: ["CocoaAsyncSocket"]),
    .target(
      name: "CocoaAsyncSocket",
      dependencies: []),
    .testTarget(
      name: "xLib6000Tests",
      dependencies: ["xLib6000"]),
  ]
)
