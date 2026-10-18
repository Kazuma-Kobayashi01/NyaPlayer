//! Metadata reading (tags, audio properties, embedded lyrics and covers)
//! built on lofty. The library is FLAC + MP3; other formats lofty knows are
//! read on a best-effort basis through its generic `TaggedFile`.

use std::borrow::Cow;
use std::fs::File;
use std::io::{BufReader, Read, Seek, SeekFrom};
use std::panic::{self, AssertUnwindSafe};
use std::time::Duration;

use anyhow::{anyhow, Context};
use lofty::config::ParseOptions;
use lofty::file::{AudioFile, FileType, TaggedFileExt};
use lofty::flac::FlacFile;
use lofty::id3::v2::{
    Frame, Id3v2Tag, SyncTextContentType, SynchronizedTextFrame, TimestampFormat,
};
use lofty::mpeg::MpegFile;
use lofty::picture::{Picture, PictureType};
use lofty::probe::Probe;
use lofty::tag::{Accessor, ItemKey, Tag};

use crate::api::meta::{MetaResult, TrackMeta};

pub(crate) mod copy;
mod encoding;
#[cfg(test)]
mod tests;

/// Audio properties normalised across file types.
#[derive(Default)]
struct Props {
    duration: Duration,
    sample_rate: Option<u32>,
    bit_depth: Option<u8>,
    bitrate_kbps: Option<u32>,
    channels: Option<u8>,
}

/// Everything collected from one file before mapping to [`TrackMeta`].
struct Collected {
    file_type: FileType,
    /// Tags in priority order (primary tag first).
    tags: Vec<Tag>,
    props: Props,
    /// Format-specific lyrics (Vorbis LYRICS / ID3v2 USLT / SYLT).
    lyrics: Option<String>,
    has_cover: bool,
}

// ---------------------------------------------------------------------------
// Public entry points (wrapped by crate::api::meta)
// ---------------------------------------------------------------------------

pub(crate) fn read_metadata(path: &str) -> anyhow::Result<TrackMeta> {
    guard(path, || read_metadata_inner(path))
}

pub(crate) fn read_cover(path: &str) -> anyhow::Result<Option<Vec<u8>>> {
    guard(path, || read_cover_inner(path))
}

pub(crate) fn read_metadata_batch(paths: Vec<String>) -> Vec<MetaResult> {
    if paths.is_empty() {
        return Vec::new();
    }
    let threads = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
        .clamp(1, 16)
        .min(paths.len());
    let chunk_size = paths.len().div_ceil(threads);

    std::thread::scope(|scope| {
        let handles: Vec<_> = paths
            .chunks(chunk_size)
            .map(|chunk| {
                scope.spawn(move || {
                    chunk
                        .iter()
                        .map(|p| to_result(p.clone(), read_metadata(p)))
                        .collect::<Vec<_>>()
                })
            })
            .collect();

        let mut out = Vec::with_capacity(paths.len());
        for (handle, chunk) in handles.into_iter().zip(paths.chunks(chunk_size)) {
            match handle.join() {
                Ok(results) => out.extend(results),
                // read_metadata already catches panics; this is a last resort.
                Err(_) => out.extend(chunk.iter().map(|p| MetaResult {
                    path: p.clone(),
                    meta: None,
                    error: Some("worker thread panicked".into()),
                })),
            }
        }
        out
    })
}

fn to_result(path: String, res: anyhow::Result<TrackMeta>) -> MetaResult {
    match res {
        Ok(meta) => MetaResult {
            path,
            meta: Some(meta),
            error: None,
        },
        Err(e) => MetaResult {
            path,
            meta: None,
            error: Some(format!("{e:#}")),
        },
    }
}

/// Converts a panic inside lofty (malformed input) into an error.
fn guard<T>(path: &str, f: impl FnOnce() -> anyhow::Result<T>) -> anyhow::Result<T> {
    match panic::catch_unwind(AssertUnwindSafe(f)) {
        Ok(r) => r,
        Err(payload) => {
            let msg = payload
                .downcast_ref::<&str>()
                .map(|s| s.to_string())
                .or_else(|| payload.downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "unknown panic".into());
            Err(anyhow!("panic while reading {path}: {msg}"))
        }
    }
}

// ---------------------------------------------------------------------------
// Reading
// ---------------------------------------------------------------------------

fn open_probe(path: &str) -> anyhow::Result<(FileType, BufReader<File>)> {
    let file = File::open(path).with_context(|| format!("cannot open {path}"))?;
    let probe = Probe::new(BufReader::new(file))
        .guess_file_type()
        .with_context(|| format!("cannot read {path}"))?;
    let file_type = probe
        .file_type()
        .ok_or_else(|| anyhow!("unsupported or unrecognised audio file: {path}"))?;
    let mut reader = probe.into_inner();
    reader.rewind()?;
    Ok((file_type, reader))
}

fn options(read_cover_art: bool) -> ParseOptions {
    ParseOptions::new().read_cover_art(read_cover_art)
}

fn read_metadata_inner(path: &str) -> anyhow::Result<TrackMeta> {
    let c = collect(path)?;
    Ok(build_meta(c))
}

fn collect(path: &str) -> anyhow::Result<Collected> {
    let (file_type, mut reader) = open_probe(path)?;
    match file_type {
        FileType::Flac => {
            // Pictures are skipped by lofty (no bytes read or copied); we only
            // look at FLAC block headers to know whether one exists.
            let flac = FlacFile::read_from(&mut reader, options(false))
                .with_context(|| format!("invalid FLAC file: {path}"))?;
            let p = flac.properties();
            let props = Props {
                duration: p.duration(),
                sample_rate: nz(p.sample_rate()),
                bit_depth: nz(p.bit_depth()),
                bitrate_kbps: nz(p.audio_bitrate()).or(nz(p.overall_bitrate())),
                channels: nz(p.channels()),
            };
            let lyrics = flac.vorbis_comments().and_then(|vc| {
                ["LYRICS", "UNSYNCEDLYRICS"]
                    .iter()
                    .find_map(|k| vc.get_all(k).find_map(clean_lyrics))
            });
            let has_cover = flac_has_picture_block(&mut reader).unwrap_or(false);
            let mut tags = Vec::new();
            if let Some(vc) = flac.vorbis_comments() {
                tags.push(Tag::from(vc.clone()));
            }
            if let Some(id3) = flac.id3v2() {
                tags.push(Tag::from(id3.clone()));
            }
            Ok(Collected {
                file_type,
                tags,
                props,
                lyrics,
                has_cover,
            })
        }
        FileType::Mpeg => {
            let mp3 = MpegFile::read_from(&mut reader, options(false))
                .with_context(|| format!("invalid MP3 file: {path}"))?;
            let p = mp3.properties();
            let props = Props {
                duration: p.duration(),
                sample_rate: nz(p.sample_rate()),
                bit_depth: None,
                bitrate_kbps: nz(p.audio_bitrate()).or(nz(p.overall_bitrate())),
                channels: nz(p.channels()),
            };
            let lyrics = mp3.id3v2().and_then(id3v2_lyrics);
            let mut tags = Vec::new();
            if let Some(t) = mp3.id3v2() {
                tags.push(Tag::from(t.clone()));
            }
            if let Some(t) = mp3.ape() {
                tags.push(Tag::from(t.clone()));
            }
            if let Some(t) = mp3.id3v1() {
                tags.push(Tag::from(t.clone()));
            }
            let has_cover = match id3v2_has_picture(&mut reader) {
                Some(b) => b,
                // Header walk inconclusive (e.g. v2.3 whole-tag unsync): let
                // lofty decide; this path does parse the pictures.
                None => {
                    reader.rewind()?;
                    MpegFile::read_from(&mut reader, options(true))
                        .ok()
                        .and_then(|f| f.id3v2().map(|t| t.into_iter().any(is_picture)))
                        .unwrap_or(false)
                }
            } || tags.iter().any(|t| t.picture_count() > 0);
            Ok(Collected {
                file_type,
                tags,
                props,
                lyrics,
                has_cover,
            })
        }
        _ => {
            // Generic path for formats outside the library scope. Pictures are
            // read here because there is no cheap per-format check.
            let tf = Probe::with_file_type(&mut reader, file_type)
                .options(options(true))
                .read()
                .with_context(|| format!("invalid audio file: {path}"))?;
            let p = tf.properties();
            let props = Props {
                duration: p.duration(),
                sample_rate: p.sample_rate().and_then(nz),
                bit_depth: p.bit_depth().and_then(nz),
                bitrate_kbps: p.audio_bitrate().or(p.overall_bitrate()).and_then(nz),
                channels: p.channels().and_then(nz),
            };
            let tags = tags_in_priority(&tf);
            let has_cover = tags.iter().any(|t| t.picture_count() > 0);
            Ok(Collected {
                file_type,
                tags: tags.into_iter().cloned().collect(),
                props,
                lyrics: None,
                has_cover,
            })
        }
    }
}

fn tags_in_priority(tf: &lofty::file::TaggedFile) -> Vec<&Tag> {
    let mut tags: Vec<&Tag> = Vec::new();
    if let Some(p) = tf.primary_tag() {
        tags.push(p);
    }
    for t in tf.tags() {
        if !tags.iter().any(|x| std::ptr::eq(*x, t)) {
            tags.push(t);
        }
    }
    tags
}

fn build_meta(c: Collected) -> TrackMeta {
    let tags = &c.tags;
    // Old MP3 tags declare Latin-1 but may hold GBK / Shift-JIS (META-06).
    let mp3 = c.file_type == FileType::Mpeg;
    let fix = |s: String| {
        if mp3 {
            encoding::repair_legacy_text(&s).unwrap_or(s)
        } else {
            s
        }
    };
    let text = |key: ItemKey| tags.iter().find_map(|t| joined(t, key)).map(fix);
    let number = |key: ItemKey| {
        tags.iter()
            .find_map(|t| t.get_strings(key).find_map(parse_leading_number))
    };

    let year = tags.iter().find_map(|t| {
        t.date()
            .map(|d| i32::from(d.year))
            .filter(|y| *y > 0)
            .or_else(|| {
                [ItemKey::Year, ItemKey::RecordingDate, ItemKey::ReleaseDate]
                    .into_iter()
                    .find_map(|k| t.get_strings(k).find_map(parse_year))
            })
    });

    let lyrics = c
        .lyrics
        .or_else(|| {
            tags.iter().find_map(|t| {
                [ItemKey::Lyrics, ItemKey::UnsyncLyrics]
                    .into_iter()
                    .find_map(|k| t.get_strings(k).find_map(clean_lyrics))
            })
        })
        .map(fix);

    let codec = match c.file_type {
        FileType::Flac => "FLAC".to_string(),
        FileType::Mpeg => "MP3".to_string(),
        other => format!("{other:?}"),
    };

    TrackMeta {
        title: text(ItemKey::TrackTitle),
        artist: text(ItemKey::TrackArtist),
        album_artist: text(ItemKey::AlbumArtist),
        album: text(ItemKey::AlbumTitle),
        track_no: number(ItemKey::TrackNumber),
        disc_no: number(ItemKey::DiscNumber),
        year,
        genre: text(ItemKey::Genre),
        duration_ms: u64::try_from(c.props.duration.as_millis()).unwrap_or(u64::MAX),
        sample_rate: c.props.sample_rate,
        bit_depth: c.props.bit_depth,
        bitrate_kbps: c.props.bitrate_kbps,
        channels: c.props.channels,
        codec,
        lyrics,
        has_cover: c.has_cover,
    }
}

// ---------------------------------------------------------------------------
// Cover
// ---------------------------------------------------------------------------

fn read_cover_inner(path: &str) -> anyhow::Result<Option<Vec<u8>>> {
    let (file_type, mut reader) = open_probe(path)?;
    let mut pictures: Vec<Picture> = Vec::new();
    match file_type {
        FileType::Mpeg => {
            let mp3 = MpegFile::read_from(&mut reader, options(true))
                .with_context(|| format!("invalid MP3 file: {path}"))?;
            if let Some(t) = mp3.id3v2() {
                pictures.extend(t.into_iter().filter_map(|f| match f {
                    Frame::Picture(p) => Some(p.picture.clone().into_owned()),
                    _ => None,
                }));
            }
            if let Some(t) = mp3.ape() {
                pictures.extend(Tag::from(t.clone()).pictures().iter().cloned());
            }
        }
        _ => {
            // For FLAC, lofty's TaggedFile conversion moves picture blocks
            // (and METADATA_BLOCK_PICTURE comments) into the Vorbis tag.
            let tf = Probe::with_file_type(&mut reader, file_type)
                .options(options(true))
                .read()
                .with_context(|| format!("invalid audio file: {path}"))?;
            for t in tags_in_priority(&tf) {
                pictures.extend(t.pictures().iter().cloned());
            }
        }
    }
    let idx = pictures
        .iter()
        .position(|p| p.pic_type() == PictureType::CoverFront)
        .or(if pictures.is_empty() { None } else { Some(0) });
    Ok(idx.map(|i| pictures.swap_remove(i).into_data()))
}

fn is_picture(f: &Frame<'_>) -> bool {
    matches!(f, Frame::Picture(_))
}

/// Walks the FLAC metadata block headers (seeking over contents) looking for a
/// PICTURE block. Returns `None` if the stream is not a well-formed FLAC.
fn flac_has_picture_block<R: Read + Seek>(r: &mut R) -> Option<bool> {
    r.rewind().ok()?;
    let mut head = [0u8; 10];
    r.read_exact(&mut head[..4]).ok()?;
    if &head[..3] == b"ID3" {
        // Skip a leading ID3v2 tag.
        r.read_exact(&mut head[4..10]).ok()?;
        let size = syncsafe(&head[6..10])?;
        let footer = if head[5] & 0x10 != 0 { 10 } else { 0 };
        r.seek(SeekFrom::Start(10 + u64::from(size) + footer))
            .ok()?;
        r.read_exact(&mut head[..4]).ok()?;
    }
    if &head[..4] != b"fLaC" {
        return None;
    }
    for _ in 0..1024 {
        let mut bh = [0u8; 4];
        r.read_exact(&mut bh).ok()?;
        let last = bh[0] & 0x80 != 0;
        let ty = bh[0] & 0x7F;
        if ty == 6 {
            return Some(true);
        }
        if last {
            return Some(false);
        }
        let len = u32::from_be_bytes([0, bh[1], bh[2], bh[3]]);
        r.seek(SeekFrom::Current(i64::from(len))).ok()?;
    }
    None
}

/// Walks the frame headers of a leading ID3v2 tag (seeking over frame bodies)
/// looking for APIC/PIC. Returns `None` when the walk is inconclusive.
fn id3v2_has_picture<R: Read + Seek>(r: &mut R) -> Option<bool> {
    r.rewind().ok()?;
    let mut h = [0u8; 10];
    if r.read_exact(&mut h).is_err() || &h[..3] != b"ID3" {
        return Some(false);
    }
    let major = h[3];
    let flags = h[5];
    let tag_end = 10 + u64::from(syncsafe(&h[6..10])?);
    if !(2..=4).contains(&major) {
        return None;
    }
    // Whole-tag unsynchronisation in v2.2/2.3 changes the on-disk layout.
    if flags & 0x80 != 0 && major < 4 {
        return None;
    }
    if flags & 0x40 != 0 {
        if major == 2 {
            return None; // v2.2 compression flag; not supported
        }
        let mut s = [0u8; 4];
        r.read_exact(&mut s).ok()?;
        if major == 3 {
            r.seek(SeekFrom::Current(i64::from(u32::from_be_bytes(s))))
                .ok()?;
        } else {
            let len = syncsafe(&s)?;
            r.seek(SeekFrom::Current(i64::from(len) - 4)).ok()?;
        }
    }
    let (id_len, hdr_len) = if major == 2 { (3, 6) } else { (4, 10) };
    loop {
        let pos = r.stream_position().ok()?;
        if pos + hdr_len as u64 > tag_end {
            return Some(false);
        }
        let mut fh = [0u8; 10];
        r.read_exact(&mut fh[..hdr_len]).ok()?;
        if fh[0] == 0 {
            return Some(false); // padding
        }
        let id = &fh[..id_len];
        if !id
            .iter()
            .all(|b| b.is_ascii_uppercase() || b.is_ascii_digit())
        {
            return None;
        }
        if id == b"APIC" || id == b"PIC" {
            return Some(true);
        }
        let size = match major {
            2 => u32::from_be_bytes([0, fh[3], fh[4], fh[5]]),
            3 => u32::from_be_bytes([fh[4], fh[5], fh[6], fh[7]]),
            _ => syncsafe(&fh[4..8])?,
        };
        let next = pos + hdr_len as u64 + u64::from(size);
        if next > tag_end {
            return None;
        }
        r.seek(SeekFrom::Start(next)).ok()?;
    }
}

fn syncsafe(b: &[u8]) -> Option<u32> {
    if b.len() != 4 || b.iter().any(|x| x & 0x80 != 0) {
        return None;
    }
    Some(b.iter().fold(0u32, |acc, x| (acc << 7) | u32::from(*x)))
}

// ---------------------------------------------------------------------------
// Lyrics
// ---------------------------------------------------------------------------

/// ID3v2 lyrics: USLT (prefer one with LRC timestamps, else the first), then
/// SYLT with millisecond timestamps converted to LRC.
fn id3v2_lyrics(tag: &Id3v2Tag) -> Option<String> {
    let uslt: Vec<String> = tag
        .unsync_text()
        .filter_map(|f| clean_lyrics(&f.content))
        .collect();
    if let Some(i) = uslt.iter().position(|t| has_lrc_timestamp(t)) {
        return uslt.into_iter().nth(i);
    }
    if let Some(first) = uslt.into_iter().next() {
        return Some(first);
    }

    let sylt: Vec<SynchronizedTextFrame<'_>> = tag
        .into_iter()
        .filter_map(|f| match f {
            Frame::Binary(b) if b.id().as_str() == "SYLT" => {
                SynchronizedTextFrame::parse(&b.data, b.flags()).ok()
            }
            _ => None,
        })
        .filter(|s| s.timestamp_format == TimestampFormat::MS && !s.content.is_empty())
        .collect();
    let best = sylt
        .iter()
        .find(|s| s.content_type == SyncTextContentType::Lyrics)
        .or(sylt.first())?;
    clean_lyrics(&sylt_to_lrc(&best.content))
}

pub(crate) fn sylt_to_lrc(content: &[(u32, String)]) -> String {
    let mut out = String::new();
    for (ms, text) in content {
        let text = text.trim_matches(|c| c == '\r' || c == '\n');
        let cs = ms / 10;
        let (min, sec, cent) = (cs / 6000, (cs / 100) % 60, cs % 100);
        if !out.is_empty() {
            out.push('\n');
        }
        out.push_str(&format!("[{min:02}:{sec:02}.{cent:02}]{text}"));
    }
    out
}

/// Normalises line endings; `None` if the text is blank.
fn clean_lyrics(s: &str) -> Option<String> {
    if s.trim().is_empty() {
        return None;
    }
    let s = if s.contains('\r') {
        Cow::Owned(s.replace("\r\n", "\n").replace('\r', "\n"))
    } else {
        Cow::Borrowed(s)
    };
    Some(s.into_owned())
}

/// True if any `[mm:ss]`, `[mm:ss.xx]` or `[mm:ss:xx]` timestamp is present.
pub(crate) fn has_lrc_timestamp(s: &str) -> bool {
    let b = s.as_bytes();
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'[' {
            let mut j = i + 1;
            let d0 = j;
            while j < b.len() && b[j].is_ascii_digit() {
                j += 1;
            }
            if j > d0 && j < b.len() && b[j] == b':' {
                j += 1;
                let s0 = j;
                while j < b.len() && b[j].is_ascii_digit() {
                    j += 1;
                }
                if j - s0 == 2 {
                    if j < b.len() && (b[j] == b'.' || b[j] == b':') {
                        j += 1;
                        let f0 = j;
                        while j < b.len() && b[j].is_ascii_digit() {
                            j += 1;
                        }
                        if j > f0 && j < b.len() && b[j] == b']' {
                            return true;
                        }
                    } else if j < b.len() && b[j] == b']' {
                        return true;
                    }
                }
            }
        }
        i += 1;
    }
    false
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

/// All non-empty trimmed values of `key`, de-duplicated and joined with "; ".
fn joined(tag: &Tag, key: ItemKey) -> Option<String> {
    let mut vals: Vec<&str> = Vec::new();
    for v in tag.get_strings(key) {
        let v = v.trim().trim_matches('\0').trim();
        if !v.is_empty() && !vals.contains(&v) {
            vals.push(v);
        }
    }
    if vals.is_empty() {
        None
    } else {
        Some(vals.join("; "))
    }
}

/// "3", "03", "3/12" -> 3. Zero is treated as missing.
fn parse_leading_number(s: &str) -> Option<u32> {
    let s = s.trim();
    let end = s.find(|c: char| !c.is_ascii_digit()).unwrap_or(s.len());
    s[..end].parse::<u32>().ok().filter(|n| *n > 0)
}

/// First run of four digits, e.g. "2021-05-01" or "May 2021".
fn parse_year(s: &str) -> Option<i32> {
    let b = s.as_bytes();
    (0..b.len().saturating_sub(3)).find_map(|i| {
        let w = &b[i..i + 4];
        let boundary_before = i == 0 || !b[i - 1].is_ascii_digit();
        let boundary_after = i + 4 == b.len() || !b[i + 4].is_ascii_digit();
        if boundary_before && boundary_after && w.iter().all(u8::is_ascii_digit) {
            std::str::from_utf8(w).ok()?.parse().ok().filter(|y| *y > 0)
        } else {
            None
        }
    })
}

fn nz<T: Default + PartialEq>(v: T) -> Option<T> {
    if v == T::default() {
        None
    } else {
        Some(v)
    }
}
