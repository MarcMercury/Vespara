import 'package:flutter/material.dart';

/// Vespara Custom Icons System
/// 
/// A curated collection of alluring, mysterious, and unique icons
/// designed to replace generic Material icons throughout the app.
/// 
/// Usage:
/// ```dart
/// Icon(VesparaIcons.close) // Instead of Icons.close
/// VesparaIcons.iconFor(context, 'close') // Dynamic lookup
/// ```
class VesparaIcons {
  VesparaIcons._();

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION & ACTIONS - Replacing basic arrows and actions
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Close/Dismiss - Use elegant × instead of basic close
  static const IconData close = Icons.close_rounded;
  
  /// Back - Sleek arrow
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  
  /// Forward - Navigation indicator  
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  
  /// Navigate/Expand - Chevron right with flair
  static const IconData navigate = Icons.keyboard_arrow_right_rounded;
  
  /// Add/Create - Plus with elegance
  static const IconData add = Icons.add_rounded;
  
  /// More options - Vertical dots
  static const IconData more = Icons.more_vert_rounded;
  
  /// Edit - Feather pen aesthetic
  static const IconData edit = Icons.edit_rounded;
  
  /// Share - Cosmic send
  static const IconData share = Icons.ios_share_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY & MATCHING - Core dating functionality
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Like/Heart - Filled passionate heart
  static const IconData like = Icons.favorite_rounded;
  
  /// Like outline - For toggleable states
  static const IconData likeOutline = Icons.favorite_border_rounded;
  
  /// Super Like - Star with sparkle
  static const IconData superLike = Icons.auto_awesome_rounded;
  
  /// Skip/Pass - Elegant dismiss
  static const IconData skip = Icons.close_rounded;
  
  /// Match - Two hearts connected
  static const IconData match = Icons.favorite_rounded;
  
  /// Explore/Discover - Compass aesthetic
  static const IconData discover = Icons.explore_rounded;
  
  /// Search - Magnifying with mystery
  static const IconData search = Icons.search_rounded;
  
  /// Filter/Tune - Sliders
  static const IconData filter = Icons.tune_rounded;
  
  /// Location - Pin with flair
  static const IconData location = Icons.place_rounded;
  
  /// Verified - Trust badge
  static const IconData verified = Icons.verified_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE & IDENTITY - User-centric icons
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Person/User - Silhouette
  static const IconData person = Icons.person_rounded;
  
  /// Person outline
  static const IconData personOutline = Icons.person_outline_rounded;
  
  /// Mirror/Profile - Self-reflection
  static const IconData mirror = Icons.face_retouching_natural;
  
  /// Settings - Cog with style
  static const IconData settings = Icons.settings_rounded;
  
  /// Camera - Photo capture
  static const IconData camera = Icons.camera_alt_rounded;
  
  /// Photo gallery
  static const IconData gallery = Icons.photo_library_rounded;
  
  /// QR Code - Connection
  static const IconData qrCode = Icons.qr_code_scanner_rounded;
  
  /// Age/Birthday
  static const IconData birthday = Icons.cake_rounded;
  
  /// Gender/Identity
  static const IconData identity = Icons.face_rounded;
  
  /// Pronouns
  static const IconData pronouns = Icons.person_pin_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNICATION - Wire/Chat
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Chat/Message - Bubble with personality
  static const IconData chat = Icons.chat_bubble_rounded;
  
  /// Chat outline
  static const IconData chatOutline = Icons.chat_bubble_outline_rounded;
  
  /// Send - Paper plane soaring
  static const IconData send = Icons.send_rounded;
  
  /// Voice message - Microphone
  static const IconData voice = Icons.mic_rounded;
  
  /// Video call - Camera
  static const IconData videoCall = Icons.videocam_rounded;
  
  /// Phone call
  static const IconData call = Icons.call_rounded;
  
  /// Attachment
  static const IconData attach = Icons.attach_file_rounded;
  
  /// Emoji picker
  static const IconData emoji = Icons.emoji_emotions_rounded;
  
  /// GIF
  static const IconData gif = Icons.gif_box_rounded;
  
  /// Read receipt - Double check
  static const IconData readReceipt = Icons.done_all_rounded;
  
  /// Sent receipt - Single check
  static const IconData sentReceipt = Icons.done_rounded;
  
  /// Reply
  static const IconData reply = Icons.reply_rounded;
  
  /// Forward message
  static const IconData forwardMsg = Icons.forward_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPS & SOCIAL - Wire Groups, Events
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Group - Multiple people
  static const IconData group = Icons.group_rounded;
  
  /// Add member
  static const IconData addMember = Icons.person_add_rounded;
  
  /// Leave group
  static const IconData leave = Icons.exit_to_app_rounded;
  
  /// Archive
  static const IconData archive = Icons.archive_rounded;
  
  /// Pin
  static const IconData pin = Icons.push_pin_rounded;
  
  /// Mute
  static const IconData mute = Icons.notifications_off_rounded;
  
  /// Unmute
  static const IconData unmute = Icons.notifications_rounded;
  
  /// Block
  static const IconData block = Icons.block_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENTS & PLANNING - Calendar, dates
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Calendar
  static const IconData calendar = Icons.calendar_month_rounded;
  
  /// Calendar today
  static const IconData calendarToday = Icons.calendar_today_rounded;
  
  /// Event
  static const IconData event = Icons.event_rounded;
  
  /// Party/Celebration
  static const IconData celebrate = Icons.celebration_rounded;
  
  /// Time/Schedule
  static const IconData time = Icons.access_time_rounded;
  
  /// Timer
  static const IconData timer = Icons.timer_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // GAMES & LUDUS - Playful icons
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Games - Casino/Dice
  static const IconData games = Icons.casino_rounded;
  
  /// Play
  static const IconData play = Icons.play_arrow_rounded;
  
  /// Pause
  static const IconData pause = Icons.pause_rounded;
  
  /// Stop
  static const IconData stop = Icons.stop_rounded;
  
  /// Refresh/Restart
  static const IconData restart = Icons.refresh_rounded;
  
  /// Trophy
  static const IconData trophy = Icons.emoji_events_rounded;
  
  /// Achievement/Star
  static const IconData achievement = Icons.star_rounded;
  
  /// Star outline
  static const IconData starOutline = Icons.star_border_rounded;
  
  /// Fire/Hot - For intensity
  static const IconData fire = Icons.local_fire_department_rounded;
  
  /// Dice - Random
  static const IconData random = Icons.casino_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // AI & INTELLIGENCE - Magic features
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// AI Magic - Auto awesome
  static const IconData ai = Icons.auto_awesome_rounded;
  
  /// Suggestion/Lightbulb
  static const IconData suggestion = Icons.lightbulb_rounded;
  
  /// Suggestion outline
  static const IconData suggestionOutline = Icons.lightbulb_outline_rounded;
  
  /// Psychology/Insight
  static const IconData insight = Icons.psychology_rounded;
  
  /// Trending
  static const IconData trending = Icons.trending_up_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS & FEEDBACK - Confirmation, errors
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Check/Confirm - Circle with checkmark
  static const IconData confirm = Icons.check_circle_rounded;
  
  /// Check outline
  static const IconData confirmOutline = Icons.check_circle_outline_rounded;
  
  /// Simple check
  static const IconData check = Icons.check_rounded;
  
  /// Error - Outlined
  static const IconData error = Icons.error_outline_rounded;
  
  /// Warning
  static const IconData warning = Icons.warning_amber_rounded;
  
  /// Info
  static const IconData info = Icons.info_outline_rounded;
  
  /// Help
  static const IconData help = Icons.help_outline_rounded;
  
  /// Lock
  static const IconData lock = Icons.lock_rounded;
  
  /// Lock outline
  static const IconData lockOutline = Icons.lock_outline_rounded;
  
  /// Unlock
  static const IconData unlock = Icons.lock_open_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHREDDER & CLEANUP - Disposal
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Shredder - Clean sweep
  static const IconData shredder = Icons.delete_sweep_rounded;
  
  /// Delete - Trash
  static const IconData delete = Icons.delete_rounded;
  
  /// Delete outline
  static const IconData deleteOutline = Icons.delete_outline_rounded;
  
  /// Delete forever
  static const IconData deleteForever = Icons.delete_forever_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEST & HOME - Match management
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Nest/Favorites - Bird nest aesthetic
  static const IconData nest = Icons.favorite_rounded;
  
  /// Home
  static const IconData home = Icons.home_rounded;
  
  /// Copy
  static const IconData copy = Icons.content_copy_rounded;
  
  /// Link
  static const IconData link = Icons.link_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL EFFECTS - Premium features
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Premium/Star
  static const IconData premium = Icons.star_rounded;
  
  /// Boost/Lightning
  static const IconData boost = Icons.bolt_rounded;
  
  /// Visibility
  static const IconData visibility = Icons.visibility_rounded;
  
  /// Visibility off
  static const IconData visibilityOff = Icons.visibility_off_rounded;
  
  /// Refresh
  static const IconData refresh = Icons.refresh_rounded;
  
  /// Download
  static const IconData download = Icons.download_rounded;
  
  /// Upload
  static const IconData upload = Icons.upload_rounded;
  
  /// Logout
  static const IconData logout = Icons.logout_rounded;
  
  /// Users/People
  static const IconData users = Icons.people_rounded;
  
  /// WiFi/Connection
  static const IconData wifi = Icons.wifi_rounded;
  
  /// Alert/Warning
  static const IconData alert = Icons.warning_amber_rounded;
  
  /// Menu/Drag handle
  static const IconData menu = Icons.drag_handle_rounded;
  
  /// Star
  static const IconData star = Icons.star_rounded;
  
  /// Shield/Protection
  static const IconData shield = Icons.shield_rounded;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHOD - Dynamic icon lookup
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get icon by semantic name
  static IconData? byName(String name) {
    return _iconMap[name.toLowerCase()];
  }
  
  static const Map<String, IconData> _iconMap = {
    'close': close,
    'back': back,
    'forward': forward,
    'navigate': navigate,
    'add': add,
    'more': more,
    'edit': edit,
    'share': share,
    'like': like,
    'like_outline': likeOutline,
    'super_like': superLike,
    'skip': skip,
    'match': match,
    'discover': discover,
    'search': search,
    'filter': filter,
    'location': location,
    'verified': verified,
    'person': person,
    'person_outline': personOutline,
    'mirror': mirror,
    'settings': settings,
    'camera': camera,
    'gallery': gallery,
    'qr_code': qrCode,
    'birthday': birthday,
    'identity': identity,
    'pronouns': pronouns,
    'chat': chat,
    'chat_outline': chatOutline,
    'send': send,
    'voice': voice,
    'video_call': videoCall,
    'call': call,
    'attach': attach,
    'emoji': emoji,
    'gif': gif,
    'read_receipt': readReceipt,
    'sent_receipt': sentReceipt,
    'reply': reply,
    'forward_msg': forwardMsg,
    'group': group,
    'add_member': addMember,
    'leave': leave,
    'archive': archive,
    'pin': pin,
    'mute': mute,
    'unmute': unmute,
    'block': block,
    'calendar': calendar,
    'calendar_today': calendarToday,
    'event': event,
    'celebrate': celebrate,
    'time': time,
    'timer': timer,
    'games': games,
    'play': play,
    'pause': pause,
    'stop': stop,
    'restart': restart,
    'trophy': trophy,
    'achievement': achievement,
    'star_outline': starOutline,
    'fire': fire,
    'random': random,
    'ai': ai,
    'suggestion': suggestion,
    'suggestion_outline': suggestionOutline,
    'insight': insight,
    'trending': trending,
    'confirm': confirm,
    'confirm_outline': confirmOutline,
    'check': check,
    'error': error,
    'warning': warning,
    'info': info,
    'help': help,
    'lock': lock,
    'lock_outline': lockOutline,
    'unlock': unlock,
    'shredder': shredder,
    'delete': delete,
    'delete_outline': deleteOutline,
    'delete_forever': deleteForever,
    'nest': nest,
    'home': home,
    'copy': copy,
    'link': link,
    'premium': premium,
    'boost': boost,
    'visibility': visibility,
    'visibility_off': visibilityOff,
    'refresh': refresh,
    'download': download,
    'upload': upload,
    'logout': logout,
  };
}

/// Vespara Emoji System
/// 
/// A curated collection of alluring, sultry, and mysterious emojis
/// designed to replace generic emojis throughout the app.
/// 
/// Aesthetic: More sensual, mysterious, and on-brand for a dating app
class VesparaEmoji {
  VesparaEmoji._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE EMOTION REPLACEMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sparkle/Magic - More mysterious than ✨
  static const String sparkle = '✧';
  static const String sparkles = '・。.・゜✭・.・✫・゜・。.';
  static const String magic = '🔮';
  static const String stars = '🌟';
  
  /// Happy/Pleased - More alluring than 😊
  static const String pleased = '😏';
  static const String flirty = '🫦';
  static const String content = '😌';
  static const String playful = '😘';
  
  /// Celebration - More sophisticated than 🎉
  static const String cheers = '🥂';
  static const String champagne = '🍾';
  static const String confetti = '🎊';
  
  /// Approval - More intimate than 👍
  static const String approve = '🤭';
  static const String kiss = '💋';
  static const String heart = '🖤';
  
  /// Sad/Decline - More dramatic than 😢
  static const String wilted = '🥀';
  static const String broken = '💔';
  static const String melting = '🫠';
  
  /// Love/Romance - More passionate than 💕
  static const String heartbeat = '🫀';
  static const String cupid = '💘';
  static const String burning = '❤️‍🔥';
  static const String purple = '💜';
  static const String desire = '🖤';
  
  /// Fire/Hot - Keep but enhance
  static const String fire = '🔥';
  static const String hotFace = '🥵';
  static const String spicy = '🌶️';

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAT/INTENSITY LEVELS - Dating app context
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// PG - Flirty
  static const String heatPG = '🌸';
  
  /// PG-13 - Suggestive  
  static const String heatPG13 = '🔥';
  
  /// R - Explicit
  static const String heatR = '🌶️';
  
  /// X - Very explicit
  static const String heatX = '💋';
  
  /// XXX - Maximum
  static const String heatXXX = '🫦';

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS INDICATORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Active/Online
  static const String online = '💫';
  
  /// Away
  static const String away = '🌙';
  
  /// Busy
  static const String busy = '🔴';
  
  /// New/Fresh
  static const String newBadge = '✧';

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME EMOJIS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Trophy/Win
  static const String trophy = '🏆';
  static const String gold = '🥇';
  static const String silver = '🥈';
  static const String bronze = '🥉';
  
  /// Game elements
  static const String dice = '🎲';
  static const String cards = '🃏';
  static const String mask = '🎭';
  static const String crystal = '🔮';
  
  /// Share or Dare specific
  static const String shareOrDare = '🎭';
  static const String dare = '🔥';
  static const String truth = '🔮';

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME & AVAILABILITY
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Morning
  static const String morning = '🌅';
  
  /// Afternoon  
  static const String afternoon = '☀️';
  
  /// Evening
  static const String evening = '🌆';
  
  /// Night
  static const String night = '🌙';
  
  /// Late night
  static const String lateNight = '🌃';
  
  /// Spontaneous
  static const String spontaneous = '⚡';

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE TYPES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String coffee = '☕';
  static const String drinks = '🍷';
  static const String dinner = '🍽️';
  static const String adventure = '🎢';
  static const String art = '🎨';
  static const String outdoors = '🌲';
  static const String nightlife = '🌃';

  // ═══════════════════════════════════════════════════════════════════════════
  // RSVP & EVENTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Going - More elegant than 👍
  static const String going = '🙌';
  
  /// Maybe
  static const String maybe = '🤔';
  
  /// Can't make it - More graceful than 😢
  static const String cantMakeIt = '🥀';
  
  /// Invite
  static const String invite = '💌';

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE & GREETINGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Wave - Keep as is, it's good
  static const String wave = '👋';
  
  /// Hey there
  static const String hey = '✨';
  
  /// Intrigued
  static const String intrigued = '🤭';
}

/// Extension for easy emoji replacement
extension EmojiReplacer on String {
  /// Replace basic emojis with Vespara alternatives
  String get vesparaStyle {
    return replaceAll('👍', VesparaEmoji.approve)
        .replaceAll('😊', VesparaEmoji.pleased)
        .replaceAll('😢', VesparaEmoji.wilted)
        .replaceAll('💕', VesparaEmoji.purple)
        .replaceAll('🎉', VesparaEmoji.cheers);
  }
}
