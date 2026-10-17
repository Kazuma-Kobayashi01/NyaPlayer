// Generates a toneless-pinyin reading for every CJK Unified Ideograph
// (U+4E00...U+9FFF) using macOS's Mandarin-Latin transform.
// Output: one line per character, "<codepoint-hex> <pinyin>", to stdout.
//   swift tool/gen_pinyin.swift > /tmp/pinyin.txt
//   python3 -I tool/build_pinyin_table.py /tmp/pinyin.txt > lib/core/pinyin_table.dart
import Foundation

func pinyin(_ s: String) -> String {
    let m = NSMutableString(string: s)
    CFStringTransform(m, nil, kCFStringTransformMandarinLatin, false)
    CFStringTransform(m, nil, kCFStringTransformStripDiacritics, false)
    return (m as String).lowercased().trimmingCharacters(in: .whitespaces)
}

if CommandLine.arguments.count > 1 {
    // Debug: print readings of the given strings.
    for a in CommandLine.arguments.dropFirst() { print(a, pinyin(a)) }
} else {
    for cp in 0x4E00...0x9FFF {
        guard let scalar = Unicode.Scalar(cp) else { continue }
        let ch = String(Character(scalar))
        let p = pinyin(ch)
        if p != ch && !p.isEmpty && p.allSatisfy({ $0.isASCII && $0.isLetter }) {
            print(String(cp, radix: 16), p)
        }
    }
}
