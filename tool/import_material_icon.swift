// Extract the exact Flutter Icons.music_note outline without redrawing it.
// swift tool/import_material_icon.swift /path/to/MaterialIcons-Regular.otf
import Foundation
import CoreGraphics
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard CommandLine.arguments.count == 2 else {
  fatalError("Pass Flutter's bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf")
}
let fontURL = URL(fileURLWithPath: CommandLine.arguments[1])
let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
let font = CTFontCreateWithFontDescriptor(descriptors[0], 24, nil)
var character: UniChar = 0xe415 // Flutter material/icons.dart: Icons.music_note.
var glyph: CGGlyph = 0
precondition(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1), "Missing music_note glyph")
guard let outline = CTFontCreatePathForGlyph(font, glyph, nil) else { fatalError("Missing outline") }

func svgPath(_ path: CGPath) -> String {
  var commands: [String] = []
  func point(_ p: CGPoint) -> String {
    String(format: "%.5f %.5f", Double(p.x), Double(p.y))
  }
  path.applyWithBlock { pointer in
    let e = pointer.pointee
    switch e.type {
    case .moveToPoint: commands.append("M " + point(e.points[0]))
    case .addLineToPoint: commands.append("L " + point(e.points[0]))
    case .addQuadCurveToPoint: commands.append("Q " + point(e.points[0]) + " " + point(e.points[1]))
    case .addCurveToPoint: commands.append("C " + point(e.points[0]) + " " + point(e.points[1]) + " " + point(e.points[2]))
    case .closeSubpath: commands.append("Z")
    @unknown default: fatalError("Unsupported glyph path")
    }
  }
  return commands.joined(separator: " ")
}

var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 24)
let source = outline.copy(using: &flip)!
let bounds = source.boundingBoxOfPath
// Center the actual artwork bounds; preserve the standard glyph proportions.
let scale = 608 / bounds.height
var placement = CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
  tx: 512 - bounds.midX * scale, ty: 512 - bounds.midY * scale)
let placed = source.copy(using: &placement)!
let geometryURL = root.appendingPathComponent("assets/branding/icon_geometry.json")
var geometry = try JSONSerialization.jsonObject(with: Data(contentsOf: geometryURL)) as! [String: Any]
geometry["source"] = "Flutter MaterialIcons-Regular.otf / Icons.music_note (U+E415)"
geometry["layers"] = [["name": "01-material-music-note", "path": svgPath(placed)]]
let json = try JSONSerialization.data(withJSONObject: geometry, options: [.prettyPrinted, .sortedKeys])
try (String(decoding: json, as: UTF8.self) + "\n").write(to: geometryURL, atomically: true, encoding: .utf8)
let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><path d=\"\(svgPath(source))\"/></svg>\n"
try svg.write(to: root.appendingPathComponent("assets/branding/material_music_note.svg"), atomically: true, encoding: .utf8)
try Data(contentsOf: fontURL.deletingLastPathComponent().appendingPathComponent("MaterialIcons_LICENSE.txt"))
  .write(to: root.appendingPathComponent("assets/branding/MaterialIcons_LICENSE.txt"))
print("Imported Flutter Icons.music_note U+E415, original 24px bounds: \(bounds)")
