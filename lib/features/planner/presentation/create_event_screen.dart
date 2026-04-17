import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import 'planner_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CREATE EVENT SCREEN
/// Quick event creation: paste text, upload info, or build from scratch.
/// ════════════════════════════════════════════════════════════════════════════

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _pasteController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  _CreateMode _mode = _CreateMode.scratch;

  @override
  void dispose() {
    _titleController.dispose();
    _pasteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableAurora: true,
        enableParticles: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeSelector(),
                      const SizedBox(height: 24),
                      if (_mode == _CreateMode.paste) _buildPasteSection(),
                      if (_mode == _CreateMode.scratch) _buildScratchSection(),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'CREATE EVENT',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFCE93D8),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeChip(_CreateMode.scratch),
        const SizedBox(width: 12),
        _modeChip(_CreateMode.paste),
      ],
    );
  }

  Widget _modeChip(_CreateMode value) {
    final selected = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFCE93D8).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: const Color(0xFFCE93D8).withOpacity(0.5))
              : null,
        ),
        child: Text(
          value.label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFFCE93D8) : Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste event details',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Copy & paste from any event page — we\'ll parse it for you.',
          style: GoogleFonts.inter(
            color: Colors.white30,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _pasteController,
            maxLines: 8,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste event info here...',
              hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.20)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScratchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Event Name', _titleController, 'What\'s happening?'),
        const SizedBox(height: 16),
        _buildField('Location', _locationController, 'Where?'),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildTimePicker(),
      ],
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.20)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _selectedDate != null
                  ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                  : 'Select date',
              style: GoogleFonts.inter(
                color: _selectedDate != null ? Colors.white70 : Colors.white.withValues(alpha: 0.20),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (time != null) setState(() => _selectedTime = time);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Select time',
              style: GoogleFonts.inter(
                color: _selectedTime != null ? Colors.white70 : Colors.white.withValues(alpha: 0.20),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCE93D8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _mode == _CreateMode.paste ? 'PARSE & CREATE' : 'CREATE EVENT',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  void _handleCreate() {
    if (_mode == _CreateMode.paste) {
      final text = _pasteController.text.trim();
      if (text.isEmpty) return;
      final entry = PlannerEntry(
        id: const Uuid().v4(),
        title: text.length > 60 ? '${text.substring(0, 60)}...' : text,
        subtitle: text.length > 60 ? text : null,
        type: PlannerEntryType.event,
        startDate: DateTime.now(),
      );
      Navigator.pop(context, entry);
    } else {
      final title = _titleController.text.trim();
      if (title.isEmpty) return;
      final date = _selectedDate ?? DateTime.now();
      final time = _selectedTime ?? TimeOfDay.now();
      final startDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
      final entry = PlannerEntry(
        id: const Uuid().v4(),
        title: title,
        type: PlannerEntryType.event,
        startDate: startDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );
      Navigator.pop(context, entry);
    }
  }
}

enum _CreateMode {
  scratch,
  paste;

  String get label {
    switch (this) {
      case scratch:
        return 'From Scratch';
      case paste:
        return 'Paste Details';
    }
  }
}
