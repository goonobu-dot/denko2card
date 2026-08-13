import SwiftUI

/// テンプレ15種の一覧（デッキJSONの hintImage.template と一致させる文字列）。
enum HintTemplateKind: String, CaseIterable {
    case thermometer
    case drum
    case signBoard = "sign_board"
    case beaker
    case fireCompare = "fire_compare"
    case tank
    case hazardBadge = "hazard_badge"
    case safetyRuler = "safety_ruler"
    case crossSection = "cross_section"
    case colorSwatch = "color_swatch"
    case vaporWeight = "vapor_weight"
    case staticElectricity = "static_electricity"
    case mixedTable = "mixed_table"
    case deadlineCalendar = "deadline_calendar"
    case staffing

    /// デッキ執筆側（別エージェント）が独自に使った別名テンプレ文字列を吸収するための寛容init。
    /// EDITORIAL.md記載の別名: signboard/distance/structure/colorChip/vapor/static/mixLoad/calendar/personnel/gradeBadge/extinguish
    init?(deckValue raw: String) {
        if let exact = HintTemplateKind(rawValue: raw) {
            self = exact
            return
        }
        switch raw {
        case "signboard": self = .signBoard
        case "distance": self = .safetyRuler
        case "structure": self = .crossSection
        case "colorChip": self = .colorSwatch
        case "vapor": self = .vaporWeight
        case "static": self = .staticElectricity
        case "mixLoad": self = .mixedTable
        case "calendar": self = .deadlineCalendar
        case "personnel": self = .staffing
        case "gradeBadge": self = .hazardBadge
        case "extinguish": self = .fireCompare
        default: return nil
        }
    }
}

/// hintImage.template文字列からテンプレビューへディスパッチする。
/// 未知のテンプレ名でもクラッシュしない（フォールバック表示）よう防御的に実装する。
struct HintImageView: View {
    let spec: HintImageSpec

    var body: some View {
        switch HintTemplateKind(deckValue: spec.template) {
        case .thermometer: ThermometerHint(params: spec.params)
        case .drum: DrumHint(params: spec.params)
        case .signBoard: SignBoardHint(params: spec.params)
        case .beaker: BeakerHint(params: spec.params)
        case .fireCompare: FireCompareHint(params: spec.params)
        case .tank: TankHint(params: spec.params)
        case .hazardBadge: HazardBadgeHint(params: spec.params)
        case .safetyRuler: SafetyRulerHint(params: spec.params)
        case .crossSection: CrossSectionHint(params: spec.params)
        case .colorSwatch: ColorSwatchHint(params: spec.params)
        case .vaporWeight: VaporWeightHint(params: spec.params)
        case .staticElectricity: StaticElectricityHint(params: spec.params)
        case .mixedTable: MixedTableHint(params: spec.params)
        case .deadlineCalendar: DeadlineCalendarHint(params: spec.params)
        case .staffing: StaffingHint(params: spec.params)
        case .none:
            HintPanel {
                Text("図解準備中（テンプレ: \(spec.template)）")
                    .font(.subheadline)
                    .foregroundStyle(CardTheme.sub)
                    .padding(20)
            }
        }
    }
}
