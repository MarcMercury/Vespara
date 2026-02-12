import 'dart:math';

import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - 100 Unique Stick Figure Illustrations
/// Every card gets its own unique, cheeky stick figure scene.
/// ════════════════════════════════════════════════════════════════════════════

/// Each card has a unique illustration enum value
enum LaneIllustration {
  // 1-10: Innocent
  foreheadGrandma,
  awkwardHandshake,
  brushHands,
  crushOnBus,
  winkAcrossRoom,
  peckOnCheek,
  shareDessert,
  holdHandsMovie,
  flirtyText,
  footsieTable,
  // 11-20: Romantic/Sensual
  danceWedding,
  lingeringHug,
  slowDanceLiving,
  gString,
  unforgetNight,
  kissNeck,
  oilMassage,
  makeOutCar,
  cabinGetaway,
  skinnyDip,
  // 21-30: Mainstream Sexual
  masturbation,
  handJob,
  dirtyTalk,
  morningSex,
  showerSex,
  cunnilingus,
  blowJob,
  vaginalSex,
  hotelVacation,
  allNighter,
  // 31-40
  tribadism,
  hairPulling,
  vibrator,
  masturbationToys,
  dildo,
  sexToyPartner,
  vacayInRoom,
  worshipped,
  squirting,
  bjSwallow,
  // 41-50
  publicTease,
  oralCreampie,
  footFetish,
  mileHighClub,
  faceSitting,
  cockRing,
  cumFacial,
  futa,
  beingDominated,
  prostateMassage,
  // 51-60
  blindfolded,
  nippleClamps,
  analBeads,
  buttPlug,
  rimming,
  submission,
  tiedTeased,
  analSex,
  voyeurism,
  domSub,
  // 61-70
  bondage,
  orgasmDenial,
  tantricWitch,
  threesome,
  fmf,
  ffm,
  mfm,
  shibari,
  strapOnFF,
  pegging,
  // 71-80
  flogger,
  bondageSpread,
  mmf,
  impactPlay,
  kinkClub,
  ballGag,
  whipping,
  surpriseThreesome,
  bdsm,
  doublePenetration,
  // 81-90
  mfmf,
  painPlay,
  gayForPay,
  masterSlave,
  leatherDaddy,
  ddlg,
  pupPlay,
  groupSex,
  sadomasochism,
  buttPlugGag,
  // 91-100
  gorean,
  electrosex,
  manyMenOneF,
  gangBang,
  cbt,
  enemaPlay,
  fisting,
  analFisting,
  breathPlay,
  autoAsphyx,
}

/// Get the appropriate illustration for a card based on its text
LaneIllustration getIllustrationForCard(String cardText) {
  final text = cardText.toLowerCase();

  // Exact / unique matching for all 100 cards
  if (text.contains('grandma') || text.contains('forehead')) return LaneIllustration.foreheadGrandma;
  if (text.contains('handshake')) return LaneIllustration.awkwardHandshake;
  if (text.contains('brushing hands')) return LaneIllustration.brushHands;
  if (text.contains('crush') && text.contains('bus')) return LaneIllustration.crushOnBus;
  if (text.contains('wink')) return LaneIllustration.winkAcrossRoom;
  if (text.contains('peck') && text.contains('cheek')) return LaneIllustration.peckOnCheek;
  if (text.contains('dessert')) return LaneIllustration.shareDessert;
  if (text.contains('holding hands')) return LaneIllustration.holdHandsMovie;
  if (text.contains('flirty text')) return LaneIllustration.flirtyText;
  if (text.contains('footsie')) return LaneIllustration.footsieTable;
  if (text.contains('wedding')) return LaneIllustration.danceWedding;
  if (text.contains('long hug')) return LaneIllustration.lingeringHug;
  if (text.contains('slow danc')) return LaneIllustration.slowDanceLiving;
  if (text.contains('g-string')) return LaneIllustration.gString;
  if (text.contains('never forget')) return LaneIllustration.unforgetNight;
  if (text.contains('kiss') && text.contains('neck')) return LaneIllustration.kissNeck;
  if (text.contains('massage')) return LaneIllustration.oilMassage;
  if (text.contains('making out') || text.contains('parked car')) return LaneIllustration.makeOutCar;
  if (text.contains('cabin') || text.contains('weekend getaway')) return LaneIllustration.cabinGetaway;
  if (text.contains('skinny dip')) return LaneIllustration.skinnyDip;
  if (text == 'masturbation') return LaneIllustration.masturbation;
  if (text == 'hand job') return LaneIllustration.handJob;
  if (text.contains('dirty talk')) return LaneIllustration.dirtyTalk;
  if (text.contains('morning sex')) return LaneIllustration.morningSex;
  if (text.contains('shower sex')) return LaneIllustration.showerSex;
  if (text.contains('cunnilingus')) return LaneIllustration.cunnilingus;
  if (text == 'blow job') return LaneIllustration.blowJob;
  if (text.contains('vaginal')) return LaneIllustration.vaginalSex;
  if (text.contains('hotel')) return LaneIllustration.hotelVacation;
  if (text.contains('all-night')) return LaneIllustration.allNighter;
  if (text.contains('tribadism')) return LaneIllustration.tribadism;
  if (text.contains('hair pull')) return LaneIllustration.hairPulling;
  if (text == 'use vibrator') return LaneIllustration.vibrator;
  if (text.contains('masturbation w')) return LaneIllustration.masturbationToys;
  if (text == 'dildo') return LaneIllustration.dildo;
  if (text.contains('sex toy with')) return LaneIllustration.sexToyPartner;
  if (text.contains('barely leave')) return LaneIllustration.vacayInRoom;
  if (text.contains('worshipped')) return LaneIllustration.worshipped;
  if (text.contains('squirting')) return LaneIllustration.squirting;
  if (text.contains('swallow')) return LaneIllustration.bjSwallow;
  if (text.contains('public teas')) return LaneIllustration.publicTease;
  if (text.contains('oral creampie')) return LaneIllustration.oralCreampie;
  if (text.contains('foot fetish')) return LaneIllustration.footFetish;
  if (text.contains('mile high')) return LaneIllustration.mileHighClub;
  if (text.contains('face sitting')) return LaneIllustration.faceSitting;
  if (text.contains('cock ring')) return LaneIllustration.cockRing;
  if (text.contains('cum shot') || text.contains('facial')) return LaneIllustration.cumFacial;
  if (text == 'futa') return LaneIllustration.futa;
  if (text.contains('dominated')) return LaneIllustration.beingDominated;
  if (text.contains('prostate')) return LaneIllustration.prostateMassage;
  if (text.contains('blindfold')) return LaneIllustration.blindfolded;
  if (text.contains('nipple clamp')) return LaneIllustration.nippleClamps;
  if (text.contains('anal beads')) return LaneIllustration.analBeads;
  if (text == 'butt plug') return LaneIllustration.buttPlug;
  if (text.contains('licking ass')) return LaneIllustration.rimming;
  if (text == 'submission') return LaneIllustration.submission;
  if (text.contains('tied up')) return LaneIllustration.tiedTeased;
  if (text == 'anal sex') return LaneIllustration.analSex;
  if (text.contains('voyeurism')) return LaneIllustration.voyeurism;
  if (text == 'dom/sub') return LaneIllustration.domSub;
  if (text == 'bondage') return LaneIllustration.bondage;
  if (text.contains('orgasm denial')) return LaneIllustration.orgasmDenial;
  if (text.contains('tantric')) return LaneIllustration.tantricWitch;
  if (text == 'threesome') return LaneIllustration.threesome;
  if (text == 'fmf') return LaneIllustration.fmf;
  if (text == 'ffm') return LaneIllustration.ffm;
  if (text == 'mfm') return LaneIllustration.mfm;
  if (text.contains('shibari')) return LaneIllustration.shibari;
  if (text.contains('strap-on')) return LaneIllustration.strapOnFF;
  if (text.contains('pegging')) return LaneIllustration.pegging;
  if (text.contains('flogger')) return LaneIllustration.flogger;
  if (text.contains('bondage spread')) return LaneIllustration.bondageSpread;
  if (text == 'mmf') return LaneIllustration.mmf;
  if (text.contains('impact play')) return LaneIllustration.impactPlay;
  if (text.contains('kink club')) return LaneIllustration.kinkClub;
  if (text.contains('ball gag')) return LaneIllustration.ballGag;
  if (text.contains('whipping')) return LaneIllustration.whipping;
  if (text.contains('surprise threesome')) return LaneIllustration.surpriseThreesome;
  if (text == 'bdsm') return LaneIllustration.bdsm;
  if (text.contains('double penetration')) return LaneIllustration.doublePenetration;
  if (text == 'mfmf') return LaneIllustration.mfmf;
  if (text.contains('pain play')) return LaneIllustration.painPlay;
  if (text.contains('gay for pay')) return LaneIllustration.gayForPay;
  if (text.contains('master') || text.contains('slave')) return LaneIllustration.masterSlave;
  if (text.contains('leather daddy')) return LaneIllustration.leatherDaddy;
  if (text.contains('ddlg')) return LaneIllustration.ddlg;
  if (text.contains('pup play')) return LaneIllustration.pupPlay;
  if (text.contains('group sex')) return LaneIllustration.groupSex;
  if (text.contains('sadomasochism')) return LaneIllustration.sadomasochism;
  if (text.contains('butt plug gag')) return LaneIllustration.buttPlugGag;
  if (text.contains('gorean')) return LaneIllustration.gorean;
  if (text.contains('electrosex')) return LaneIllustration.electrosex;
  if (text.contains('mmmmmm')) return LaneIllustration.manyMenOneF;
  if (text.contains('gang bang')) return LaneIllustration.gangBang;
  if (text.contains('cock and ball torture')) return LaneIllustration.cbt;
  if (text.contains('enema')) return LaneIllustration.enemaPlay;
  if (text == 'fisting') return LaneIllustration.fisting;
  if (text.contains('anal fisting')) return LaneIllustration.analFisting;
  if (text == 'breathplay') return LaneIllustration.breathPlay;
  if (text.contains('autoerotic')) return LaneIllustration.autoAsphyx;

  return LaneIllustration.foreheadGrandma; // fallback
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

    final unit = size.width / 10;

    switch (illustration) {
      // ═══ CARDS 1-10: Innocent ═══
      case LaneIllustration.foreheadGrandma:
        _drawForeheadGrandma(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.awkwardHandshake:
        _drawAwkwardHandshake(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.brushHands:
        _drawBrushHands(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.crushOnBus:
        _drawCrushOnBus(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.winkAcrossRoom:
        _drawWinkAcrossRoom(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.peckOnCheek:
        _drawPeckOnCheek(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.shareDessert:
        _drawShareDessert(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.holdHandsMovie:
        _drawHoldHandsMovie(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.flirtyText:
        _drawFlirtyText(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.footsieTable:
        _drawFootsieTable(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 11-20: Romantic / Sensual ═══
      case LaneIllustration.danceWedding:
        _drawDanceWedding(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.lingeringHug:
        _drawLingeringHug(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.slowDanceLiving:
        _drawSlowDanceLiving(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.gString:
        _drawGString(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.unforgetNight:
        _drawUnforgetNight(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.kissNeck:
        _drawKissNeck(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.oilMassage:
        _drawOilMassage(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.makeOutCar:
        _drawMakeOutCar(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.cabinGetaway:
        _drawCabinGetaway(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.skinnyDip:
        _drawSkinnyDip(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 21-30: Mainstream Sexual ═══
      case LaneIllustration.masturbation:
        _drawMasturbation(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.handJob:
        _drawHandJob(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.dirtyTalk:
        _drawDirtyTalk(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.morningSex:
        _drawMorningSex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.showerSex:
        _drawShowerSex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.cunnilingus:
        _drawCunnilingus(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.blowJob:
        _drawBlowJob(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.vaginalSex:
        _drawVaginalSex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.hotelVacation:
        _drawHotelVacation(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.allNighter:
        _drawAllNighter(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 31-40 ═══ (BATCH 4)
      case LaneIllustration.tribadism:
        _drawTribadism(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.hairPulling:
        _drawHairPulling(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.vibrator:
        _drawVibrator(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.masturbationToys:
        _drawMasturbationToys(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.dildo:
        _drawDildo(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.sexToyPartner:
        _drawSexToyPartner(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.vacayInRoom:
        _drawVacayInRoom(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.worshipped:
        _drawWorshipped(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.squirting:
        _drawSquirting(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.bjSwallow:
        _drawBjSwallow(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 41-50 ═══ (BATCH 5)
      case LaneIllustration.publicTease:
        _drawPublicTease(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.oralCreampie:
        _drawOralCreampie(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.footFetish:
        _drawFootFetish(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.mileHighClub:
        _drawMileHighClub(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.faceSitting:
        _drawFaceSitting(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.cockRing:
        _drawCockRing(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.cumFacial:
        _drawCumFacial(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.futa:
        _drawFuta(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.beingDominated:
        _drawBeingDominated(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.prostateMassage:
        _drawProstateMassage(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 51-60 ═══ (BATCH 6)
      case LaneIllustration.blindfolded:
        _drawBlindfolded(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.nippleClamps:
        _drawNippleClamps(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.analBeads:
        _drawAnalBeads(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.buttPlug:
        _drawButtPlug(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.rimming:
        _drawRimming(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.submission:
        _drawSubmission(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.tiedTeased:
        _drawTiedTeased(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.analSex:
        _drawAnalSex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.voyeurism:
        _drawVoyeurism(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.domSub:
        _drawDomSub(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 61-70 ═══ (BATCH 7)
      case LaneIllustration.bondage:
        _drawBondage(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.orgasmDenial:
        _drawOrgasmDenial(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.tantricWitch:
        _drawTantricWitch(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.threesome:
        _drawThreesome(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.fmf:
        _drawFmf(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.ffm:
        _drawFfm(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.mfm:
        _drawMfm(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.shibari:
        _drawShibari(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.strapOnFF:
        _drawStrapOnFF(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.pegging:
        _drawPegging(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 71-80 ═══ (BATCH 8)
      case LaneIllustration.flogger:
        _drawFlogger(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.bondageSpread:
        _drawBondageSpread(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.mmf:
        _drawMmf(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.impactPlay:
        _drawImpactPlay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.kinkClub:
        _drawKinkClub(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.ballGag:
        _drawBallGag(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.whipping:
        _drawWhipping(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.surpriseThreesome:
        _drawSurpriseThreesome(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.bdsm:
        _drawBdsm(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.doublePenetration:
        _drawDoublePenetration(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 81-90 ═══ (BATCH 9)
      case LaneIllustration.mfmf:
        _drawMfmf(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.painPlay:
        _drawPainPlay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.gayForPay:
        _drawGayForPay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.masterSlave:
        _drawMasterSlave(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.leatherDaddy:
        _drawLeatherDaddy(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.ddlg:
        _drawDdlg(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.pupPlay:
        _drawPupPlay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.groupSex:
        _drawGroupSex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.sadomasochism:
        _drawSadomasochism(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.buttPlugGag:
        _drawButtPlugGag(canvas, size, paint, fillPaint, unit);

      // ═══ CARDS 91-100 ═══ (BATCH 10)
      case LaneIllustration.gorean:
        _drawGorean(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.electrosex:
        _drawElectrosex(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.manyMenOneF:
        _drawManyMenOneF(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.gangBang:
        _drawGangBang(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.cbt:
        _drawCbt(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.enemaPlay:
        _drawEnemaPlay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.fisting:
        _drawFisting(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.analFisting:
        _drawAnalFisting(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.breathPlay:
        _drawBreathPlay(canvas, size, paint, fillPaint, unit);
      case LaneIllustration.autoAsphyx:
        _drawAutoAsphyx(canvas, size, paint, fillPaint, unit);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 1: Cards 1-10 — Innocent / Non-Sexual
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 1: Grandma peck — tiny old lady on tiptoes kissing tall person's forehead
  void _drawForeheadGrandma(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Short grandma figure (left) with bun hair
    _drawHead(canvas, Offset(cx - 2 * unit, 4.5 * unit), unit * 0.7, paint);
    // Bun on top
    canvas.drawCircle(Offset(cx - 2 * unit, 3.6 * unit), unit * 0.35, fillPaint);
    // Grandma body
    canvas.drawLine(Offset(cx - 2 * unit, 5.2 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    // Cane
    canvas.drawLine(Offset(cx - 3.2 * unit, 5.5 * unit), Offset(cx - 3.2 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx - 3.2 * unit, 5.5 * unit), Offset(cx - 2.8 * unit, 5.2 * unit), paint);
    // Grandma legs
    canvas.drawLine(Offset(cx - 2 * unit, 7 * unit), Offset(cx - 2.7 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 7 * unit), Offset(cx - 1.3 * unit, 8.5 * unit), paint);
    // Arm reaching up to kiss
    canvas.drawLine(Offset(cx - 2 * unit, 5.8 * unit), Offset(cx - 0.5 * unit, 4 * unit), paint);

    // Tall person (right)
    _drawHead(canvas, Offset(cx + 1.5 * unit, 2.5 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 3.3 * unit), Offset(cx + 1.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6.5 * unit), Offset(cx + 0.7 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6.5 * unit), Offset(cx + 2.3 * unit, 8.5 * unit), paint);
    // Confused expression — "?"
    _drawText(canvas, '?', Offset(cx + 3 * unit, 2 * unit), unit * 0.9, fillPaint);

    // Kiss mark (lips)
    _drawSmallHeart(canvas, Offset(cx - 0.2 * unit, 2.8 * unit), unit * 0.4, fillPaint);
  }

  /// Card 2: Awkward handshake — two stick figures, one goes for hug, other extends hand
  void _drawAwkwardHandshake(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Left figure — arms open for hug
    _drawHead(canvas, Offset(cx - 2.5 * unit, 3 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 3.7 * unit), Offset(cx - 2.5 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 4.5 * unit), Offset(cx - 0.5 * unit, 3.5 * unit), paint); // arm up
    canvas.drawLine(Offset(cx - 2.5 * unit, 4.5 * unit), Offset(cx - 0.5 * unit, 5.5 * unit), paint); // arm down
    canvas.drawLine(Offset(cx - 2.5 * unit, 6 * unit), Offset(cx - 3.2 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 6 * unit), Offset(cx - 1.8 * unit, 8 * unit), paint);

    // Right figure — stiff, arm out for handshake
    _drawHead(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 3.7 * unit), Offset(cx + 2.5 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 4.5 * unit), Offset(cx + 0.5 * unit, 5 * unit), paint); // extended arm
    canvas.drawLine(Offset(cx + 2.5 * unit, 4.5 * unit), Offset(cx + 3.5 * unit, 5.5 * unit), paint); // other arm stiff
    canvas.drawLine(Offset(cx + 2.5 * unit, 6 * unit), Offset(cx + 1.8 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 6 * unit), Offset(cx + 3.2 * unit, 8 * unit), paint);

    // Sweat drop on left figure
    canvas.drawCircle(Offset(cx - 1.5 * unit, 2.5 * unit), unit * 0.2, fillPaint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 2.7 * unit), Offset(cx - 1.5 * unit, 3 * unit), paint);
  }

  /// Card 3: Brushing hands — two hands reaching for same popcorn bucket
  void _drawBrushHands(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Popcorn bucket
    final bucketPath = Path();
    bucketPath.moveTo(cx - 1.2 * unit, 3.5 * unit);
    bucketPath.lineTo(cx - 0.8 * unit, 6 * unit);
    bucketPath.lineTo(cx + 0.8 * unit, 6 * unit);
    bucketPath.lineTo(cx + 1.2 * unit, 3.5 * unit);
    canvas.drawPath(bucketPath, paint);
    // Popcorn bumps
    canvas.drawCircle(Offset(cx - 0.5 * unit, 3.2 * unit), unit * 0.3, paint);
    canvas.drawCircle(Offset(cx + 0.3 * unit, 3 * unit), unit * 0.35, paint);
    canvas.drawCircle(Offset(cx, 3.5 * unit), unit * 0.25, paint);

    // Left hand reaching in
    canvas.drawLine(Offset(unit, 5 * unit), Offset(cx - 0.5 * unit, 4 * unit), paint);
    // Fingers
    canvas.drawLine(Offset(cx - 0.5 * unit, 4 * unit), Offset(cx - 0.3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.5 * unit, 4 * unit), Offset(cx - 0.1 * unit, 3.7 * unit), paint);

    // Right hand reaching in
    canvas.drawLine(Offset(9 * unit, 5 * unit), Offset(cx + 0.5 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 4 * unit), Offset(cx + 0.3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 4 * unit), Offset(cx + 0.1 * unit, 3.7 * unit), paint);

    // Spark where fingers touch!
    _drawSparkle(canvas, Offset(cx, 3.7 * unit), unit * 0.4, paint);

    // "!" surprise
    _drawText(canvas, '!', Offset(cx, 1.5 * unit), unit, fillPaint);
  }

  /// Card 4: Sitting next to crush on bus — two on a seat, one blushing
  void _drawCrushOnBus(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Bus seat back
    canvas.drawLine(Offset(unit, 3 * unit), Offset(unit, 7 * unit), paint);
    // Seat
    canvas.drawLine(Offset(unit, 7 * unit), Offset(9 * unit, 7 * unit), paint);

    // Left figure (sitting, stiff, blushing)
    _drawHead(canvas, Offset(cx - 1.5 * unit, 4.5 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.2 * unit), Offset(cx - 1.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 6.5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    // Blush circles
    canvas.drawCircle(Offset(cx - 2.2 * unit, 4.7 * unit), unit * 0.2, fillPaint);
    canvas.drawCircle(Offset(cx - 0.8 * unit, 4.7 * unit), unit * 0.2, fillPaint);

    // Right figure (crush, hair flowing, casual)
    _drawHead(canvas, Offset(cx + 1.5 * unit, 4.5 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5.2 * unit), Offset(cx + 1.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6.5 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    // Cool hair
    canvas.drawLine(Offset(cx + 1 * unit, 3.8 * unit), Offset(cx + 0.5 * unit, 3.2 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 3.8 * unit), Offset(cx + 1.5 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 3.8 * unit), Offset(cx + 2.5 * unit, 3.2 * unit), paint);

    // Tiny heart floating from blushing figure
    _drawSmallHeart(canvas, Offset(cx - 0.3 * unit, 3.2 * unit), unit * 0.35, fillPaint);
  }

  /// Card 5: Wink across the room — figure winking, sparkle, other figure swooning
  void _drawWinkAcrossRoom(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Winking figure (left)
    _drawHead(canvas, Offset(2.5 * unit, 3.5 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(2.5 * unit, 4.3 * unit), Offset(2.5 * unit, 6.5 * unit), paint);
    // Winking eye (line)
    canvas.drawLine(Offset(2.1 * unit, 3.3 * unit), Offset(2.5 * unit, 3.5 * unit), paint);
    // Open eye (dot)
    canvas.drawCircle(Offset(2.9 * unit, 3.3 * unit), unit * 0.12, fillPaint);
    // Smirk
    final smirkPath = Path();
    smirkPath.moveTo(2.2 * unit, 3.8 * unit);
    smirkPath.quadraticBezierTo(2.5 * unit, 4.1 * unit, 2.9 * unit, 3.7 * unit);
    canvas.drawPath(smirkPath, paint);
    // Finger guns
    canvas.drawLine(Offset(2.5 * unit, 5 * unit), Offset(4 * unit, 4.5 * unit), paint);

    // Sparkle trail across room
    _drawSparkle(canvas, Offset(cx, 4 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx + unit, 3.8 * unit), unit * 0.2, paint);

    // Swooning figure (right)
    _drawHead(canvas, Offset(7.5 * unit, 3.5 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(7.5 * unit, 4.3 * unit), Offset(7.5 * unit, 6.5 * unit), paint);
    // Hand on chest (swooning)
    canvas.drawLine(Offset(7.5 * unit, 5 * unit), Offset(7 * unit, 4.8 * unit), paint);
    // Heart eyes
    _drawSmallHeart(canvas, Offset(7.2 * unit, 3.3 * unit), unit * 0.2, fillPaint);
    _drawSmallHeart(canvas, Offset(7.8 * unit, 3.3 * unit), unit * 0.2, fillPaint);
  }

  /// Card 6: Quick peck on cheek — one figure quickly kissing other's cheek, motion lines
  void _drawPeckOnCheek(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Standing figure (receiving)
    _drawHead(canvas, Offset(cx + unit, 3.5 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx + unit, 4.3 * unit), Offset(cx + unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 7 * unit), Offset(cx + 0.3 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 7 * unit), Offset(cx + 1.7 * unit, 8.5 * unit), paint);
    // Surprised eyes
    canvas.drawCircle(Offset(cx + 0.7 * unit, 3.3 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 1.3 * unit, 3.3 * unit), unit * 0.15, fillPaint);
    // Open mouth "o"
    canvas.drawCircle(Offset(cx + unit, 3.8 * unit), unit * 0.15, paint);

    // Kissing figure (leaning in fast)
    _drawHead(canvas, Offset(cx - 2 * unit, 3.8 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 4.5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    // Lips puckered toward cheek
    _drawSmallHeart(canvas, Offset(cx - 0.5 * unit, 3.6 * unit), unit * 0.25, fillPaint);

    // Speed lines (quick peck!)
    canvas.drawLine(Offset(cx - 3.5 * unit, 3.5 * unit), Offset(cx - 4 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx - 3.5 * unit, 4 * unit), Offset(cx - 4.2 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx - 3.5 * unit, 4.5 * unit), Offset(cx - 4 * unit, 4.5 * unit), paint);
  }

  /// Card 7: Sharing dessert — two figures, one cake, both reaching with forks
  void _drawShareDessert(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Table
    canvas.drawLine(Offset(unit, 6 * unit), Offset(9 * unit, 6 * unit), paint);

    // Cake in center
    final cakeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 5 * unit), width: 2 * unit, height: 1.5 * unit),
      Radius.circular(unit * 0.3),
    );
    canvas.drawRRect(cakeRect, paint);
    // Cherry on top
    canvas.drawCircle(Offset(cx, 4 * unit), unit * 0.25, fillPaint);
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx + 0.2 * unit, 3.5 * unit), paint);

    // Left figure
    _drawHead(canvas, Offset(3 * unit, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(3 * unit, 3.6 * unit), Offset(3 * unit, 5.5 * unit), paint);
    // Fork hand reaching
    canvas.drawLine(Offset(3 * unit, 4.2 * unit), Offset(cx - 0.5 * unit, 5 * unit), paint);
    // Fork tines
    canvas.drawLine(Offset(cx - 0.5 * unit, 5 * unit), Offset(cx - 0.5 * unit, 4.6 * unit), paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 5 * unit), Offset(cx - 0.3 * unit, 4.6 * unit), paint);

    // Right figure
    _drawHead(canvas, Offset(7 * unit, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(7 * unit, 3.6 * unit), Offset(7 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(7 * unit, 4.2 * unit), Offset(cx + 0.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 5 * unit), Offset(cx + 0.5 * unit, 4.6 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 5 * unit), Offset(cx + 0.3 * unit, 4.6 * unit), paint);

    // Heart
    _drawSmallHeart(canvas, Offset(cx, 2 * unit), unit * 0.4, fillPaint);
  }

  /// Card 8: Holding hands in movie theater — two seated figures, hands clasped, screen glow
  void _drawHoldHandsMovie(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Movie screen (glowing rectangle at top)
    canvas.drawRect(Rect.fromLTWH(unit, unit, 8 * unit, 2.5 * unit), paint);
    // Screen glow lines
    canvas.drawLine(Offset(2 * unit, 1.5 * unit), Offset(4 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(5 * unit, 2 * unit), Offset(8 * unit, 2 * unit), paint);

    // Two seated figures
    _drawHead(canvas, Offset(cx - 1.5 * unit, 5 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.6 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 7 * unit), Offset(cx - 2.2 * unit, 8 * unit), paint);

    _drawHead(canvas, Offset(cx + 1.5 * unit, 5 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5.6 * unit), Offset(cx + 1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 7 * unit), Offset(cx + 2.2 * unit, 8 * unit), paint);

    // Clasped hands in the middle (heart shape)
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6 * unit), Offset(cx, 6.5 * unit), paint);
    _drawSmallHeart(canvas, Offset(cx, 6 * unit), unit * 0.3, fillPaint);
  }

  /// Card 9: Flirty text at work — stick figure at desk, phone with hearts popping out
  void _drawFlirtyText(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Desk
    canvas.drawLine(Offset(unit, 6 * unit), Offset(6 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 6 * unit), Offset(2 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(5 * unit, 6 * unit), Offset(5 * unit, 8.5 * unit), paint);

    // Computer monitor on desk
    canvas.drawRect(Rect.fromLTWH(2.5 * unit, 4 * unit, 2 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(3.5 * unit, 5.5 * unit), Offset(3.5 * unit, 6 * unit), paint);

    // Figure sitting at desk
    _drawHead(canvas, Offset(3.5 * unit, 2.5 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(3.5 * unit, 3.1 * unit), Offset(3.5 * unit, 5.5 * unit), paint);

    // Phone in hand (to the right)
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(7.5 * unit, 4.5 * unit), width: 1.2 * unit, height: 2 * unit),
      Radius.circular(unit * 0.2),
    );
    canvas.drawRRect(phoneRect, paint);
    // Arm to phone
    canvas.drawLine(Offset(3.5 * unit, 4 * unit), Offset(7 * unit, 4.5 * unit), paint);

    // Hearts from phone
    _drawSmallHeart(canvas, Offset(8.5 * unit, 3.5 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(8 * unit, 2.5 * unit), unit * 0.25, fillPaint);
    _drawSmallHeart(canvas, Offset(8.8 * unit, 2 * unit), unit * 0.2, fillPaint);

    // Sneaky grin — "😏"
    final smirkPath = Path();
    smirkPath.moveTo(3.2 * unit, 2.8 * unit);
    smirkPath.quadraticBezierTo(3.5 * unit, 3.1 * unit, 3.8 * unit, 2.7 * unit);
    canvas.drawPath(smirkPath, paint);
  }

  /// Card 10: Playing footsie — table with two figures, feet tangled underneath
  void _drawFootsieTable(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Table top
    canvas.drawLine(Offset(1.5 * unit, 4 * unit), Offset(8.5 * unit, 4 * unit), paint);
    // Table legs
    canvas.drawLine(Offset(2 * unit, 4 * unit), Offset(2 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 4 * unit), Offset(8 * unit, 8.5 * unit), paint);

    // Left figure above table
    _drawHead(canvas, Offset(3 * unit, 2 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(3 * unit, 2.6 * unit), Offset(3 * unit, 4 * unit), paint);
    // Innocent face
    canvas.drawCircle(Offset(2.8 * unit, 1.9 * unit), unit * 0.1, fillPaint);
    canvas.drawCircle(Offset(3.2 * unit, 1.9 * unit), unit * 0.1, fillPaint);

    // Right figure above table
    _drawHead(canvas, Offset(7 * unit, 2 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(7 * unit, 2.6 * unit), Offset(7 * unit, 4 * unit), paint);
    // Smirk
    final smirkPath = Path();
    smirkPath.moveTo(6.8 * unit, 2.3 * unit);
    smirkPath.quadraticBezierTo(7 * unit, 2.5 * unit, 7.3 * unit, 2.2 * unit);
    canvas.drawPath(smirkPath, paint);

    // Feet tangled under table — the fun part!
    // Left foot going right
    canvas.drawLine(Offset(3 * unit, 5.5 * unit), Offset(4.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(4.5 * unit, 7 * unit), Offset(5.5 * unit, 7 * unit), paint); // foot
    // Right foot going left
    canvas.drawLine(Offset(7 * unit, 5.5 * unit), Offset(5.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(5.5 * unit, 7 * unit), Offset(4.5 * unit, 7.2 * unit), paint); // foot
    // Intertwined
    canvas.drawLine(Offset(3 * unit, 6 * unit), Offset(5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(7 * unit, 6 * unit), Offset(5 * unit, 7.5 * unit), paint);

    // Sparkle at feet
    _drawSparkle(canvas, Offset(cx, 7.2 * unit), unit * 0.3, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 2: Cards 11-20 — Romantic / Sensual
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 11: Dancing close at wedding — two figures slow dancing, confetti
  void _drawDanceWedding(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Two close figures
    _drawHead(canvas, Offset(cx - 0.7 * unit, 3 * unit), unit * 0.7, paint);
    _drawHead(canvas, Offset(cx + 0.7 * unit, 3 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx - 0.7 * unit, 3.7 * unit), Offset(cx - 0.7 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + 0.7 * unit, 3.7 * unit), Offset(cx + 0.7 * unit, 6 * unit), paint);
    // Arms around each other
    canvas.drawLine(Offset(cx - 0.7 * unit, 4.3 * unit), Offset(cx + 0.7 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.7 * unit, 4.3 * unit), Offset(cx - 0.7 * unit, 4.5 * unit), paint);
    // Legs
    canvas.drawLine(Offset(cx - 0.7 * unit, 6 * unit), Offset(cx - 1.5 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx - 0.7 * unit, 6 * unit), Offset(cx - 0.2 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + 0.7 * unit, 6 * unit), Offset(cx + 0.2 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + 0.7 * unit, 6 * unit), Offset(cx + 1.5 * unit, 8 * unit), paint);
    // Confetti
    canvas.drawCircle(Offset(2 * unit, 1.5 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(4 * unit, unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(7 * unit, 1.2 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(8 * unit, 2 * unit), unit * 0.1, fillPaint);
    canvas.drawCircle(Offset(1.5 * unit, 2.5 * unit), unit * 0.1, fillPaint);
    // Musical note
    canvas.drawCircle(Offset(8 * unit, 4 * unit), unit * 0.2, fillPaint);
    canvas.drawLine(Offset(8.2 * unit, 4 * unit), Offset(8.2 * unit, 3 * unit), paint);
  }

  /// Card 12: A long hug that lingers — two figures wrapped tight, clock showing time passing
  void _drawLingeringHug(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Two figures merged in hug
    _drawHead(canvas, Offset(cx - 0.5 * unit, 3 * unit), unit * 0.65, paint);
    _drawHead(canvas, Offset(cx + 0.5 * unit, 3 * unit), unit * 0.65, paint);
    // Bodies close
    canvas.drawLine(Offset(cx - 0.5 * unit, 3.65 * unit), Offset(cx - 0.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 3.65 * unit), Offset(cx + 0.5 * unit, 6.5 * unit), paint);
    // Arms wrapping fully around
    final armL = Path();
    armL.moveTo(cx - 0.5 * unit, 4.2 * unit);
    armL.quadraticBezierTo(cx + 1.5 * unit, 4.5 * unit, cx + 0.5 * unit, 5.2 * unit);
    canvas.drawPath(armL, paint);
    final armR = Path();
    armR.moveTo(cx + 0.5 * unit, 4.2 * unit);
    armR.quadraticBezierTo(cx - 1.5 * unit, 4.5 * unit, cx - 0.5 * unit, 5.2 * unit);
    canvas.drawPath(armR, paint);
    // Clock in corner (time passing)
    canvas.drawCircle(Offset(8 * unit, 2 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(8 * unit, 2 * unit), Offset(8 * unit, 1.4 * unit), paint); // minute
    canvas.drawLine(Offset(8 * unit, 2 * unit), Offset(8.4 * unit, 2 * unit), paint); // hour
    // "zzz" — so long they could fall asleep
    _drawText(canvas, 'z z z', Offset(2 * unit, 1.5 * unit), unit * 0.6, fillPaint);
  }

  /// Card 13: Slow dancing in the living room — two figures, lamp, musical notes
  void _drawSlowDanceLiving(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Lamp in corner
    canvas.drawLine(Offset(1.5 * unit, 2 * unit), Offset(1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(0.8 * unit, 2 * unit), Offset(2.2 * unit, 2 * unit), paint);
    // Lamp glow
    canvas.drawCircle(Offset(1.5 * unit, 1.5 * unit), unit * 0.3, fillPaint);
    // Two figures dancing
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 1.2 * unit, 3.3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.6 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx + 1.2 * unit, 3.85 * unit), Offset(cx + 1.2 * unit, 6 * unit), paint);
    // Hands held out
    canvas.drawLine(Offset(cx, 4.2 * unit), Offset(cx + 1.2 * unit, 4.4 * unit), paint);
    // Two musical notes
    canvas.drawCircle(Offset(7 * unit, 2 * unit), unit * 0.18, fillPaint);
    canvas.drawLine(Offset(7.18 * unit, 2 * unit), Offset(7.18 * unit, 1 * unit), paint);
    canvas.drawCircle(Offset(8 * unit, 3 * unit), unit * 0.18, fillPaint);
    canvas.drawLine(Offset(8.18 * unit, 3 * unit), Offset(8.18 * unit, 2 * unit), paint);
    _drawSmallHeart(canvas, Offset(cx + 0.6 * unit, 2 * unit), unit * 0.35, fillPaint);
  }

  /// Card 14: G-string — sassy stick figure posing, tiny triangular underwear
  void _drawGString(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Sassy pose figure
    _drawHead(canvas, Offset(cx, 2 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 2.7 * unit), Offset(cx, 5.5 * unit), paint);
    // Hand on hip
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(cx + 1.8 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.8 * unit, 4.5 * unit), Offset(cx + 1.2 * unit, 5.5 * unit), paint);
    // Other arm up behind head
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(cx - 1.3 * unit, 2.5 * unit), paint);
    // Legs in pose
    canvas.drawLine(Offset(cx, 5.5 * unit), Offset(cx - 1.5 * unit, 8.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5.5 * unit), Offset(cx + 1.5 * unit, 8.5 * unit), paint);
    // G-string triangle
    final gPath = Path();
    gPath.moveTo(cx - 0.8 * unit, 5.5 * unit);
    gPath.lineTo(cx + 0.8 * unit, 5.5 * unit);
    gPath.lineTo(cx, 6.3 * unit);
    gPath.close();
    canvas.drawPath(gPath, fillPaint);
    // Sparkle
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.3, paint);
  }

  /// Card 15: A night you'll never forget — silhouette couple under stars, city skyline
  void _drawUnforgetNight(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Stars
    _drawSparkle(canvas, Offset(2 * unit, 1.5 * unit), unit * 0.2, paint);
    _drawSparkle(canvas, Offset(5 * unit, unit), unit * 0.25, paint);
    _drawSparkle(canvas, Offset(8 * unit, 1.8 * unit), unit * 0.2, paint);
    _drawSparkle(canvas, Offset(6.5 * unit, 0.8 * unit), unit * 0.15, paint);
    // Moon
    canvas.drawArc(Rect.fromCircle(center: Offset(9 * unit, unit), radius: unit * 0.6), 0.5, 4.5, false, paint);
    // City skyline at bottom
    canvas.drawLine(Offset(0, 7 * unit), Offset(unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(unit, 5.5 * unit), Offset(2 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 5.5 * unit), Offset(2 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 6 * unit), Offset(3 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(3 * unit, 6 * unit), Offset(3 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(3 * unit, 4.5 * unit), Offset(4 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(7 * unit, 5 * unit), Offset(8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 5 * unit), Offset(8 * unit, 7 * unit), paint);
    // Two silhouette figures close
    _drawHead(canvas, Offset(cx, 5.5 * unit), unit * 0.5, fillPaint);
    _drawHead(canvas, Offset(cx + 1 * unit, 5.5 * unit), unit * 0.5, fillPaint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 6 * unit), Offset(cx + unit, 7.5 * unit), paint);
  }

  /// Card 16: Kiss on the neck — one figure tilting head, other kissing neck, shivers
  void _drawKissNeck(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Receiving figure — head tilted
    _drawHead(canvas, Offset(cx + unit, 3 * unit), unit * 0.8, paint);
    canvas.drawLine(Offset(cx + unit, 3.8 * unit), Offset(cx + unit, 7 * unit), paint);
    // Head tilted (line showing tilt)
    canvas.drawLine(Offset(cx + 0.3 * unit, 2.5 * unit), Offset(cx + 1.8 * unit, 3.3 * unit), paint);

    // Kissing figure leaning in
    _drawHead(canvas, Offset(cx - 1.5 * unit, 3.5 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 4.15 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    // Lips on neck
    _drawSmallHeart(canvas, Offset(cx + 0.2 * unit, 4 * unit), unit * 0.25, fillPaint);

    // Shiver/goosebump lines
    canvas.drawLine(Offset(cx + 2.5 * unit, 4 * unit), Offset(cx + 3 * unit, 3.8 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 4.5 * unit), Offset(cx + 3.2 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 5 * unit), Offset(cx + 3 * unit, 5.2 * unit), paint);

    // "~" pleasure wave
    final wavePath = Path();
    wavePath.moveTo(cx + 2.5 * unit, 2 * unit);
    wavePath.quadraticBezierTo(cx + 3 * unit, 1.5 * unit, cx + 3.5 * unit, 2 * unit);
    wavePath.quadraticBezierTo(cx + 4 * unit, 2.5 * unit, cx + 4.5 * unit, 2 * unit);
    canvas.drawPath(wavePath, paint);
  }

  /// Card 17: Oil massage — one figure lying down, other's hands on back, oil drops
  void _drawOilMassage(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Massage table
    canvas.drawLine(Offset(unit, 6.5 * unit), Offset(8.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(1.5 * unit, 6.5 * unit), Offset(1.5 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 6.5 * unit), Offset(8 * unit, 8 * unit), paint);
    // Lying figure (face down)
    _drawHead(canvas, Offset(2.5 * unit, 5.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(3 * unit, 5.5 * unit), Offset(7.5 * unit, 5.5 * unit), paint);
    // Happy expression
    final smilePath = Path();
    smilePath.moveTo(2.2 * unit, 5.8 * unit);
    smilePath.quadraticBezierTo(2.5 * unit, 6.1 * unit, 2.8 * unit, 5.8 * unit);
    canvas.drawPath(smilePath, paint);

    // Person standing/kneeling with hands
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.55 * unit), Offset(cx, 5 * unit), paint);
    // Hands pressing down
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx - unit, 5.3 * unit), paint);
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx + unit, 5.3 * unit), paint);

    // Oil drops
    canvas.drawCircle(Offset(cx - 0.5 * unit, 4.8 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 0.5 * unit, 4.6 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(cx, 4.5 * unit), unit * 0.1, fillPaint);
  }

  /// Card 18: Making out in parked car — car outline, two heads VERY close, steamy windows
  void _drawMakeOutCar(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Car body
    final carBody = Path();
    carBody.moveTo(unit, 6 * unit);
    carBody.lineTo(2 * unit, 4 * unit);
    carBody.lineTo(8 * unit, 4 * unit);
    carBody.lineTo(9 * unit, 6 * unit);
    carBody.close();
    canvas.drawPath(carBody, paint);
    // Roof
    canvas.drawLine(Offset(3 * unit, 4 * unit), Offset(3.5 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(3.5 * unit, 2.5 * unit), Offset(7 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(7 * unit, 2.5 * unit), Offset(7.5 * unit, 4 * unit), paint);
    // Wheels
    canvas.drawCircle(Offset(3 * unit, 6.5 * unit), unit * 0.6, paint);
    canvas.drawCircle(Offset(7.5 * unit, 6.5 * unit), unit * 0.6, paint);
    // Two heads close inside
    _drawHead(canvas, Offset(cx - 0.3 * unit, 3.5 * unit), unit * 0.4, fillPaint);
    _drawHead(canvas, Offset(cx + 0.3 * unit, 3.5 * unit), unit * 0.4, fillPaint);
    // Steam lines from windows
    final steamPath = Path();
    steamPath.moveTo(4 * unit, 2.5 * unit);
    steamPath.quadraticBezierTo(4.2 * unit, 1.5 * unit, 4.5 * unit, 1.8 * unit);
    canvas.drawPath(steamPath, paint);
    final steam2 = Path();
    steam2.moveTo(6 * unit, 2.5 * unit);
    steam2.quadraticBezierTo(6.3 * unit, 1.5 * unit, 6.6 * unit, 1.8 * unit);
    canvas.drawPath(steam2, paint);
    _drawSmallHeart(canvas, Offset(5 * unit, 1.2 * unit), unit * 0.3, fillPaint);
  }

  /// Card 19: Weekend getaway cabin — cute cabin with chimney smoke, hearts in windows
  void _drawCabinGetaway(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Cabin
    canvas.drawLine(Offset(2 * unit, 4.5 * unit), Offset(cx, 2.5 * unit), paint); // roof left
    canvas.drawLine(Offset(8 * unit, 4.5 * unit), Offset(cx, 2.5 * unit), paint); // roof right
    canvas.drawLine(Offset(2 * unit, 4.5 * unit), Offset(2 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 4.5 * unit), Offset(8 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 7.5 * unit), Offset(8 * unit, 7.5 * unit), paint);
    // Door
    canvas.drawRect(Rect.fromLTWH(4.5 * unit, 5.5 * unit, 1.5 * unit, 2 * unit), paint);
    // Windows with hearts
    canvas.drawRect(Rect.fromLTWH(2.8 * unit, 5 * unit, 1.2 * unit, unit), paint);
    _drawSmallHeart(canvas, Offset(3.4 * unit, 5.5 * unit), unit * 0.2, fillPaint);
    canvas.drawRect(Rect.fromLTWH(6.5 * unit, 5 * unit, 1.2 * unit, unit), paint);
    _drawSmallHeart(canvas, Offset(7.1 * unit, 5.5 * unit), unit * 0.2, fillPaint);
    // Chimney
    canvas.drawLine(Offset(7 * unit, 3.2 * unit), Offset(7 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(7 * unit, 2 * unit), Offset(7.6 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(7.6 * unit, 2 * unit), Offset(7.6 * unit, 3.6 * unit), paint);
    // Smoke
    final smokePath = Path();
    smokePath.moveTo(7.3 * unit, 2 * unit);
    smokePath.quadraticBezierTo(7 * unit, 1.2 * unit, 7.5 * unit, 0.8 * unit);
    canvas.drawPath(smokePath, paint);
    // Trees
    canvas.drawLine(Offset(unit, 4 * unit), Offset(unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(0.3 * unit, 5 * unit), Offset(unit, 4 * unit), paint);
    canvas.drawLine(Offset(1.7 * unit, 5 * unit), Offset(unit, 4 * unit), paint);
  }

  /// Card 20: Skinny dipping — two stick figures in water, clothes on shore, moon
  void _drawSkinnyDip(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Moon
    canvas.drawCircle(Offset(8.5 * unit, 1.5 * unit), unit * 0.7, paint);
    // Water waves
    final wavePath = Path();
    wavePath.moveTo(0, 5.5 * unit);
    for (int i = 0; i < 5; i++) {
      wavePath.quadraticBezierTo(
        (i * 2 + 1) * unit, 5 * unit,
        (i + 1) * 2 * unit, 5.5 * unit,
      );
    }
    canvas.drawPath(wavePath, paint);
    // More waves
    final wave2 = Path();
    wave2.moveTo(0, 6.5 * unit);
    for (int i = 0; i < 5; i++) {
      wave2.quadraticBezierTo(
        (i * 2 + 1) * unit, 6 * unit,
        (i + 1) * 2 * unit, 6.5 * unit,
      );
    }
    canvas.drawPath(wave2, paint);
    // Two heads peeking out of water
    _drawHead(canvas, Offset(cx - 1.5 * unit, 4.5 * unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 4.5 * unit), unit * 0.6, paint);
    // Cheeky grins
    final grin1 = Path();
    grin1.moveTo(cx - 1.8 * unit, 4.8 * unit);
    grin1.quadraticBezierTo(cx - 1.5 * unit, 5.1 * unit, cx - 1.2 * unit, 4.8 * unit);
    canvas.drawPath(grin1, paint);
    // Clothes on shore (top right)
    canvas.drawLine(Offset(8 * unit, 7 * unit), Offset(8.5 * unit, 7.5 * unit), paint); // shirt
    canvas.drawLine(Offset(8 * unit, 7 * unit), Offset(7.5 * unit, 7.5 * unit), paint);
    canvas.drawCircle(Offset(9 * unit, 7.5 * unit), unit * 0.3, paint); // pants crumpled
    // "!" excitement
    _drawText(canvas, '!', Offset(cx, 3 * unit), unit * 0.8, fillPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 3: Cards 21-30 — Mainstream Sexual
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 21: Masturbation — solo figure reclining on couch, sparkles, content face
  void _drawMasturbation(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Couch
    final couchPath = Path();
    couchPath.moveTo(unit, 7 * unit);
    couchPath.lineTo(unit, 5 * unit);
    couchPath.quadraticBezierTo(unit, 4 * unit, 2 * unit, 4 * unit);
    canvas.drawPath(couchPath, paint);
    canvas.drawLine(Offset(unit, 7 * unit), Offset(8 * unit, 7 * unit), paint);
    _drawHead(canvas, Offset(3 * unit, 3.5 * unit), unit * 0.65, paint);
    final bodyPath = Path();
    bodyPath.moveTo(3 * unit, 4.15 * unit);
    bodyPath.quadraticBezierTo(4 * unit, 5 * unit, 6 * unit, 6 * unit);
    canvas.drawPath(bodyPath, paint);
    canvas.drawLine(Offset(6 * unit, 6 * unit), Offset(5.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(6 * unit, 6 * unit), Offset(7 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(2.7 * unit, 3.3 * unit), Offset(3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(3 * unit, 3.5 * unit), Offset(3.3 * unit, 3.3 * unit), paint);
    _drawSparkle(canvas, Offset(7 * unit, 3 * unit), unit * 0.35, paint);
    _drawSparkle(canvas, Offset(8 * unit, 4 * unit), unit * 0.25, paint);
  }

  /// Card 22: Hand job — abstract hand with motion lines
  void _drawHandJob(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 0.5 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + unit, 3.8 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 1.2 * unit, 4.2 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + unit, 4.8 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 3.5 * unit), Offset(cx + 2.8 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 4.3 * unit), Offset(cx + 3 * unit, 4.3 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5 * unit), Offset(cx + 2.8 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx, 2 * unit), Offset(cx - 0.5 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx - 0.5 * unit, 3 * unit), Offset(cx + 0.3 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 3 * unit), Offset(cx - 0.3 * unit, 4 * unit), paint);
    _drawText(canvas, '!', Offset(cx + 3 * unit, 2 * unit), unit * 0.8, fillPaint);
  }

  /// Card 23: Dirty talk — two figures, spicy speech bubble
  void _drawDirtyTalk(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 4 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 4.65 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    _drawHead(canvas, Offset(cx + 2 * unit, 4 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 4.65 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx - 0.5 * unit, 4.5 * unit), paint);
    final bubblePath = Path();
    bubblePath.addOval(Rect.fromCenter(center: Offset(cx, 2 * unit), width: 4 * unit, height: 2.5 * unit));
    canvas.drawPath(bubblePath, paint);
    canvas.drawLine(Offset(cx - unit, 3.2 * unit), Offset(cx - 1.5 * unit, 3.8 * unit), paint);
    _drawText(canvas, '#!@', Offset(cx, 2 * unit), unit * 0.6, fillPaint);
    canvas.drawLine(Offset(cx + 2 * unit, 5 * unit), Offset(cx + 3 * unit, 3.5 * unit), paint);
  }

  /// Card 24: Morning sex — two in bed, alarm ringing, sun
  void _drawMorningSex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawLine(Offset(unit, 5.5 * unit), Offset(8 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(unit, 5.5 * unit), Offset(unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 5.5 * unit), Offset(8 * unit, 7.5 * unit), paint);
    final blanketPath = Path();
    blanketPath.moveTo(2 * unit, 5.5 * unit);
    blanketPath.quadraticBezierTo(cx, 3.5 * unit, 7 * unit, 5.5 * unit);
    canvas.drawPath(blanketPath, paint);
    _drawHead(canvas, Offset(2.5 * unit, 4.5 * unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(4 * unit, 4.5 * unit), unit * 0.5, paint);
    canvas.drawCircle(Offset(8.5 * unit, 2 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(8.5 * unit, 2 * unit), Offset(8.5 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(8.5 * unit, 2 * unit), Offset(8.9 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(7.6 * unit, 1.2 * unit), Offset(7.3 * unit, 0.8 * unit), paint);
    canvas.drawLine(Offset(9.4 * unit, 1.2 * unit), Offset(9.7 * unit, 0.8 * unit), paint);
    canvas.drawCircle(Offset(unit, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 25: Shower sex — shower box with steam, two close figures
  void _drawShowerSex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawRect(Rect.fromLTWH(2 * unit, 2 * unit, 6 * unit, 6.5 * unit), paint);
    canvas.drawCircle(Offset(7 * unit, 2.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(7 * unit, 2 * unit), Offset(7.5 * unit, unit), paint);
    canvas.drawCircle(Offset(5 * unit, 3.5 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(6 * unit, 4 * unit), unit * 0.1, fillPaint);
    canvas.drawCircle(Offset(4 * unit, 4.5 * unit), unit * 0.12, fillPaint);
    _drawHead(canvas, Offset(cx - 0.3 * unit, 4 * unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(cx + 0.8 * unit, 4.2 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 4.5 * unit), Offset(cx - 0.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 4.65 * unit), Offset(cx + unit, 7 * unit), paint);
    final steam1 = Path();
    steam1.moveTo(3 * unit, 2 * unit);
    steam1.quadraticBezierTo(3.2 * unit, 1 * unit, 3.5 * unit, 1.3 * unit);
    canvas.drawPath(steam1, paint);
    final steam2 = Path();
    steam2.moveTo(5 * unit, 2 * unit);
    steam2.quadraticBezierTo(5.3 * unit, 1 * unit, 5.6 * unit, 1.3 * unit);
    canvas.drawPath(steam2, paint);
  }

  /// Card 26: Cunnilingus — standing figure, kneeling figure, sparkles
  void _drawCunnilingus(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 2 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx, 2.65 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5.5 * unit), Offset(cx - unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5.5 * unit), Offset(cx + unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx - unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx + unit, 5 * unit), paint);
    _drawHead(canvas, Offset(cx, 5.8 * unit), unit * 0.4, paint);
    _drawSparkle(canvas, Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.25, paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 1.8 * unit), Offset(cx, 2 * unit), paint);
    canvas.drawLine(Offset(cx, 2 * unit), Offset(cx + 0.3 * unit, 1.8 * unit), paint);
  }

  /// Card 27: Blow job — kneeling figure, standing figure, mind blown
  void _drawBlowJob(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx + unit, 2.5 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx + unit, 3.15 * unit), Offset(cx + unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 6 * unit), Offset(cx + 0.3 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 6 * unit), Offset(cx + 1.7 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + 0.2 * unit, 2 * unit), Offset(cx - 0.3 * unit, 1.3 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 1.8 * unit), Offset(cx + unit, 1 * unit), paint);
    canvas.drawLine(Offset(cx + 1.8 * unit, 2 * unit), Offset(cx + 2.3 * unit, 1.3 * unit), paint);
    _drawHead(canvas, Offset(cx - 1.5 * unit, 5.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 7 * unit), Offset(cx - 2 * unit, 8 * unit), paint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 2 * unit), unit * 0.3, paint);
  }

  /// Card 28: Vaginal sex — two intertwined figures, heart
  void _drawVaginalSex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 0.5 * unit, 2.5 * unit), unit * 0.6, paint);
    _drawHead(canvas, Offset(cx + 0.5 * unit, 2.5 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 0.5 * unit, 3.1 * unit), Offset(cx - 0.3 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 3.1 * unit), Offset(cx + 0.3 * unit, 5.5 * unit), paint);
    final armPath = Path();
    armPath.moveTo(cx - 0.5 * unit, 3.8 * unit);
    armPath.quadraticBezierTo(cx + 1.5 * unit, 4 * unit, cx + 0.5 * unit, 4.8 * unit);
    canvas.drawPath(armPath, paint);
    final arm2 = Path();
    arm2.moveTo(cx + 0.5 * unit, 3.8 * unit);
    arm2.quadraticBezierTo(cx - 1.5 * unit, 4 * unit, cx - 0.5 * unit, 4.8 * unit);
    canvas.drawPath(arm2, paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 5.5 * unit), Offset(cx - 1.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 5.5 * unit), Offset(cx + 1.5 * unit, 7.5 * unit), paint);
    _drawSmallHeart(canvas, Offset(cx, 1.5 * unit), unit * 0.5, fillPaint);
  }

  /// Card 29: Hotel vacation — fancy bed, DND sign, palm tree
  void _drawHotelVacation(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(2 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 5 * unit), Offset(8 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(2 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 5 * unit), Offset(8 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 3.5 * unit), Offset(8 * unit, 3.5 * unit), paint);
    final blanket = Path();
    blanket.moveTo(3 * unit, 5 * unit);
    blanket.quadraticBezierTo(cx, 3 * unit, 7 * unit, 5 * unit);
    canvas.drawPath(blanket, paint);
    final signRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(unit, 3 * unit), width: 1.5 * unit, height: 2.5 * unit),
      Radius.circular(unit * 0.2),
    );
    canvas.drawRRect(signRect, paint);
    _drawText(canvas, 'DND', Offset(unit, 3 * unit), unit * 0.4, fillPaint);
    canvas.drawLine(Offset(9 * unit, 2 * unit), Offset(9 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(9 * unit, 2 * unit), Offset(8 * unit, 2.8 * unit), paint);
    canvas.drawLine(Offset(9 * unit, 2 * unit), Offset(9.8 * unit, 2.8 * unit), paint);
  }

  /// Card 30: All-night session — moon, clock, two bumps in bed
  void _drawAllNighter(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawArc(Rect.fromCircle(center: Offset(1.5 * unit, 1.5 * unit), radius: unit * 0.6), 0.5, 4.5, false, paint);
    _drawSparkle(canvas, Offset(3.5 * unit, unit), unit * 0.2, paint);
    _drawSparkle(canvas, Offset(6 * unit, 0.8 * unit), unit * 0.25, paint);
    canvas.drawLine(Offset(2 * unit, 6 * unit), Offset(8 * unit, 6 * unit), paint);
    final blanket = Path();
    blanket.moveTo(2.5 * unit, 6 * unit);
    blanket.quadraticBezierTo(4 * unit, 4 * unit, 5 * unit, 5.5 * unit);
    blanket.quadraticBezierTo(6 * unit, 3.5 * unit, 7.5 * unit, 6 * unit);
    canvas.drawPath(blanket, paint);
    _drawHead(canvas, Offset(3.5 * unit, 4.5 * unit), unit * 0.4, paint);
    _drawHead(canvas, Offset(6 * unit, 4 * unit), unit * 0.4, paint);
    canvas.drawCircle(Offset(8.5 * unit, 2 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(8.5 * unit, 2 * unit), Offset(8.5 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(8.5 * unit, 2 * unit), Offset(8.1 * unit, 2.3 * unit), paint);
    _drawText(canvas, '4am', Offset(8.5 * unit, 3.2 * unit), unit * 0.4, fillPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 4: Cards 31-40 — Adventurous / Toys
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 31: Tribadism — two figures scissoring, sparkles
  void _drawTribadism(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 3.5 * unit), Offset(cx - 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5 * unit), Offset(cx - 3 * unit, 7 * unit), paint);
    _drawHead(canvas, Offset(cx + 2 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 3.5 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5 * unit), Offset(cx + 3 * unit, 7 * unit), paint);
    _drawSparkle(canvas, Offset(cx, 5 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx - 0.5 * unit, 6.5 * unit), unit * 0.2, paint);
    _drawSparkle(canvas, Offset(cx + 0.5 * unit, 6.5 * unit), unit * 0.2, paint);
  }

  /// Card 32: Hair pulling — figure grabbing another's hair, motion lines
  void _drawHairPulling(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx + unit, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx + unit, 3.6 * unit), Offset(cx + unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 4.5 * unit), Offset(cx - unit, 3.5 * unit), paint);
    _drawHead(canvas, Offset(cx - 2 * unit, 4 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 4.6 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    // Hair strands from head being pulled
    canvas.drawLine(Offset(cx - 2 * unit, 3.4 * unit), Offset(cx - unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.8 * unit, 3.5 * unit), Offset(cx - 0.8 * unit, 3.3 * unit), paint);
    canvas.drawLine(Offset(cx - 1.6 * unit, 3.6 * unit), Offset(cx - 0.6 * unit, 3.6 * unit), paint);
    // Motion lines
    canvas.drawLine(Offset(cx - 0.5 * unit, 2.5 * unit), Offset(cx + 0.3 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 3 * unit), Offset(cx + 0.5 * unit, 3 * unit), paint);
    _drawText(canvas, '!', Offset(cx - 2 * unit, 2.5 * unit), unit * 0.7, fillPaint);
  }

  /// Card 33: Vibrator — figure on bed with buzzing toy, zzz waves
  void _drawVibrator(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawLine(Offset(2 * unit, 6 * unit), Offset(8 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(3 * unit, 4 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(3 * unit, 4.55 * unit), Offset(5 * unit, 5.8 * unit), paint);
    canvas.drawLine(Offset(5 * unit, 5.8 * unit), Offset(6.5 * unit, 6 * unit), paint);
    // Vibrator shape - small rounded rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + unit, 5 * unit), width: 0.8 * unit, height: 2 * unit),
        Radius.circular(unit * 0.3),
      ),
      paint,
    );
    // Buzz waves
    canvas.drawArc(Rect.fromCircle(center: Offset(cx + unit, 4 * unit), radius: unit * 0.5), -1.5, 1.2, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx + unit, 4 * unit), radius: unit * 0.8), -1.5, 1.2, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx + unit, 4 * unit), radius: unit * 1.1), -1.5, 1.2, false, paint);
    // Happy face
    canvas.drawLine(Offset(2.8 * unit, 3.8 * unit), Offset(3 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(3 * unit, 4 * unit), Offset(3.2 * unit, 3.8 * unit), paint);
  }

  /// Card 34: Masturbation w/ toys — figure with toy box, options
  void _drawMasturbationToys(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 3.6 * unit), Offset(cx - 2 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 4.5 * unit), Offset(cx - 0.5 * unit, 5 * unit), paint);
    // Box o' toys
    canvas.drawRect(Rect.fromLTWH(cx, 4 * unit, 3 * unit, 2.5 * unit), paint);
    // Items poking out
    canvas.drawLine(Offset(cx + 0.5 * unit, 4 * unit), Offset(cx + 0.5 * unit, 3 * unit), paint);
    canvas.drawCircle(Offset(cx + 0.5 * unit, 2.8 * unit), unit * 0.2, fillPaint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 4 * unit), Offset(cx + 1.5 * unit, 3.2 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 4 * unit), Offset(cx + 2.8 * unit, 2.8 * unit), paint);
    _drawSparkle(canvas, Offset(cx + 3.5 * unit, 3 * unit), unit * 0.3, paint);
    _drawText(canvas, '?!', Offset(cx - 2 * unit, 2 * unit), unit * 0.6, fillPaint);
  }

  /// Card 35: Dildo — figure holding rod-shaped item, big grin
  void _drawDildo(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx, 3.65 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(cx + 2 * unit, 4 * unit), paint);
    // Dildo shape
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 3 * unit, 3.5 * unit), width: 0.8 * unit, height: 2.5 * unit),
        Radius.circular(unit * 0.4),
      ),
      paint,
    );
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(cx - 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + unit, 8 * unit), paint);
    // Grin
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 3.1 * unit), width: 0.7 * unit, height: 0.5 * unit),
      0.2, 2.7, false, paint,
    );
  }

  /// Card 36: Sex toy w/ partner — two figures, shared toy between them
  void _drawSexToyPartner(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 3.55 * unit), Offset(cx - 2 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 2 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 3.55 * unit), Offset(cx + 2 * unit, 6 * unit), paint);
    // Hands reaching toward center
    canvas.drawLine(Offset(cx - 2 * unit, 4.5 * unit), Offset(cx - 0.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 4.5 * unit), Offset(cx + 0.5 * unit, 5 * unit), paint);
    // Toy in center
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 5 * unit), width: 0.7 * unit, height: 1.8 * unit),
        Radius.circular(unit * 0.3),
      ),
      paint,
    );
    // Buzz waves
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, 4 * unit), radius: unit * 0.5), -1.5, 1.2, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, 4 * unit), radius: unit * 0.8), -1.5, 1.2, false, paint);
    _drawSmallHeart(canvas, Offset(cx, 2 * unit), unit * 0.4, fillPaint);
  }

  /// Card 37: Vacay (never leave the room) — door with DND, hearts floating
  void _drawVacayInRoom(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Door
    canvas.drawRect(Rect.fromLTWH(cx - 1.5 * unit, 2 * unit, 3 * unit, 6 * unit), paint);
    canvas.drawCircle(Offset(cx + unit, 5 * unit), unit * 0.2, fillPaint);
    // DND sign
    final signRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 3.5 * unit), width: 2 * unit, height: unit),
      Radius.circular(unit * 0.15),
    );
    canvas.drawRRect(signRect, paint);
    _drawText(canvas, 'DND', Offset(cx, 3.5 * unit), unit * 0.35, fillPaint);
    // Hearts floating out
    _drawSmallHeart(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.35, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 3 * unit, 2 * unit), unit * 0.45, fillPaint);
    _drawSmallHeart(canvas, Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.3, fillPaint);
    // Sock on doorknob
    final sockPath = Path();
    sockPath.moveTo(cx + unit, 4.8 * unit);
    sockPath.lineTo(cx + 1.5 * unit, 4.3 * unit);
    sockPath.lineTo(cx + 2 * unit, 4.6 * unit);
    canvas.drawPath(sockPath, paint);
  }

  /// Card 38: Being worshipped — figure on throne, other kneeling
  void _drawWorshipped(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Throne
    canvas.drawRect(Rect.fromLTWH(cx - 1.5 * unit, 3 * unit, 3 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 3 * unit), Offset(cx - 1.5 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 3 * unit), Offset(cx + 1.5 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 2 * unit), Offset(cx + 1.5 * unit, 2 * unit), paint);
    _drawHead(canvas, Offset(cx, 2.5 * unit), unit * 0.5, paint);
    // Crown
    canvas.drawLine(Offset(cx - 0.5 * unit, 2 * unit), Offset(cx - 0.3 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 1.5 * unit), Offset(cx, 1.8 * unit), paint);
    canvas.drawLine(Offset(cx, 1.8 * unit), Offset(cx + 0.3 * unit, 1.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 1.5 * unit), Offset(cx + 0.5 * unit, 2 * unit), paint);
    // Kneeling figure
    _drawHead(canvas, Offset(cx - 3 * unit, 5 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx - 3 * unit, 5.45 * unit), Offset(cx - 3 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 3 * unit, 6.5 * unit), Offset(cx - 3 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx - 3 * unit, 5.8 * unit), Offset(cx - 2 * unit, 6 * unit), paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 2 * unit), unit * 0.3, paint);
  }

  /// Card 39: Squirting — figure with splash effect, stars
  void _drawSquirting(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - unit, 3.55 * unit), Offset(cx - unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 5.5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 5.5 * unit), Offset(cx, 7 * unit), paint);
    // Splash effect
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx + 2 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx + 2.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx + 2 * unit, 6 * unit), paint);
    canvas.drawCircle(Offset(cx + 2.5 * unit, 3.5 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 3 * unit, 4.5 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(cx + 2.8 * unit, 5.8 * unit), unit * 0.1, fillPaint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.25, paint);
    _drawText(canvas, '!!', Offset(cx - unit, 2 * unit), unit * 0.6, fillPaint);
  }

  /// Card 40: BJ with swallow — kneeling fig, standing fig, gulp icon
  void _drawBjSwallow(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx + unit, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx + unit, 3.6 * unit), Offset(cx + unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 6 * unit), Offset(cx + 0.3 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 6 * unit), Offset(cx + 1.7 * unit, 8 * unit), paint);
    _drawHead(canvas, Offset(cx - 1.5 * unit, 5.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 7 * unit), Offset(cx - 2 * unit, 8 * unit), paint);
    // Gulp indicator — throat line with dot passing through
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx - 1.5 * unit, 6.6 * unit), paint);
    canvas.drawCircle(Offset(cx - 1.5 * unit, 6.3 * unit), unit * 0.12, fillPaint);
    // Stars
    _drawSparkle(canvas, Offset(cx + 3 * unit, 2.5 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 4 * unit), unit * 0.25, paint);
    _drawText(canvas, '*gulp*', Offset(cx - 1.5 * unit, 4.5 * unit), unit * 0.35, fillPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 5: Cards 41-50 — Fetish / Kink-lite
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 41: Public tease — two figures at dinner table, hand under table
  void _drawPublicTease(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx, 7 * unit), paint);
    _drawHead(canvas, Offset(3 * unit, 3.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(3 * unit, 4.05 * unit), Offset(3 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(7 * unit, 3.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(7 * unit, 4.05 * unit), Offset(7 * unit, 6 * unit), paint);
    // Hand sneaking under table
    final handPath = Path();
    handPath.moveTo(3 * unit, 4.8 * unit);
    handPath.quadraticBezierTo(5 * unit, 6 * unit, 6.5 * unit, 6 * unit);
    canvas.drawPath(handPath, paint);
    // Eyes wide on other figure
    canvas.drawCircle(Offset(6.8 * unit, 3.3 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(7.2 * unit, 3.3 * unit), unit * 0.12, fillPaint);
    _drawText(canvas, '😏', Offset(3 * unit, 2.5 * unit), unit * 0.5, fillPaint);
  }

  /// Card 42: Oral creampie — abstract: glass overflowing, sparkle
  void _drawOralCreampie(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Glass shape
    canvas.drawLine(Offset(cx - unit, 3 * unit), Offset(cx - 0.7 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 3 * unit), Offset(cx + 0.7 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 0.7 * unit, 7 * unit), Offset(cx + 0.7 * unit, 7 * unit), paint);
    // Liquid overflow
    final overflow = Path();
    overflow.moveTo(cx - unit, 3 * unit);
    overflow.quadraticBezierTo(cx, 2 * unit, cx + unit, 3 * unit);
    canvas.drawPath(overflow, paint);
    canvas.drawLine(Offset(cx - 1.2 * unit, 3.2 * unit), Offset(cx - 1.8 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 1.2 * unit, 3.2 * unit), Offset(cx + 1.8 * unit, 4 * unit), paint);
    canvas.drawCircle(Offset(cx - 1.5 * unit, 4.5 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(cx + 1.5 * unit, 4.5 * unit), unit * 0.12, fillPaint);
    _drawSparkle(canvas, Offset(cx, 1.5 * unit), unit * 0.3, paint);
    _drawText(canvas, '!', Offset(cx + 2.5 * unit, 2 * unit), unit * 0.7, fillPaint);
  }

  /// Card 43: Foot fetish — figure worshipping another's foot on pedestal
  void _drawFootFetish(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Pedestal
    canvas.drawRect(Rect.fromLTWH(cx - unit, 5.5 * unit, 2 * unit, 2 * unit), paint);
    // Foot on pedestal
    final foot = Path();
    foot.moveTo(cx - 0.8 * unit, 5.5 * unit);
    foot.lineTo(cx - 0.3 * unit, 4.8 * unit);
    foot.quadraticBezierTo(cx + unit, 4.5 * unit, cx + 1.2 * unit, 5.5 * unit);
    canvas.drawPath(foot, paint);
    // Worshipping figure
    _drawHead(canvas, Offset(cx - 3 * unit, 4.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 3 * unit, 5 * unit), Offset(cx - 3 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 3 * unit, 6.5 * unit), Offset(cx - 3.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx - 3 * unit, 5.5 * unit), Offset(cx - 2 * unit, 5.5 * unit), paint);
    // Hearts
    _drawSmallHeart(canvas, Offset(cx - 2 * unit, 3.5 * unit), unit * 0.35, fillPaint);
    _drawSmallHeart(canvas, Offset(cx - 1 * unit, 3 * unit), unit * 0.25, fillPaint);
    _drawSparkle(canvas, Offset(cx + 2 * unit, 4 * unit), unit * 0.25, paint);
  }

  /// Card 44: Mile high club — plane window, two figures crammed in lavatory
  void _drawMileHighClub(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Lavatory box
    canvas.drawRect(Rect.fromLTWH(2 * unit, 2 * unit, 6 * unit, 6 * unit), paint);
    // "OCCUPIED" sign
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 2 * unit), width: 3 * unit, height: 0.8 * unit),
        Radius.circular(unit * 0.1),
      ),
      paint,
    );
    _drawText(canvas, 'OCC', Offset(cx, 2 * unit), unit * 0.3, fillPaint);
    // Two heads close together
    _drawHead(canvas, Offset(cx - 0.5 * unit, 4 * unit), unit * 0.5, paint);
    _drawHead(canvas, Offset(cx + 0.5 * unit, 4 * unit), unit * 0.5, paint);
    // Plane window - oval
    canvas.drawOval(Rect.fromCenter(center: Offset(8.5 * unit, 4 * unit), width: 1.2 * unit, height: 1.5 * unit), paint);
    // Cloud outside
    canvas.drawCircle(Offset(8.5 * unit, 4 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(cx, 6 * unit), unit * 0.4, fillPaint);
  }

  /// Card 45: Face sitting — one figure on chair/face, throne-like
  void _drawFaceSitting(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Lower figure lying down
    _drawHead(canvas, Offset(cx, 6 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx, 6.5 * unit), Offset(cx, 8 * unit), paint);
    // Upper figure sitting
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 3.6 * unit), Offset(cx, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx - 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5 * unit), Offset(cx + 1.5 * unit, 7 * unit), paint);
    // Crown
    canvas.drawLine(Offset(cx - 0.5 * unit, 2.4 * unit), Offset(cx - 0.3 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx - 0.3 * unit, 2 * unit), Offset(cx, 2.3 * unit), paint);
    canvas.drawLine(Offset(cx, 2.3 * unit), Offset(cx + 0.3 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 2 * unit), Offset(cx + 0.5 * unit, 2.4 * unit), paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.3, paint);
  }

  /// Card 46: Cock ring — abstract: ring shape with sparkle
  void _drawCockRing(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Ring
    canvas.drawCircle(Offset(cx, 4.5 * unit), unit * 1.2, paint);
    canvas.drawCircle(Offset(cx, 4.5 * unit), unit * 0.7, paint);
    // Sparkle on ring
    _drawSparkle(canvas, Offset(cx + unit, 3.5 * unit), unit * 0.4, paint);
    _drawSparkle(canvas, Offset(cx - 1.5 * unit, 4 * unit), unit * 0.3, paint);
    // Figure reaction
    _drawHead(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 2.7 * unit, 2.8 * unit), Offset(cx + 3 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 3 * unit, 3 * unit), Offset(cx + 3.3 * unit, 2.8 * unit), paint);
    _drawText(canvas, 'ooh', Offset(cx + 3 * unit, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 47: Cum facial — face with splash marks
  void _drawCumFacial(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 4 * unit), unit * 1.2, paint);
    // Eyes squeezed shut
    canvas.drawLine(Offset(cx - 0.5 * unit, 3.8 * unit), Offset(cx - 0.2 * unit, 3.8 * unit), paint);
    canvas.drawLine(Offset(cx + 0.2 * unit, 3.8 * unit), Offset(cx + 0.5 * unit, 3.8 * unit), paint);
    // Open mouth
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 4.3 * unit), width: 0.6 * unit, height: 0.4 * unit),
      0, 3.14, false, paint,
    );
    // Splash marks
    canvas.drawCircle(Offset(cx + 0.8 * unit, 3.3 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx - 0.5 * unit, 3 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(cx + 0.3 * unit, 4.8 * unit), unit * 0.1, fillPaint);
    canvas.drawLine(Offset(cx + unit, 3 * unit), Offset(cx + 1.5 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.8 * unit, 3.2 * unit), Offset(cx - 1.5 * unit, 2.8 * unit), paint);
    _drawText(canvas, '💦', Offset(cx + 2 * unit, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 48: Futa — figure with both gender symbols merged
  void _drawFuta(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Body
    _drawHead(canvas, Offset(cx, 2.5 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx, 3.15 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx - 1.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    // Combined gender symbol
    canvas.drawCircle(Offset(cx + 3 * unit, 4 * unit), unit * 0.8, paint);
    // Arrow (male)
    canvas.drawLine(Offset(cx + 3.6 * unit, 3.4 * unit), Offset(cx + 4.3 * unit, 2.7 * unit), paint);
    canvas.drawLine(Offset(cx + 4.3 * unit, 2.7 * unit), Offset(cx + 3.8 * unit, 2.7 * unit), paint);
    canvas.drawLine(Offset(cx + 4.3 * unit, 2.7 * unit), Offset(cx + 4.3 * unit, 3.2 * unit), paint);
    // Cross (female)
    canvas.drawLine(Offset(cx + 3 * unit, 4.8 * unit), Offset(cx + 3 * unit, 5.8 * unit), paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 5.3 * unit), Offset(cx + 3.5 * unit, 5.3 * unit), paint);
    _drawSparkle(canvas, Offset(cx - 2 * unit, 2 * unit), unit * 0.3, paint);
  }

  /// Card 49: Being dominated — figure with collar, leash held by standing figure
  void _drawBeingDominated(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Dom figure (standing tall)
    _drawHead(canvas, Offset(cx + 2 * unit, 2 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 2.6 * unit), Offset(cx + 2 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5.5 * unit), Offset(cx + 1.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5.5 * unit), Offset(cx + 2.5 * unit, 7.5 * unit), paint);
    // Leash
    canvas.drawLine(Offset(cx + 2 * unit, 3.5 * unit), Offset(cx - unit, 4.5 * unit), paint);
    // Sub figure (kneeling)
    _drawHead(canvas, Offset(cx - 2 * unit, 4.5 * unit), unit * 0.5, paint);
    // Collar
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 2 * unit, 5 * unit), width: 1.5 * unit, height: 0.5 * unit),
      0, 3.14, false, paint,
    );
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx - 2 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 6.5 * unit), Offset(cx - 2.5 * unit, 7.5 * unit), paint);
    _drawText(canvas, 'yes sir', Offset(cx - 2 * unit, 3.5 * unit), unit * 0.35, fillPaint);
  }

  /// Card 50: Prostate massage — abstract: figure with target/bullseye
  void _drawProstateMassage(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 3.55 * unit), Offset(cx - 2 * unit, 6 * unit), paint);
    // Eyes rolling back expression
    canvas.drawLine(Offset(cx - 2.2 * unit, 2.8 * unit), Offset(cx - 2 * unit, 2.7 * unit), paint);
    canvas.drawLine(Offset(cx - 1.8 * unit, 2.8 * unit), Offset(cx - 2 * unit, 2.7 * unit), paint);
    // Bullseye/target
    canvas.drawCircle(Offset(cx + 2 * unit, 4.5 * unit), unit * 1.2, paint);
    canvas.drawCircle(Offset(cx + 2 * unit, 4.5 * unit), unit * 0.8, paint);
    canvas.drawCircle(Offset(cx + 2 * unit, 4.5 * unit), unit * 0.3, fillPaint);
    // Arrow pointing at target
    canvas.drawLine(Offset(cx - 0.5 * unit, 5 * unit), Offset(cx + 0.8 * unit, 4.6 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 4.6 * unit), Offset(cx + 0.5 * unit, 4.3 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 4.6 * unit), Offset(cx + 0.5 * unit, 4.9 * unit), paint);
    _drawText(canvas, '!!!', Offset(cx - 2 * unit, 2 * unit), unit * 0.6, fillPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 6: Cards 51-60 — BDSM / Kink
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 51: Blindfolded — figure with blindfold, question marks
  void _drawBlindfolded(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.8, paint);
    // Blindfold band
    canvas.drawLine(Offset(cx - 1.2 * unit, 3.3 * unit), Offset(cx + 1.2 * unit, 3.3 * unit), paint);
    canvas.drawLine(Offset(cx - 1.2 * unit, 3.6 * unit), Offset(cx + 1.2 * unit, 3.6 * unit), paint);
    // Tie behind head
    canvas.drawLine(Offset(cx + 1.2 * unit, 3.3 * unit), Offset(cx + 1.8 * unit, 2.8 * unit), paint);
    canvas.drawLine(Offset(cx + 1.2 * unit, 3.6 * unit), Offset(cx + 1.8 * unit, 4.2 * unit), paint);
    canvas.drawLine(Offset(cx, 4.3 * unit), Offset(cx, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx - 1.5 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 1.5 * unit, 6 * unit), paint);
    _drawText(canvas, '?', Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.7, fillPaint);
    _drawText(canvas, '?', Offset(cx + 2.5 * unit, 2.5 * unit), unit * 0.7, fillPaint);
  }

  /// Card 52: Nipple clamps — abstract: chain with clamps, sparkles
  void _drawNippleClamps(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Chain arc
    final chain = Path();
    chain.moveTo(cx - 2 * unit, 4 * unit);
    chain.quadraticBezierTo(cx, 5.5 * unit, cx + 2 * unit, 4 * unit);
    canvas.drawPath(chain, paint);
    // Clamps (V shapes)
    canvas.drawLine(Offset(cx - 2 * unit, 3.5 * unit), Offset(cx - 1.8 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx - 1.6 * unit, 3.5 * unit), Offset(cx - 1.8 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 3.5 * unit), Offset(cx + 1.8 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 1.6 * unit, 3.5 * unit), Offset(cx + 1.8 * unit, 4 * unit), paint);
    _drawSparkle(canvas, Offset(cx, 3 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 3.5 * unit), unit * 0.25, paint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3.5 * unit), unit * 0.25, paint);
    _drawText(canvas, 'ouch!', Offset(cx, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 53: Anal beads — abstract: string of graduated circles
  void _drawAnalBeads(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // String of beads getting bigger
    final beadSizes = [0.25, 0.35, 0.45, 0.55, 0.65];
    double yPos = 2 * unit;
    for (var i = 0; i < beadSizes.length; i++) {
      final r = beadSizes[i] * unit;
      canvas.drawCircle(Offset(cx, yPos + r), r, paint);
      yPos += r * 2 + unit * 0.2;
    }
    // Ring at end
    canvas.drawCircle(Offset(cx, yPos + unit * 0.3), unit * 0.35, paint);
    canvas.drawCircle(Offset(cx, yPos + unit * 0.3), unit * 0.15, fillPaint);
    // Reaction figure
    _drawHead(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.45, paint);
    canvas.drawCircle(Offset(cx + 2.85 * unit, 2.9 * unit), unit * 0.1, fillPaint);
    canvas.drawCircle(Offset(cx + 3.15 * unit, 2.9 * unit), unit * 0.1, fillPaint);
  }

  /// Card 54: Butt plug — abstract: plug shape, jewel sparkle
  void _drawButtPlug(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Plug shape
    final plugPath = Path();
    plugPath.moveTo(cx, 2 * unit);
    plugPath.quadraticBezierTo(cx + 2 * unit, 4 * unit, cx + 0.5 * unit, 5.5 * unit);
    plugPath.lineTo(cx + 0.8 * unit, 6 * unit);
    plugPath.lineTo(cx - 0.8 * unit, 6 * unit);
    plugPath.lineTo(cx - 0.5 * unit, 5.5 * unit);
    plugPath.quadraticBezierTo(cx - 2 * unit, 4 * unit, cx, 2 * unit);
    canvas.drawPath(plugPath, paint);
    // Base
    canvas.drawLine(Offset(cx - 1.2 * unit, 6 * unit), Offset(cx + 1.2 * unit, 6 * unit), paint);
    // Jewel sparkle at base
    _drawSparkle(canvas, Offset(cx, 6.2 * unit), unit * 0.4, paint);
    _drawSparkle(canvas, Offset(cx + 2 * unit, 3 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx - 2 * unit, 3.5 * unit), unit * 0.25, paint);
  }

  /// Card 55: Rimming — abstract: peach emoji style + tongue
  void _drawRimming(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Peach shape
    final peach = Path();
    peach.moveTo(cx, 2.5 * unit);
    peach.quadraticBezierTo(cx + 3 * unit, 3 * unit, cx + 1.5 * unit, 6 * unit);
    peach.quadraticBezierTo(cx, 7 * unit, cx - 1.5 * unit, 6 * unit);
    peach.quadraticBezierTo(cx - 3 * unit, 3 * unit, cx, 2.5 * unit);
    canvas.drawPath(peach, paint);
    // Cleft line
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(cx, 6.5 * unit), paint);
    // Tongue shape
    final tongue = Path();
    tongue.moveTo(cx - 0.5 * unit, 7 * unit);
    tongue.quadraticBezierTo(cx, 8 * unit, cx + 0.5 * unit, 7 * unit);
    canvas.drawPath(tongue, paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 2 * unit), unit * 0.3, paint);
    _drawText(canvas, '😛', Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.5, fillPaint);
  }

  /// Card 56: Submission — kneeling figure, collar, chin-tilt hand
  void _drawSubmission(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Kneeling sub
    _drawHead(canvas, Offset(cx, 4 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 4.6 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + unit, 7 * unit), paint);
    // Collar
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 4.7 * unit), width: 1.8 * unit, height: 0.6 * unit),
      0, 3.14, false, paint,
    );
    // Dom hand tilting chin
    canvas.drawLine(Offset(cx + 2 * unit, 2 * unit), Offset(cx + 0.5 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 3.5 * unit), Offset(cx, 3.4 * unit), paint);
    // Down arrows
    canvas.drawLine(Offset(cx - 2 * unit, 2 * unit), Offset(cx - 2 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx - 2.3 * unit, 2.7 * unit), Offset(cx - 2 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx - 1.7 * unit, 2.7 * unit), Offset(cx - 2 * unit, 3 * unit), paint);
    _drawText(canvas, 'kneel', Offset(cx + 2.5 * unit, 3 * unit), unit * 0.4, fillPaint);
  }

  /// Card 57: Tied up & teased — figure tied to bed posts, feather
  void _drawTiedTeased(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Bed
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(2 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 5 * unit), Offset(8 * unit, 3 * unit), paint);
    // Figure on bed
    _drawHead(canvas, Offset(cx, 4.5 * unit), unit * 0.4, paint);
    canvas.drawLine(Offset(cx, 4.9 * unit), Offset(cx, 5 * unit), paint);
    // Arms tied to posts
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(2 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(8 * unit, 3 * unit), paint);
    // Rope marks
    canvas.drawArc(Rect.fromCircle(center: Offset(2.5 * unit, 3.3 * unit), radius: unit * 0.3), 0, 5, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(7.5 * unit, 3.3 * unit), radius: unit * 0.3), 0, 5, false, paint);
    // Feather
    final feather = Path();
    feather.moveTo(cx + 2 * unit, 2 * unit);
    feather.quadraticBezierTo(cx + 2.5 * unit, 3 * unit, cx + 2 * unit, 4 * unit);
    canvas.drawPath(feather, paint);
    canvas.drawLine(Offset(cx + 1.7 * unit, 2.5 * unit), Offset(cx + 2 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 2.3 * unit, 2.5 * unit), Offset(cx + 2 * unit, 3 * unit), paint);
  }

  /// Card 58: Anal sex — two figures, peach emoji, sparkles
  void _drawAnalSex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - unit, 3.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - unit, 4.05 * unit), Offset(cx - unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx + unit, 3.55 * unit), Offset(cx + unit, 5.5 * unit), paint);
    // Close together
    canvas.drawLine(Offset(cx - unit, 6 * unit), Offset(cx - 2 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5.5 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    // Peach symbol
    final peach = Path();
    peach.moveTo(cx + 3 * unit, 2 * unit);
    peach.quadraticBezierTo(cx + 4 * unit, 2.5 * unit, cx + 3.5 * unit, 3.5 * unit);
    peach.quadraticBezierTo(cx + 3 * unit, 4 * unit, cx + 2.5 * unit, 3.5 * unit);
    peach.quadraticBezierTo(cx + 2 * unit, 2.5 * unit, cx + 3 * unit, 2 * unit);
    canvas.drawPath(peach, paint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 3 * unit), unit * 0.3, paint);
    _drawText(canvas, '🍑', Offset(cx + 3 * unit, 2.8 * unit), unit * 0.5, fillPaint);
  }

  /// Card 59: Voyeurism — figure peeking through blinds, two figures in light
  void _drawVoyeurism(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Window with blinds
    canvas.drawRect(Rect.fromLTWH(cx - 2 * unit, 2 * unit, 4 * unit, 5 * unit), paint);
    for (double y = 2.5; y < 7; y += 0.8) {
      canvas.drawLine(Offset(cx - 2 * unit, y * unit), Offset(cx + 2 * unit, y * unit), paint);
    }
    // Gap in blinds
    canvas.drawLine(Offset(cx - 0.5 * unit, 4 * unit), Offset(cx + 0.5 * unit, 4 * unit), paint..strokeWidth = 2.5);
    // Two figures visible through gap (tiny)
    canvas.drawCircle(Offset(cx - 0.2 * unit, 3.8 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 0.2 * unit, 3.8 * unit), unit * 0.15, fillPaint);
    // Peeker figure outside
    _drawHead(canvas, Offset(cx - 3.5 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 3.5 * unit, 4.5 * unit), Offset(cx - 3.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 3.5 * unit, 5 * unit), Offset(cx - 2.5 * unit, 4.5 * unit), paint);
    // Eye peeking
    canvas.drawCircle(Offset(cx - 3.3 * unit, 3.9 * unit), unit * 0.12, fillPaint);
  }

  /// Card 60: Dom/sub dynamic — two figures, one commanding, one obeying
  void _drawDomSub(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Dom figure standing tall with crop
    _drawHead(canvas, Offset(cx + 2 * unit, 2 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 2.6 * unit), Offset(cx + 2 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5.5 * unit), Offset(cx + 1.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5.5 * unit), Offset(cx + 2.5 * unit, 7.5 * unit), paint);
    // Riding crop
    canvas.drawLine(Offset(cx + 2 * unit, 3.5 * unit), Offset(cx + 3.5 * unit, 2 * unit), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 3.7 * unit, 1.8 * unit), width: 0.6 * unit, height: 0.3 * unit), paint);
    // Sub kneeling
    _drawHead(canvas, Offset(cx - 2 * unit, 5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 5.5 * unit), Offset(cx - 2 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 6.5 * unit), Offset(cx - 2.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 5.8 * unit), Offset(cx - 1 * unit, 6 * unit), paint);
    // Collar + leash
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 2 * unit, 5.6 * unit), width: 1.5 * unit, height: 0.4 * unit), 0, 3.14, false, paint);
    _drawText(canvas, 'yes', Offset(cx - 2 * unit, 4 * unit), unit * 0.45, fillPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 7: Cards 61-70 — Advanced Kink / Group
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 61: Bondage — figure wrapped in rope, X-frame
  void _drawBondage(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // X-frame
    canvas.drawLine(Offset(2 * unit, 2 * unit), Offset(8 * unit, 8 * unit), paint);
    canvas.drawLine(Offset(8 * unit, 2 * unit), Offset(2 * unit, 8 * unit), paint);
    // Figure spread on frame
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.55 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(3 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(7 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(3 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(7 * unit, 7.5 * unit), paint);
    // Rope marks at wrists/ankles
    canvas.drawArc(Rect.fromCircle(center: Offset(3 * unit, 2.5 * unit), radius: unit * 0.3), 0, 5, false, paint);
    canvas.drawArc(Rect.fromCircle(center: Offset(7 * unit, 2.5 * unit), radius: unit * 0.3), 0, 5, false, paint);
  }

  /// Card 62: Orgasm denial — figure reaching for star, hand blocking
  void _drawOrgasmDenial(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - unit, 3.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - unit, 4.05 * unit), Offset(cx - unit, 6.5 * unit), paint);
    // Reaching arm
    canvas.drawLine(Offset(cx - unit, 4.5 * unit), Offset(cx + 2 * unit, 2.5 * unit), paint);
    // Star (goal)
    _drawSparkle(canvas, Offset(cx + 3 * unit, 2 * unit), unit * 0.5, paint);
    // Blocking hand (stop sign shape)
    canvas.drawLine(Offset(cx + unit, 2.5 * unit), Offset(cx + unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 2.5 * unit), Offset(cx + 1.5 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 2.5 * unit), Offset(cx + 0.5 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 2.5 * unit), Offset(cx + 1.5 * unit, 3 * unit), paint);
    _drawText(canvas, 'NOT YET', Offset(cx, 1.5 * unit), unit * 0.4, fillPaint);
    // Frustration lines
    canvas.drawLine(Offset(cx - 1.8 * unit, 3 * unit), Offset(cx - 2.2 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.2 * unit, 3 * unit), Offset(cx + 0.2 * unit, 2.5 * unit), paint);
  }

  /// Card 63: Tantric — two figures in lotus position, energy circles
  void _drawTantricWitch(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Two figures in lotus facing each other
    _drawHead(canvas, Offset(cx - unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - unit, 3.5 * unit), Offset(cx - unit, 5 * unit), paint);
    _drawHead(canvas, Offset(cx + unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + unit, 3.5 * unit), Offset(cx + unit, 5 * unit), paint);
    // Crossed legs
    canvas.drawLine(Offset(cx - unit, 5 * unit), Offset(cx - 2 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 5 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx + 2 * unit, 5.5 * unit), paint);
    // Energy circles
    canvas.drawCircle(Offset(cx, 4 * unit), unit * 2, paint);
    canvas.drawCircle(Offset(cx, 4 * unit), unit * 2.8, paint);
    // Third eye
    canvas.drawCircle(Offset(cx, 2 * unit), unit * 0.2, fillPaint);
    _drawSparkle(canvas, Offset(cx, 1.5 * unit), unit * 0.3, paint);
  }

  /// Card 64: Threesome — three figures, triangle formation
  void _drawThreesome(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Triangle
    canvas.drawLine(Offset(cx, 2 * unit), Offset(2.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx, 2 * unit), Offset(7.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(2.5 * unit, 7 * unit), Offset(7.5 * unit, 7 * unit), paint);
    // Three heads at vertices
    _drawHead(canvas, Offset(cx, 2 * unit), unit * 0.55, paint);
    _drawHead(canvas, Offset(2.5 * unit, 7 * unit), unit * 0.55, paint);
    _drawHead(canvas, Offset(7.5 * unit, 7 * unit), unit * 0.55, paint);
    _drawSmallHeart(canvas, Offset(cx, 4.5 * unit), unit * 0.5, fillPaint);
    _drawText(canvas, 'x3', Offset(cx + 2 * unit, 3 * unit), unit * 0.5, fillPaint);
  }

  /// Card 65: FMF — two female figures flanking male, hearts
  void _drawFmf(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2.5 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 3.5 * unit), Offset(cx - 2.5 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.55 * unit), Offset(cx, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 3.5 * unit), Offset(cx + 2.5 * unit, 6 * unit), paint);
    // F signs
    _drawText(canvas, 'F', Offset(cx - 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'M', Offset(cx, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'F', Offset(cx + 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx - 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
  }

  /// Card 66: FFM — two females and one male, arrows
  void _drawFfm(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2.5 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 3.5 * unit), Offset(cx - 2.5 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 3.55 * unit), Offset(cx + 2.5 * unit, 6 * unit), paint);
    _drawText(canvas, 'F', Offset(cx - 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'F', Offset(cx, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'M', Offset(cx + 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    // Arrow from M to both F
    canvas.drawLine(Offset(cx + 2 * unit, 4 * unit), Offset(cx + 0.5 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 4.5 * unit), Offset(cx - 2 * unit, 4.5 * unit), paint);
    _drawSmallHeart(canvas, Offset(cx, 5 * unit), unit * 0.35, fillPaint);
  }

  /// Card 67: MFM — two male figures flanking female
  void _drawMfm(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2.5 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 3.55 * unit), Offset(cx - 2.5 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 3.55 * unit), Offset(cx + 2.5 * unit, 6 * unit), paint);
    _drawText(canvas, 'M', Offset(cx - 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'F', Offset(cx, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'M', Offset(cx + 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx - 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
  }

  /// Card 68: Shibari — figure with intricate rope patterns
  void _drawShibari(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 2.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.05 * unit), Offset(cx, 7 * unit), paint);
    // Rope diamond pattern on torso
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx - unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 4.5 * unit), Offset(cx, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx + unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 4.5 * unit), Offset(cx, 5.5 * unit), paint);
    // Horizontal rope lines
    canvas.drawLine(Offset(cx - 1.5 * unit, 4 * unit), Offset(cx + 1.5 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    // Arms bound behind
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.35, paint);
    _drawText(canvas, 'art', Offset(cx - 2.5 * unit, 3 * unit), unit * 0.45, fillPaint);
  }

  /// Card 69: Strap-on (F/F) — two female figures, strap shape
  void _drawStrapOnFF(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 1.5 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 3.5 * unit), Offset(cx - 1.5 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 3.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 4 * unit), Offset(cx + 1.5 * unit, 6 * unit), paint);
    // Strap harness lines
    canvas.drawLine(Offset(cx - 1.5 * unit, 5 * unit), Offset(cx - 0.5 * unit, 5 * unit), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 0.5 * unit, 4.5 * unit, 0.6 * unit, 1.5 * unit),
        Radius.circular(unit * 0.2),
      ),
      paint,
    );
    // F symbols
    _drawText(canvas, 'F', Offset(cx - 1.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'F', Offset(cx + 1.5 * unit, 2.5 * unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx, 2 * unit), unit * 0.35, fillPaint);
  }

  /// Card 70: Pegging — figure bending over, other with strap
  void _drawPegging(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Bent over figure
    _drawHead(canvas, Offset(cx + 2 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 2 * unit, 4.5 * unit), Offset(cx + unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5.5 * unit), Offset(cx + 0.5 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5.5 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    // Standing figure behind
    _drawHead(canvas, Offset(cx - 1.5 * unit, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 3.5 * unit), Offset(cx - 1.5 * unit, 5.5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.5 * unit), Offset(cx - unit, 7 * unit), paint);
    // Strap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 0.8 * unit, 5 * unit, 0.5 * unit, 1.2 * unit),
        Radius.circular(unit * 0.15),
      ),
      paint,
    );
    _drawText(canvas, '!', Offset(cx + 2 * unit, 3 * unit), unit * 0.6, fillPaint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 2.5 * unit), unit * 0.3, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 8: Cards 71-80 — Heavy BDSM / Group
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 71: Flogger — hand holding flogger, motion lines
  void _drawFlogger(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Handle
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx, 4 * unit), paint);
    // Flogger strands fanning out
    for (double angle = -0.8; angle <= 0.8; angle += 0.2) {
      canvas.drawLine(
        Offset(cx, 4 * unit),
        Offset(cx + angle * 3 * unit, 2 * unit),
        paint,
      );
    }
    // Motion arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, 4 * unit), radius: 2.5 * unit),
      -2.5, 1.5, false, paint,
    );
    // Hand at handle
    canvas.drawCircle(Offset(cx, 6 * unit), unit * 0.4, paint);
    _drawText(canvas, 'SMACK', Offset(cx, 7.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 72: Bondage spreader bar — figure with arms/legs spread, bar
  void _drawBondageSpread(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 2.5 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.05 * unit), Offset(cx, 6 * unit), paint);
    // Spreader bar at ankles
    canvas.drawLine(Offset(cx - 2.5 * unit, 7.5 * unit), Offset(cx + 2.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - 2.5 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + 2.5 * unit, 7.5 * unit), paint);
    // Cuffs at ends
    canvas.drawCircle(Offset(cx - 2.5 * unit, 7.5 * unit), unit * 0.25, paint);
    canvas.drawCircle(Offset(cx + 2.5 * unit, 7.5 * unit), unit * 0.25, paint);
    // Arms spread
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(cx - 2.5 * unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx, 3.8 * unit), Offset(cx + 2.5 * unit, 3 * unit), paint);
    // Cuffs at wrists
    canvas.drawCircle(Offset(cx - 2.5 * unit, 3 * unit), unit * 0.25, paint);
    canvas.drawCircle(Offset(cx + 2.5 * unit, 3 * unit), unit * 0.25, paint);
  }

  /// Card 73: MMF — two male figures, one female
  void _drawMmf(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2.5 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 3.55 * unit), Offset(cx - 2.5 * unit, 6 * unit), paint);
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx, 3.5 * unit), Offset(cx, 6 * unit), paint);
    _drawHead(canvas, Offset(cx + 2.5 * unit, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 3.55 * unit), Offset(cx + 2.5 * unit, 6 * unit), paint);
    _drawText(canvas, 'M', Offset(cx - 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'M', Offset(cx, 2 * unit), unit * 0.4, fillPaint);
    _drawText(canvas, 'F', Offset(cx + 2.5 * unit, 2 * unit), unit * 0.4, fillPaint);
    _drawSmallHeart(canvas, Offset(cx - 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(cx + 1.2 * unit, 4 * unit), unit * 0.3, fillPaint);
  }

  /// Card 74: Impact play — hand print, smack star
  void _drawImpactPlay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Hand outline
    canvas.drawLine(Offset(cx - unit, 5 * unit), Offset(cx - unit, 3 * unit), paint);
    canvas.drawLine(Offset(cx - 0.5 * unit, 5 * unit), Offset(cx - 0.5 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx, 2.8 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 5 * unit), Offset(cx + 0.5 * unit, 3.2 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx + 1.5 * unit, 4 * unit), paint);
    // Palm
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 5.5 * unit), width: 3 * unit, height: 1.5 * unit),
      0, 3.14, false, paint,
    );
    // Smack star
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.6, paint);
    _drawText(canvas, 'SMACK!', Offset(cx, 7.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 75: Kink club — door with velvet rope, neon sign
  void _drawKinkClub(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Door
    canvas.drawRect(Rect.fromLTWH(cx - 1.5 * unit, 3 * unit, 3 * unit, 5 * unit), paint);
    // Neon sign above
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 2 * unit), width: 4 * unit, height: 1.2 * unit),
        Radius.circular(unit * 0.2),
      ),
      paint,
    );
    _drawText(canvas, 'KINK', Offset(cx, 2 * unit), unit * 0.45, fillPaint);
    // Velvet rope
    final rope = Path();
    rope.moveTo(cx - 3 * unit, 6 * unit);
    rope.quadraticBezierTo(cx - 2 * unit, 7 * unit, cx - 1.5 * unit, 6 * unit);
    canvas.drawPath(rope, paint);
    // Pole
    canvas.drawLine(Offset(cx - 3 * unit, 5 * unit), Offset(cx - 3 * unit, 8 * unit), paint);
    canvas.drawCircle(Offset(cx - 3 * unit, 5 * unit), unit * 0.2, fillPaint);
    _drawSparkle(canvas, Offset(cx + 2 * unit, 1 * unit), unit * 0.35, paint);
  }

  /// Card 76: Ball gag — face with round gag, straps
  void _drawBallGag(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 4 * unit), unit * 1, paint);
    // Ball gag
    canvas.drawCircle(Offset(cx, 4.3 * unit), unit * 0.35, fillPaint);
    // Straps
    canvas.drawLine(Offset(cx - 0.35 * unit, 4.3 * unit), Offset(cx - 1.2 * unit, 3.7 * unit), paint);
    canvas.drawLine(Offset(cx + 0.35 * unit, 4.3 * unit), Offset(cx + 1.2 * unit, 3.7 * unit), paint);
    // Wide eyes
    canvas.drawCircle(Offset(cx - 0.35 * unit, 3.7 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 0.35 * unit, 3.7 * unit), unit * 0.15, fillPaint);
    // Body
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx, 7 * unit), paint);
    _drawText(canvas, 'mmph!', Offset(cx, 2.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 77: Whipping — arm with whip, crack lines
  void _drawWhipping(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Arm
    canvas.drawLine(Offset(2 * unit, 5 * unit), Offset(cx, 4 * unit), paint);
    // Whip
    final whipPath = Path();
    whipPath.moveTo(cx, 4 * unit);
    whipPath.quadraticBezierTo(cx + 2 * unit, 3 * unit, cx + 3 * unit, 4 * unit);
    whipPath.quadraticBezierTo(cx + 4 * unit, 5 * unit, cx + 3 * unit, 2.5 * unit);
    canvas.drawPath(whipPath, paint);
    // Crack at tip
    _drawSparkle(canvas, Offset(cx + 3 * unit, 2 * unit), unit * 0.4, paint);
    // Sound effect
    _drawText(canvas, 'CRACK!', Offset(cx + unit, 1.5 * unit), unit * 0.45, fillPaint);
    // Motion lines
    canvas.drawLine(Offset(cx + 2.5 * unit, 3 * unit), Offset(cx + 3 * unit, 2.5 * unit), paint);
    canvas.drawLine(Offset(cx + 3.5 * unit, 3 * unit), Offset(cx + 4 * unit, 2.5 * unit), paint);
  }

  /// Card 78: Surprise threesome — three figures, speech bubble "?!"
  void _drawSurpriseThreesome(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 2 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 4.5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    _drawHead(canvas, Offset(cx, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx, 4.5 * unit), Offset(cx, 7 * unit), paint);
    // Third figure arriving with surprise
    _drawHead(canvas, Offset(cx + 2.5 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 2.5 * unit, 4.5 * unit), Offset(cx + 2.5 * unit, 7 * unit), paint);
    // Motion lines (arriving)
    canvas.drawLine(Offset(cx + 4 * unit, 3.5 * unit), Offset(cx + 3 * unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 4 * unit, 4.5 * unit), Offset(cx + 3 * unit, 4.5 * unit), paint);
    // Surprise bubble
    final bubble = Path();
    bubble.addOval(Rect.fromCenter(center: Offset(cx, 2 * unit), width: 3 * unit, height: 1.8 * unit));
    canvas.drawPath(bubble, paint);
    _drawText(canvas, '?!', Offset(cx, 2 * unit), unit * 0.6, fillPaint);
  }

  /// Card 79: BDSM lifestyle — leather mask, whip, chains
  void _drawBdsm(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Leather mask outline
    final mask = Path();
    mask.moveTo(cx - 1.5 * unit, 3 * unit);
    mask.quadraticBezierTo(cx, 2 * unit, cx + 1.5 * unit, 3 * unit);
    mask.quadraticBezierTo(cx + 1.5 * unit, 5 * unit, cx, 5.5 * unit);
    mask.quadraticBezierTo(cx - 1.5 * unit, 5 * unit, cx - 1.5 * unit, 3 * unit);
    canvas.drawPath(mask, paint);
    // Eye holes
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 0.5 * unit, 3.5 * unit), width: 0.8 * unit, height: 0.5 * unit), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 0.5 * unit, 3.5 * unit), width: 0.8 * unit, height: 0.5 * unit), paint);
    // Zipper mouth
    canvas.drawLine(Offset(cx - 0.5 * unit, 4.5 * unit), Offset(cx + 0.5 * unit, 4.5 * unit), paint);
    for (double x = -0.4; x <= 0.4; x += 0.2) {
      canvas.drawLine(Offset(cx + x * unit, 4.3 * unit), Offset(cx + x * unit, 4.7 * unit), paint);
    }
    // Chain hanging
    canvas.drawLine(Offset(cx, 5.5 * unit), Offset(cx, 7 * unit), paint);
    canvas.drawCircle(Offset(cx, 6 * unit), unit * 0.2, paint);
    canvas.drawCircle(Offset(cx, 6.5 * unit), unit * 0.2, paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 2 * unit), unit * 0.3, paint);
  }

  /// Card 80: Double penetration — two arrows converging, figure
  void _drawDoublePenetration(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, 3.55 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + unit, 7.5 * unit), paint);
    // Two converging arrows
    canvas.drawLine(Offset(cx - 3 * unit, 4 * unit), Offset(cx - 0.8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.8 * unit, 5 * unit), Offset(cx - 1.2 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.8 * unit, 5 * unit), Offset(cx - 0.5 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + 3 * unit, 4 * unit), Offset(cx + 0.8 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 5 * unit), Offset(cx + 1.2 * unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 5 * unit), Offset(cx + 0.5 * unit, 4.5 * unit), paint);
    _drawText(canvas, 'x2', Offset(cx, 2 * unit), unit * 0.5, fillPaint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 3 * unit), unit * 0.25, paint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.25, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 9: Cards 81-90 — Extreme / Niche
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 81: MFMF — four figures in square formation
  void _drawMfmf(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Four figures in 2x2 grid
    _drawHead(canvas, Offset(cx - 1.5 * unit, 3 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 3.45 * unit), Offset(cx - 1.5 * unit, 5 * unit), paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 3 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 3.45 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    _drawHead(canvas, Offset(cx - 1.5 * unit, 5.5 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.95 * unit), Offset(cx - 1.5 * unit, 7.5 * unit), paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 5.5 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 5.95 * unit), Offset(cx + 1.5 * unit, 7.5 * unit), paint);
    _drawText(canvas, 'M', Offset(cx - 1.5 * unit, 2 * unit), unit * 0.3, fillPaint);
    _drawText(canvas, 'F', Offset(cx + 1.5 * unit, 2 * unit), unit * 0.3, fillPaint);
    _drawText(canvas, 'M', Offset(cx - 1.5 * unit, 8 * unit), unit * 0.3, fillPaint);
    _drawText(canvas, 'F', Offset(cx + 1.5 * unit, 8 * unit), unit * 0.3, fillPaint);
    _drawSmallHeart(canvas, Offset(cx, 4.3 * unit), unit * 0.35, fillPaint);
  }

  /// Card 82: Pain play — figure with lightning bolts, smile
  void _drawPainPlay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx, 4.15 * unit), Offset(cx, 6.5 * unit), paint);
    // Happy face despite pain
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 3.7 * unit), width: 0.6 * unit, height: 0.4 * unit),
      0.2, 2.7, false, paint,
    );
    // Lightning bolts
    final bolt1 = Path();
    bolt1.moveTo(cx - 2.5 * unit, 2 * unit);
    bolt1.lineTo(cx - 2 * unit, 3.5 * unit);
    bolt1.lineTo(cx - 2.5 * unit, 3.5 * unit);
    bolt1.lineTo(cx - 2 * unit, 5 * unit);
    canvas.drawPath(bolt1, paint);
    final bolt2 = Path();
    bolt2.moveTo(cx + 2.5 * unit, 2 * unit);
    bolt2.lineTo(cx + 2 * unit, 3.5 * unit);
    bolt2.lineTo(cx + 2.5 * unit, 3.5 * unit);
    bolt2.lineTo(cx + 2 * unit, 5 * unit);
    canvas.drawPath(bolt2, paint);
    _drawText(canvas, '⚡', Offset(cx, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 83: Gay for pay — dollar sign, two male figures dancing
  void _drawGayForPay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx - 1.5 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 4.5 * unit), Offset(cx - 1.5 * unit, 7 * unit), paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 4.5 * unit), Offset(cx + 1.5 * unit, 7 * unit), paint);
    // Dollar sign
    _drawText(canvas, '\$', Offset(cx, 2.5 * unit), unit * 1, fillPaint);
    // Holding hands
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.5 * unit), Offset(cx + 1.5 * unit, 5.5 * unit), paint);
    _drawSmallHeart(canvas, Offset(cx, 3.5 * unit), unit * 0.3, fillPaint);
  }

  /// Card 84: Master/slave — figure on throne, chained figure
  void _drawMasterSlave(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Throne
    canvas.drawRect(Rect.fromLTWH(cx, 3 * unit, 3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx, 3 * unit), Offset(cx, 2 * unit), paint);
    canvas.drawLine(Offset(cx + 3 * unit, 3 * unit), Offset(cx + 3 * unit, 2 * unit), paint);
    _drawHead(canvas, Offset(cx + 1.5 * unit, 2.8 * unit), unit * 0.5, paint);
    // Crown
    canvas.drawLine(Offset(cx + unit, 2.3 * unit), Offset(cx + 1.2 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx + 1.2 * unit, 2 * unit), Offset(cx + 1.5 * unit, 2.2 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 2.2 * unit), Offset(cx + 1.8 * unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx + 1.8 * unit, 2 * unit), Offset(cx + 2 * unit, 2.3 * unit), paint);
    // Slave kneeling with chain
    _drawHead(canvas, Offset(cx - 2.5 * unit, 5 * unit), unit * 0.45, paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 5.45 * unit), Offset(cx - 2.5 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, 6.5 * unit), Offset(cx - 3 * unit, 7.5 * unit), paint);
    // Chain from throne to collar
    canvas.drawLine(Offset(cx, 4 * unit), Offset(cx - 2 * unit, 5 * unit), paint);
    canvas.drawCircle(Offset(cx - 1 * unit, 4.5 * unit), unit * 0.15, paint);
    canvas.drawCircle(Offset(cx - 1.5 * unit, 4.7 * unit), unit * 0.15, paint);
  }

  /// Card 85: Leather daddy — figure in leather cap, harness, mustache
  void _drawLeatherDaddy(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.7, paint);
    // Cap visor
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 2.9 * unit), width: 2 * unit, height: 0.6 * unit),
      3.14, 3.14, false, paint,
    );
    // Mustache
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 0.3 * unit, 3.8 * unit), width: 0.5 * unit, height: 0.3 * unit),
      0, 3.14, false, paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 0.3 * unit, 3.8 * unit), width: 0.5 * unit, height: 0.3 * unit),
      0, 3.14, false, paint,
    );
    canvas.drawLine(Offset(cx, 4.2 * unit), Offset(cx, 7 * unit), paint);
    // Harness X
    canvas.drawLine(Offset(cx - unit, 5 * unit), Offset(cx + unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 5 * unit), Offset(cx - unit, 6 * unit), paint);
    // Boots
    canvas.drawLine(Offset(cx, 7 * unit), Offset(cx - 0.8 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.8 * unit, 7.5 * unit), Offset(cx - 1.2 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx, 7 * unit), Offset(cx + 0.8 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.8 * unit, 7.5 * unit), Offset(cx + 1.2 * unit, 7.5 * unit), paint);
  }

  /// Card 86: DDLG — tall figure with small figure, pacifier, bow
  void _drawDdlg(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Daddy figure
    _drawHead(canvas, Offset(cx - 1.5 * unit, 2.5 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 3.1 * unit), Offset(cx - 1.5 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx - 2 * unit, 7.5 * unit), paint);
    canvas.drawLine(Offset(cx - 1.5 * unit, 6 * unit), Offset(cx - unit, 7.5 * unit), paint);
    // Little — smaller figure with bow
    _drawHead(canvas, Offset(cx + 1.5 * unit, 4 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 4.5 * unit), Offset(cx + 1.5 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6 * unit), Offset(cx + unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 6 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    // Bow on head
    canvas.drawLine(Offset(cx + 1.2 * unit, 3.5 * unit), Offset(cx + 1.5 * unit, 3.7 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, 3.7 * unit), Offset(cx + 1.8 * unit, 3.5 * unit), paint);
    // Teddy bear in hand
    canvas.drawCircle(Offset(cx + 2.5 * unit, 5 * unit), unit * 0.3, paint);
    canvas.drawCircle(Offset(cx + 2.5 * unit, 4.6 * unit), unit * 0.2, paint);
    _drawText(canvas, 'DD/lg', Offset(cx, 1.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 87: Pup play — figure with ears & tail, paw up
  void _drawPupPlay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.65, paint);
    // Puppy ears
    canvas.drawLine(Offset(cx - 0.5 * unit, 2.9 * unit), Offset(cx - unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 2 * unit), Offset(cx - 0.3 * unit, 2.9 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 2.9 * unit), Offset(cx + unit, 2 * unit), paint);
    canvas.drawLine(Offset(cx + unit, 2 * unit), Offset(cx + 0.3 * unit, 2.9 * unit), paint);
    // Body on all fours
    canvas.drawLine(Offset(cx, 4.15 * unit), Offset(cx, 5 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx - 2 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx - 2 * unit, 7 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 2 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 2 * unit, 5 * unit), Offset(cx + 2 * unit, 7 * unit), paint);
    // Tail wagging
    final tail = Path();
    tail.moveTo(cx + 2 * unit, 5 * unit);
    tail.quadraticBezierTo(cx + 3 * unit, 3.5 * unit, cx + 3.5 * unit, 4 * unit);
    canvas.drawPath(tail, paint);
    // Paw up
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx - 2.5 * unit, 4 * unit), paint);
    _drawText(canvas, 'woof!', Offset(cx, 1.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 88: Group sex — many figures in circle, party confetti
  void _drawGroupSex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Circle of heads
    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2 - 1.57;
      final x = cx + 2.5 * unit * cos(angle);
      final y = cy + 2.5 * unit * sin(angle);
      _drawHead(canvas, Offset(x, y), unit * 0.35, paint);
    }
    // Confetti
    _drawSparkle(canvas, Offset(cx, cy), unit * 0.4, paint);
    _drawSparkle(canvas, Offset(cx - 3 * unit, 2 * unit), unit * 0.25, paint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 2 * unit), unit * 0.25, paint);
    _drawText(canvas, 'PARTY', Offset(cx, 1.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 89: Sadomasochism — yin-yang style: whip and heart intertwined
  void _drawSadomasochism(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Main circle
    canvas.drawCircle(Offset(cx, cy), unit * 2.5, paint);
    // Dividing S-curve
    final sCurve = Path();
    sCurve.moveTo(cx, cy - 2.5 * unit);
    sCurve.quadraticBezierTo(cx + 2 * unit, cy - unit, cx, cy);
    sCurve.quadraticBezierTo(cx - 2 * unit, cy + unit, cx, cy + 2.5 * unit);
    canvas.drawPath(sCurve, paint);
    // Heart in one half
    _drawSmallHeart(canvas, Offset(cx - unit, cy - 0.5 * unit), unit * 0.5, fillPaint);
    // Whip in other half
    canvas.drawLine(Offset(cx + 0.5 * unit, cy + 0.5 * unit), Offset(cx + 1.5 * unit, cy - 0.5 * unit), paint);
    canvas.drawLine(Offset(cx + 1.5 * unit, cy - 0.5 * unit), Offset(cx + 2 * unit, cy + 0.5 * unit), paint);
    _drawText(canvas, 'S&M', Offset(cx, 1 * unit), unit * 0.5, fillPaint);
  }

  /// Card 90: Butt plug + gag combo — plug shape + gag ball, chain
  void _drawButtPlugGag(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Plug on left
    final plug = Path();
    plug.moveTo(cx - 2.5 * unit, 3 * unit);
    plug.quadraticBezierTo(cx - 1 * unit, 4.5 * unit, cx - 2 * unit, 6 * unit);
    plug.quadraticBezierTo(cx - 3 * unit, 4.5 * unit, cx - 2.5 * unit, 3 * unit);
    canvas.drawPath(plug, paint);
    canvas.drawLine(Offset(cx - 3.2 * unit, 6 * unit), Offset(cx - 1.3 * unit, 6 * unit), paint);
    // Gag on right
    canvas.drawCircle(Offset(cx + 2.5 * unit, 4 * unit), unit * 0.5, fillPaint);
    canvas.drawLine(Offset(cx + 2 * unit, 4 * unit), Offset(cx + unit, 4 * unit), paint);
    canvas.drawLine(Offset(cx + 3 * unit, 4 * unit), Offset(cx + 4 * unit, 4 * unit), paint);
    // Chain connecting
    final chain = Path();
    chain.moveTo(cx - 2.5 * unit, 6 * unit);
    chain.quadraticBezierTo(cx, 7.5 * unit, cx + 2.5 * unit, 4.5 * unit);
    canvas.drawPath(chain, paint);
    _drawText(canvas, '+', Offset(cx, 4 * unit), unit * 0.8, fillPaint);
    _drawSparkle(canvas, Offset(cx - 2.5 * unit, 2 * unit), unit * 0.3, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH 10: Cards 91-100 — Extreme
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card 91: Gorean — kneeling figure, pedestal, "GOR" text
  void _drawGorean(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Pedestal / column
    canvas.drawRect(Rect.fromLTWH(cx + unit, 2 * unit, 2 * unit, 6 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 2 * unit), Offset(cx + 3.5 * unit, 2 * unit), paint);
    // Kneeling figure chained to column
    _drawHead(canvas, Offset(cx - 2 * unit, 4.5 * unit), unit * 0.5, paint);
    canvas.drawLine(Offset(cx - 2 * unit, 5 * unit), Offset(cx - 2 * unit, 6.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2 * unit, 6.5 * unit), Offset(cx - 2.5 * unit, 7.5 * unit), paint);
    // Chain to column
    canvas.drawLine(Offset(cx - 1.5 * unit, 5.3 * unit), Offset(cx + unit, 4 * unit), paint);
    canvas.drawCircle(Offset(cx - 0.5 * unit, 4.8 * unit), unit * 0.12, paint);
    canvas.drawCircle(Offset(cx + 0.3 * unit, 4.4 * unit), unit * 0.12, paint);
    _drawText(canvas, 'GOR', Offset(cx + 2 * unit, 4.5 * unit), unit * 0.5, fillPaint);
  }

  /// Card 92: Electrosex — figure with lightning, wand device
  void _drawElectrosex(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 3.6 * unit), Offset(cx, 6 * unit), paint);
    // Wand device
    canvas.drawLine(Offset(cx + 2 * unit, 4 * unit), Offset(cx + 3.5 * unit, 3 * unit), paint);
    canvas.drawCircle(Offset(cx + 3.7 * unit, 2.8 * unit), unit * 0.3, paint);
    // Lightning from wand
    final bolt = Path();
    bolt.moveTo(cx + unit, 4 * unit);
    bolt.lineTo(cx + 0.5 * unit, 5 * unit);
    bolt.lineTo(cx + unit, 5 * unit);
    bolt.lineTo(cx + 0.5 * unit, 6 * unit);
    canvas.drawPath(bolt, paint);
    // ZAP effects
    _drawSparkle(canvas, Offset(cx - 2 * unit, 3 * unit), unit * 0.35, paint);
    _drawSparkle(canvas, Offset(cx + unit, 2 * unit), unit * 0.3, paint);
    _drawText(canvas, 'ZAP!', Offset(cx, 1.5 * unit), unit * 0.5, fillPaint);
  }

  /// Card 93: Many men one F — circle of M around F
  void _drawManyMenOneF(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Center F
    _drawHead(canvas, Offset(cx, cy), unit * 0.5, paint);
    _drawText(canvas, 'F', Offset(cx, cy + 1.2 * unit), unit * 0.35, fillPaint);
    // Circle of M
    const count = 5;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2 - 1.57;
      final x = cx + 3 * unit * cos(angle);
      final y = cy + 3 * unit * sin(angle);
      _drawHead(canvas, Offset(x, y), unit * 0.35, paint);
    }
    _drawText(canvas, 'M', Offset(cx + 3 * unit, cy - 2.5 * unit), unit * 0.3, fillPaint);
    // Arrows pointing inward
    canvas.drawLine(Offset(cx + 2.5 * unit, cy - 2 * unit), Offset(cx + 0.8 * unit, cy - 0.5 * unit), paint);
    canvas.drawLine(Offset(cx - 2.5 * unit, cy - 2 * unit), Offset(cx - 0.8 * unit, cy - 0.5 * unit), paint);
  }

  /// Card 94: Gang bang — many figures surrounding one, exclamation marks
  void _drawGangBang(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Center figure
    _drawHead(canvas, Offset(cx, cy), unit * 0.55, paint);
    canvas.drawLine(Offset(cx, cy + 0.55 * unit), Offset(cx, cy + 2 * unit), paint);
    // Surrounding figures
    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2 - 1.57;
      final x = cx + 3 * unit * cos(angle);
      final y = cy + 3 * unit * sin(angle);
      _drawHead(canvas, Offset(x, y), unit * 0.3, paint);
      canvas.drawLine(Offset(x, y + 0.3 * unit), Offset(x, y + unit), paint);
    }
    _drawText(canvas, '!!!', Offset(cx, 1.5 * unit), unit * 0.6, fillPaint);
  }

  /// Card 95: CBT — abstract: target on figure, warning sign
  void _drawCbt(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3 * unit), unit * 0.6, paint);
    canvas.drawLine(Offset(cx, 3.6 * unit), Offset(cx, 6 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx - unit, 8 * unit), paint);
    canvas.drawLine(Offset(cx, 6 * unit), Offset(cx + unit, 8 * unit), paint);
    // Warning triangle
    final warning = Path();
    warning.moveTo(cx + 3 * unit, 2 * unit);
    warning.lineTo(cx + 1.5 * unit, 5 * unit);
    warning.lineTo(cx + 4.5 * unit, 5 * unit);
    warning.close();
    canvas.drawPath(warning, paint);
    _drawText(canvas, '!', Offset(cx + 3 * unit, 4 * unit), unit * 0.6, fillPaint);
    // Ouch stars
    _drawSparkle(canvas, Offset(cx - 2 * unit, 5 * unit), unit * 0.3, paint);
    _drawText(canvas, 'CBT', Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.45, fillPaint);
  }

  /// Card 96: Enema play — syringe shape, figure, water droplets
  void _drawEnemaPlay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Syringe / bulb shape
    canvas.drawCircle(Offset(cx, 4 * unit), unit * 1, paint);
    canvas.drawLine(Offset(cx + unit, 4 * unit), Offset(cx + 3 * unit, 4 * unit), paint);
    // Nozzle
    canvas.drawLine(Offset(cx + 3 * unit, 3.7 * unit), Offset(cx + 3 * unit, 4.3 * unit), paint);
    canvas.drawLine(Offset(cx + 3 * unit, 4 * unit), Offset(cx + 3.5 * unit, 4 * unit), paint);
    // Water drops
    canvas.drawCircle(Offset(cx - 0.5 * unit, 6 * unit), unit * 0.15, fillPaint);
    canvas.drawCircle(Offset(cx + 0.5 * unit, 6.5 * unit), unit * 0.12, fillPaint);
    canvas.drawCircle(Offset(cx, 7 * unit), unit * 0.1, fillPaint);
    // Figure reacting
    _drawHead(canvas, Offset(cx - 3 * unit, 3 * unit), unit * 0.45, paint);
    canvas.drawCircle(Offset(cx - 3.15 * unit, 2.9 * unit), unit * 0.08, fillPaint);
    canvas.drawCircle(Offset(cx - 2.85 * unit, 2.9 * unit), unit * 0.08, fillPaint);
    _drawText(canvas, '💧', Offset(cx, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 97: Fisting — giant fist, figure, mind blown stars
  void _drawFisting(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Big fist
    canvas.drawCircle(Offset(cx, 5 * unit), unit * 1.5, paint);
    // Fingers curled on top
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 0.5 * unit, 3.8 * unit), width: unit, height: 0.6 * unit),
      3.14, 3.14, false, paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 0.5 * unit, 3.8 * unit), width: unit, height: 0.6 * unit),
      3.14, 3.14, false, paint,
    );
    // Thumb
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 1.5 * unit, 4.5 * unit), width: 0.8 * unit, height: unit),
      -1.57, 3.14, false, paint,
    );
    // Mind blown
    _drawSparkle(canvas, Offset(cx - 2.5 * unit, 2.5 * unit), unit * 0.4, paint);
    _drawSparkle(canvas, Offset(cx + 2.5 * unit, 2.5 * unit), unit * 0.4, paint);
    _drawText(canvas, 'OMG', Offset(cx, 2 * unit), unit * 0.5, fillPaint);
  }

  /// Card 98: Anal fisting — fist shape + peach, warning
  void _drawAnalFisting(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    // Fist smaller
    canvas.drawCircle(Offset(cx - 1.5 * unit, 5 * unit), unit, paint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 1.5 * unit, 4.2 * unit), width: 1.2 * unit, height: 0.5 * unit),
      3.14, 3.14, false, paint,
    );
    // Arrow pointing right
    canvas.drawLine(Offset(cx - 0.5 * unit, 5 * unit), Offset(cx + 0.5 * unit, 5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 5 * unit), Offset(cx + 0.2 * unit, 4.7 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 5 * unit), Offset(cx + 0.2 * unit, 5.3 * unit), paint);
    // Peach
    final peach = Path();
    peach.moveTo(cx + 2 * unit, 4 * unit);
    peach.quadraticBezierTo(cx + 3.5 * unit, 4.5 * unit, cx + 3 * unit, 6 * unit);
    peach.quadraticBezierTo(cx + 2 * unit, 6.5 * unit, cx + unit, 6 * unit);
    peach.quadraticBezierTo(cx + 0.5 * unit, 4.5 * unit, cx + 2 * unit, 4 * unit);
    canvas.drawPath(peach, paint);
    // Warning
    _drawText(canvas, '⚠️', Offset(cx, 2.5 * unit), unit * 0.6, fillPaint);
    _drawSparkle(canvas, Offset(cx + 3 * unit, 3 * unit), unit * 0.3, paint);
  }

  /// Card 99: Breath play — figure with hand on throat, dizzy stars
  void _drawBreathPlay(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.7, paint);
    canvas.drawLine(Offset(cx, 4.2 * unit), Offset(cx, 7 * unit), paint);
    // Hand on throat
    canvas.drawLine(Offset(cx + 2 * unit, 3 * unit), Offset(cx + 0.5 * unit, 4.2 * unit), paint);
    canvas.drawLine(Offset(cx + 0.5 * unit, 4.2 * unit), Offset(cx - 0.5 * unit, 4.2 * unit), paint);
    canvas.drawLine(Offset(cx - 0.5 * unit, 4.2 * unit), Offset(cx + 0.2 * unit, 4.5 * unit), paint);
    // Dizzy stars
    _drawSparkle(canvas, Offset(cx - 1.5 * unit, 2.5 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx + 1.5 * unit, 2.5 * unit), unit * 0.3, paint);
    _drawSparkle(canvas, Offset(cx, 2 * unit), unit * 0.25, paint);
    // X eyes
    canvas.drawLine(Offset(cx - 0.4 * unit, 3.2 * unit), Offset(cx - 0.2 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.2 * unit, 3.2 * unit), Offset(cx - 0.4 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.2 * unit, 3.2 * unit), Offset(cx + 0.4 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.4 * unit, 3.2 * unit), Offset(cx + 0.2 * unit, 3.5 * unit), paint);
    _drawText(canvas, '⚠️', Offset(cx, 1 * unit), unit * 0.5, fillPaint);
  }

  /// Card 100: Auto-asphyxiation — figure alone, belt, warning signs
  void _drawAutoAsphyx(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    _drawHead(canvas, Offset(cx, 3.5 * unit), unit * 0.65, paint);
    canvas.drawLine(Offset(cx, 4.15 * unit), Offset(cx, 7 * unit), paint);
    // Belt around neck
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 4.3 * unit), width: 2 * unit, height: 0.6 * unit),
      0, 3.14, false, paint,
    );
    canvas.drawLine(Offset(cx + unit, 4.3 * unit), Offset(cx + 1.5 * unit, 5 * unit), paint);
    // Own hands
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx - unit, 4.5 * unit), paint);
    canvas.drawLine(Offset(cx - unit, 4.5 * unit), Offset(cx - 0.5 * unit, 4.3 * unit), paint);
    canvas.drawLine(Offset(cx, 5 * unit), Offset(cx + 0.5 * unit, 4.3 * unit), paint);
    // Warning triangles
    final warn1 = Path();
    warn1.moveTo(cx - 3 * unit, 2 * unit);
    warn1.lineTo(cx - 3.8 * unit, 3.5 * unit);
    warn1.lineTo(cx - 2.2 * unit, 3.5 * unit);
    warn1.close();
    canvas.drawPath(warn1, paint);
    _drawText(canvas, '!', Offset(cx - 3 * unit, 3 * unit), unit * 0.4, fillPaint);
    final warn2 = Path();
    warn2.moveTo(cx + 3 * unit, 2 * unit);
    warn2.lineTo(cx + 2.2 * unit, 3.5 * unit);
    warn2.lineTo(cx + 3.8 * unit, 3.5 * unit);
    warn2.close();
    canvas.drawPath(warn2, paint);
    _drawText(canvas, '!', Offset(cx + 3 * unit, 3 * unit), unit * 0.4, fillPaint);
    // X eyes for danger
    canvas.drawLine(Offset(cx - 0.3 * unit, 3.2 * unit), Offset(cx - 0.1 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx - 0.1 * unit, 3.2 * unit), Offset(cx - 0.3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.1 * unit, 3.2 * unit), Offset(cx + 0.3 * unit, 3.5 * unit), paint);
    canvas.drawLine(Offset(cx + 0.3 * unit, 3.2 * unit), Offset(cx + 0.1 * unit, 3.5 * unit), paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLACEHOLDER for batches not yet drawn
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawPlaceholder(Canvas canvas, Size size, Paint paint, Paint fillPaint, double unit) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Simple flame as placeholder
    final flamePath = Path();
    flamePath.moveTo(cx, 8 * unit);
    flamePath.quadraticBezierTo(cx - 2.5 * unit, 5 * unit, cx - unit, 3 * unit);
    flamePath.quadraticBezierTo(cx - 0.5 * unit, 4 * unit, cx, 2 * unit);
    flamePath.quadraticBezierTo(cx + 0.5 * unit, 4 * unit, cx + unit, 3 * unit);
    flamePath.quadraticBezierTo(cx + 2.5 * unit, 5 * unit, cx, 8 * unit);
    canvas.drawPath(flamePath, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawHead(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }

  void _drawSmallHeart(Canvas canvas, Offset center, double s, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.3);
    path.cubicTo(center.dx - s, center.dy - s * 0.5, center.dx - s * 0.5, center.dy - s, center.dx, center.dy - s * 0.3);
    path.cubicTo(center.dx + s * 0.5, center.dy - s, center.dx + s, center.dy - s * 0.5, center.dx, center.dy + s * 0.3);
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double s, Paint paint) {
    canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx + s, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy + s), paint);
    canvas.drawLine(Offset(center.dx - s * 0.7, center.dy - s * 0.7), Offset(center.dx + s * 0.7, center.dy + s * 0.7), paint);
    canvas.drawLine(Offset(center.dx + s * 0.7, center.dy - s * 0.7), Offset(center.dx - s * 0.7, center.dy + s * 0.7), paint);
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize, Paint paint) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: paint.color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) {
    return oldDelegate.illustration != illustration || oldDelegate.color != color;
  }
}
