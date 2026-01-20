# 🎭 Drama Sutra Card Assets

Position card images for the Drama Sutra game.

---

## ✅ UPLOADED GROUP POSITIONS (12 Cards)

| File | Position Name | Difficulty | Intensity |
|------|---------------|------------|-----------|
| `group-sex-1_X5.png` | **The Constellation** | ★★★☆☆ | 🌙 Intimate |
| `group-sex-2_X5.png` | **The Daisy Chain** | ★★★☆☆ | 🌙 Intimate |
| `group-sex-3_X5.png` | **The Pyramid** | ★★★★☆ | 🤸 Acrobatic |
| `group-sex-4_X5.png` | **The Thunderclap** | ★★★★☆ | 🤸 Acrobatic |
| `group-sex-5_X5.png` | **The Velvet Sandwich** | ★★☆☆☆ | 💕 Romantic |
| `group-sex-6_X5.png` | **The Serpentine** | ★★★☆☆ | 🌙 Intimate |
| `group-sex-7_X5.png` | **The Triple Crown** | ★★★☆☆ | 💕 Romantic |
| `group-sex-8_X5.png` | **The Circus Act** | ★★★★★ | 🤸 Acrobatic |
| `group-sex-9_X5.png` | **The Love Knot** | ★★★★☆ | 🌙 Intimate |
| `group-sex-10_X5.png` | **The Tidal Wave** | ★★★☆☆ | 💕 Romantic |
| `group-sex-11_X5.png` | **The Phoenix Rising** | ★★★★☆ | 🤸 Acrobatic |
| `group-sex-12_X5.png` | **The Grand Finale** | ★★★★★ | 🌙 Intimate |

---

## 📋 CLASSIC COUPLES POSITIONS (15 Cards - Need Images)

| ID | Position Name | Difficulty | Intensity |
|----|---------------|------------|-----------|
| p1 | **The Spoons** | ★☆☆☆☆ | 💕 Romantic |
| p2 | **The Lotus** | ★☆☆☆☆ | 🌙 Intimate |
| p3 | **The Lazy Dog** | ★☆☆☆☆ | 💕 Romantic |
| p4 | **The Cowgirl** | ★★☆☆☆ | 💕 Romantic |
| p5 | **The Reverse Cowgirl** | ★★☆☆☆ | 🤸 Acrobatic |
| p6 | **The Throne** | ★★☆☆☆ | 💕 Romantic |
| p7 | **The Standing Ovation** | ★★★☆☆ | 🤸 Acrobatic |
| p8 | **The Wheelbarrow** | ★★★☆☆ | 🤸 Acrobatic |
| p9 | **The Pretzel** | ★★★☆☆ | 🌙 Intimate |
| p10 | **The Spider** | ★★★☆☆ | 🤸 Acrobatic |
| p11 | **The Splitting Bamboo** | ★★★★☆ | 🤸 Acrobatic |
| p12 | **The Suspended Congress** | ★★★★☆ | 🤸 Acrobatic |
| p13 | **The Glowing Firefly** | ★★★★☆ | 🌙 Intimate |
| p14 | **The Propeller** | ★★★★☆ | 🤸 Acrobatic |
| p15 | **The Acrobat** | ★★★★★ | 🤸 Acrobatic |

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
