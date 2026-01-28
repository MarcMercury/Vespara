import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - Stick Figure Illustrations
/// Artistic stick figure representations of card actions
/// Each illustration is a CustomPainter for crisp rendering
/// ════════════════════════════════════════════════════════════════════════════

/// Maps card text to an illustration type for consistent imagery
enum LaneIllustration {
  // Innocent/Low Desire
  forehead,        // Forehead kiss
  handshake,       // Handshake
  cheekKiss,       // Cheek peck
  handsTouch,      // Hands touching
  sitTogether,     // Sitting together
  wink,            // Winking
  holdHands,       // Holding hands
  shareDessert,    // Sharing food
  footsie,         // Playing footsie
  slowDance,       // Dancing close
  longHug,         // Long embrace
  neckKiss,        // Kiss on neck
  textFlirt,       // Phone/texting
  massage,         // Back massage
  
  // Medium Desire
  makeOut,         // Making out
  swimNaked,       // Skinny dipping
  lingerie,        // Lingerie
  morningPassion,  // In bed together
  shower,          // Shower together
  whisper,         // Whispering
  selfPleasure,    // Solo figure
  handAction,      // Hand gesture
  oralLow,         // Kneeling figure
  twoTogether,     // Two figures close
  hairPull,        // Hair pulling
  
  // Higher Desire
  oralHigh,        // Oral action
  vacation,        // Beach/vacation
  toyUse,          // With toy
  publicTease,     // Under table
  cabin,           // Cabin scene
  footFetish,      // Foot focus
  airplane,        // Airplane
  allNight,        // Moon and stars
  faceAction,      // Face sitting
  
  // Adventurous
  blindfold,       // Blindfolded figure
  domSub,          // Power dynamic
  bound,           // Tied up
  worship,         // Kneeling worship
  submission,      // Submissive pose
  watch,           // Voyeur eye
  plug,            // Toy insertion
  
  // Kinky
  threesome,       // Three figures
  foursome,        // Four figures
  group,           // Many figures
  ropes,           // Shibari ropes
  whip,            // Whip/flogger
  gag,             // Ball gag
  denial,          // Denial symbol
  clubScene,       // Club/party
  
  // Extreme
  extreme,         // Fire/intensity symbol
  chain,           // Chains
  electric,        // Lightning
  
  // Default
  fire,            // Generic flame
}

/// Get the appropriate illustration for a card based on its text
LaneIllustration getIllustrationForCard(String cardText) {
  final text = cardText.toLowerCase();
  
  // Map text patterns to illustrations
  if (text.contains('forehead') || text.contains('grandma')) return LaneIllustration.forehead;
  if (text.contains('handshake')) return LaneIllustration.handshake;
  if (text.contains('peck') && text.contains('cheek')) return LaneIllustration.cheekKiss;
  if (text.contains('brushing hands') || text.contains('accidentally')) return LaneIllustration.handsTouch;
  if (text.contains('sitting next') || text.contains('bus')) return LaneIllustration.sitTogether;
  if (text.contains('wink')) return LaneIllustration.wink;
  if (text.contains('holding hands')) return LaneIllustration.holdHands;
  if (text.contains('dessert') || text.contains('dinner')) return LaneIllustration.shareDessert;
  if (text.contains('footsie')) return LaneIllustration.footsie;
  if (text.contains('dancing') || text.contains('dance')) return LaneIllustration.slowDance;
  if (text.contains('hug') && text.contains('linger')) return LaneIllustration.longHug;
  if (text.contains('neck')) return LaneIllustration.neckKiss;
  if (text.contains('text') || text.contains('flirty')) return LaneIllustration.textFlirt;
  if (text.contains('massage')) return LaneIllustration.massage;
  if (text.contains('making out') || text.contains('make out')) return LaneIllustration.makeOut;
  if (text.contains('skinny dipping') || text.contains('swimming')) return LaneIllustration.swimNaked;
  if (text.contains('g-string') || text.contains('lingerie')) return LaneIllustration.lingerie;
  if (text.contains('morning') && text.contains('sex')) return LaneIllustration.morningPassion;
  if (text.contains('shower')) return LaneIllustration.shower;
  if (text.contains('dirty talk') || text.contains('whisper')) return LaneIllustration.whisper;
  if (text.contains('masturbation') && !text.contains('toy')) return LaneIllustration.selfPleasure;
  if (text.contains('hand job')) return LaneIllustration.handAction;
  if (text.contains('cunnilingus')) return LaneIllustration.oralLow;
  if (text.contains('vaginal')) return LaneIllustration.twoTogether;
  if (text.contains('hair pull')) return LaneIllustration.hairPull;
  if (text.contains('blow job')) return LaneIllustration.oralHigh;
  if (text.contains('hotel') || text.contains('vacation')) return LaneIllustration.vacation;
  if (text.contains('vibrator') || text.contains('dildo') || text.contains('toy')) return LaneIllustration.toyUse;
  if (text.contains('swallow') || text.contains('creampie')) return LaneIllustration.oralHigh;
  if (text.contains('public') || text.contains('table')) return LaneIllustration.publicTease;
  if (text.contains('cabin') || text.contains('weekend')) return LaneIllustration.cabin;
  if (text.contains('foot')) return LaneIllustration.footFetish;
  if (text.contains('mile high') || text.contains('airplane')) return LaneIllustration.airplane;
  if (text.contains('all-night') || text.contains('all night')) return LaneIllustration.allNight;
  if (text.contains('face sitting')) return LaneIllustration.faceAction;
  if (text.contains('blindfold')) return LaneIllustration.blindfold;
  if (text.contains('dominated') || text.contains('dominant') || text.contains('dom')) return LaneIllustration.domSub;
  if (text.contains('tied') || text.contains('bondage') || text.contains('bound')) return LaneIllustration.bound;
  if (text.contains('worship')) return LaneIllustration.worship;
  if (text.contains('submission') || text.contains('submissive')) return LaneIllustration.submission;
  if (text.contains('voyeur') || text.contains('watch')) return LaneIllustration.watch;
  if (text.contains('plug')) return LaneIllustration.plug;
  if (text.contains('threesome') || text.contains('ffm') || text.contains('mmf') || text.contains('mfm') || text.contains('fmf')) return LaneIllustration.threesome;
  if (text.contains('mfmf') || text.contains('foursome')) return LaneIllustration.foursome;
  if (text.contains('group') || text.contains('gang') || text.contains('mmmm')) return LaneIllustration.group;
  if (text.contains('shibari') || text.contains('rope')) return LaneIllustration.ropes;
  if (text.contains('flogger') || text.contains('whip')) return LaneIllustration.whip;
  if (text.contains('gag')) return LaneIllustration.gag;
  if (text.contains('denial') || text.contains('orgasm')) return LaneIllustration.denial;
  if (text.contains('club') || text.contains('kink') || text.contains('munch')) return LaneIllustration.clubScene;
  if (text.contains('electro') || text.contains('electric')) return LaneIllustration.electric;
  if (text.contains('chain') || text.contains('slave') || text.contains('master')) return LaneIllustration.chain;
  if (text.contains('extreme') || text.contains('torture') || text.contains('fist') || text.contains('breath')) return LaneIllustration.extreme;
  
  // Default to fire/passion
  return LaneIllustration.fire;
}

/// Widget that paints stick figure illustrations
class LaneCardIllustration extends StatelessWidget {
  final LaneIllustration illustration;
  final Color color;
  final double size;
  
  const LaneCardIllustration({
    super.key,
    required this.illustration,
    required this.color,
    this.size = 48,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StickFigurePainter(
        illustration: illustration,
        color: color,
      ),
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  final LaneIllustration illustration;
  final Color color;
  
  _StickFigurePainter({
    required this.illustration,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10; // Base unit for proportions
    
    switch (illustration) {
      case LaneIllustration.forehead:
        _drawKissForehead(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.handshake:
        _drawHandshake(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.cheekKiss:
        _drawCheekKiss(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.handsTouch:
        _drawHandsTouch(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.sitTogether:
        _drawSitTogether(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.wink:
        _drawWink(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.holdHands:
        _drawHoldHands(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.shareDessert:
        _drawShareDessert(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.footsie:
        _drawFootsie(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.slowDance:
        _drawSlowDance(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.longHug:
        _drawHug(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.neckKiss:
        _drawNeckKiss(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.textFlirt:
        _drawTextFlirt(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.massage:
        _drawMassage(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.makeOut:
        _drawMakeOut(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.swimNaked:
        _drawSwimNaked(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.lingerie:
        _drawLingerie(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.morningPassion:
        _drawMorningPassion(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.shower:
        _drawShower(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.whisper:
        _drawWhisper(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.selfPleasure:
        _drawSelfPleasure(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.handAction:
        _drawHandAction(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.oralLow:
      case LaneIllustration.oralHigh:
        _drawOral(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.twoTogether:
        _drawTwoTogether(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.hairPull:
        _drawHairPull(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.vacation:
        _drawVacation(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.toyUse:
        _drawToyUse(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.publicTease:
        _drawPublicTease(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.cabin:
        _drawCabin(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.footFetish:
        _drawFootFetish(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.airplane:
        _drawAirplane(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.allNight:
        _drawAllNight(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.faceAction:
        _drawFaceAction(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.blindfold:
        _drawBlindfold(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.domSub:
        _drawDomSub(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.bound:
        _drawBound(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.worship:
        _drawWorship(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.submission:
        _drawSubmission(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.watch:
        _drawWatch(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.plug:
        _drawPlug(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.threesome:
        _drawThreesome(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.foursome:
        _drawFoursome(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.group:
        _drawGroup(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.ropes:
        _drawRopes(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.whip:
        _drawWhip(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.gag:
        _drawGag(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.denial:
        _drawDenial(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.clubScene:
        _drawClubScene(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.electric:
        _drawElectric(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.chain:
        _drawChain(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.extreme:
        _drawExtreme(canvas, size, paint, fillPaint, unit);
        break;
      case LaneIllustration.fire:
      default:
        _drawFire(canvas, size, paint, fillPaint, unit);
        break;
    }
  }
  
  // Helper to draw a simple stick figure head
  void _drawHead(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }
  
  // Helper to draw stick figure body
  void _drawBody(Canvas canvas, Offset top, Offset bottom, Paint paint) {
    canvas.drawLine(top, bottom, paint);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ILLUSTRATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _drawKissForehead(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    // Two figures, one taller kissing shorter's forehead
    final cx = size.width / 2;
    
    // Left figure (shorter)
    _drawHead(canvas, Offset(cx - 2*unit, 4*unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx - 2*unit, 4.8*unit), Offset(cx - 2*unit, 7*unit), paint); // body
    canvas.drawLine(Offset(cx - 2*unit, 5.5*unit), Offset(cx - 3*unit, 6.5*unit), paint); // left arm
    canvas.drawLine(Offset(cx - 2*unit, 5.5*unit), Offset(cx - 1*unit, 6.5*unit), paint); // right arm
    
    // Right figure (taller, leaning)
    _drawHead(canvas, Offset(cx + 1.5*unit, 3*unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx + 1.5*unit, 3.8*unit), Offset(cx + 2*unit, 7*unit), paint); // body
    canvas.drawLine(Offset(cx + 1.5*unit, 4.5*unit), Offset(cx - 0.5*unit, 4.5*unit), paint); // arm reaching
    
    // Heart above
    _drawSmallHeart(canvas, Offset(cx - 0.5*unit, 2*unit), unit * 0.5, fillPaint);
  }
  
  void _drawHandshake(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two hands meeting in the middle
    canvas.drawLine(Offset(cx - 4*unit, 5*unit), Offset(cx - unit, 5*unit), paint);
    canvas.drawLine(Offset(cx + 4*unit, 5*unit), Offset(cx + unit, 5*unit), paint);
    
    // Clasped hands (X pattern)
    canvas.drawLine(Offset(cx - unit, 4.5*unit), Offset(cx + unit, 5.5*unit), paint);
    canvas.drawLine(Offset(cx - unit, 5.5*unit), Offset(cx + unit, 4.5*unit), paint);
    canvas.drawCircle(Offset(cx, 5*unit), unit * 0.8, paint);
  }
  
  void _drawCheekKiss(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two heads close together
    _drawHead(canvas, Offset(cx - 1.5*unit, 4*unit), unit * 1.2, paint);
    _drawHead(canvas, Offset(cx + 1.5*unit, 4*unit), unit * 1.2, paint);
    
    // Lips/kiss mark
    _drawSmallHeart(canvas, Offset(cx, 3*unit), unit * 0.4, fillPaint);
  }
  
  void _drawHandsTouch(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Two hands from opposite sides, fingers touching
    canvas.drawLine(Offset(cx - 4*unit, cy), Offset(cx - unit, cy), paint);
    canvas.drawLine(Offset(cx + 4*unit, cy), Offset(cx + unit, cy), paint);
    
    // Sparkle at touch point
    canvas.drawCircle(Offset(cx, cy), unit * 0.4, fillPaint);
    canvas.drawLine(Offset(cx, cy - unit), Offset(cx, cy + unit), paint);
    canvas.drawLine(Offset(cx - unit, cy), Offset(cx + unit, cy), paint);
  }
  
  void _drawSitTogether(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Bench/seat
    canvas.drawLine(Offset(unit, 7*unit), Offset(9*unit, 7*unit), paint);
    
    // Two seated figures
    _drawHead(canvas, Offset(cx - 2*unit, 4*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 2*unit, 4.7*unit), Offset(cx - 2*unit, 6*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 6*unit), Offset(cx - 3*unit, 7*unit), paint); // legs bent
    
    _drawHead(canvas, Offset(cx + 2*unit, 4*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx + 2*unit, 4.7*unit), Offset(cx + 2*unit, 6*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 6*unit), Offset(cx + 3*unit, 7*unit), paint);
  }
  
  void _drawWink(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Face circle
    canvas.drawCircle(Offset(cx, cy), unit * 2.5, paint);
    
    // Open eye (left)
    canvas.drawCircle(Offset(cx - unit, cy - 0.5*unit), unit * 0.3, fillPaint);
    
    // Winking eye (right) - just a line
    canvas.drawLine(Offset(cx + 0.5*unit, cy - 0.5*unit), Offset(cx + 1.5*unit, cy - 0.5*unit), paint);
    
    // Smile
    final smilePath = Path();
    smilePath.moveTo(cx - unit, cy + unit);
    smilePath.quadraticBezierTo(cx, cy + 1.8*unit, cx + unit, cy + unit);
    canvas.drawPath(smilePath, paint);
  }
  
  void _drawHoldHands(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two figures walking, holding hands
    _drawHead(canvas, Offset(cx - 2*unit, 2*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 2*unit, 2.7*unit), Offset(cx - 2*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 5*unit), Offset(cx - 3*unit, 7*unit), paint); // leg
    canvas.drawLine(Offset(cx - 2*unit, 5*unit), Offset(cx - 1*unit, 7*unit), paint); // leg
    
    _drawHead(canvas, Offset(cx + 2*unit, 2*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx + 2*unit, 2.7*unit), Offset(cx + 2*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5*unit), Offset(cx + 3*unit, 7*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5*unit), Offset(cx + 1*unit, 7*unit), paint);
    
    // Joined arms
    canvas.drawLine(Offset(cx - 2*unit, 3.5*unit), Offset(cx, 4.5*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 3.5*unit), Offset(cx, 4.5*unit), paint);
    
    // Heart between them
    _drawSmallHeart(canvas, Offset(cx, 2*unit), unit * 0.5, fillPaint);
  }
  
  void _drawShareDessert(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Table
    canvas.drawLine(Offset(unit, 6*unit), Offset(9*unit, 6*unit), paint);
    
    // Two heads
    _drawHead(canvas, Offset(cx - 2*unit, 3*unit), unit * 0.7, paint);
    _drawHead(canvas, Offset(cx + 2*unit, 3*unit), unit * 0.7, paint);
    
    // Dessert in center (circle with cherry)
    canvas.drawCircle(Offset(cx, 5*unit), unit * 0.8, paint);
    canvas.drawCircle(Offset(cx, 4.2*unit), unit * 0.3, fillPaint);
  }
  
  void _drawFootsie(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Table legs
    canvas.drawLine(Offset(2*unit, 2*unit), Offset(2*unit, 8*unit), paint);
    canvas.drawLine(Offset(8*unit, 2*unit), Offset(8*unit, 8*unit), paint);
    
    // Feet touching under table
    canvas.drawLine(Offset(3*unit, 7*unit), Offset(cx, 7*unit), paint); // left foot
    canvas.drawLine(Offset(7*unit, 7*unit), Offset(cx, 7*unit), paint); // right foot
    
    // Sparkle at touch
    canvas.drawCircle(Offset(cx, 7*unit), unit * 0.4, fillPaint);
  }
  
  void _drawSlowDance(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two figures close together
    _drawHead(canvas, Offset(cx - 0.8*unit, 2.5*unit), unit * 0.7, paint);
    _drawHead(canvas, Offset(cx + 0.8*unit, 2.5*unit), unit * 0.7, paint);
    
    // Bodies close
    canvas.drawLine(Offset(cx - 0.8*unit, 3.2*unit), Offset(cx - 0.8*unit, 5.5*unit), paint);
    canvas.drawLine(Offset(cx + 0.8*unit, 3.2*unit), Offset(cx + 0.8*unit, 5.5*unit), paint);
    
    // Legs
    canvas.drawLine(Offset(cx - 0.8*unit, 5.5*unit), Offset(cx - 1.5*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx - 0.8*unit, 5.5*unit), Offset(cx - 0.3*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx + 0.8*unit, 5.5*unit), Offset(cx + 1.5*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx + 0.8*unit, 5.5*unit), Offset(cx + 0.3*unit, 7.5*unit), paint);
    
    // Arms embracing
    canvas.drawLine(Offset(cx - 0.8*unit, 3.8*unit), Offset(cx + 0.8*unit, 4.2*unit), paint);
    canvas.drawLine(Offset(cx + 0.8*unit, 3.8*unit), Offset(cx - 0.8*unit, 4.2*unit), paint);
    
    // Musical notes
    canvas.drawCircle(Offset(cx - 2.5*unit, 1.5*unit), unit * 0.25, fillPaint);
    canvas.drawLine(Offset(cx - 2.5*unit + unit * 0.25, 1.5*unit), Offset(cx - 2.5*unit + unit * 0.25, 0.5*unit), paint);
  }
  
  void _drawHug(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two figures in embrace
    _drawHead(canvas, Offset(cx - unit, 2.5*unit), unit * 0.7, paint);
    _drawHead(canvas, Offset(cx + unit, 2.5*unit), unit * 0.7, paint);
    
    // Bodies
    canvas.drawLine(Offset(cx - unit, 3.2*unit), Offset(cx - unit, 6*unit), paint);
    canvas.drawLine(Offset(cx + unit, 3.2*unit), Offset(cx + unit, 6*unit), paint);
    
    // Arms wrapping around
    final armPath = Path();
    armPath.moveTo(cx - unit, 4*unit);
    armPath.quadraticBezierTo(cx + 2*unit, 4.5*unit, cx + unit, 5*unit);
    canvas.drawPath(armPath, paint);
    
    final armPath2 = Path();
    armPath2.moveTo(cx + unit, 4*unit);
    armPath2.quadraticBezierTo(cx - 2*unit, 4.5*unit, cx - unit, 5*unit);
    canvas.drawPath(armPath2, paint);
    
    // Heart
    _drawSmallHeart(canvas, Offset(cx, 1.5*unit), unit * 0.5, fillPaint);
  }
  
  void _drawNeckKiss(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Standing figure
    _drawHead(canvas, Offset(cx + unit, 3*unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx + unit, 3.8*unit), Offset(cx + unit, 7*unit), paint);
    
    // Figure leaning to kiss neck
    _drawHead(canvas, Offset(cx - 1.5*unit, 3.5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 1.5*unit, 4.2*unit), Offset(cx - 1.5*unit, 7*unit), paint);
    canvas.drawLine(Offset(cx - 1.5*unit, 4.5*unit), Offset(cx + 0.2*unit, 3.5*unit), paint); // arm reaching
    
    // Lips on neck
    _drawSmallHeart(canvas, Offset(cx + 0.2*unit, 4*unit), unit * 0.3, fillPaint);
  }
  
  void _drawTextFlirt(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Phone shape
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height / 2), width: 3*unit, height: 5*unit),
      Radius.circular(unit * 0.3),
    );
    canvas.drawRRect(phoneRect, paint);
    
    // Heart bubbles coming from phone
    _drawSmallHeart(canvas, Offset(cx + 2*unit, 3*unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 3*unit, 2*unit), unit * 0.5, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 2.5*unit, 1.5*unit), unit * 0.35, fillPaint);
  }
  
  void _drawMassage(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Lying down figure
    canvas.drawLine(Offset(unit, 6*unit), Offset(8*unit, 6*unit), paint); // table
    _drawHead(canvas, Offset(2*unit, 5*unit), unit * 0.6, paint);
    canvas.drawLine(Offset(2.6*unit, 5*unit), Offset(7*unit, 5*unit), paint); // body horizontal
    
    // Standing figure with hands on back
    _drawHead(canvas, Offset(cx, 2.5*unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 3.1*unit), Offset(cx, 5.5*unit), paint);
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx - unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx + unit, 4.5*unit), paint);
  }
  
  void _drawMakeOut(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two heads very close/overlapping
    canvas.drawCircle(Offset(cx - 0.5*unit, 4*unit), unit * 1.2, paint);
    canvas.drawCircle(Offset(cx + 0.5*unit, 4*unit), unit * 1.2, paint);
    
    // Bodies close
    canvas.drawLine(Offset(cx - 0.5*unit, 5.2*unit), Offset(cx - unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx + 0.5*unit, 5.2*unit), Offset(cx + unit, 7.5*unit), paint);
    
    // Hearts
    _drawSmallHeart(canvas, Offset(cx - 2*unit, 2.5*unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 2*unit, 3*unit), unit * 0.35, fillPaint);
  }
  
  void _drawSwimNaked(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Water waves
    final wavePath = Path();
    wavePath.moveTo(unit, 6*unit);
    for (int i = 0; i < 4; i++) {
      wavePath.quadraticBezierTo(
        unit + (i * 2 + 1) * unit, 5.5*unit,
        unit + (i + 1) * 2 * unit, 6*unit,
      );
    }
    canvas.drawPath(wavePath, paint);
    
    // Moon
    canvas.drawCircle(Offset(8*unit, 2*unit), unit * 0.8, paint);
    
    // Figure in water (head above water)
    _drawHead(canvas, Offset(cx, 5*unit), unit * 0.7, paint);
  }
  
  void _drawLingerie(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Feminine figure silhouette
    _drawHead(canvas, Offset(cx, 2*unit), unit * 0.6, paint);
    
    // Curved body outline
    final bodyPath = Path();
    bodyPath.moveTo(cx, 2.6*unit);
    bodyPath.quadraticBezierTo(cx - 1.2*unit, 4*unit, cx - unit, 5*unit); // curve out
    bodyPath.quadraticBezierTo(cx - 0.5*unit, 6*unit, cx - 1.2*unit, 7.5*unit); // hip curve
    canvas.drawPath(bodyPath, paint);
    
    final bodyPath2 = Path();
    bodyPath2.moveTo(cx, 2.6*unit);
    bodyPath2.quadraticBezierTo(cx + 1.2*unit, 4*unit, cx + unit, 5*unit);
    bodyPath2.quadraticBezierTo(cx + 0.5*unit, 6*unit, cx + 1.2*unit, 7.5*unit);
    canvas.drawPath(bodyPath2, paint);
    
    // Decorative bow
    _drawSmallHeart(canvas, Offset(cx, 3.5*unit), unit * 0.3, fillPaint);
  }
  
  void _drawMorningPassion(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Bed outline
    final bedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit, 4*unit, 8*unit, 4*unit),
      Radius.circular(unit * 0.5),
    );
    canvas.drawRRect(bedRect, paint);
    
    // Two heads on pillows
    _drawHead(canvas, Offset(3*unit, 5*unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(5*unit, 5*unit), unit * 0.6, paint);
    
    // Sun rays
    canvas.drawCircle(Offset(8*unit, 2*unit), unit * 0.6, fillPaint);
    canvas.drawLine(Offset(8*unit, 0.8*unit), Offset(8*unit, 0.3*unit), paint);
    canvas.drawLine(Offset(8.8*unit, 1.4*unit), Offset(9.3*unit, 0.9*unit), paint);
  }
  
  void _drawShower(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Shower head
    canvas.drawCircle(Offset(cx, unit), unit * 0.6, paint);
    
    // Water droplets
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(cx - unit + i * unit, 2.5*unit + i * 0.3*unit), unit * 0.15, fillPaint);
    }
    
    // Two close figures
    _drawHead(canvas, Offset(cx - 0.5*unit, 4*unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 0.5*unit, 4.3*unit), unit * 0.5, paint);
    
    canvas.drawLine(Offset(cx - 0.5*unit, 4.6*unit), Offset(cx - 0.8*unit, 7*unit), paint);
    canvas.drawLine(Offset(cx + 0.5*unit, 4.8*unit), Offset(cx + 0.8*unit, 7*unit), paint);
  }
  
  void _drawWhisper(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two heads close, one leaning in
    _drawHead(canvas, Offset(cx + unit, 4*unit), unit * 0.8, paint);
    _drawHead(canvas, Offset(cx - 1.5*unit, 3.5*unit), unit * 0.7, paint);
    
    // Sound waves from mouth
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 0.5*unit, 3.5*unit), radius: unit * 0.5), -0.5, 1, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx - 0.3*unit, 3.5*unit), radius: unit * 0.8), -0.5, 1, false, paint);
  }
  
  void _drawSelfPleasure(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Single figure reclining
    _drawHead(canvas, Offset(cx - 2*unit, 3*unit), unit * 0.7, paint);
    
    // Reclining body
    final bodyPath = Path();
    bodyPath.moveTo(cx - 1.3*unit, 3*unit);
    bodyPath.quadraticBezierTo(cx, 4*unit, cx + 2*unit, 5*unit);
    canvas.drawPath(bodyPath, paint);
    
    // Bent legs
    canvas.drawLine(Offset(cx + 2*unit, 5*unit), Offset(cx + unit, 7*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5*unit), Offset(cx + 3*unit, 6.5*unit), paint);
    
    // Sparkles
    _drawSparkle(canvas, Offset(cx - unit, 2*unit), unit * 0.3, paint);
  }
  
  void _drawHandAction(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Hand shape
    canvas.drawLine(Offset(cx - 2*unit, 5*unit), Offset(cx, 5*unit), paint);
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx + 0.5*unit, 3.5*unit), paint); // thumb
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx + unit, 4*unit), paint); // fingers
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx + 1.2*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx + unit, 5*unit), paint);
    
    // Motion lines
    canvas.drawLine(Offset(cx + 2*unit, 4*unit), Offset(cx + 2.5*unit, 3.5*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5*unit), Offset(cx + 2.8*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 6*unit), Offset(cx + 2.5*unit, 6.5*unit), paint);
  }
  
  void _drawOral(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Standing figure
    _drawHead(canvas, Offset(cx, 2*unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 2.6*unit), Offset(cx, 5.5*unit), paint);
    canvas.drawLine(Offset(cx, 5.5*unit), Offset(cx - unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx, 5.5*unit), Offset(cx + unit, 7.5*unit), paint);
    
    // Kneeling figure
    _drawHead(canvas, Offset(cx - 2*unit, 5*unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2*unit, 5.5*unit), Offset(cx - 2*unit, 6.5*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 6.5*unit), Offset(cx - 1*unit, 7.5*unit), paint);
  }
  
  void _drawTwoTogether(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Two figures intertwined
    _drawHead(canvas, Offset(cx - unit, 3*unit), unit * 0.7, paint);
    _drawHead(canvas, Offset(cx + unit, 3*unit), unit * 0.7, paint);
    
    // Bodies close and overlapping
    canvas.drawLine(Offset(cx - unit, 3.7*unit), Offset(cx - 0.5*unit, 6*unit), paint);
    canvas.drawLine(Offset(cx + unit, 3.7*unit), Offset(cx + 0.5*unit, 6*unit), paint);
    
    // Arms wrapped
    canvas.drawLine(Offset(cx - unit, 4.2*unit), Offset(cx + 0.5*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx + unit, 4.2*unit), Offset(cx - 0.5*unit, 4.5*unit), paint);
    
    // Heart
    _drawSmallHeart(canvas, Offset(cx, 2*unit), unit * 0.5, fillPaint);
  }
  
  void _drawHairPull(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Head with hair
    _drawHead(canvas, Offset(cx, 4*unit), unit * 0.8, paint);
    // Hair
    canvas.drawLine(Offset(cx - 0.5*unit, 3.2*unit), Offset(cx - 0.8*unit, 2*unit), paint);
    canvas.drawLine(Offset(cx, 3.2*unit), Offset(cx, 2*unit), paint);
    canvas.drawLine(Offset(cx + 0.5*unit, 3.2*unit), Offset(cx + 0.8*unit, 2*unit), paint);
    
    // Hand gripping hair
    canvas.drawLine(Offset(cx + 2*unit, 3*unit), Offset(cx + 0.5*unit, 2.5*unit), paint);
    canvas.drawCircle(Offset(cx + 0.5*unit, 2.5*unit), unit * 0.3, paint);
  }
  
  void _drawVacation(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Palm tree
    canvas.drawLine(Offset(2*unit, 2*unit), Offset(2*unit, 6*unit), paint);
    canvas.drawLine(Offset(2*unit, 2*unit), Offset(0.5*unit, 3*unit), paint);
    canvas.drawLine(Offset(2*unit, 2*unit), Offset(3.5*unit, 2.5*unit), paint);
    canvas.drawLine(Offset(2*unit, 2.5*unit), Offset(1*unit, 3.5*unit), paint);
    
    // Sun
    canvas.drawCircle(Offset(8*unit, 2*unit), unit * 0.8, fillPaint);
    
    // Two figures on beach
    _drawHead(canvas, Offset(5*unit, 5*unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(7*unit, 5*unit), unit * 0.5, paint);
    
    // Ground
    canvas.drawLine(Offset(unit, 7*unit), Offset(9*unit, 7*unit), paint);
  }
  
  void _drawToyUse(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Figure
    _drawHead(canvas, Offset(cx - 1.5*unit, 3*unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 1.5*unit, 3.6*unit), Offset(cx - 1.5*unit, 6*unit), paint);
    
    // Toy shape (abstract wand)
    final toyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 1.5*unit, 5*unit), width: unit, height: 3*unit),
      Radius.circular(unit * 0.4),
    );
    canvas.drawRRect(toyRect, paint);
    
    // Vibration lines
    canvas.drawLine(Offset(cx + 2.5*unit, 4.5*unit), Offset(cx + 3*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx + 2.5*unit, 5*unit), Offset(cx + 3.2*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx + 2.5*unit, 5.5*unit), Offset(cx + 3*unit, 5.5*unit), paint);
  }
  
  void _drawPublicTease(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Table
    canvas.drawLine(Offset(unit, 4*unit), Offset(9*unit, 4*unit), paint);
    canvas.drawLine(Offset(2*unit, 4*unit), Offset(2*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(8*unit, 4*unit), Offset(8*unit, 7.5*unit), paint);
    
    // Two heads above table
    _drawHead(canvas, Offset(cx - 1.5*unit, 2.5*unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 1.5*unit, 2.5*unit), unit * 0.6, paint);
    
    // Hand reaching under table
    canvas.drawLine(Offset(cx - 1.5*unit, 5*unit), Offset(cx + unit, 5.5*unit), paint);
    
    // Exclamation
    canvas.drawCircle(Offset(cx + 3*unit, 2*unit), unit * 0.15, fillPaint);
    canvas.drawLine(Offset(cx + 3*unit, 2.5*unit), Offset(cx + 3*unit, 3.5*unit), paint);
  }
  
  void _drawCabin(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Cabin shape
    canvas.drawLine(Offset(2*unit, 4*unit), Offset(cx, 2*unit), paint); // roof left
    canvas.drawLine(Offset(8*unit, 4*unit), Offset(cx, 2*unit), paint); // roof right
    canvas.drawLine(Offset(2*unit, 4*unit), Offset(2*unit, 7.5*unit), paint); // left wall
    canvas.drawLine(Offset(8*unit, 4*unit), Offset(8*unit, 7.5*unit), paint); // right wall
    canvas.drawLine(Offset(2*unit, 7.5*unit), Offset(8*unit, 7.5*unit), paint); // floor
    
    // Window with hearts
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, 5.5*unit), width: 2*unit, height: 1.5*unit), paint);
    _drawSmallHeart(canvas, Offset(cx, 5.5*unit), unit * 0.3, fillPaint);
    
    // Trees
    canvas.drawLine(Offset(unit, 3*unit), Offset(unit, 7.5*unit), paint);
  }
  
  void _drawFootFetish(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Foot shape
    final footPath = Path();
    footPath.moveTo(cx - 2*unit, 5*unit);
    footPath.quadraticBezierTo(cx - 2*unit, 7*unit, cx, 7*unit);
    footPath.quadraticBezierTo(cx + 2*unit, 7*unit, cx + 2*unit, 5.5*unit);
    footPath.lineTo(cx + 1.5*unit, 4.5*unit);
    canvas.drawPath(footPath, paint);
    
    // Toes
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(cx + 1.8*unit - i * 0.4*unit, 4.2*unit + i * 0.1*unit), unit * 0.2, paint);
    }
    
    // Heart
    _drawSmallHeart(canvas, Offset(cx, 3*unit), unit * 0.5, fillPaint);
  }
  
  void _drawAirplane(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Airplane body
    canvas.drawLine(Offset(2*unit, 5*unit), Offset(8*unit, 5*unit), paint);
    
    // Wings
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx - unit, 3.5*unit), paint);
    canvas.drawLine(Offset(cx, 5*unit), Offset(cx + unit, 3.5*unit), paint);
    
    // Tail
    canvas.drawLine(Offset(2*unit, 5*unit), Offset(unit, 4*unit), paint);
    
    // Windows with figures
    canvas.drawCircle(Offset(4*unit, 4.8*unit), unit * 0.3, paint);
    canvas.drawCircle(Offset(5*unit, 4.8*unit), unit * 0.3, paint);
    
    // Heart between windows
    _drawSmallHeart(canvas, Offset(4.5*unit, 4.8*unit), unit * 0.2, fillPaint);
  }
  
  void _drawAllNight(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Moon
    canvas.drawArc(Rect.fromCircle(center: Offset(2*unit, 2.5*unit), radius: unit), 0.5, 4.5, false, paint);
    
    // Stars
    _drawStar(canvas, Offset(4*unit, 2*unit), unit * 0.3, paint);
    _drawStar(canvas, Offset(7*unit, 1.5*unit), unit * 0.4, paint);
    _drawStar(canvas, Offset(8*unit, 3*unit), unit * 0.25, paint);
    
    // Bed with two figures
    canvas.drawLine(Offset(2*unit, 6*unit), Offset(8*unit, 6*unit), paint);
    _drawHead(canvas, Offset(3.5*unit, 5*unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(5.5*unit, 5*unit), unit * 0.5, paint);
    
    // Zzz
    canvas.drawLine(Offset(7*unit, 4*unit), Offset(7.5*unit, 4*unit), paint);
    canvas.drawLine(Offset(7.5*unit, 4*unit), Offset(7*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(7*unit, 4.5*unit), Offset(7.5*unit, 4.5*unit), paint);
  }
  
  void _drawFaceAction(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Lying figure face up
    _drawHead(canvas, Offset(cx, 5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 5.7*unit), Offset(cx, 7.5*unit), paint);
    
    // Sitting figure
    _drawHead(canvas, Offset(cx, 3.5*unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 4.1*unit), Offset(cx, 5*unit), paint);
    canvas.drawLine(Offset(cx, 4.5*unit), Offset(cx - unit, 5.5*unit), paint); // legs to sides
    canvas.drawLine(Offset(cx, 4.5*unit), Offset(cx + unit, 5.5*unit), paint);
  }
  
  void _drawBlindfold(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Head
    _drawHead(canvas, Offset(cx, 3.5*unit), unit, paint);
    
    // Blindfold (thick line across eyes)
    final thickPaint = Paint()
      ..color = color
      ..strokeWidth = unit * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 1.5*unit, 3.3*unit), Offset(cx + 1.5*unit, 3.3*unit), thickPaint);
    
    // Body
    canvas.drawLine(Offset(cx, 4.5*unit), Offset(cx, 7*unit), paint);
    
    // Question marks around
    canvas.drawLine(Offset(cx - 2.5*unit, 2.5*unit), Offset(cx - 2.3*unit, 2.2*unit), paint);
    canvas.drawCircle(Offset(cx - 2.5*unit, 2.8*unit), unit * 0.1, fillPaint);
    
    canvas.drawLine(Offset(cx + 2.5*unit, 2.5*unit), Offset(cx + 2.3*unit, 2.2*unit), paint);
    canvas.drawCircle(Offset(cx + 2.5*unit, 2.8*unit), unit * 0.1, fillPaint);
  }
  
  void _drawDomSub(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Standing dominant figure (taller)
    _drawHead(canvas, Offset(cx, 2.5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 3.2*unit), Offset(cx, 5.5*unit), paint);
    canvas.drawLine(Offset(cx, 5.5*unit), Offset(cx - 0.8*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx, 5.5*unit), Offset(cx + 0.8*unit, 7.5*unit), paint);
    // Arm pointing down
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx - 2*unit, 5*unit), paint);
    
    // Kneeling sub figure
    _drawHead(canvas, Offset(cx - 2.5*unit, 5.5*unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2.5*unit, 6*unit), Offset(cx - 2.5*unit, 6.8*unit), paint);
    canvas.drawLine(Offset(cx - 2.5*unit, 6.8*unit), Offset(cx - 2*unit, 7.5*unit), paint); // bent legs
  }
  
  void _drawBound(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Figure
    _drawHead(canvas, Offset(cx, 2.5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 3.2*unit), Offset(cx, 6*unit), paint);
    
    // Arms up and tied
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx - 1.5*unit, 2.5*unit), paint);
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx + 1.5*unit, 2.5*unit), paint);
    
    // Rope/binding lines around wrists
    canvas.drawCircle(Offset(cx - 1.5*unit, 2.5*unit), unit * 0.3, paint);
    canvas.drawCircle(Offset(cx + 1.5*unit, 2.5*unit), unit * 0.3, paint);
    canvas.drawLine(Offset(cx - 1.5*unit, 2.2*unit), Offset(cx + 1.5*unit, 2.2*unit), paint); // tie line
    
    // Legs
    canvas.drawLine(Offset(cx, 6*unit), Offset(cx - unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx, 6*unit), Offset(cx + unit, 7.5*unit), paint);
  }
  
  void _drawWorship(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Standing figure being worshipped
    _drawHead(canvas, Offset(cx + unit, 2.5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx + unit, 3.2*unit), Offset(cx + unit, 5.5*unit), paint);
    canvas.drawLine(Offset(cx + unit, 5.5*unit), Offset(cx + 0.5*unit, 7.5*unit), paint);
    canvas.drawLine(Offset(cx + unit, 5.5*unit), Offset(cx + 1.5*unit, 7.5*unit), paint);
    
    // Kneeling worshipping figure
    _drawHead(canvas, Offset(cx - 2*unit, 4.5*unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2*unit, 5*unit), Offset(cx - 2*unit, 6*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 6*unit), Offset(cx - 1.5*unit, 7.5*unit), paint);
    // Arms reaching
    canvas.drawLine(Offset(cx - 2*unit, 5.3*unit), Offset(cx, 5.5*unit), paint);
  }
  
  void _drawSubmission(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Figure on all fours
    _drawHead(canvas, Offset(cx + 2*unit, 4*unit), unit * 0.6, paint);
    
    // Back/torso horizontal
    canvas.drawLine(Offset(cx + 1.4*unit, 4*unit), Offset(cx - 2*unit, 4.5*unit), paint);
    
    // Arms down
    canvas.drawLine(Offset(cx + unit, 4.2*unit), Offset(cx + 1.5*unit, 6*unit), paint);
    canvas.drawLine(Offset(cx - 1.5*unit, 4.5*unit), Offset(cx - 2*unit, 6*unit), paint);
    
    // Legs bent
    canvas.drawLine(Offset(cx - 2*unit, 4.5*unit), Offset(cx - 1*unit, 6*unit), paint);
  }
  
  void _drawWatch(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Large eye
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height / 2), width: 4*unit, height: 3*unit), paint);
    
    // Pupil
    canvas.drawCircle(Offset(cx, size.height / 2), unit * 0.8, fillPaint);
    
    // Eye shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 0.3*unit, size.height / 2 - 0.3*unit), unit * 0.25, shinePaint);
  }
  
  void _drawPlug(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Plug shape (tapered oval with base)
    final plugPath = Path();
    plugPath.moveTo(cx, 2.5*unit);
    plugPath.quadraticBezierTo(cx - 1.5*unit, 4*unit, cx - unit, 5.5*unit);
    plugPath.quadraticBezierTo(cx - 0.5*unit, 6.5*unit, cx, 6.5*unit);
    plugPath.quadraticBezierTo(cx + 0.5*unit, 6.5*unit, cx + unit, 5.5*unit);
    plugPath.quadraticBezierTo(cx + 1.5*unit, 4*unit, cx, 2.5*unit);
    canvas.drawPath(plugPath, paint);
    
    // Base
    canvas.drawLine(Offset(cx - 1.5*unit, 6.5*unit), Offset(cx + 1.5*unit, 6.5*unit), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 7*unit), width: 2*unit, height: unit), paint);
  }
  
  void _drawThreesome(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Three heads in triangular arrangement
    _drawHead(canvas, Offset(cx, 2.5*unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx - 2*unit, 4.5*unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 2*unit, 4.5*unit), unit * 0.6, paint);
    
    // Bodies
    canvas.drawLine(Offset(cx, 3.1*unit), Offset(cx, 5*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 5.1*unit), Offset(cx - 2*unit, 7*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5.1*unit), Offset(cx + 2*unit, 7*unit), paint);
    
    // Connecting arms
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx - 1.5*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx, 3.8*unit), Offset(cx + 1.5*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(cx - 2*unit, 5.5*unit), Offset(cx + 2*unit, 5.5*unit), paint);
  }
  
  void _drawFoursome(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Four heads in square arrangement
    _drawHead(canvas, Offset(cx - 1.5*unit, cy - 1.5*unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(cx + 1.5*unit, cy - 1.5*unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(cx - 1.5*unit, cy + 1.5*unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(cx + 1.5*unit, cy + 1.5*unit), unit * 0.5, paint);
    
    // Connecting lines
    canvas.drawLine(Offset(cx - 1.5*unit, cy - unit), Offset(cx + 1.5*unit, cy - unit), paint);
    canvas.drawLine(Offset(cx - 1.5*unit, cy + unit), Offset(cx + 1.5*unit, cy + unit), paint);
    canvas.drawLine(Offset(cx - 1.5*unit, cy - unit), Offset(cx - 1.5*unit, cy + unit), paint);
    canvas.drawLine(Offset(cx + 1.5*unit, cy - unit), Offset(cx + 1.5*unit, cy + unit), paint);
  }
  
  void _drawGroup(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Multiple small heads in cluster
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (i == 1 && j == 1) continue; // skip center sometimes
        _drawHead(canvas, 
          Offset(2*unit + i * 2.5*unit, 2*unit + j * 2.5*unit), 
          unit * 0.4, paint);
      }
    }
    
    // Connecting chaos lines
    canvas.drawLine(Offset(2*unit, 4.5*unit), Offset(7*unit, 4.5*unit), paint);
    canvas.drawLine(Offset(4.5*unit, 2*unit), Offset(4.5*unit, 7*unit), paint);
  }
  
  void _drawRopes(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Figure with rope pattern
    _drawHead(canvas, Offset(cx, 2.5*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 3.2*unit), Offset(cx, 6.5*unit), paint);
    
    // Rope diamond pattern on torso
    canvas.drawLine(Offset(cx - unit, 3.5*unit), Offset(cx, 4.5*unit), paint);
    canvas.drawLine(Offset(cx + unit, 3.5*unit), Offset(cx, 4.5*unit), paint);
    canvas.drawLine(Offset(cx - unit, 3.5*unit), Offset(cx - 1.2*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx + unit, 3.5*unit), Offset(cx + 1.2*unit, 5*unit), paint);
    canvas.drawLine(Offset(cx - 1.2*unit, 5*unit), Offset(cx, 5.5*unit), paint);
    canvas.drawLine(Offset(cx + 1.2*unit, 5*unit), Offset(cx, 5.5*unit), paint);
  }
  
  void _drawWhip(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Whip handle
    canvas.drawLine(Offset(cx - 3*unit, 7*unit), Offset(cx - 2*unit, 5*unit), paint);
    
    // Whip strands (curved)
    final whipPath = Path();
    whipPath.moveTo(cx - 2*unit, 5*unit);
    whipPath.quadraticBezierTo(cx, 3*unit, cx + 2*unit, 4*unit);
    canvas.drawPath(whipPath, paint);
    
    final whipPath2 = Path();
    whipPath2.moveTo(cx - 2*unit, 5*unit);
    whipPath2.quadraticBezierTo(cx - 0.5*unit, 2.5*unit, cx + unit, 3.5*unit);
    canvas.drawPath(whipPath2, paint);
    
    final whipPath3 = Path();
    whipPath3.moveTo(cx - 2*unit, 5*unit);
    whipPath3.quadraticBezierTo(cx + 0.5*unit, 3.5*unit, cx + 2.5*unit, 4.5*unit);
    canvas.drawPath(whipPath3, paint);
    
    // Motion lines
    canvas.drawLine(Offset(cx + 2.5*unit, 3.5*unit), Offset(cx + 3*unit, 3*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 3*unit), Offset(cx + 2.5*unit, 2.5*unit), paint);
  }
  
  void _drawGag(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Head
    _drawHead(canvas, Offset(cx, 4*unit), unit * 1.2, paint);
    
    // Ball gag (filled circle at mouth)
    canvas.drawCircle(Offset(cx, 4.3*unit), unit * 0.5, fillPaint);
    
    // Strap lines
    canvas.drawLine(Offset(cx - 1.2*unit, 4.3*unit), Offset(cx - 0.5*unit, 4.3*unit), paint);
    canvas.drawLine(Offset(cx + 0.5*unit, 4.3*unit), Offset(cx + 1.2*unit, 4.3*unit), paint);
  }
  
  void _drawDenial(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Circle with X through it
    canvas.drawCircle(Offset(cx, cy), unit * 2.5, paint);
    canvas.drawLine(Offset(cx - 1.8*unit, cy - 1.8*unit), Offset(cx + 1.8*unit, cy + 1.8*unit), paint);
    
    // Heart inside (denied)
    _drawSmallHeart(canvas, Offset(cx, cy), unit * 0.8, paint);
  }
  
  void _drawClubScene(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Disco ball / lights
    canvas.drawCircle(Offset(cx, 2*unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, unit), Offset(cx, 1.3*unit), paint);
    
    // Light rays
    canvas.drawLine(Offset(cx - 0.5*unit, 2.7*unit), Offset(cx - 2*unit, 4*unit), paint);
    canvas.drawLine(Offset(cx, 2.7*unit), Offset(cx, 4*unit), paint);
    canvas.drawLine(Offset(cx + 0.5*unit, 2.7*unit), Offset(cx + 2*unit, 4*unit), paint);
    
    // Dancing figures
    _drawHead(canvas, Offset(cx - 2*unit, 5*unit), unit * 0.4, paint);
    _drawHead(canvas, Offset(cx, 5.2*unit), unit * 0.4, paint);
    _drawHead(canvas, Offset(cx + 2*unit, 4.8*unit), unit * 0.4, paint);
    
    // Bodies moving
    canvas.drawLine(Offset(cx - 2*unit, 5.4*unit), Offset(cx - 2.3*unit, 7*unit), paint);
    canvas.drawLine(Offset(cx, 5.6*unit), Offset(cx, 7*unit), paint);
    canvas.drawLine(Offset(cx + 2*unit, 5.2*unit), Offset(cx + 2.3*unit, 7*unit), paint);
  }
  
  void _drawElectric(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Lightning bolt
    final boltPath = Path();
    boltPath.moveTo(cx + unit, unit);
    boltPath.lineTo(cx - unit, 4*unit);
    boltPath.lineTo(cx, 4*unit);
    boltPath.lineTo(cx - 1.5*unit, 8*unit);
    boltPath.lineTo(cx + 0.5*unit, 5*unit);
    boltPath.lineTo(cx - 0.5*unit, 5*unit);
    boltPath.close();
    canvas.drawPath(boltPath, paint);
    
    // Sparks
    _drawSparkle(canvas, Offset(cx + 2*unit, 3*unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx - 2*unit, 5*unit), unit * 0.25, paint);
  }
  
  void _drawChain(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Chain links
    for (int i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, 2*unit + i * 1.8*unit), 
          width: unit * 1.2, 
          height: unit * 2,
        ), 
        paint,
      );
    }
  }
  
  void _drawExtreme(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Warning triangle
    final trianglePath = Path();
    trianglePath.moveTo(cx, unit);
    trianglePath.lineTo(cx - 3*unit, 7*unit);
    trianglePath.lineTo(cx + 3*unit, 7*unit);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);
    
    // Exclamation mark
    canvas.drawLine(Offset(cx, 3*unit), Offset(cx, 5*unit), paint);
    canvas.drawCircle(Offset(cx, 5.8*unit), unit * 0.25, fillPaint);
  }
  
  void _drawFire(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    
    // Flame shape
    final flamePath = Path();
    flamePath.moveTo(cx, 8*unit);
    flamePath.quadraticBezierTo(cx - 2.5*unit, 5*unit, cx - unit, 3*unit);
    flamePath.quadraticBezierTo(cx - 0.5*unit, 4*unit, cx, 2*unit);
    flamePath.quadraticBezierTo(cx + 0.5*unit, 4*unit, cx + unit, 3*unit);
    flamePath.quadraticBezierTo(cx + 2.5*unit, 5*unit, cx, 8*unit);
    canvas.drawPath(flamePath, paint);
    
    // Inner flame
    final innerPath = Path();
    innerPath.moveTo(cx, 8*unit);
    innerPath.quadraticBezierTo(cx - unit, 6*unit, cx - 0.5*unit, 5*unit);
    innerPath.quadraticBezierTo(cx, 6*unit, cx + 0.5*unit, 5*unit);
    innerPath.quadraticBezierTo(cx + unit, 6*unit, cx, 8*unit);
    canvas.drawPath(innerPath, paint);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _drawSmallHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.5,
      center.dx - size * 0.5, center.dy - size,
      center.dx, center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size,
      center.dx + size, center.dy - size * 0.5,
      center.dx, center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }
  
  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - size, center.dy), 
      Offset(center.dx + size, center.dy), 
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size), 
      Offset(center.dx, center.dy + size), 
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size * 0.7, center.dy - size * 0.7), 
      Offset(center.dx + size * 0.7, center.dy + size * 0.7), 
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size * 0.7, center.dy - size * 0.7), 
      Offset(center.dx - size * 0.7, center.dy + size * 0.7), 
      paint,
    );
  }
  
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      Offset(center.dx, center.dy - size), 
      Offset(center.dx, center.dy + size), 
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy), 
      Offset(center.dx + size, center.dy), 
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) {
    return oldDelegate.illustration != illustration || oldDelegate.color != color;
  }
}
