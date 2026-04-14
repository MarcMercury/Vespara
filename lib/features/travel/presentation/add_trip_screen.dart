import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ADD TRIP SCREEN
/// Create a new travel plan with destination, dates, certainty, and visibility
/// ════════════════════════════════════════════════════════════════════════════

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accommodationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  TripCertainty _certainty = TripCertainty.tentative;
  TripVisibility _visibility = TripVisibility.connections;
  TravelType _travelType = TravelType.leisure;
  bool _isFlexible = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _accommodationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
          'New Trip',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _saving
                    ? VesparaColors.secondary
                    : const Color(0xFF00BFA6),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Trip Name',
              hint: 'e.g. Miami Beach Weekend',
              icon: Icons.flight_takeoff_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Give your trip a name' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'e.g. Miami',
                    icon: Icons.location_city_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _countryController,
                    label: 'Country',
                    hint: 'e.g. USA',
                    icon: Icons.public_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date pickers
            _buildSectionLabel('DATES'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: 'Start',
                    date: _startDate,
                    onPick: (d) => setState(() {
                      _startDate = d;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 1));
                      }
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: VesparaColors.secondary.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: _buildDatePicker(
                    label: 'End',
                    date: _endDate,
                    onPick: (d) => setState(() => _endDate = d),
                    firstDate: _startDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              'Dates are flexible',
              Icons.swap_horiz_rounded,
              _isFlexible,
              (v) => setState(() => _isFlexible = v),
            ),
            const SizedBox(height: 24),

            // Travel type
            _buildSectionLabel('TRIP TYPE'),
            const SizedBox(height: 12),
            _buildChipSelector<TravelType>(
              values: TravelType.values,
              selected: _travelType,
              labelBuilder: (t) => '${t.emoji} ${t.label}',
              onSelected: (t) => setState(() => _travelType = t),
            ),
            const SizedBox(height: 24),

            // Certainty
            _buildSectionLabel('HOW SURE ARE YOU?'),
            const SizedBox(height: 12),
            _buildCertaintySelector(),
            const SizedBox(height: 24),

            // Visibility
            _buildSectionLabel('WHO CAN SEE THIS'),
            const SizedBox(height: 12),
            _buildChipSelector<TripVisibility>(
              values: TripVisibility.values,
              selected: _visibility,
              labelBuilder: (v) => '${v.icon} ${v.label}',
              onSelected: (v) => setState(() => _visibility = v),
            ),
            const SizedBox(height: 24),

            // Optional fields
            _buildSectionLabel('DETAILS (OPTIONAL)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'What\'s the vibe?',
              icon: Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _accommodationController,
              label: 'Accommodation',
              hint: 'Hotel, Airbnb, etc.',
              icon: Icons.hotel_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Anything else...',
              icon: Icons.sticky_note_2_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: VesparaColors.secondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: VesparaColors.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: VesparaColors.secondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: VesparaColors.secondary.withOpacity(0.5),
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFF00BFA6).withOpacity(0.6))
            : null,
        filled: true,
        fillColor: VesparaColors.surface.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: VesparaColors.secondary.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: VesparaColors.secondary.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF00BFA6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPick,
    DateTime? firstDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: VesparaColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: VesparaColors.secondary.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: const Color(0xFF00BFA6).withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VesparaColors.surface.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: VesparaColors.secondary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00BFA6).withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.primary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00BFA6),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelector<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((val) {
        final isSelected = val == selected;
        return GestureDetector(
          onTap: () => onSelected(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00BFA6).withOpacity(0.15)
                  : VesparaColors.surface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00BFA6).withOpacity(0.5)
                    : VesparaColors.secondary.withOpacity(0.1),
              ),
            ),
            child: Text(
              labelBuilder(val),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF00BFA6)
                    : VesparaColors.secondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertaintySelector() {
    return Column(
      children: TripCertainty.values.map((cert) {
        final isSelected = cert == _certainty;
        return GestureDetector(
          onTap: () => setState(() => _certainty = cert),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cert.color.withOpacity(0.1)
                  : VesparaColors.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? cert.color.withOpacity(0.4)
                    : VesparaColors.secondary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cert.color.withOpacity(isSelected ? 0.2 : 0.08),
                  ),
                  child: Icon(cert.icon, size: 16, color: cert.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cert.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? cert.color : VesparaColors.secondary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 20, color: cert.color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final plan = TravelPlan(
      id: '',
      userId: userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      destinationCity: _cityController.text.trim(),
      destinationCountry: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      isFlexible: _isFlexible,
      certainty: _certainty,
      visibility: _visibility,
      travelType: _travelType,
      accommodation: _accommodationController.text.trim().isNotEmpty
          ? _accommodationController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    final result = await TravelService.instance.createTrip(plan);

    if (mounted) {
      setState(() => _saving = false);
      if (result != null) {
        Navigator.pop(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create trip. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
    }
  }
}
