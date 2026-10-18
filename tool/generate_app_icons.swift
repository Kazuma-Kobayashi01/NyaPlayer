// Rebuild every platform icon from the same flat vector geometry.
// Run: swift tool/generate_app_icons.swift [repository-root]
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct IconLayer: Decodable { let name: String; let path: String }
struct IconDesign: Decodable {
  let name: String
  let canvas: Int
  let foreground: String
  let background: String
  let darkForeground: String
  let darkBackground: String
  let androidScale: Double
  let layers: [IconLayer]
}

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let design = try JSONDecoder().decode(IconDesign.self, from: Data(contentsOf: root.appendingPathComponent("assets/branding/icon_geometry.json")))
let files = FileManager.default
func write(_ text: String, _ relativePath: String) throws {
  let url = root.appendingPathComponent(relativePath)
  try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try text.write(to: url, atomically: true, encoding: .utf8)
}
func svg(_ layers: [IconLayer], color: String) -> String {
  let paths = layers.map { "<path d=\"\($0.path)\"/>" }.joined(separator: "\n")
  return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\"><g fill=\"\(color)\">\(paths)</g></svg>\n"
}
func rgba(_ hex: String) -> [CGFloat] {
  let value = Int(hex.dropFirst(), radix: 16)!
  return [CGFloat((value >> 16) & 255) / 255, CGFloat((value >> 8) & 255) / 255, CGFloat(value & 255) / 255, 1]
}
func cgColor(_ hex: String) -> CGColor { CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: rgba(hex))! }
func serializedColor(_ hex: String) -> String { "srgb:" + rgba(hex).map { String(format: "%.5f", Double($0)) }.joined(separator: ",") }

// The source intentionally uses only M/L/Q/C/Z, shared verbatim with SVG and
// Android VectorDrawable. No raster tracing, fonts, effects or dependencies.
func path(_ source: String) -> CGPath {
  let expression = try! NSRegularExpression(pattern: "[MLQCZ]|-?[0-9]+(?:\\.[0-9]+)?")
  let range = NSRange(source.startIndex..., in: source)
  let tokens = expression.matches(in: source, range: range).map { String(source[Range($0.range, in: source)!]) }
  let result = CGMutablePath()
  var index = 0
  func number() -> CGFloat { defer { index += 1 }; return CGFloat(Double(tokens[index])!) }
  func point() -> CGPoint { CGPoint(x: number(), y: number()) }
  while index < tokens.count {
    let command = tokens[index]; index += 1
    switch command {
    case "M": result.move(to: point())
    case "L": result.addLine(to: point())
    case "Q": let control = point(); result.addQuadCurve(to: point(), control: control)
    case "C": let first = point(); let second = point(); result.addCurve(to: point(), control1: first, control2: second)
    case "Z": result.closeSubpath()
    default: fatalError("Unsupported icon geometry command: \(command)")
    }
  }
  return result
}
let artwork = design.layers.map { path($0.path) }

enum IconMask { case mac, android, circle, none }
func render(size: Int, foreground: String, background: String?, mask: IconMask, markScale: Double = 1) throws -> CGImage {
  let space = CGColorSpace(name: CGColorSpace.sRGB)!
  guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
  else { throw NSError(domain: "NyaPlayer.Icon", code: 1) }
  context.translateBy(x: 0, y: CGFloat(size))
  context.scaleBy(x: CGFloat(size) / 1024, y: -CGFloat(size) / 1024)
  if let background {
    let enclosure: CGPath
    switch mask {
    case .mac: enclosure = CGPath(roundedRect: CGRect(x: 96, y: 96, width: 832, height: 832), cornerWidth: 186, cornerHeight: 186, transform: nil)
    case .circle: enclosure = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 1024, height: 1024), transform: nil)
    case .android: enclosure = CGPath(roundedRect: CGRect(x: 0, y: 0, width: 1024, height: 1024), cornerWidth: 224, cornerHeight: 224, transform: nil)
    case .none: enclosure = CGPath(rect: CGRect(x: 0, y: 0, width: 1024, height: 1024), transform: nil)
    }
    context.addPath(enclosure); context.setFillColor(cgColor(background)); context.fillPath()
  }
  context.translateBy(x: 512, y: 512); context.scaleBy(x: markScale, y: markScale); context.translateBy(x: -512, y: -512)
  context.setFillColor(cgColor(foreground))
  for shape in artwork { context.addPath(shape); context.fillPath() }
  return context.makeImage()!
}
func png(_ image: CGImage, _ relativePath: String) throws {
  let url = root.appendingPathComponent(relativePath)
  try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, image, nil)
  guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "NyaPlayer.Icon", code: 2) }
}

try write(svg(design.layers, color: design.foreground), "assets/branding/nyaplayer.svg")
let nativeAssets = root.appendingPathComponent("macos/Runner/NyaPlayerIcon.icon/Assets")
let activeAssets = Set(design.layers.map { "\($0.name).svg" })
if files.fileExists(atPath: nativeAssets.path) {
  for asset in try files.contentsOfDirectory(at: nativeAssets, includingPropertiesForKeys: nil)
    where asset.pathExtension == "svg" && !activeAssets.contains(asset.lastPathComponent) {
    try files.removeItem(at: asset)
  }
}
for layer in design.layers {
  try write(svg([layer], color: design.foreground), "macos/Runner/NyaPlayerIcon.icon/Assets/\(layer.name).svg")
}
let appearances: [[String: Any]] = [
  ["value": ["solid": serializedColor(design.foreground)]],
  ["appearance": "dark", "value": ["solid": serializedColor(design.darkForeground)]],
  ["appearance": "tinted", "value": ["solid": "extended-gray:1.00000,1.00000"]],
]
let composition: [String: Any] = [
  "fill-specializations": [
    ["value": ["solid": serializedColor(design.background)]],
    ["appearance": "dark", "value": ["solid": serializedColor(design.darkBackground)]],
    ["appearance": "tinted", "value": "automatic"],
  ],
  "groups": [[
    "name": "NyaPlayer flat mark",
    "layers": design.layers.map { [
      "name": $0.name, "image-name": "\($0.name).svg", "glass": false,
      "fill-specializations": appearances,
    ] as [String: Any] },
    "lighting": "combined", "specular": false,
    "shadow": ["kind": "none", "opacity": 0],
    "translucency": ["enabled": false, "value": 0],
  ]],
  "supported-platforms": ["squares": "shared"],
]
let json = try JSONSerialization.data(withJSONObject: composition, options: [.prettyPrinted, .sortedKeys])
try write(String(decoding: json, as: UTF8.self) + "\n", "macos/Runner/NyaPlayerIcon.icon/icon.json")

for size in [16, 32, 64, 128, 256, 512, 1024] {
  try png(render(size: size, foreground: design.foreground, background: design.background, mask: .mac),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_\(size).png")
}
try png(render(size: 1024, foreground: design.foreground, background: nil, mask: .none), "assets/branding/nyaplayer-foreground.png")
try png(render(size: 1024, foreground: design.foreground, background: design.background, mask: .none), "assets/branding/nyaplayer-1024.png")
for (density, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
  try png(render(size: size, foreground: design.foreground, background: design.background, mask: .android, markScale: design.androidScale),
    "android/app/src/main/res/mipmap-\(density)/ic_launcher.png")
}
let androidPaths = design.layers.map { "    <path android:fillColor=\"\(design.foreground)\" android:pathData=\"\($0.path)\"/>" }.joined(separator: "\n")
let monoPaths = design.layers.map { "    <path android:fillColor=\"#FF000000\" android:pathData=\"\($0.path)\"/>" }.joined(separator: "\n")
func vector(_ paths: String) -> String {
  """
  <vector xmlns:android="http://schemas.android.com/apk/res/android"
      android:width="108dp" android:height="108dp" android:viewportWidth="1024" android:viewportHeight="1024">
    <group android:pivotX="512" android:pivotY="512" android:scaleX="\(design.androidScale)" android:scaleY="\(design.androidScale)">
  \(paths)
    </group>
  </vector>

  """
}
try write(vector(androidPaths), "android/app/src/main/res/drawable/ic_launcher_foreground.xml")
try write(vector(monoPaths), "android/app/src/main/res/drawable/ic_launcher_monochrome.xml")
try write("""
<resources>
    <color name="ic_launcher_background">\(design.background)</color>
</resources>

""", "android/app/src/main/res/values/icon_colors.xml")
try write("""
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>

""", "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml")
try write("""
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>

""", "android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml")

// Verify the foreground fits Android's circular 66dp safe zone (108dp canvas).
let androidImage = try render(size: 1024, foreground: "#FFFFFF", background: nil, mask: .none, markScale: design.androidScale)
let bytes = CFDataGetBytePtr(androidImage.dataProvider!.data!)!
let safeRadius = 1024.0 * 33 / 108
var bounds = CGRect.null
for y in 0..<1024 {
  for x in 0..<1024 where bytes[y * androidImage.bytesPerRow + x * 4 + 3] > 127 {
    let radius = hypot(Double(x) + 0.5 - 512, Double(y) + 0.5 - 512)
    precondition(radius <= safeRadius, "Logo exceeds Android adaptive-icon safe zone")
    bounds = bounds.union(CGRect(x: x, y: y, width: 1, height: 1))
  }
}
print("Android safe-zone verified; mark \(String(format: "%.1f", bounds.width * 108 / 1024))×\(String(format: "%.1f", bounds.height * 108 / 1024))dp")
let previews = [
  ("mac-light", design.foreground, design.background, IconMask.mac, 1.0),
  ("mac-dark", design.darkForeground, design.darkBackground, IconMask.mac, 1.0),
  ("android-round", design.foreground, design.background, IconMask.circle, design.androidScale),
  ("android-square", design.foreground, design.background, IconMask.android, design.androidScale),
  ("themed-mint", "#214E40", "#CDEDDD", IconMask.circle, design.androidScale),
  ("themed-lilac", "#D0BCFF", "#33264A", IconMask.android, design.androidScale),
]
for (name, foreground, background, mask, scale) in previews {
  try png(render(size: 512, foreground: foreground, background: background, mask: mask, markScale: scale), "build/icon_previews/\(name).png")
}
print("Generated NyaPlayer platform icons, source layers and previews.")
