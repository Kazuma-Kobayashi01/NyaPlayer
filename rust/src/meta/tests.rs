//! Fixtures are produced at test time in a temp dir:
//! * FLAC: `tests/fixtures/sine_44k_16bit_mono.flac.bin` (committed with a
//!   `.bin` suffix because the repo gitignores `*.flac`; regenerate
//!   with the ignored `regenerate_flac_fixture` test, which needs macOS
//!   `afconvert`) copied and tagged with lofty.
//! * MP3: silent MPEG-1 Layer III frames written byte by byte, tagged with
//!   lofty.

use super::*;
use crate::api::meta as api;

use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};

use lofty::config::WriteOptions;
use lofty::id3::v2::{BinaryFrame, FrameId, TextInformationFrame, UnsynchronizedTextFrame};
use lofty::ogg::tag::VorbisComments;
use lofty::ogg::OggPictureStorage;
use lofty::picture::{MimeType, PictureInformation};
use lofty::tag::TagExt;
use lofty::TextEncoding;

const FLAC_FIXTURE: &str = concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/tests/fixtures/sine_44k_16bit_mono.flac.bin"
);

/// 1x1 PNG.
const PNG_FRONT: &[u8] = &[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
];

/// Same PNG with one trailing byte so the two covers are distinguishable.
fn png_back() -> Vec<u8> {
    let mut v = PNG_FRONT.to_vec();
    v.push(0xBB);
    v
}

fn tmp_path(name: &str) -> PathBuf {
    static N: AtomicUsize = AtomicUsize::new(0);
    let dir = std::env::temp_dir().join(format!(
        "nya_core_meta_{}_{}",
        std::process::id(),
        N.fetch_add(1, Ordering::Relaxed)
    ));
    std::fs::create_dir_all(&dir).unwrap();
    dir.join(name)
}

fn s(p: &Path) -> String {
    p.to_string_lossy().into_owned()
}

fn picture(ty: PictureType, data: Vec<u8>) -> Picture {
    Picture::unchecked(data)
        .pic_type(ty)
        .mime_type(MimeType::Png)
        .build()
}

// ---------------------------------------------------------------------------
// Fixture builders
// ---------------------------------------------------------------------------

/// Copies the base FLAC and writes the given Vorbis comments and pictures.
fn make_flac(name: &str, comments: &[(&str, &str)], pictures: Vec<Picture>) -> PathBuf {
    let path = tmp_path(name);
    std::fs::copy(FLAC_FIXTURE, &path).expect("FLAC fixture missing");
    let mut f = File::open(&path).unwrap();
    let mut flac = FlacFile::read_from(&mut f, ParseOptions::new()).unwrap();
    drop(f);
    let mut vc = VorbisComments::default();
    for (k, v) in comments {
        vc.push(k.to_string(), v.to_string());
    }
    flac.set_vorbis_comments(vc);
    for p in pictures {
        flac.insert_picture(p, Some(PictureInformation::default()))
            .unwrap();
    }
    flac.save_to_path(&path, WriteOptions::default()).unwrap();
    path
}

/// A few silent MPEG-1 Layer III frames (128 kbps, 44.1 kHz, stereo).
fn raw_mp3(frames: usize) -> Vec<u8> {
    // FF FB: sync, MPEG-1, Layer III, no CRC; 0x90: 128 kbps, 44.1 kHz, no
    // padding; 0x00: stereo. Frame length = 144 * 128000 / 44100 = 417.
    const LEN: usize = 417;
    let mut out = Vec::with_capacity(frames * LEN);
    for _ in 0..frames {
        let mut fr = vec![0u8; LEN];
        fr[..4].copy_from_slice(&[0xFF, 0xFB, 0x90, 0x00]);
        out.extend(fr);
    }
    out
}

fn make_mp3(name: &str, tag: Option<Id3v2Tag>) -> PathBuf {
    let path = tmp_path(name);
    std::fs::write(&path, raw_mp3(60)).unwrap();
    if let Some(tag) = tag {
        tag.save_to_path(&path, WriteOptions::default()).unwrap();
    }
    path
}

fn text_frame(id: &'static str, v: &str) -> Frame<'static> {
    Frame::Text(TextInformationFrame::new(
        FrameId::Valid(Cow::Borrowed(id)),
        TextEncoding::UTF8,
        v.to_string(),
    ))
}

fn uslt(desc: &str, text: &str) -> Frame<'static> {
    Frame::UnsynchronizedText(UnsynchronizedTextFrame::new(
        TextEncoding::UTF8,
        *b"jpn",
        desc.to_string(),
        text.to_string(),
    ))
}

fn sylt_frame(format: TimestampFormat, content: Vec<(u32, String)>) -> Frame<'static> {
    let sylt = SynchronizedTextFrame::new(
        TextEncoding::UTF8,
        *b"jpn",
        format,
        SyncTextContentType::Lyrics,
        None,
        content,
    );
    let bytes = sylt.as_bytes(WriteOptions::default()).unwrap();
    Frame::Binary(BinaryFrame::new(
        FrameId::Valid(Cow::Borrowed("SYLT")),
        bytes,
    ))
}

// ---------------------------------------------------------------------------
// FLAC
// ---------------------------------------------------------------------------

#[test]
fn flac_cjk_tags_and_properties() {
    let path = make_flac(
        "cjk.flac",
        &[
            ("TITLE", "  晴天  "),
            ("ARTIST", "周杰倫"),
            ("ALBUMARTIST", "宇多田ヒカル"),
            ("ALBUM", "初恋 / はつこい"),
            ("TRACKNUMBER", "3/12"),
            ("DISCNUMBER", "02"),
            ("DATE", "2018-06-27"),
            ("GENRE", "   "),
        ],
        vec![],
    );
    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.title.as_deref(), Some("晴天"));
    assert_eq!(m.artist.as_deref(), Some("周杰倫"));
    assert_eq!(m.album_artist.as_deref(), Some("宇多田ヒカル"));
    assert_eq!(m.album.as_deref(), Some("初恋 / はつこい"));
    assert_eq!(m.track_no, Some(3));
    assert_eq!(m.disc_no, Some(2));
    assert_eq!(m.year, Some(2018));
    assert_eq!(m.genre, None, "blank values become None");
    assert_eq!(m.codec, "FLAC");
    assert_eq!(m.sample_rate, Some(44100));
    assert_eq!(m.bit_depth, Some(16));
    assert_eq!(m.channels, Some(1));
    assert!(
        (200..=300).contains(&m.duration_ms),
        "duration {}",
        m.duration_ms
    );
    assert!(m.bitrate_kbps.is_some());
    assert_eq!(m.lyrics, None);
    assert!(!m.has_cover);
    assert_eq!(api::read_cover(s(&path)).unwrap(), None);
}

#[test]
fn flac_lyrics_priority() {
    let both = make_flac(
        "both.flac",
        &[
            ("UNSYNCEDLYRICS", "unsynced text"),
            ("LYRICS", "[00:01.00]歌詞\r\n[00:02.50]二行目\r\n"),
        ],
        vec![],
    );
    let m = api::read_metadata(s(&both)).unwrap();
    assert_eq!(
        m.lyrics.as_deref(),
        Some("[00:01.00]歌詞\n[00:02.50]二行目\n")
    );

    let only_unsynced = make_flac(
        "unsynced.flac",
        &[("LYRICS", "  "), ("UNSYNCEDLYRICS", "line b\nline a")],
        vec![],
    );
    let m = api::read_metadata(s(&only_unsynced)).unwrap();
    assert_eq!(m.lyrics.as_deref(), Some("line b\nline a"), "not reordered");
}

#[test]
fn flac_front_cover_preferred() {
    let path = make_flac(
        "cover.flac",
        &[("TITLE", "x")],
        vec![
            picture(PictureType::CoverBack, png_back()),
            picture(PictureType::CoverFront, PNG_FRONT.to_vec()),
        ],
    );
    let m = api::read_metadata(s(&path)).unwrap();
    assert!(m.has_cover);
    assert_eq!(
        api::read_cover(s(&path)).unwrap().as_deref(),
        Some(PNG_FRONT)
    );

    let back_only = make_flac(
        "back.flac",
        &[],
        vec![picture(PictureType::Other, png_back())],
    );
    assert!(api::read_metadata(s(&back_only)).unwrap().has_cover);
    assert_eq!(api::read_cover(s(&back_only)).unwrap(), Some(png_back()));
}

// ---------------------------------------------------------------------------
// MP3
// ---------------------------------------------------------------------------

#[test]
fn raw_mp3_is_accepted_by_lofty() {
    let path = make_mp3("plain.mp3", None);
    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.codec, "MP3");
    assert_eq!(m.sample_rate, Some(44100));
    assert_eq!(m.channels, Some(2));
    assert_eq!(m.bitrate_kbps, Some(128));
    assert_eq!(m.bit_depth, None);
    // 60 frames * 1152 samples / 44100 Hz ~= 1567 ms
    assert!(
        (1400..=1700).contains(&m.duration_ms),
        "duration {}",
        m.duration_ms
    );
    assert_eq!(m.title, None);
    assert!(!m.has_cover);
    assert_eq!(api::read_cover(s(&path)).unwrap(), None);
}

#[test]
fn mp3_cjk_tags_and_uslt_with_timestamps_preferred() {
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "残酷な天使のテーゼ"));
    tag.insert(text_frame("TPE1", "高橋洋子"));
    tag.insert(text_frame("TPE2", "王菲"));
    tag.insert(text_frame("TALB", "新世紀エヴァンゲリオン"));
    tag.insert(text_frame("TRCK", "7/10"));
    tag.insert(text_frame("TPOS", "1/2"));
    tag.insert(text_frame("TDRC", "1995"));
    tag.insert(text_frame("TCON", "Anime"));
    tag.insert(uslt("plain", "ただの歌詞\r\n二行目"));
    tag.insert(uslt(
        "lrc",
        "[00:10.20]残酷な天使のように\r\n[00:05.00]少年よ",
    ));
    let path = make_mp3("tags.mp3", Some(tag));

    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.title.as_deref(), Some("残酷な天使のテーゼ"));
    assert_eq!(m.artist.as_deref(), Some("高橋洋子"));
    assert_eq!(m.album_artist.as_deref(), Some("王菲"));
    assert_eq!(m.album.as_deref(), Some("新世紀エヴァンゲリオン"));
    assert_eq!(m.track_no, Some(7));
    assert_eq!(m.disc_no, Some(1));
    assert_eq!(m.year, Some(1995));
    assert_eq!(m.genre.as_deref(), Some("Anime"));
    assert_eq!(
        m.lyrics.as_deref(),
        Some("[00:10.20]残酷な天使のように\n[00:05.00]少年よ"),
        "USLT with timestamps wins; lines kept in original order"
    );

    // Without a timestamped USLT the first one is used.
    let mut tag = Id3v2Tag::new();
    tag.insert(uslt("a", "first"));
    tag.insert(uslt("b", "second"));
    let path = make_mp3("uslt_plain.mp3", Some(tag));
    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.lyrics.as_deref(), Some("first"));
}

/// What a legacy tagger wrote: `text` in `encoding`, declared as Latin-1.
fn legacy_bytes(encoding: &'static encoding_rs::Encoding, text: &str) -> String {
    let (bytes, _, unmappable) = encoding.encode(text);
    assert!(!unmappable);
    bytes.iter().map(|b| char::from(*b)).collect()
}

fn latin1_frame(id: &'static str, v: &str) -> Frame<'static> {
    Frame::Text(TextInformationFrame::new(
        FrameId::Valid(Cow::Borrowed(id)),
        TextEncoding::Latin1,
        v.to_string(),
    ))
}

#[test]
fn mp3_legacy_gbk_and_shift_jis_tags_are_repaired() {
    let mut tag = Id3v2Tag::new();
    tag.insert(latin1_frame(
        "TIT2",
        &legacy_bytes(encoding_rs::GBK, "十年"),
    ));
    tag.insert(latin1_frame(
        "TPE1",
        &legacy_bytes(encoding_rs::GBK, "陈奕迅"),
    ));
    tag.insert(latin1_frame(
        "TALB",
        &legacy_bytes(encoding_rs::SHIFT_JIS, "打上花火"),
    ));
    tag.insert(Frame::UnsynchronizedText(UnsynchronizedTextFrame::new(
        TextEncoding::Latin1,
        *b"chi",
        String::new(),
        legacy_bytes(encoding_rs::GBK, "[00:01.00]你好\n[00:02.00]世界"),
    )));
    let path = make_mp3("legacy.mp3", Some(tag));

    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.title.as_deref(), Some("十年"));
    assert_eq!(m.artist.as_deref(), Some("陈奕迅"));
    assert_eq!(m.album.as_deref(), Some("打上花火"));
    assert_eq!(m.lyrics.as_deref(), Some("[00:01.00]你好\n[00:02.00]世界"));
}

#[test]
fn mp3_real_latin1_and_utf8_tags_are_left_alone() {
    let mut tag = Id3v2Tag::new();
    tag.insert(latin1_frame("TIT2", "Café Del Mar"));
    tag.insert(latin1_frame("TPE1", "Señor Coconut"));
    tag.insert(text_frame("TALB", "打上花火"));
    let path = make_mp3("latin1.mp3", Some(tag));

    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(m.title.as_deref(), Some("Café Del Mar"));
    assert_eq!(m.artist.as_deref(), Some("Señor Coconut"));
    assert_eq!(m.album.as_deref(), Some("打上花火"));
}

#[test]
fn mp3_sylt_converted_to_lrc() {
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "sylt"));
    tag.insert(sylt_frame(
        TimestampFormat::MS,
        vec![
            (0, "始まり".into()),
            (1_500, "\nsecond".into()),
            (61_234, "一分後".into()),
        ],
    ));
    let path = make_mp3("sylt.mp3", Some(tag));
    let m = api::read_metadata(s(&path)).unwrap();
    assert_eq!(
        m.lyrics.as_deref(),
        Some("[00:00.00]始まり\n[00:01.50]second\n[01:01.23]一分後")
    );

    // MPEG-frame timestamps are not converted.
    let mut tag = Id3v2Tag::new();
    tag.insert(sylt_frame(TimestampFormat::MPEG, vec![(10, "x".into())]));
    let path = make_mp3("sylt_mpeg.mp3", Some(tag));
    assert_eq!(api::read_metadata(s(&path)).unwrap().lyrics, None);

    // USLT takes precedence over SYLT.
    let mut tag = Id3v2Tag::new();
    tag.insert(uslt("", "unsynced"));
    tag.insert(sylt_frame(TimestampFormat::MS, vec![(10, "x".into())]));
    let path = make_mp3("sylt_uslt.mp3", Some(tag));
    assert_eq!(
        api::read_metadata(s(&path)).unwrap().lyrics.as_deref(),
        Some("unsynced")
    );
}

#[test]
fn mp3_front_cover_preferred() {
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "cover"));
    tag.insert_picture(picture(PictureType::Artist, png_back()));
    tag.insert_picture(picture(PictureType::CoverFront, PNG_FRONT.to_vec()));
    let path = make_mp3("cover.mp3", Some(tag));

    // Header walk detects the APIC frame without lofty parsing it.
    let mut f = File::open(&path).unwrap();
    assert_eq!(id3v2_has_picture(&mut f), Some(true));

    let m = api::read_metadata(s(&path)).unwrap();
    assert!(m.has_cover);
    assert_eq!(m.title.as_deref(), Some("cover"));
    assert_eq!(
        api::read_cover(s(&path)).unwrap().as_deref(),
        Some(PNG_FRONT)
    );

    let mut tag = Id3v2Tag::new();
    tag.insert_picture(picture(PictureType::Artist, png_back()));
    let path = make_mp3("artist_only.mp3", Some(tag));
    assert!(api::read_metadata(s(&path)).unwrap().has_cover);
    assert_eq!(api::read_cover(s(&path)).unwrap(), Some(png_back()));
}

// ---------------------------------------------------------------------------
// Copying tags onto a FLAC (SQ-AI)
// ---------------------------------------------------------------------------

#[test]
fn copy_tags_to_flac_carries_tags_lyrics_cover_and_marker() {
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "缭花绚烂"));
    tag.insert(text_frame("TPE1", "歌手"));
    tag.insert(text_frame("TALB", "アルバム"));
    tag.insert(text_frame("TRCK", "3/12"));
    tag.insert(uslt("", "[00:01.00]第一行\n[00:02.00]第二行"));
    tag.insert_picture(picture(PictureType::CoverFront, PNG_FRONT.to_vec()));
    let mp3 = make_mp3("source.mp3", Some(tag));
    // The target has its own, different tags that must not survive.
    let flac = make_flac("target.flac", &[("TITLE", "old"), ("GENRE", "old")], vec![]);

    api::copy_tags_to_flac(s(&mp3), s(&flac), Some("ai-sr".into())).unwrap();

    let m = api::read_metadata(s(&flac)).unwrap();
    assert_eq!(m.codec, "FLAC");
    assert_eq!(m.title.as_deref(), Some("缭花绚烂"));
    assert_eq!(m.artist.as_deref(), Some("歌手"));
    assert_eq!(m.album.as_deref(), Some("アルバム"));
    assert_eq!(m.track_no, Some(3));
    assert_eq!(m.genre, None, "tags of the target are replaced");
    assert_eq!(
        m.lyrics.as_deref(),
        Some("[00:01.00]第一行\n[00:02.00]第二行")
    );
    assert!(m.has_cover);
    assert_eq!(
        api::read_cover(s(&flac)).unwrap().as_deref(),
        Some(PNG_FRONT)
    );

    let mut f = File::open(&flac).unwrap();
    let parsed = FlacFile::read_from(&mut f, ParseOptions::new()).unwrap();
    let vc = parsed.vorbis_comments().unwrap();
    assert_eq!(vc.get(copy::SOURCE_FIELD), Some("ai-sr"));
}

#[test]
fn copy_tags_converts_sylt_lyrics_to_lrc() {
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "sylt"));
    tag.insert(sylt_frame(
        TimestampFormat::MS,
        vec![(1000, "one".into()), (2500, "two".into())],
    ));
    let mp3 = make_mp3("sylt.mp3", Some(tag));
    let flac = make_flac("sylt.flac", &[], vec![]);
    api::copy_tags_to_flac(s(&mp3), s(&flac), None).unwrap();
    let lyrics = api::read_metadata(s(&flac)).unwrap().lyrics.unwrap();
    assert_eq!(lyrics, "[00:01.00]one\n[00:02.50]two");
}

#[test]
fn copy_tags_without_source_tags_still_writes_the_marker() {
    let mp3 = make_mp3("bare.mp3", None);
    let flac = make_flac("bare.flac", &[("TITLE", "old")], vec![]);
    api::copy_tags_to_flac(s(&mp3), s(&flac), Some("ai-sr".into())).unwrap();
    let m = api::read_metadata(s(&flac)).unwrap();
    assert_eq!(m.title, None);
    let mut f = File::open(&flac).unwrap();
    let parsed = FlacFile::read_from(&mut f, ParseOptions::new()).unwrap();
    assert_eq!(
        parsed.vorbis_comments().unwrap().get("NYAPLAYER_SOURCE"),
        Some("ai-sr")
    );
}

// ---------------------------------------------------------------------------
// Batch and errors
// ---------------------------------------------------------------------------

#[test]
fn batch_preserves_order_and_reports_errors() {
    let flac = make_flac("b.flac", &[("TITLE", "flac")], vec![]);
    let mut tag = Id3v2Tag::new();
    tag.insert(text_frame("TIT2", "mp3"));
    let mp3 = make_mp3("b.mp3", Some(tag));
    let missing = tmp_path("does_not_exist.flac");
    let garbage = tmp_path("garbage.mp3");
    std::fs::write(
        &garbage,
        b"this is definitely not audio data at all".repeat(20),
    )
    .unwrap();
    let bad_flac = tmp_path("truncated.flac");
    std::fs::write(&bad_flac, b"fLaC\x00\x00").unwrap();

    let mut paths = vec![s(&flac), s(&missing), s(&garbage), s(&mp3), s(&bad_flac)];
    // Enough entries to exercise several worker chunks.
    for i in 0..37 {
        paths.push(if i % 2 == 0 { s(&flac) } else { s(&mp3) });
    }
    let out = api::read_metadata_batch(paths.clone());
    assert_eq!(out.len(), paths.len());
    for (r, p) in out.iter().zip(&paths) {
        assert_eq!(&r.path, p);
        assert_eq!(r.meta.is_some(), r.error.is_none());
    }
    assert_eq!(out[0].meta.as_ref().unwrap().title.as_deref(), Some("flac"));
    assert!(out[1].error.is_some(), "missing file");
    assert!(out[2].error.is_some(), "garbage file");
    assert_eq!(out[3].meta.as_ref().unwrap().title.as_deref(), Some("mp3"));
    assert!(out[4].error.is_some(), "truncated flac");
    for (i, r) in out.iter().enumerate().skip(5) {
        let want = if (i - 5) % 2 == 0 { "flac" } else { "mp3" };
        assert_eq!(r.meta.as_ref().unwrap().title.as_deref(), Some(want));
    }

    assert!(api::read_metadata(s(&missing)).is_err());
    assert!(api::read_cover(s(&garbage)).is_err());
    assert!(api::read_metadata_batch(vec![]).is_empty());
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

#[test]
fn lrc_timestamp_detection() {
    assert!(has_lrc_timestamp("[00:12.34]a"));
    assert!(has_lrc_timestamp("x\n[1:02]b"));
    assert!(has_lrc_timestamp("[12:02:500]b"));
    assert!(!has_lrc_timestamp("[ar:someone]\nplain"));
    assert!(!has_lrc_timestamp("[00:1]x [ab:cd]"));
    assert!(!has_lrc_timestamp("plain text ["));
}

#[test]
fn sylt_lrc_formatting() {
    assert_eq!(
        sylt_to_lrc(&[(0, "a".into()), (599_999, "b\r\n".into())]),
        "[00:00.00]a\n[09:59.99]b"
    );
    assert_eq!(sylt_to_lrc(&[(6_000_000, "c".into())]), "[100:00.00]c");
}

#[test]
fn number_and_year_parsing() {
    assert_eq!(parse_leading_number(" 03/12"), Some(3));
    assert_eq!(parse_leading_number("0"), None);
    assert_eq!(parse_leading_number("abc"), None);
    assert_eq!(parse_year("2021-05-01"), Some(2021));
    assert_eq!(parse_year("May 1999"), Some(1999));
    assert_eq!(parse_year("12345"), None);
}

// ---------------------------------------------------------------------------
// Manual / maintenance tests
// ---------------------------------------------------------------------------

/// Reads the real files in the repo's `test_music/` (gitignored; override the
/// folder with `NYA_TEST_MUSIC=/path`).
/// Run with `cargo test real_test_music -- --ignored --nocapture`.
#[test]
#[ignore]
fn real_test_music() {
    let dir = std::env::var_os("NYA_TEST_MUSIC")
        .map(PathBuf::from)
        .unwrap_or_else(|| Path::new(env!("CARGO_MANIFEST_DIR")).join("../test_music"));
    let Ok(entries) = std::fs::read_dir(&dir) else {
        println!("{} not found, skipping", dir.display());
        return;
    };
    let mut paths: Vec<String> = entries
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.is_file())
        .map(|p| s(&p))
        .collect();
    paths.sort();
    for r in api::read_metadata_batch(paths) {
        println!("== {}", r.path);
        match (&r.meta, &r.error) {
            (Some(m), _) => {
                let mut m = m.clone();
                let lyrics = m.lyrics.take();
                println!("{m:#?}");
                match lyrics {
                    Some(l) => println!(
                        "lyrics ({} chars, timestamps: {}):\n{}",
                        l.chars().count(),
                        has_lrc_timestamp(&l),
                        l.lines().take(8).collect::<Vec<_>>().join("\n")
                    ),
                    None => println!("lyrics: none"),
                }
                match api::read_cover(r.path.clone()) {
                    Ok(Some(c)) => println!(
                        "cover: {} bytes, head {:02X?}",
                        c.len(),
                        &c[..c.len().min(4)]
                    ),
                    Ok(None) => println!("cover: none"),
                    Err(e) => println!("cover error: {e:#}"),
                }
            }
            (None, Some(e)) => println!("error: {e}"),
            _ => unreachable!(),
        }
    }
}

/// Writes a 16-bit PCM WAV with no external crates.
fn write_sine_wav(path: &Path, sample_rate: u32, channels: u16, ms: u32) {
    let frames = sample_rate * ms / 1000;
    let data_len = frames * u32::from(channels) * 2;
    let mut b = Vec::with_capacity(44 + data_len as usize);
    b.extend(b"RIFF");
    b.extend((36 + data_len).to_le_bytes());
    b.extend(b"WAVEfmt ");
    b.extend(16u32.to_le_bytes());
    b.extend(1u16.to_le_bytes()); // PCM
    b.extend(channels.to_le_bytes());
    b.extend(sample_rate.to_le_bytes());
    b.extend((sample_rate * u32::from(channels) * 2).to_le_bytes());
    b.extend((channels * 2).to_le_bytes());
    b.extend(16u16.to_le_bytes());
    b.extend(b"data");
    b.extend(data_len.to_le_bytes());
    for i in 0..frames {
        let t = i as f64 / f64::from(sample_rate);
        let v = ((t * 440.0 * std::f64::consts::TAU).sin() * 8000.0) as i16;
        for _ in 0..channels {
            b.extend(v.to_le_bytes());
        }
    }
    std::fs::write(path, b).unwrap();
}

/// Regenerates the committed FLAC fixture (macOS only, uses afconvert).
/// Run with `cargo test regenerate_flac_fixture -- --ignored`.
#[test]
#[ignore]
fn regenerate_flac_fixture() {
    let wav = tmp_path("sine.wav");
    write_sine_wav(&wav, 44100, 1, 250);
    let flac = wav.with_extension("flac");
    let status = std::process::Command::new("/usr/bin/afconvert")
        .args(["-f", "flac", "-d", "flac"])
        .arg(&wav)
        .arg(&flac)
        .status()
        .expect("afconvert not available");
    assert!(status.success());
    std::fs::copy(&flac, FLAC_FIXTURE).unwrap();
}
