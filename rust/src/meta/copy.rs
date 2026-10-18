//! Moves the tags of a lossy file onto the FLAC made from it by the AI
//! super-resolution (SQ-AI): title, artist, album, numbers, genre, lyrics and
//! the embedded cover, plus an optional source marker.

use anyhow::Context;
use lofty::config::WriteOptions;
use lofty::file::TaggedFileExt;
use lofty::ogg::tag::VorbisComments;
use lofty::tag::TagExt;

/// Vorbis comment holding where the audio came from (e.g. `ai-sr`).
pub(crate) const SOURCE_FIELD: &str = "NYAPLAYER_SOURCE";

/// Writes `source`'s tags into the FLAC at `destination`, replacing whatever
/// tags that file has. Pictures travel with the tag. Lyrics are taken from the
/// app's own reader as well, so synchronised (SYLT) lyrics arrive as LRC text,
/// the form the app shows.
pub(crate) fn copy_tags_to_flac(
    source: &str,
    destination: &str,
    marker: Option<&str>,
) -> anyhow::Result<()> {
    let tagged = lofty::read_from_path(source).with_context(|| format!("reading {source}"))?;
    let mut vorbis = match tagged.primary_tag().or_else(|| tagged.first_tag()) {
        Some(tag) => VorbisComments::from(tag.clone()),
        None => VorbisComments::default(),
    };

    let has_lyrics = vorbis.get("LYRICS").is_some() || vorbis.get("UNSYNCEDLYRICS").is_some();
    if !has_lyrics {
        if let Some(lyrics) = super::read_metadata(source)?.lyrics {
            vorbis.push("LYRICS".to_string(), lyrics);
        }
    }
    if let Some(marker) = marker {
        let _ = vorbis.remove(SOURCE_FIELD).count();
        vorbis.push(SOURCE_FIELD.to_string(), marker.to_string());
    }
    vorbis
        .save_to_path(destination, WriteOptions::default())
        .with_context(|| format!("writing tags to {destination}"))?;
    Ok(())
}
