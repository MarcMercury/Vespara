import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'user_dna_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DEEP BIO GENERATOR - Psychologically-Informed Bio Creation
/// ════════════════════════════════════════════════════════════════════════════
///
/// Replaces the old template-based bio generation with deep AI that:
/// - Uses the full UserDNA (50+ signals) instead of just name + tags
/// - Generates bios that feel written by the person, not by a bot
/// - Creates distinct voice/tone based on communication archetype
/// - Adapts to the user's heat level, seeking goals, and personality
/// - Isn't generic — two people with different DNA get wildly different bios
///
/// The old approach: "Hey, I'm {name}. Into {tag1}, {tag2}, {tag3}."
/// The new approach: A bio that sounds like only this specific person could
///   have written it, because it's informed by their entire psychological profile.

class DeepBioGenerator {
  DeepBioGenerator._();
  static DeepBioGenerator? _instance;
  static DeepBioGenerator get instance => _instance ??= DeepBioGenerator._();

  final AIService _aiService = AIService.instance;
  final UserDNAService _dnaService = UserDNAService.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE BIO - The Main Event
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a deeply personalized bio using full DNA context.
  /// Returns 3 options with different voice/style calibrations.
  Future<List<BioGenResult>> generateDeepBios({
    String? userId,
    String? existingBio,
    List<String> avoidPhrases = const [],
  }) async {
    final dna = await _dnaService.buildUserDNA(userId: userId);
    if (dna == null) return _fallbackBios();

    final voiceGuide = _buildVoiceGuide(dna);
    final contextBrief = dna.toContextBrief();

    // Generate 3 distinct bio styles calibrated to this person's DNA
    final styles = _selectStylesForDNA(dna);
    final results = <BioGenResult>[];

    for (final style in styles) {
      final bio = await _generateSingleBio(
        dna: dna,
        contextBrief: contextBrief,
        voiceGuide: voiceGuide,
        style: style,
        existingBio: existingBio,
        avoidPhrases: avoidPhrases,
      );
      if (bio != null) results.add(bio);
    }

    return results.isNotEmpty ? results : _fallbackBios();
  }

  /// Generate a single bio for a specific style
  Future<BioGenResult?> _generateSingleBio({
    required UserDNA dna,
    required String contextBrief,
    required String voiceGuide,
    required BioStyle style,
    String? existingBio,
    List<String> avoidPhrases = const [],
  }) async {
    final systemPrompt = '''You are writing a dating profile bio for the app Vespara — an exclusive, sex-positive social networking platform for adults 21+.

YOUR VOICE CALIBRATION FOR THIS PERSON:
$voiceGuide

STYLE FOR THIS VERSION: ${style.name}
${style.description}

CRITICAL RULES:
- Write in FIRST PERSON as if you ARE this person
- 2-4 sentences, under 200 characters ideally (280 max)
- No hashtags, no emojis unless their communication archetype uses them
- No clichés ("living my best life", "partner in crime", "love to laugh")
- Never list traits directly — EMBODY them through word choice and tone
- The bio should make someone curious and want to know more
- Must feel authentic to their specific personality profile, not generic
- Respect their heat level and discretion preferences
- If they're discreet, keep it tasteful and suggestive, not explicit
- If they're nuclear heat, be bold but still classy
- Don't mention the app name or that this is a dating profile
${existingBio != null ? '- Their current bio is: "$existingBio" — make something distinctly different' : ''}
${avoidPhrases.isNotEmpty ? '- AVOID using these phrases: ${avoidPhrases.join(", ")}' : ''}''';

    final userPrompt = '''Generate a ${style.name.toLowerCase()} bio for this user.

$contextBrief

Remember: This bio should feel like it could ONLY have been written by this specific person. Use their unique combination of traits, energy, desires, and lifestyle to create something original.''';

    final result = await _aiService.chat(
      systemPrompt: systemPrompt,
      prompt: userPrompt,
      model: AIModel.gpt4oMini,
      temperature: style.temperature,
      maxTokens: 200,
    );

    return result.fold(
      onSuccess: (response) => BioGenResult(
        bio: _cleanBio(response.content),
        style: style,
        tokensUsed: response.totalTokens,
      ),
      onFailure: (_) => null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE CALIBRATION - Make it Sound Like Them
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a detailed voice guide based on DNA dimensions.
  /// This is what makes two different users get completely different-sounding bios.
  String _buildVoiceGuide(UserDNA dna) {
    final parts = <String>[];

    // Communication archetype → writing voice
    switch (dna.communicationArchetype) {
      case 'jokester':
        parts.add('VOICE: Witty, irreverent, uses dry humor and playful sarcasm. Sentences are punchy.');
        parts.add('TONE: Confident and fun, like someone you\'d want at your dinner party.');
        break;
      case 'deep_diver':
        parts.add('VOICE: Thoughtful, articulate, comfortable with vulnerability. Uses evocative language.');
        parts.add('TONE: Magnetic — the kind of person who says something at a party that makes the room go quiet.');
        break;
      case 'storyteller':
        parts.add('VOICE: Vivid, descriptive, paints pictures with words. Slightly longer sentences.');
        parts.add('TONE: Inviting and warm, like the opening line of a novel you can\'t put down.');
        break;
      case 'rapid_fire':
        parts.add('VOICE: Quick, energetic, punchy. Short sentences. Maybe a dash or two.');
        parts.add('TONE: Electric — like texting your most exciting friend.');
        break;
      case 'curious_explorer':
        parts.add('VOICE: Open, inquisitive, genuinely interested. May pose a subtle question.');
        parts.add('TONE: Approachable and genuine, like someone who really wants to hear your story.');
        break;
      default: // slow_burner
        parts.add('VOICE: Measured, calm, confident. Doesn\'t try too hard. Understated.');
        parts.add('TONE: Cool and self-assured — less is more.');
    }

    // Social energy → energy level of writing
    switch (dna.socialEnergyProfile) {
      case 'high_energy_social':
        parts.add('ENERGY: High — exclamation points are OK (one max), bold statements.');
        break;
      case 'selective_introvert':
        parts.add('ENERGY: Low-key — calm confidence, no exclamation points, quiet magnetism.');
        break;
      case 'quality_over_quantity':
        parts.add('ENERGY: Selective — implies depth, values substance over flash.');
        break;
      default:
        parts.add('ENERGY: Balanced — neither over-the-top nor too reserved.');
    }

    // Intimacy blueprint → what to hint at
    switch (dna.intimacyBlueprint) {
      case 'romantic_connection_first':
        parts.add('SUBTEXT: Romance and emotional connection. Sensual but not explicit.');
        break;
      case 'power_exchange_explorer':
        parts.add('SUBTEXT: Confidence and knowing what they want. Subtle power dynamic hints.');
        break;
      case 'curious_newcomer':
        parts.add('SUBTEXT: Openness and genuine curiosity. Excited energy without pretense.');
        break;
      case 'intensity_seeker':
        parts.add('SUBTEXT: Unapologetic intensity. Direct about desires without being crude.');
        break;
      case 'sensual_connection':
        parts.add('SUBTEXT: Warmth, touch, sensuality. Poetic rather than explicit.');
        break;
      default:
        parts.add('SUBTEXT: Open and adaptable. Hint at versatility without revealing everything.');
    }

    // Lifestyle temperature → overall heat of writing
    switch (dna.lifestyleTemperature) {
      case 'fire':
        parts.add('HEAT: Bold, unapologetic, no pretense about what they want.');
        break;
      case 'warm':
        parts.add('HEAT: Warm and suggestive, leaves things to imagination.');
        break;
      case 'cool':
        parts.add('HEAT: Cool exterior, depth underneath. Measured.');
        break;
      case 'ice':
        parts.add('HEAT: Reserved, dignified. Attraction through mystery, not exposure.');
        break;
      default:
        parts.add('HEAT: Balanced — neither cold nor overtly sensual.');
    }

    // Discretion modifier
    if (dna.discretionLevel == 'very_discreet') {
      parts.add('DISCRETION: HIGH — be elegant and subtle. Nothing that reveals too much. Think "private club", not "open house".');
    } else if (dna.discretionLevel == 'discreet') {
      parts.add('DISCRETION: MODERATE — tasteful and somewhat guarded. Intriguing without overexposing.');
    }

    // Attachment style → emotional vibe
    if (dna.attachmentStyle == 'secure') {
      parts.add('EMOTIONAL VIBE: Grounded, comfortable, emotionally available.');
    } else if (dna.attachmentStyle == 'avoidant') {
      parts.add('EMOTIONAL VIBE: Independent, values space, doesn\'t try to please everyone.');
    } else if (dna.attachmentStyle == 'anxious') {
      parts.add('EMOTIONAL VIBE: Warm, eager to connect, honest about wanting connection.');
    }

    return parts.join('\n');
  }

  /// Select the 3 bio styles best suited to this user's DNA.
  /// Not every style works for every person.
  List<BioStyle> _selectStylesForDNA(UserDNA dna) {
    final styles = <BioStyle>[];

    // Style 1: Always include their natural voice
    styles.add(_getNaturalStyle(dna));

    // Style 2: A more daring version of themselves
    styles.add(_getBoldStyle(dna));

    // Style 3: A contrasting approach (opposites intrigue)
    styles.add(_getContrastStyle(dna));

    return styles;
  }

  BioStyle _getNaturalStyle(UserDNA dna) {
    switch (dna.communicationArchetype) {
      case 'jokester':
        return const BioStyle(
          name: 'Effortlessly Witty',
          description: 'Lean into their natural humor. Quick, clever, makes someone laugh.',
          temperature: 0.85,
        );
      case 'deep_diver':
        return const BioStyle(
          name: 'Magnetic Depth',
          description: 'Lean into their thoughtfulness. One sentence that stops you scrolling.',
          temperature: 0.7,
        );
      case 'storyteller':
        return const BioStyle(
          name: 'Captivating Narrative',
          description: 'Mini-story energy. Paint a scene that draws someone in.',
          temperature: 0.8,
        );
      case 'curious_explorer':
        return const BioStyle(
          name: 'Genuine & Open',
          description: 'Warm, approachable, makes someone feel like they could talk to this person for hours.',
          temperature: 0.75,
        );
      default:
        return const BioStyle(
          name: 'Cool Confidence',
          description: 'Understated, doesn\'t try too hard. The less-is-more approach.',
          temperature: 0.7,
        );
    }
  }

  BioStyle _getBoldStyle(UserDNA dna) {
    if (dna.riskTolerance > 0.6) {
      return const BioStyle(
        name: 'Unapologetically Bold',
        description: 'Direct about desires without being crude. Confidence radiates. No pretense.',
        temperature: 0.9,
      );
    }
    if (dna.lifestyleTemperature == 'fire' || dna.lifestyleTemperature == 'warm') {
      return const BioStyle(
        name: 'Provocatively Confident',
        description: 'Suggestive, self-assured, leaves them wanting to know more. Tasteful tease.',
        temperature: 0.85,
      );
    }
    return const BioStyle(
      name: 'Quietly Powerful',
      description: 'Understated confidence that commands attention without raising voice.',
      temperature: 0.75,
    );
  }

  BioStyle _getContrastStyle(UserDNA dna) {
    // Give them something unexpected — often the most compelling bios
    // are slightly against type
    if (dna.communicationArchetype == 'jokester') {
      return const BioStyle(
        name: 'Unexpectedly Sincere',
        description: 'Drop the jokes for a moment. One honest truth that catches people off guard.',
        temperature: 0.7,
      );
    }
    if (dna.communicationArchetype == 'deep_diver') {
      return const BioStyle(
        name: 'Playfully Light',
        description: 'Show the fun side. Self-deprecating, breezy, surprisingly funny.',
        temperature: 0.85,
      );
    }
    if (dna.socialEnergyProfile == 'selective_introvert') {
      return const BioStyle(
        name: 'Intriguing Enigma',
        description: 'Mysterious. A single evocative image or statement. Magnetic silence.',
        temperature: 0.8,
      );
    }
    return const BioStyle(
      name: 'Charmingly Unexpected',
      description: 'Something surprising. A non-obvious angle that makes them memorable.',
      temperature: 0.85,
    );
  }

  String _cleanBio(String raw) {
    var bio = raw.trim();
    // Remove surrounding quotes if AI added them
    if (bio.startsWith('"') && bio.endsWith('"')) {
      bio = bio.substring(1, bio.length - 1);
    }
    if (bio.startsWith("'") && bio.endsWith("'")) {
      bio = bio.substring(1, bio.length - 1);
    }
    // Remove any "Bio:" or "Here's" prefix
    bio = bio.replaceAll(RegExp(r"^(Bio:|Here's.*?:|Option \d+:)\s*", caseSensitive: false), '');
    return bio.trim();
  }

  List<BioGenResult> _fallbackBios() => [
        BioGenResult(
          bio: 'New here! Still crafting the perfect intro. Ask me anything.',
          style: const BioStyle(
            name: 'Placeholder',
            description: 'Fallback',
            temperature: 0,
          ),
          tokensUsed: 0,
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING BIO - Generate During Signup
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a bio during onboarding using all the data collected so far.
  /// This is called from the onboarding screen's AI bio step.
  Future<String> generateOnboardingBio({
    required String name,
    required List<String> traits,
    required List<String> seeking,
    required List<String> relationshipStatus,
    required String heatLevel,
    required List<String> hardLimits,
    required List<String> availability,
    String? schedulingStyle,
    String? hostingStatus,
    String? discretionLevel,
    String? occupation,
    String? city,
    String? state,
    List<String> gender = const [],
    List<String> orientation = const [],
    double bandwidth = 0.5,
  }) async {
    // Build a mini-DNA for onboarding (no behavior data yet)
    final contextParts = <String>[
      'Name: $name',
      if (occupation != null) 'Occupation: $occupation',
      if (city != null) 'Location: $city${state != null ? ", $state" : ""}',
      if (gender.isNotEmpty) 'Gender: ${gender.join(", ")}',
      if (orientation.isNotEmpty) 'Orientation: ${orientation.join(", ")}',
      'Relationship status: ${relationshipStatus.join(", ")}',
      'Seeking: ${seeking.join(", ")}',
      'Personality traits: ${traits.join(", ")}',
      'Heat level: $heatLevel',
      if (hardLimits.isNotEmpty) 'Hard limits: ${hardLimits.join(", ")}',
      'Availability: ${availability.join(", ")}',
      if (schedulingStyle != null) 'Scheduling style: $schedulingStyle',
      if (hostingStatus != null) 'Hosting: $hostingStatus',
      if (discretionLevel != null) 'Discretion: $discretionLevel',
      'Bandwidth: ${(bandwidth * 100).toInt()}%',
    ];

    // Determine voice from traits
    final isPlayful = traits.any((t) =>
        t.contains('Witty') || t.contains('Mischievous') || t.contains('Playful'));
    final isCalm = traits.any((t) =>
        t.contains('Calm') || t.contains('Gentle'));
    final isDominant = traits.any((t) => t.contains('Dominant'));
    final isExperienced = traits.any((t) => t.contains('Experienced'));
    final isBeginner = traits.any((t) => t.contains('Beginner') || t.contains('Curious'));

    String voiceGuide;
    if (isPlayful) {
      voiceGuide = 'Write with wit, humor, and playful energy. Punchy sentences.';
    } else if (isCalm) {
      voiceGuide = 'Write with quiet confidence and warmth. Measured, not loud.';
    } else if (isDominant && isExperienced) {
      voiceGuide = 'Write with unapologetic confidence. Direct. Knows what they want.';
    } else if (isBeginner) {
      voiceGuide = 'Write with genuine curiosity and openness. Excited but not naive.';
    } else {
      voiceGuide = 'Write with balanced confidence. Approachable and authentic.';
    }

    // Discretion calibration
    if (discretionLevel == 'very_discreet') {
      voiceGuide += ' Keep it extremely tasteful and suggestive rather than explicit.';
    }

    final systemPrompt = '''You are writing a first dating profile bio for "${name}" on Vespara, an exclusive adult social networking app.

$voiceGuide

RULES:
- Write in FIRST PERSON as if you are this person
- 2-3 sentences, under 200 characters ideally
- No hashtags, emojis, or bullet points
- No clichés ("living my best life", "partner in crime")
- Never list their traits — EMBODY them through word choice
- The bio should make someone want to swipe right and start a conversation
- Must reflect their UNIQUE combination — not something that could apply to anyone
- Respect their heat/discretion preferences''';

    final result = await _aiService.chat(
      systemPrompt: systemPrompt,
      prompt: '''Create a standout bio for this person:

${contextParts.join('\n')}

Remember: This should sound like only THIS person could have written it.''',
      model: AIModel.gpt4oMini,
      temperature: 0.85,
      maxTokens: 150,
    );

    return result.fold(
      onSuccess: (response) => _cleanBio(response.content),
      onFailure: (_) => _buildLocalFallback(name, traits, seeking, heatLevel),
    );
  }

  /// Local fallback if AI call fails during onboarding
  String _buildLocalFallback(
    String name,
    List<String> traits,
    List<String> seeking,
    String heatLevel,
  ) {
    final isPlayful = traits.any((t) => t.contains('Witty') || t.contains('Mischievous'));
    final isCalm = traits.any((t) => t.contains('Calm'));
    final isDominant = traits.any((t) => t.contains('Dominant'));
    final isBeginner = traits.any((t) => t.contains('Beginner') || t.contains('Curious'));

    // Select a template style based on their traits
    if (isPlayful && heatLevel == 'hot') {
      return "Trouble, but the kind you don't regret. Looking for someone who can keep up.";
    }
    if (isCalm) {
      return "Calm exterior, curious mind. I'd rather have one real conversation than a hundred small talks.";
    }
    if (isDominant) {
      return "I know what I like, and I'm not apologizing for it. Clarity is attractive.";
    }
    if (isBeginner) {
      return "New to this world, open to all of it. Looking for someone patient and exciting in equal measure.";
    }
    return "Still finding the right words. The real me shows up better in conversation.";
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class BioStyle {
  const BioStyle({
    required this.name,
    required this.description,
    required this.temperature,
  });
  final String name;
  final String description;
  final double temperature;
}

class BioGenResult {
  BioGenResult({
    required this.bio,
    required this.style,
    required this.tokensUsed,
  });
  final String bio;
  final BioStyle style;
  final int tokensUsed;
}
