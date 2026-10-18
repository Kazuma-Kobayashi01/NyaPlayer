//! Metadata API exposed to Dart through flutter_rust_bridge.
//!
//! Thin wrappers only; the implementation lives in `crate::meta`.

/// Tags, audio properties and embedded lyrics of one track.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct TrackMeta {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album_artist: Option<String>,
    pub album: Option<String>,
    pub track_no: Option<u32>,
    pub disc_no: Option<u32>,
    pub year: Option<i32>,
    pub genre: Option<String>,
    pub duration_ms: u64,
    pub sample_rate: Option<u32>,
    pub bit_depth: Option<u8>,
    pub bitrate_kbps: Option<u32>,
    pub channels: Option<u8>,
    /// "FLAC" or "MP3" (otherwise the lofty file type name).
    pub codec: String,
    /// Embedded lyrics text (LRC or plain), line endings normalised to `\n`.
    pub lyrics: Option<String>,
    pub has_cover: bool,
}

/// Per-file result of [`read_metadata_batch`].
#[derive(Debug, Clone, Default, PartialEq)]
pub struct MetaResult {
    pub path: String,
    pub meta: Option<TrackMeta>,
    pub error: Option<String>,
}

/// Reads tags, properties and embedded lyrics. Never copies cover bytes.
pub fn read_metadata(path: String) -> anyhow::Result<TrackMeta> {
    crate::meta::read_metadata(&path)
}

/// Reads many files in parallel. Output order matches input order; per-file
/// failures are reported in [`MetaResult::error`].
pub fn read_metadata_batch(paths: Vec<String>) -> Vec<MetaResult> {
    crate::meta::read_metadata_batch(paths)
}

/// Returns the embedded cover (front cover preferred, else the first picture)
/// as stored in the file (jpeg/png bytes), or `None` if there is none.
pub fn read_cover(path: String) -> anyhow::Result<Option<Vec<u8>>> {
    crate::meta::read_cover(&path)
}

/// Copies the tags and cover of `source` (the lossy file) onto the FLAC at
/// `destination` made from it, and records `marker` (e.g. `ai-sr`) in the
/// FLAC's `NYAPLAYER_SOURCE` field. Used by the AI super-resolution (SQ-AI).
pub fn copy_tags_to_flac(
    source: String,
    destination: String,
    marker: Option<String>,
) -> anyhow::Result<()> {
    crate::meta::copy::copy_tags_to_flac(&source, &destination, marker.as_deref())
}
