//! Repairs text from old MP3 tags (META-06).
//!
//! ID3 tags written before UTF-8 was common declare ISO-8859-1 but often hold
//! GBK or Shift-JIS bytes. The tag reader turns every byte into the character
//! of the same value, so such a title arrives as mojibake (`Ê®Äê`). Since that
//! mapping is lossless, the original bytes can be recovered and decoded again.

use encoding_rs::{Encoding, GBK, SHIFT_JIS};

/// Returns the repaired text, or `None` when `s` looks like it really is
/// Latin-1 (or plain ASCII, or genuine Unicode) and must be left alone.
pub(crate) fn repair_legacy_text(s: &str) -> Option<String> {
    // A character above U+00FF cannot come from a single byte: the tag was
    // already proper Unicode.
    let mut bytes = Vec::with_capacity(s.len());
    for c in s.chars() {
        bytes.push(u8::try_from(u32::from(c)).ok()?);
    }
    if bytes.is_ascii() {
        return None;
    }
    let all_high = bytes.iter().all(|b| *b >= 0x80);

    let sjis = decode_strict(SHIFT_JIS, &bytes);
    let gbk = decode_strict(GBK, &bytes);

    let chosen = match (sjis, gbk) {
        (None, None) => return None,
        (Some(j), None) => j,
        (None, Some(g)) => g,
        // Both decode. Full-width kana only appear in real Japanese; GBK text
        // read as Shift-JIS turns into half-width katakana or kanji noise.
        // Kanji-only text is ambiguous: everyday Chinese lies in the GB2312
        // block of GBK, Japanese kanji in Shift-JIS mostly does not.
        (Some(j), Some(g)) => {
            if has_kana(&j) && !has_halfwidth_katakana(&j) {
                j
            } else if looks_like_gb2312(&bytes) {
                g
            } else {
                j
            }
        }
    };

    // "Señor" is a high byte followed by an ASCII letter, which also happens
    // to be a valid GBK pair. Real legacy text has several CJK characters, or
    // is nothing but high bytes.
    let cjk = chosen.chars().filter(|c| is_cjk_or_kana(*c)).count();
    if cjk >= 2 || (all_high && cjk >= 1) {
        Some(chosen)
    } else {
        None
    }
}

/// True if every high byte pair lies in GB2312's range (lead 0xA1-0xF7, trail
/// 0xA1-0xFE), where simplified Chinese text is.
fn looks_like_gb2312(bytes: &[u8]) -> bool {
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] < 0x80 {
            i += 1;
            continue;
        }
        match bytes.get(i..i + 2) {
            Some([0xA1..=0xF7, 0xA1..=0xFE]) => i += 2,
            _ => return false,
        }
    }
    true
}

/// Decodes without any replacement character, control character or
/// private-use character; those mean the guess was wrong.
fn decode_strict(encoding: &'static Encoding, bytes: &[u8]) -> Option<String> {
    let (text, _, had_errors) = encoding.decode(bytes);
    if had_errors
        || text
            .chars()
            .any(|c| c == '\u{FFFD}' || is_stray_control(c) || is_private_use(c))
    {
        return None;
    }
    Some(text.into_owned())
}

/// Line breaks and tabs are normal in lyrics; other controls are not.
fn is_stray_control(c: char) -> bool {
    c.is_control() && !matches!(c, '\n' | '\r' | '\t')
}

fn is_private_use(c: char) -> bool {
    matches!(u32::from(c), 0xE000..=0xF8FF)
}

fn is_cjk_or_kana(c: char) -> bool {
    matches!(
        u32::from(c),
        0x3040..=0x30FF   // hiragana, katakana
        | 0x3400..=0x4DBF // extension A
        | 0x4E00..=0x9FFF // unified ideographs
        | 0xF900..=0xFAFF // compatibility ideographs
        | 0x20000..=0x2FFFF
    )
}

fn has_kana(s: &str) -> bool {
    s.chars().any(|c| matches!(u32::from(c), 0x3041..=0x30FF))
}

fn has_halfwidth_katakana(s: &str) -> bool {
    s.chars().any(|c| matches!(u32::from(c), 0xFF61..=0xFF9F))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// What the tag reader hands over for `legacy` bytes declared as Latin-1.
    fn as_latin1(bytes: &[u8]) -> String {
        bytes.iter().map(|b| char::from(*b)).collect()
    }

    fn encode(encoding: &'static Encoding, text: &str) -> String {
        let (bytes, _, unmappable) = encoding.encode(text);
        assert!(!unmappable, "{text} is not representable");
        as_latin1(&bytes)
    }

    #[test]
    fn gbk_text_is_recovered() {
        for original in ["十年", "陈奕迅", "我们的歌", "Love Story 十年", "歌"] {
            assert_eq!(
                repair_legacy_text(&encode(GBK, original)).as_deref(),
                Some(original),
                "{original}"
            );
        }
    }

    #[test]
    fn shift_jis_text_is_recovered() {
        for original in ["打上花火", "ありがとう", "米津玄師", "Lemon - 米津玄師"]
        {
            assert_eq!(
                repair_legacy_text(&encode(SHIFT_JIS, original)).as_deref(),
                Some(original),
                "{original}"
            );
        }
    }

    #[test]
    fn kana_decides_for_shift_jis_and_halfwidth_noise_for_gbk() {
        // Without kana both decoders accept the bytes; Chinese wins.
        let chinese = encode(GBK, "我们的歌");
        assert_eq!(repair_legacy_text(&chinese).as_deref(), Some("我们的歌"));
        let japanese = encode(SHIFT_JIS, "ありがとう");
        assert_eq!(repair_legacy_text(&japanese).as_deref(), Some("ありがとう"));
    }

    #[test]
    fn genuine_text_is_left_alone() {
        for s in [
            "",
            "Plain ASCII",
            // Unicode that cannot be a byte string.
            "打上花火",
            "Привет",
            // Real Latin-1 text.
            "Café Del Mar",
            "Señor",
            "Ünlü",
            "Ñandú",
            "Beyoncé - Halo",
            "Sigur Rós",
        ] {
            assert_eq!(repair_legacy_text(s), None, "{s}");
        }
    }

    #[test]
    fn mojibake_that_would_not_decode_is_left_alone() {
        // A lone lead byte at the end is not valid in either encoding.
        assert_eq!(repair_legacy_text(&as_latin1(&[0x41, 0xCA])), None);
    }
}
