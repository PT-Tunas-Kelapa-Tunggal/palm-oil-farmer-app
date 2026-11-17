import SwiftUI

/// Design tokens for KROPS.
///
/// Source of truth: Sketch › FOUNDATIONS › Colors ("Style Guide / Colors / Default").
/// Every colour token below mirrors one `KROPS Light/…` Color Variable 1:1, with the same name and value.
/// Variables named `Deprecated/…` and `Accent/Deep` must not be used, so they have no token here.
///
/// The app is locked to light mode (`UIUserInterfaceStyle = Light`) until a dark palette is designed,
/// so these tokens have a single light value.
///
/// Proportion rule from the style guide: light surfaces dominate, black is secondary, orange is a small accent.
enum KropsTheme {

    // MARK: - Accent
    // Oranye hanya aksen kecil. Proporsi warna: terang dominan, hitam sekunder, oranye aksen.

    /// `Accent/Hero` #FF4F18 — Aksen utama: ikon kecil, titik status, chip terdekat. **Bukan untuk teks kecil.**
    static let accentHero = Color(rgba: 0xFF4F18FF)
    /// `Accent/Primary` #C9390C — Teks oranye kecil (status Kurang/Berlebih) agar kontras 5:1.
    static let accentPrimary = Color(rgba: 0xC9390CFF)
    /// `Accent/Section Label` #C9390C — Eyebrow atau label bagian berwarna oranye.
    static let accentSectionLabel = Color(rgba: 0xC9390CFF)
    /// `Accent/Soft` #FFEAE3 — Latar chip oranye samar dan gradasi lembut.
    static let accentSoft = Color(rgba: 0xFFEAE3FF)
    /// `Accent/Success` #34C759 — Centang hijau dan pohon Normal. Satu-satunya hijau.
    static let accentSuccess = Color(rgba: 0x34C759FF)

    // MARK: - Surface
    // Permukaan: yang bisa diketuk lebih terang dari latarnya, atau hitam di atas latar terang.

    /// `Surface/Background` #F2F4F7 — Latar halaman (Fog Gray).
    static let surfaceBackground = Color(rgba: 0xF2F4F7FF)
    /// `Surface/Card` #FFFFFF — Kartu dan baris yang bisa diketuk di atas latar abu.
    static let surfaceCard = Color(rgba: 0xFFFFFFFF)
    /// `Surface/Card Raised` #F2F4F7 — Latar sheet besar, kolom isian di dalam kartu putih.
    static let surfaceCardRaised = Color(rgba: 0xF2F4F7FF)
    /// `Surface/Control` #E5E5EA — Kontrol netral seperti track slider.
    static let surfaceControl = Color(rgba: 0xE5E5EAFF)
    /// `Surface/Inverse` #141517 — Hitam Coal: tombol utama, kanvas gelap, bilah jadwal.
    static let surfaceInverse = Color(rgba: 0x141517FF)
    /// `Surface/Inverse Raised` #2E3034 — Ujung bawah gradasi hitam (Inverse → Inverse Raised).
    static let surfaceInverseRaised = Color(rgba: 0x2E3034FF)

    // MARK: - Label
    // Warna teks. Versi Inverse dipakai di atas hitam, foto, atau peta.

    /// `Label/Primary` #141517 — Judul dan isi utama.
    static let labelPrimary = Color(rgba: 0x141517FF)
    /// `Label/Emphasis` #141517 90% — Teks penting yang sedikit lebih ringan dari Primary.
    static let labelEmphasis = Color(rgba: 0x141517E6)
    /// `Label/Secondary` #141517 72% — Penjelasan, subjudul, keterangan.
    static let labelSecondary = Color(rgba: 0x141517B8)
    /// `Label/Tertiary` #141517 55% — Chevron dan info pelengkap.
    static let labelTertiary = Color(rgba: 0x1415178C)
    /// `Label/Quaternary` #141517 40% — Teks nonaktif.
    static let labelQuaternary = Color(rgba: 0x14151766)
    /// `Label/Inverse Primary` #FFFFFF — Teks putih di atas hitam, foto, atau peta.
    static let labelInversePrimary = Color(rgba: 0xFFFFFFFF)
    /// `Label/Inverse Secondary` #FFFFFF 80% — Keterangan putih 80%.
    static let labelInverseSecondary = Color(rgba: 0xFFFFFFCC)
    /// `Label/Inverse Tertiary` #FFFFFF 60% — Info pelengkap putih 60%.
    static let labelInverseTertiary = Color(rgba: 0xFFFFFF99)

    // MARK: - Separator

    /// `Separator/Default` #C0C0C0 29% — Garis pemisah tipis di dalam kartu.
    static let separatorDefault = Color(rgba: 0xC0C0C04A)
    /// `Separator/Opaque` #C6C6C8 — Garis pemisah padat.
    static let separatorOpaque = Color(rgba: 0xC6C6C8FF)

    // MARK: - Fill
    // Isian transparan. Black untuk latar terang, White untuk latar gelap dan peta.

    /// `Fill/Black 4` #141517 4% — Chip dan tag pupuk.
    static let fillBlack4 = Color(rgba: 0x1415170A)
    /// `Fill/Black 8` #141517 8% — Kotak di dalam sheet kaca dan latar ikon.
    static let fillBlack8 = Color(rgba: 0x14151714)
    /// `Fill/Black 12` #141517 12% — Isian hitam transparan.
    static let fillBlack12 = Color(rgba: 0x1415171F)
    /// `Fill/Black 20` #141517 20% — Isian hitam transparan.
    static let fillBlack20 = Color(rgba: 0x14151733)
    /// `Fill/Black 30` #141517 30% — Isian hitam transparan.
    static let fillBlack30 = Color(rgba: 0x1415174D)
    /// `Fill/Black 45` #141517 45% — Isian hitam transparan pekat.
    static let fillBlack45 = Color(rgba: 0x14151773)
    /// `Fill/Gray 1` #787880 20% — Isian sistem netral.
    static let fillGray1 = Color(rgba: 0x78788033)
    /// `Fill/Gray 2` #787880 16% — Isian sistem netral.
    static let fillGray2 = Color(rgba: 0x78788029)
    /// `Fill/Gray 3` #767680 12% — Tombol nonaktif.
    static let fillGray3 = Color(rgba: 0x7676801F)
    /// `Fill/Scrim 40` #141517 40% — Redupan di belakang sheet.
    static let fillScrim40 = Color(rgba: 0x14151766)
    /// `Fill/White 6` #FFFFFF 6% — Garis batas tipis di atas peta.
    static let fillWhite6 = Color(rgba: 0xFFFFFF0F)
    /// `Fill/White 8` #FFFFFF 8% — Kotak info di atas kanvas hitam.
    static let fillWhite8 = Color(rgba: 0xFFFFFF14)
    /// `Fill/White 12` #FFFFFF 12% — Pemisah dan chip di atas hitam.
    static let fillWhite12 = Color(rgba: 0xFFFFFF1F)
    /// `Fill/White 15` #FFFFFF 15% — Garis batas kebun di atas peta.
    static let fillWhite15 = Color(rgba: 0xFFFFFF26)
    /// `Fill/White 25` #FFFFFF 25% — Panel dan garis di atas peta.
    static let fillWhite25 = Color(rgba: 0xFFFFFF40)
    /// `Fill/White 55` #FFFFFF 55% — Titik dan garis tegas di atas peta.
    static let fillWhite55 = Color(rgba: 0xFFFFFF8C)

    // MARK: - Status
    // Warna kondisi. Hanya untuk peta dan status, selalu dengan label teks.

    /// `Status/Caution` #A88D00 — Pohon Terindikasi. Selalu disertai label teks.
    static let statusCaution = Color(rgba: 0xA88D00FF)
    /// `Status/Critical` #FF383C — Aksi berbahaya: Hapus Semua.
    static let statusCritical = Color(rgba: 0xFF383CFF)
    /// `Status/Neutral` #9C9CA1 — Pohon Tidak wajar. Selalu disertai label teks.
    static let statusNeutral = Color(rgba: 0x9C9CA1FF)
    /// `Status/Warning` #DD6B2C — Pohon Defisiensi. Selalu disertai label teks.
    static let statusWarning = Color(rgba: 0xDD6B2CFF)

    // MARK: - Material

    /// `Material/Bar` #FFFFFF 70% — Bilah navigasi buram saat digulir.
    static let materialBar = Color(rgba: 0xFFFFFFB3)

    // MARK: - Not in Sketch yet
    // Chart and metric colours have no Color Variable in Sketch. They keep their current values until the
    // designer adds them; do not use them for anything new.

    enum Chart {
        /// Nutrient level now / after fertilizing.
        static let current = dynamic(light: 0x6E9F79, dark: 0x4E7A58)
        static let target = dynamic(light: 0x1F4D2C, dark: 0xB8E6C2)
        /// Rain below / at or above the heavy-rain threshold.
        static let lightRain = dynamic(light: 0x5E92C2, dark: 0x4A75A0)
        static let heavyRain = dynamic(light: 0x163F73, dark: 0xB5D6F5)
    }

    /// Garden metric tiles: a soft fill with a matching ink for the icon.
    enum Metric {
        static let areaFill = dynamic(light: 0xE3F1E6, dark: 0x1F3325)
        static let areaInk = dynamic(light: 0x2E6B3F, dark: 0x8FD19E)
        static let perimeterFill = dynamic(light: 0xE2EEF9, dark: 0x1C2B3B)
        static let perimeterInk = dynamic(light: 0x1F5FA8, dark: 0x9CC6F0)
        static let yearFill = dynamic(light: 0xFBEEDB, dark: 0x3A2C17)
        static let yearInk = dynamic(light: 0x9A5B0B, dark: 0xF2B866)
    }

    // MARK: - Legacy (green theme)
    // Kept so existing code and other branches still build. Each one shows a warning pointing to its
    // replacement; they are removed once every feature has migrated.

    @available(*, deprecated, message: "Tema hijau lama. Tombol utama: surfaceInverse. Ikon/penanda: accentHero.")
    static let primary = dynamic(light: 0x2E6B3F, dark: 0x3B7F4E)
    @available(*, deprecated, message: "Tema hijau lama. Teks: labelPrimary. Teks oranye kecil: accentPrimary.")
    static let primaryText = dynamic(light: 0x2E6B3F, dark: 0x8FD19E)
    @available(*, deprecated, message: "Ikon/titik: accentHero. Teks oranye kecil: accentPrimary.")
    static let accent = dynamic(light: 0xB5541A, dark: 0xF0A067)
    @available(*, deprecated, renamed: "surfaceBackground")
    static let background = dynamic(light: 0xF2F2F2, dark: 0x1C1C1C)
    @available(*, deprecated, message: "Kartu: surfaceCard. Kolom isian di dalam kartu putih: surfaceCardRaised.")
    static let cardFill = dynamic(light: 0xEAEAEA, dark: 0x2C2C2C)
    @available(*, deprecated, renamed: "fillGray2")
    static let secondaryFill = Color(uiColor: .secondarySystemFill)
    @available(*, deprecated, renamed: "labelSecondary")
    static let secondaryText = Color(uiColor: .secondaryLabel)
    @available(*, deprecated, renamed: "labelSecondary")
    static let titleText = Color.primary.opacity(0.7)
    @available(*, deprecated, renamed: "surfaceInverse")
    static let buttonBackground = dynamic(light: 0x2E6B3F, dark: 0x3B7F4E)
    @available(*, deprecated, message: "Tidak ada di Sketch. Untuk status pohon: statusWarning + label teks.")
    static let warningFill = dynamic(light: 0xFBEBD0, dark: 0x3A2A10)
    @available(*, deprecated, message: "Tidak ada di Sketch. Untuk status pohon: statusWarning + label teks.")
    static let warningText = dynamic(light: 0x8A5300, dark: 0xF5C16C)

    // MARK: - Typography, radius, spacing

    enum Typography {
        static let fieldLabel = Font.headline
        static let body = Font.body
        static let caption = Font.footnote
    }

    enum Radius {
        static let card: CGFloat = 24
        static let metric: CGFloat = 20
    }

    enum Spacing {
        static let compact: CGFloat = 8
        static let field: CGFloat = 12
        static let screen: CGFloat = 16
        static let content: CGFloat = 32
        static let section: CGFloat = 24
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension Color {
    /// `0xRRGGBBAA` in sRGB, written the same way Sketch shows a Color Variable.
    init(rgba: UInt32) {
        self.init(.sRGB,
                  red: Double((rgba >> 24) & 0xFF) / 255,
                  green: Double((rgba >> 16) & 0xFF) / 255,
                  blue: Double((rgba >> 8) & 0xFF) / 255,
                  opacity: Double(rgba & 0xFF) / 255)
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
