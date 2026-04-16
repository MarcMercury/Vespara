import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GIPHY PICKER - Searchable GIF selector for Wire chat
/// ════════════════════════════════════════════════════════════════════════════

class GiphyPickerSheet extends StatefulWidget {
  const GiphyPickerSheet({super.key, required this.onGifSelected});

  /// Callback with the selected GIF URL (fixed-height rendition for chat)
  final void Function(String gifUrl, String title) onGifSelected;

  @override
  State<GiphyPickerSheet> createState() => _GiphyPickerSheetState();
}

class _GiphyPickerSheetState extends State<GiphyPickerSheet> {
  final _searchController = TextEditingController();
  List<_GiphyGif> _gifs = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final gifs = await _fetchGifs(endpoint: 'trending');
      if (mounted) setState(() => _gifs = gifs);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadTrending();
      return;
    }
    setState(() {
      _isLoading = true;
      _query = query;
    });
    try {
      final gifs = await _fetchGifs(endpoint: 'search', query: query);
      if (mounted && _query == query) setState(() => _gifs = gifs);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<_GiphyGif>> _fetchGifs({
    required String endpoint,
    String? query,
    int limit = 30,
  }) async {
    final apiKey = Env.giphyApiKey;
    if (apiKey.isEmpty) return [];

    final params = {
      'api_key': apiKey,
      'limit': '$limit',
      'rating': 'r',
      if (query != null) 'q': query,
    };

    final uri = Uri.https('api.giphy.com', '/v1/gifs/$endpoint', params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final results = data['data'] as List<dynamic>? ?? [];

      return results.map((item) {
        final images = item['images'] ?? {};
        final fixedHeight = images['fixed_height'] ?? {};
        final original = images['original'] ?? {};
        return _GiphyGif(
          id: item['id'] ?? '',
          title: item['title'] ?? '',
          previewUrl: fixedHeight['url'] ?? original['url'] ?? '',
          originalUrl: original['url'] ?? fixedHeight['url'] ?? '',
          width: int.tryParse('${fixedHeight['width']}') ?? 200,
          height: int.tryParse('${fixedHeight['height']}') ?? 200,
        );
      }).where((g) => g.previewUrl.isNotEmpty).toList();
    } catch (e) {
      debugPrint('GIPHY fetch error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => _search(v),
                style: const TextStyle(color: VesparaColors.primary),
                decoration: InputDecoration(
                  hintText: 'Search GIFs...',
                  hintStyle: const TextStyle(color: VesparaColors.secondary),
                  prefixIcon: const Icon(Icons.search, color: VesparaColors.secondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: VesparaColors.secondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadTrending();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: VesparaColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            // GIPHY attribution
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Powered by GIPHY',
                style: TextStyle(fontSize: 10, color: VesparaColors.secondary),
              ),
            ),

            // GIF grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: VesparaColors.glow,
                        strokeWidth: 2,
                      ),
                    )
                  : _gifs.isEmpty
                      ? const Center(
                          child: Text(
                            'No GIFs found',
                            style: TextStyle(color: VesparaColors.secondary),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _gifs.length,
                          itemBuilder: (context, index) {
                            final gif = _gifs[index];
                            return GestureDetector(
                              onTap: () {
                                widget.onGifSelected(gif.originalUrl, gif.title);
                                Navigator.pop(context);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  gif.previewUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: VesparaColors.background,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: VesparaColors.glow,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: VesparaColors.background,
                                    child: const Icon(Icons.broken_image, color: VesparaColors.secondary),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      );
}

class _GiphyGif {
  const _GiphyGif({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
  });
  final String id;
  final String title;
  final String previewUrl;
  final String originalUrl;
  final int width;
  final int height;
}
