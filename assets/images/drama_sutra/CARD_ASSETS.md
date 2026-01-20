# 🎭 Drama Sutra Card Assets

Upload position card images to this folder for the Drama Sutra game.

---

## 📁 File Naming Convention

Use the position ID as the filename:

| Position ID | Position Name | Filename |
|-------------|---------------|----------|
| `p1` | The Spoons | `p1_spoons.png` |
| `p2` | The Lotus | `p2_lotus.png` |
| `p3` | The Lazy Dog | `p3_lazy_dog.png` |
| `p4` | The Cowgirl | `p4_cowgirl.png` |
| `p5` | The Reverse Cowgirl | `p5_reverse_cowgirl.png` |
| `p6` | The Throne | `p6_throne.png` |
| `p7` | The Standing Ovation | `p7_standing_ovation.png` |
| `p8` | The Wheelbarrow | `p8_wheelbarrow.png` |
| `p9` | The Pretzel | `p9_pretzel.png` |
| `p10` | The Spider | `p10_spider.png` |
| `p11` | The Splitting Bamboo | `p11_splitting_bamboo.png` |
| `p12` | The Suspended Congress | `p12_suspended_congress.png` |
| `p13` | The Glowing Firefly | `p13_glowing_firefly.png` |
| `p14` | The Propeller | `p14_propeller.png` |
| `p15` | The Acrobat | `p15_acrobat.png` |

---

## 🎨 Image Specifications

### Dimensions
- **Recommended:** 400 x 600 px (2:3 portrait ratio)
- **Minimum:** 300 x 450 px
- **Maximum:** 800 x 1200 px (for retina displays)

### Format
- **Preferred:** PNG with transparency
- **Alternative:** WEBP, JPG

### Style Guidelines
- **Aesthetic:** Artistic silhouettes or tasteful illustrations (no explicit imagery)
- **Background:** Transparent or dark gradient (#1A0A1F to #2D1B35)
- **Color Accents:** Gold (#FFD700), Crimson (#DC143C)
- **Style Reference:** Think Kama Sutra art meets theater/cinema aesthetic

### Examples of Acceptable Styles
1. ✅ Elegant silhouette outlines (like dance pose illustrations)
2. ✅ Abstract geometric representations
3. ✅ Vintage Kama Sutra-inspired line art
4. ✅ Minimalist iconic symbols
5. ❌ Explicit/pornographic imagery
6. ❌ Photographic content

---

## 📐 Difficulty Indicators (Built into Card UI)

The app will overlay difficulty stars automatically:
- ★☆☆☆☆ = Easy (Green)
- ★★★☆☆ = Medium (Orange)  
- ★★★★★ = Hard (Red)

---

## 🏷️ Intensity Categories

Images should visually reflect the intensity:
- **💕 Romantic** - Soft, flowing, connected poses
- **🤸 Acrobatic** - Dynamic, athletic, complex poses
- **🌙 Intimate** - Close, intertwined, sensual poses

---

## ⚡ After Uploading

1. Add images to this folder
2. Update `pubspec.yaml` to include the assets:
   ```yaml
   flutter:
     assets:
       - assets/images/drama_sutra/
   ```
3. Update the position data in `drama_sutra_provider.dart`:
   ```dart
   DramaPosition(
     id: 'p1',
     name: 'The Spoons',
     description: 'Partners lie on their sides, curved like nested spoons.',
     imageUrl: 'assets/images/drama_sutra/p1_spoons.png', // Add this
     difficulty: 1,
     intensity: PositionIntensity.romantic,
   ),
   ```

---

## 🖼️ Placeholder

If no image is provided, the app displays:
- Position name in large theatrical font
- Difficulty stars
- Intensity emoji (💕/🤸/🌙)
- Gradient background

---

## 📋 Full Position List (15 Cards)

### Easy (★-★★)
| ID | Name | Intensity | Description |
|----|------|-----------|-------------|
| p1 | The Spoons | 💕 Romantic | Partners lie on their sides, curved like nested spoons |
| p2 | The Lotus | 🌙 Intimate | Partner A sits cross-legged while Partner B sits in their lap |
| p3 | The Lazy Dog | 💕 Romantic | Partner A on hands and knees, Partner B behind |
| p4 | The Cowgirl | 💕 Romantic | Partner A lies back while Partner B straddles and faces them |
| p5 | The Reverse Cowgirl | 🤸 Acrobatic | Like Cowgirl, but Partner B faces away |
| p6 | The Throne | 💕 Romantic | Partner A sits in a chair while Partner B sits in their lap |

### Medium (★★★)
| ID | Name | Intensity | Description |
|----|------|-----------|-------------|
| p7 | The Standing Ovation | 🤸 Acrobatic | Partner A stands while Partner B wraps legs around their waist |
| p8 | The Wheelbarrow | 🤸 Acrobatic | Partner A on hands, Partner B holds their legs up from behind |
| p9 | The Pretzel | 🌙 Intimate | Partners intertwine limbs in a complex seated twist |
| p10 | The Spider | 🤸 Acrobatic | Both lean back on hands, legs interlocked, bodies forming an X |

### Hard (★★★★-★★★★★)
| ID | Name | Intensity | Description |
|----|------|-----------|-------------|
| p11 | The Splitting Bamboo | 🤸 Acrobatic | Partner A lies back, one leg raised to Partner B's shoulder |
| p12 | The Suspended Congress | 🤸 Acrobatic | Partner A against a wall, both legs wrapped around standing Partner B |
| p13 | The Glowing Firefly | 🌙 Intimate | Partner A lies back with hips elevated, Partner B kneels between |
| p14 | The Propeller | 🤸 Acrobatic | Partner B rotates 180 degrees while connected |
| p15 | The Acrobat | 🤸 Acrobatic | Partner A does a shoulder stand while Partner B supports from above |

---

## 💡 Art Resources

Consider commissioning from:
- Fiverr (search "Kama Sutra illustration" or "intimate pose art")
- Etsy digital artists
- DeviantArt commissions
- AI art tools (Midjourney, DALL-E) with appropriate styling prompts

**Prompt example for AI art:**
> "Elegant silhouette illustration of two figures in [POSE NAME], artistic Kama Sutra style, tasteful and non-explicit, dark purple gradient background, gold accent lines, theatrical poster aesthetic, 2:3 portrait ratio"

---

*Last updated: January 2026*
