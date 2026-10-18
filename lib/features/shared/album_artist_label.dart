import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// The artist line of an album. An empty album artist means the tracks have
/// different artists and no Album Artist tag (see `LibraryScanner`).
String albumArtistLabel(AppLocalizations l10n, Album album) =>
    album.artist.isEmpty ? l10n.variousArtists : album.artist;
