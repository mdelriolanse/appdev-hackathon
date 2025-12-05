// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Candid",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Candid", targets: ["Candid"])
    ],
    targets: [
        .target(name: "Candid")
    ]
)

