import 'package:flutter/material.dart';
import '../domain/models/content_rating.dart';
import '../utils/haptic_patterns.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG HEAT SELECTOR - Content Rating/Heat Level Picker
/// ════════════════════════════════════════════════════════════════════════════
///
/// A reusable widget for selecting content/spiciness level across all TAG games.
/// Supports different display modes and animations.

class TagHeatSelector extends StatefulWidget {
  const TagHeatSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availableRatings,
    this.style = TagHeatSelectorStyle.chips,
    this.showDescriptions = false,
    this.showIcons = true,
    this.enabled = true,
    this.label,
    this.scale = 1.0,
  });

  /// Currently selected rating
  final ContentRating selected;

  /// Called when rating changes
  final ValueChanged<ContentRating> onChanged;

  /// Available ratings to show (defaults to all)
  final List<ContentRating>? availableRatings;

  /// Display style
  final TagHeatSelectorStyle style;

  /// Whether to show descriptions
  final bool showDescriptions;

  /// Whether to show icons
  final bool showIcons;

  /// Whether selector is enabled
  final bool enabled;

  /// Custom label for the selector
  final String? label;

  /// Size multiplier
  final double scale;

  @override
  State<TagHeatSelector> createState() => _TagHeatSelectorState();
}

class _TagHeatSelectorState extends State<TagHeatSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<ContentRating> get ratings =>
      widget.availableRatings ?? ContentRating.values;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelect(ContentRating rating) {
    if (!widget.enabled || rating == widget.selected) return;
    TagHaptics.selection();
    widget.onChanged(rating);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14 * widget.scale,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12 * widget.scale),
          ],
          switch (widget.style) {
            TagHeatSelectorStyle.chips => _buildChips(),
            TagHeatSelectorStyle.slider => _buildSlider(),
            TagHeatSelectorStyle.thermometer => _buildThermometer(),
            TagHeatSelectorStyle.grid => _buildGrid(),
          },
          if (widget.showDescriptions) ...[
            SizedBox(height: 12 * widget.scale),
            _buildDescription(),
          ],
        ],
      );

  Widget _buildChips() => Wrap(
        spacing: 8 * widget.scale,
        runSpacing: 8 * widget.scale,
        children: ratings.map((rating) {
          final isSelected = rating == widget.selected;
          return GestureDetector(
            onTap: () => _onSelect(rating),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 16 * widget.scale,
                vertical: 10 * widget.scale,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected ? rating.color : rating.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20 * widget.scale),
                border: Border.all(
                  color:
                      isSelected ? rating.color : rating.color.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: rating.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showIcons) ...[
                    Icon(
                      _getIcon(rating),
                      size: 18 * widget.scale,
                      color: isSelected ? Colors.white : rating.color,
                    ),
                    SizedBox(width: 6 * widget.scale),
                  ],
                  Text(
                    rating.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : rating.color,
                      fontSize: 14 * widget.scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildSlider() {
    final selectedIndex = ratings.indexOf(widget.selected);

    return Column(
      children: [
        // Track
        Container(
          height: 40 * widget.scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * widget.scale),
            gradient: LinearGradient(
              colors: ratings.map((r) => r.color.withOpacity(0.3)).toList(),
            ),
          ),
          child: Stack(
            children: [
              // Selection indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: (selectedIndex / (ratings.length - 1)) *
                    (MediaQuery.of(context).size.width -
                        80 -
                        60 * widget.scale),
                child: Container(
                  width: 60 * widget.scale,
                  height: 40 * widget.scale,
                  decoration: BoxDecoration(
                    color: widget.selected.color,
                    borderRadius: BorderRadius.circular(20 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: widget.selected.color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.selected.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * widget.scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Touch targets
              Row(
                children: ratings
                    .map(
                      (rating) => Expanded(
                        child: GestureDetector(
                          onTap: () => _onSelect(rating),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 40 * widget.scale,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        // Labels
        SizedBox(height: 8 * widget.scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ratings.map((rating) {
            final isSelected = rating == widget.selected;
            return Text(
              rating.displayName,
              style: TextStyle(
                color: isSelected ? rating.color : Colors.white38,
                fontSize: 10 * widget.scale,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThermometer() {
    final selectedIndex = ratings.indexOf(widget.selected);

    return SizedBox(
      height: 200 * widget.scale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thermometer
          Container(
            width: 40 * widget.scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Fill
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  heightFactor: (selectedIndex + 1) / ratings.length,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18 * widget.scale),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: ratings
                            .take(selectedIndex + 1)
                            .map((r) => r.color)
                            .toList(),
                      ),
                    ),
                  ),
                ),
                // Level markers
                ...List.generate(ratings.length, (i) {
                  final rating = ratings[i];
                  return Positioned(
                    bottom: (i / ratings.length) * 180 * widget.scale,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _onSelect(rating),
                      child: Container(
                        height: 2,
                        color: Colors.white24,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(width: 12 * widget.scale),
          // Labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ratings.reversed.map((rating) {
              final isSelected = rating == widget.selected;
              return GestureDetector(
                onTap: () => _onSelect(rating),
                child: Row(
                  children: [
                    if (widget.showIcons) ...[
                      Icon(
                        _getIcon(rating),
                        size: 16 * widget.scale,
                        color: isSelected ? rating.color : Colors.white38,
                      ),
                      SizedBox(width: 6 * widget.scale),
                    ],
                    Text(
                      rating.displayName,
                      style: TextStyle(
                        color: isSelected ? rating.color : Colors.white38,
                        fontSize: 14 * widget.scale,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 8 * widget.scale,
        crossAxisSpacing: 8 * widget.scale,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: ratings.map((rating) {
          final isSelected = rating == widget.selected;
          return GestureDetector(
            onTap: () => _onSelect(rating),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isSelected ? rating.color : rating.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12 * widget.scale),
                border: Border.all(
                  color: rating.color.withOpacity(isSelected ? 1 : 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.showIcons)
                    Icon(
                      _getIcon(rating),
                      size: 24 * widget.scale,
                      color: isSelected ? Colors.white : rating.color,
                    ),
                  SizedBox(height: 4 * widget.scale),
                  Text(
                    rating.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : rating.color,
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildDescription() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(widget.selected),
          padding: EdgeInsets.all(12 * widget.scale),
          decoration: BoxDecoration(
            color: widget.selected.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12 * widget.scale),
            border: Border.all(
              color: widget.selected.color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(widget.selected),
                color: widget.selected.color,
                size: 24 * widget.scale,
              ),
              SizedBox(width: 12 * widget.scale),
              Expanded(
                child: Text(
                  widget.selected.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13 * widget.scale,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  IconData _getIcon(ContentRating rating) => switch (rating) {
        ContentRating.pg => Icons.sentiment_satisfied_outlined,
        ContentRating.pg13 => Icons.local_fire_department_outlined,
        ContentRating.r => Icons.whatshot_outlined,
        ContentRating.x => Icons.whatshot_rounded,
        ContentRating.xxx => Icons.local_fire_department_rounded,
      };
}

/// Heat selector display styles
enum TagHeatSelectorStyle {
  /// Horizontal chips (default)
  chips,

  /// Horizontal slider
  slider,

  /// Vertical thermometer
  thermometer,

  /// Grid layout
  grid,
}
