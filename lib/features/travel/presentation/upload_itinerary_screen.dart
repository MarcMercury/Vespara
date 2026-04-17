import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// UPLOAD ITINERARY SCREEN
/// Upload a travel itinerary file, AI parses it, user reviews & saves trips
/// ════════════════════════════════════════════════════════════════════════════

class UploadItineraryScreen extends StatefulWidget {
  const UploadItineraryScreen({super.key});

  @override
  State<UploadItineraryScreen> createState() => _UploadItineraryScreenState();
}

enum _ScreenState { pickFile, parsing, review, saving }

class _UploadItineraryScreenState extends State<UploadItineraryScreen> {
  _ScreenState _state = _ScreenState.pickFile;
  String? _fileName;
  String? _errorMessage;

  // Parsed trips from AI
  List<_ParsedTrip> _parsedTrips = [];

  final _aiService = AIService.instance;

  // ── File Pick & Parse ─────────────────────────────────────────────────

  Future<void> _pickAndParse() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'html', 'htm', 'eml', 'ics'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _fileName = file.name;
        _state = _ScreenState.parsing;
        _errorMessage = null;
      });

      // Read file content as text
      String itineraryText;
      if (file.bytes != null) {
        itineraryText = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (!kIsWeb && file.path != null) {
        itineraryText = await File(file.path!).readAsString();
      } else {
        setState(() {
          _errorMessage = 'Could not read file contents.';
          _state = _ScreenState.pickFile;
        });
        return;
      }

      // Trim excessive content
      if (itineraryText.length > 8000) {
        itineraryText = itineraryText.substring(0, 8000);
      }

      if (itineraryText.trim().isEmpty) {
        setState(() {
          _errorMessage = 'File appears to be empty or unreadable.';
          _state = _ScreenState.pickFile;
        });
        return;
      }

      // Send to AI for parsing
      final aiResult =
          await _aiService.parseItinerary(itineraryText: itineraryText);

      aiResult.when(
        success: (trips) {
          if (trips.isEmpty) {
            setState(() {
              _errorMessage =
                  'Could not extract any trips from this file. Try a different format or enter manually.';
              _state = _ScreenState.pickFile;
            });
            return;
          }
          setState(() {
            _parsedTrips =
                trips.map((t) => _ParsedTrip.fromAiJson(t)).toList();
            _state = _ScreenState.review;
          });
        },
        failure: (error) {
          setState(() {
            _errorMessage = 'Parsing failed: ${error.message}';
            _state = _ScreenState.pickFile;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _state = _ScreenState.pickFile;
      });
    }
  }

  // ── Paste text flow ───────────────────────────────────────────────────

  Future<void> _showPasteDialog() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: Text(
          'Paste Itinerary',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            color: VesparaColors.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 12,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: VesparaColors.primary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Paste your itinerary email, booking confirmation, or trip details here...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary.withOpacity(0.5),
              ),
              filled: true,
              fillColor: VesparaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: VesparaColors.secondary.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Parse',
                style: GoogleFonts.inter(color: const Color(0xFF00BFA6))),
          ),
        ],
      ),
    );

    if (text == null || text.trim().isEmpty) return;

    setState(() {
      _fileName = 'Pasted text';
      _state = _ScreenState.parsing;
      _errorMessage = null;
    });

    final aiResult = await _aiService.parseItinerary(
      itineraryText: text.length > 8000 ? text.substring(0, 8000) : text,
    );

    aiResult.when(
      success: (trips) {
        if (trips.isEmpty) {
          setState(() {
            _errorMessage =
                'Could not extract any trips. Try more detailed text or enter manually.';
            _state = _ScreenState.pickFile;
          });
          return;
        }
        setState(() {
          _parsedTrips = trips.map((t) => _ParsedTrip.fromAiJson(t)).toList();
          _state = _ScreenState.review;
        });
      },
      failure: (error) {
        setState(() {
          _errorMessage = 'Parsing failed: ${error.message}';
          _state = _ScreenState.pickFile;
        });
      },
    );
  }

  // ── Save trips ────────────────────────────────────────────────────────

  Future<void> _saveTrips() async {
    final selected = _parsedTrips.where((t) => t.selected).toList();
    if (selected.isEmpty) return;

    setState(() => _state = _ScreenState.saving);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Not authenticated.';
        _state = _ScreenState.review;
      });
      return;
    }

    TravelPlan? lastCreated;
    int successCount = 0;

    for (final trip in selected) {
      final plan = TravelPlan(
        id: '',
        userId: userId,
        title: trip.title,
        description: trip.description,
        destinationCity: trip.city,
        destinationCountry:
            trip.country.isNotEmpty ? trip.country : null,
        startDate: trip.startDate,
        endDate: trip.endDate,
        travelType: trip.travelType,
        accommodation: trip.accommodation,
        notes: trip.notes,
        certainty: trip.certainty,
        visibility: trip.visibility,
        createdAt: DateTime.now(),
      );

      final result = await TravelService.instance.createTrip(plan);
      if (result != null) {
        lastCreated = result;
        successCount++;
      }
    }

    if (mounted) {
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount == 1
                  ? 'Trip created!'
                  : '$successCount trips created!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF00BFA6),
          ),
        );
        Navigator.pop(context, lastCreated);
      } else {
        setState(() {
          _errorMessage = 'Failed to save trips. Please try again.';
          _state = _ScreenState.review;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: VesparaColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Itinerary',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.pickFile:
        return _buildPickFileState();
      case _ScreenState.parsing:
        return _buildParsingState();
      case _ScreenState.review:
        return _buildReviewState();
      case _ScreenState.saving:
        return _buildSavingState();
    }
  }

  // ── Pick File State ───────────────────────────────────────────────────

  Widget _buildPickFileState() {
    return Padding(
      key: const ValueKey('pickFile'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00BFA6).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 40,
              color: Color(0xFF00BFA6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Import Your Itinerary',
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a booking confirmation, itinerary email, or travel plan to extract your trip details.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: VesparaColors.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported: .txt, .html, .eml, .ics',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: VesparaColors.secondary.withOpacity(0.6),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFEF5350), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Upload file button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickAndParse,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                'Choose File',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA6),
                foregroundColor: VesparaColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Paste text button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.content_paste_rounded),
              label: Text(
                'Paste Text Instead',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00BFA6),
                side: BorderSide(
                  color: const Color(0xFF00BFA6).withOpacity(0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Parsing State ─────────────────────────────────────────────────────

  Widget _buildParsingState() {
    return Center(
      key: const ValueKey('parsing'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF00BFA6),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Parsing Itinerary...',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reading $_fileName and extracting trip details',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Review State ──────────────────────────────────────────────────────

  Widget _buildReviewState() {
    final selectedCount = _parsedTrips.where((t) => t.selected).length;

    return Column(
      key: const ValueKey('review'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: const Color(0xFF00BFA6).withOpacity(0.6), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found ${_parsedTrips.length} trip${_parsedTrips.length == 1 ? '' : 's'} — review and save',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VesparaColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFFEF5350)),
            ),
          ),

        // Trip cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: _parsedTrips.length,
            itemBuilder: (ctx, i) => _buildTripReviewCard(_parsedTrips[i], i),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.3),
            border: Border(
              top: BorderSide(
                color: VesparaColors.secondary.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount trip${selectedCount == 1 ? '' : 's'} selected',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VesparaColors.secondary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? _saveTrips : null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Save Trips',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  foregroundColor: VesparaColors.background,
                  disabledBackgroundColor:
                      VesparaColors.secondary.withOpacity(0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripReviewCard(_ParsedTrip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VesparaColors.surface.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trip.selected
              ? const Color(0xFF00BFA6).withOpacity(0.3)
              : VesparaColors.secondary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Header with checkbox
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  trip.travelType.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                      Text(
                        '${trip.city}${trip.country.isNotEmpty ? ', ${trip.country}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: trip.selected,
                  onChanged: (v) => setState(
                      () => _parsedTrips[index].selected = v ?? true),
                  activeColor: const Color(0xFF00BFA6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Date & details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  '${DateFormat('MMM d, yyyy').format(trip.startDate)} – ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                ),
                _buildDetailRow(
                    trip.certainty.icon,
                    trip.certainty.label,
                    color: trip.certainty.color),
                if (trip.accommodation != null && trip.accommodation!.isNotEmpty)
                  _buildDetailRow(
                      Icons.hotel_rounded, trip.accommodation!),
                if (trip.description != null && trip.description!.isNotEmpty)
                  _buildDetailRow(
                      Icons.description_rounded, trip.description!),
                if (trip.notes != null && trip.notes!.isNotEmpty)
                  _buildDetailRow(
                      Icons.sticky_note_2_rounded, trip.notes!),
              ],
            ),
          ),

          // Edit inline
          InkWell(
            onTap: () => _editTrip(index),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: VesparaColors.secondary.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded,
                      size: 14,
                      color: const Color(0xFF00BFA6).withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Details',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00BFA6).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 14,
              color: color ?? VesparaColors.secondary.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color ?? VesparaColors.secondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit trip dialog ──────────────────────────────────────────────────

  Future<void> _editTrip(int index) async {
    final trip = _parsedTrips[index];
    final titleCtrl = TextEditingController(text: trip.title);
    final cityCtrl = TextEditingController(text: trip.city);
    final countryCtrl = TextEditingController(text: trip.country);
    final descCtrl = TextEditingController(text: trip.description ?? '');
    final accomCtrl = TextEditingController(text: trip.accommodation ?? '');
    final notesCtrl = TextEditingController(text: trip.notes ?? '');
    var startDate = trip.startDate;
    var endDate = trip.endDate;
    var certainty = trip.certainty;
    var visibility = trip.visibility;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VesparaColors.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Trip',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editField(titleCtrl, 'Trip Name'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(flex: 3, child: _editField(cityCtrl, 'City')),
                      const SizedBox(width: 10),
                      Expanded(
                          flex: 2, child: _editField(countryCtrl, 'Country')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _editDateButton(
                          ctx,
                          'Start',
                          startDate,
                          (d) => setSheetState(() => startDate = d),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _editDateButton(
                          ctx,
                          'End',
                          endDate,
                          (d) => setSheetState(() => endDate = d),
                          firstDate: startDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _editField(accomCtrl, 'Accommodation'),
                  const SizedBox(height: 14),
                  Text('CERTAINTY', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 1.2, color: VesparaColors.secondary,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: TripCertainty.values.map((c) {
                      final sel = c == certainty;
                      return GestureDetector(
                        onTap: () => setSheetState(() => certainty = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? c.color.withOpacity(0.15) : VesparaColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? c.color.withOpacity(0.5) : VesparaColors.secondary.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon, size: 14, color: sel ? c.color : VesparaColors.secondary),
                              const SizedBox(width: 4),
                              Text(c.label, style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? c.color : VesparaColors.secondary,
                              )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('VISIBILITY', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 1.2, color: VesparaColors.secondary,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: TripVisibility.values.map((v) {
                      final sel = v == visibility;
                      return GestureDetector(
                        onTap: () => setSheetState(() => visibility = v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF00BFA6).withOpacity(0.12) : VesparaColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? const Color(0xFF00BFA6).withOpacity(0.4) : VesparaColors.secondary.withOpacity(0.15),
                            ),
                          ),
                          child: Text('${v.icon} ${v.label}', style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? const Color(0xFF00BFA6) : VesparaColors.secondary,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _editField(descCtrl, 'Description', maxLines: 2),
                  const SizedBox(height: 10),
                  _editField(notesCtrl, 'Notes', maxLines: 2),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA6),
                        foregroundColor: VesparaColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Update',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == true) {
      setState(() {
        _parsedTrips[index] = _ParsedTrip(
          title: titleCtrl.text.trim(),
          city: cityCtrl.text.trim(),
          country: countryCtrl.text.trim(),
          startDate: startDate,
          endDate: endDate,
          travelType: trip.travelType,
          certainty: certainty,
          visibility: visibility,
          accommodation:
              accomCtrl.text.trim().isNotEmpty ? accomCtrl.text.trim() : null,
          description:
              descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          notes:
              notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
          selected: trip.selected,
        );
      });
    }

    titleCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();
    descCtrl.dispose();
    accomCtrl.dispose();
    notesCtrl.dispose();
  }

  Widget _editField(TextEditingController ctrl, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 13, color: VesparaColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            fontSize: 12, color: VesparaColors.secondary),
        filled: true,
        fillColor: VesparaColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: VesparaColors.secondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: VesparaColors.secondary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BFA6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _editDateButton(
    BuildContext ctx,
    String label,
    DateTime date,
    ValueChanged<DateTime> onPick, {
    DateTime? firstDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00BFA6),
                surface: Color(0xFF1E1830),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: VesparaColors.secondary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14,
                color: const Color(0xFF00BFA6).withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              '$label: ${DateFormat('MMM d').format(date)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: VesparaColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Saving State ──────────────────────────────────────────────────────

  Widget _buildSavingState() {
    return const Center(
      key: ValueKey('saving'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF00BFA6),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text('Saving trips...'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARSED TRIP (local mutable model for the review step)
// ═══════════════════════════════════════════════════════════════════════════

class _ParsedTrip {
  String title;
  String city;
  String country;
  DateTime startDate;
  DateTime endDate;
  TravelType travelType;
  TripCertainty certainty;
  TripVisibility visibility;
  String? accommodation;
  String? description;
  String? notes;
  bool selected;

  _ParsedTrip({
    required this.title,
    required this.city,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.travelType,
    this.certainty = TripCertainty.tentative,
    this.visibility = TripVisibility.connections,
    this.accommodation,
    this.description,
    this.notes,
    this.selected = true,
  });

  factory _ParsedTrip.fromAiJson(Map<String, dynamic> json) {
    DateTime parseDate(String? dateStr, DateTime fallback) {
      if (dateStr == null || dateStr.isEmpty) return fallback;
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return fallback;
      }
    }

    final now = DateTime.now();
    final defaultStart = now.add(const Duration(days: 7));
    final defaultEnd = now.add(const Duration(days: 14));

    return _ParsedTrip(
      title: json['title'] as String? ?? 'Untitled Trip',
      city: json['destination_city'] as String? ?? '',
      country: json['destination_country'] as String? ?? '',
      startDate: parseDate(json['start_date'] as String?, defaultStart),
      endDate: parseDate(json['end_date'] as String?, defaultEnd),
      travelType:
          TravelType.fromString(json['travel_type'] as String?),
      accommodation: json['accommodation'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
