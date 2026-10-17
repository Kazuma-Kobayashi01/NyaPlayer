import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';

/// A global search route also available above the expanded player.
class LibrarySearchDelegate extends SearchDelegate<void> {
  LibrarySearchDelegate({required String hint}) : super(searchFieldLabel: hint);

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  Widget _results(BuildContext context) => Consumer(
    builder: (context, ref, _) => ListView(
      children: librarySearchSuggestions(
        context,
        ref,
        query,
        () => close(context, null),
      ),
    ),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
}
