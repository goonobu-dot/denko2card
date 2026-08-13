import SwiftUI

// 図解テンプレ15種。cards5.swift（scratchpad検証済み5種）の作法を踏襲し、
// パラメトリック（hintImage.paramsで描き分け）にした10種を追加。
// H1段階（図解のみ・数値/答えは伏せる想定）で使う想定のため、paramsに答え文字列を
// そのまま置かない運用はデッキ執筆側に委ねる（本テンプレは受け取った値をそのまま描画する）。

// MARK: 1. 温度計（引火点）
struct ThermometerHint: View {
    let params: [String: String]
    var body: some View {
        let value = params.string("value", default: "?")
        let unit = params.string("unit", default: "℃")
        let note = params.string("note")
        HintPanel {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    if !note.isEmpty {
                        Text(note).font(.headline.bold()).foregroundStyle(CardTheme.accent)
                    }
                    FlameView(scale: 0.9)
                }
                .frame(maxWidth: .infinity)

                ZStack(alignment: .bottom) {
                    Capsule().fill(Color.white).stroke(CardTheme.ink.opacity(0.5), lineWidth: 3)
                        .frame(width: 34, height: 180)
                    Capsule().fill(CardTheme.blue)
                        .frame(width: 18, height: 70)
                        .padding(.bottom, 6)
                    Circle().fill(CardTheme.blue).frame(width: 46, height: 46)
                        .offset(y: 23)
                }
                .overlay(alignment: .top) {
                    Text("\(value)\(unit)")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(CardTheme.blue)
                        .fixedSize()
                        .offset(y: -34)
                }
                .padding(.trailing, 12)
                .padding(.top, 30)
            }
            .padding(20)
        }
    }
}

// MARK: 2. ドラム缶（指定数量）
struct DrumHint: View {
    let params: [String: String]
    var body: some View {
        let liters = params.string("liters", default: "?")
        let label = params.string("label")
        HintPanel {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    ForEach(0..<2, id: \.self) { i in
                        VStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(CardTheme.accent.opacity(i == 0 ? 0.85 : 0.55))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(CardTheme.ink.opacity(0.5), lineWidth: 2))
                                .overlay(
                                    VStack(spacing: 18) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            Rectangle().fill(Color.white.opacity(0.5)).frame(height: 2)
                                        }
                                    }.padding(.vertical, 20)
                                )
                                .frame(width: 90, height: 130)
                                .overlay(
                                    Text("\(liters)L").font(.headline.bold()).foregroundStyle(.white)
                                )
                        }
                    }
                }
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
                Text("？本ぶんで届け出").font(.title3.bold()).foregroundStyle(CardTheme.ink)
            }
            .padding(20)
        }
    }
}

// MARK: 3. 法定標識板
struct SignBoardHint: View {
    let params: [String: String]
    var body: some View {
        let text = params.string("text", default: "？？？")
        HintPanel {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.78, green: 0.12, blue: 0.10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(CardTheme.ink, lineWidth: 3))
                    .frame(height: 130)
                    .overlay(
                        Text(text).font(.system(size: 34, weight: .black)).foregroundStyle(.white)
                    )
                    .padding(.horizontal, 24)
                Rectangle().fill(CardTheme.sub).frame(width: 10, height: 40)
                Text("地は赤色・文字は白色（規格様式）").font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 4. ビーカー比重
struct BeakerHint: View {
    let params: [String: String]
    var body: some View {
        let substance = params.string("substance", default: "？？？")
        let sg = params.string("specificGravity", default: "?")
        HintPanel {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: 0, y: 140))
                        p.addLine(to: CGPoint(x: 180, y: 140))
                        p.addLine(to: CGPoint(x: 180, y: 0))
                    }
                    .stroke(CardTheme.ink.opacity(0.7), lineWidth: 6)
                    .frame(width: 180, height: 140)

                    VStack(spacing: 0) {
                        Rectangle().fill(CardTheme.blue.opacity(0.30))
                            .frame(width: 172, height: 95)
                            .overlay(Text("水").font(.headline.bold()).foregroundStyle(CardTheme.blue), alignment: .topTrailing)
                        Rectangle().fill(CardTheme.gold.opacity(0.85))
                            .frame(width: 172, height: 40)
                            .overlay(Text("比重\(sg)").font(.caption.bold()).foregroundStyle(CardTheme.ink))
                    }
                }
                Text("\(substance)（沈む＝水より重い）")
                    .font(.headline.bold())
                    .foregroundStyle(CardTheme.accent)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }
}

// MARK: 5. 消火対比
struct FireCompareHint: View {
    let params: [String: String]
    var body: some View {
        let left = params.string("left", default: "水")
        let right = params.string("right", default: "泡")
        HintPanel {
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    FlameView(scale: 0.8)
                    Text(left).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
                    Text("NG").font(.title3.bold()).foregroundStyle(CardTheme.accent)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CardTheme.accent.opacity(0.30))
                        .frame(width: 120, height: 60)
                        .overlay(
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle().fill(.white).frame(width: 22, height: 22)
                                        .overlay(Circle().stroke(CardTheme.sub.opacity(0.5), lineWidth: 1))
                                }
                            }
                        )
                    Text(right).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
                    Text("OK").font(.title3.bold()).foregroundStyle(CardTheme.ink)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }
}

// MARK: 6. タンク
struct TankHint: View {
    let params: [String: String]
    var body: some View {
        let feature = params.string("feature", default: "？？？")
        HintPanel {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CardTheme.chipBG)
                        .frame(width: 160, height: 110)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(CardTheme.ink.opacity(0.5), lineWidth: 3))
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(CardTheme.accent, lineWidth: 4)
                        .frame(width: 200, height: 130)
                }
                Text(feature).font(.title3.bold()).foregroundStyle(CardTheme.accent)
                Text("タンク周囲の安全構造").font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 7. 危険等級バッジ
struct HazardBadgeHint: View {
    let params: [String: String]
    var body: some View {
        let grade = params.string("grade", default: "?")
        let example = params.string("example")
        HintPanel {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(CardTheme.ink).frame(width: 110, height: 110)
                    Text(grade).font(.system(size: 30, weight: .black)).foregroundStyle(.white)
                }
                if !example.isEmpty {
                    Text(example).font(.headline.bold()).foregroundStyle(CardTheme.accent)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
    }
}

// MARK: 8. 保安距離ものさし
struct SafetyRulerHint: View {
    let params: [String: String]
    var body: some View {
        // H1段階では数値は伏せる想定のため、distanceパラメータ自体は描画に使わず「？」表記のみとする。
        let target = params.string("target", default: "対象物")
        HintPanel {
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8).fill(CardTheme.gold).frame(width: 60, height: 40)
                        .overlay(Text("施設").font(.caption.bold()))
                    ForEach(0..<8, id: \.self) { i in
                        Rectangle().fill(CardTheme.sub).frame(width: 2, height: i % 2 == 0 ? 18 : 10)
                    }
                    RoundedRectangle(cornerRadius: 8).fill(CardTheme.blue.opacity(0.5)).frame(width: 60, height: 40)
                        .overlay(Text(target).font(.caption.bold()))
                }
                Text("？m以上").font(.system(size: 36, weight: .black)).foregroundStyle(CardTheme.accent)
            }
            .padding(20)
        }
    }
}

// MARK: 9. 構造断面
struct CrossSectionHint: View {
    let params: [String: String]
    var body: some View {
        let structure = params.string("structure", default: "？？？")
        HintPanel {
            VStack(spacing: 10) {
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle().fill(i % 2 == 0 ? CardTheme.ink.opacity(0.7) : CardTheme.chipBG)
                            .frame(width: 16, height: 100)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(structure).font(.headline.bold()).foregroundStyle(CardTheme.accent)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }
}

// MARK: 10. 色見本
struct ColorSwatchHint: View {
    let params: [String: String]
    var body: some View {
        let colorName = params.string("colorName", default: "？？？")
        HintPanel {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(CardTheme.ink)
                    .frame(width: 200, height: 90)
                    .overlay(
                        Text("危 険 物").font(.headline.bold())
                            .foregroundStyle(Color.yellow)
                    )
                Text(colorName).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 11. 引火性蒸気の重さ
struct VaporWeightHint: View {
    let params: [String: String]
    var body: some View {
        let ratio = params.string("ratio", default: "?")
        let label = params.string("label", default: "蒸気")
        HintPanel {
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 30) {
                    VStack {
                        Circle().fill(CardTheme.blue.opacity(0.4)).frame(width: 30, height: 30)
                        Text("空気").font(.caption).foregroundStyle(CardTheme.sub)
                    }
                    VStack {
                        Image(systemName: "arrow.down").font(.title).foregroundStyle(CardTheme.accent)
                        Circle().fill(CardTheme.gold).frame(width: 46, height: 46)
                        Text(label).font(.caption.bold()).foregroundStyle(CardTheme.ink)
                    }
                }
                Text("空気の\(ratio)の重さ").font(.title3.bold()).foregroundStyle(CardTheme.accent)
                Text("低所に滞留しやすい").font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 12. 静電気
struct StaticElectricityHint: View {
    let params: [String: String]
    var body: some View {
        let condition = params.string("condition", default: "？？？")
        HintPanel {
            VStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(CardTheme.gold)
                Text(condition).font(.headline.bold()).foregroundStyle(CardTheme.accent)
                    .multilineTextAlignment(.center)
                Text("摩擦・流動・乾燥に注意").font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 13. 混載表
struct MixedTableHint: View {
    let params: [String: String]
    var body: some View {
        let classA = params.string("classA", default: "第4類")
        let classB = params.string("classB", default: "？類")
        let result = params.string("result", default: "？")
        HintPanel {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    VStack {
                        RoundedRectangle(cornerRadius: 10).fill(CardTheme.chipBG).frame(width: 90, height: 60)
                            .overlay(Text(classA).font(.headline.bold()))
                    }
                    Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundStyle(CardTheme.accent)
                    VStack {
                        RoundedRectangle(cornerRadius: 10).fill(CardTheme.chipBG).frame(width: 90, height: 60)
                            .overlay(Text(classB).font(.headline.bold()))
                    }
                }
                Text(result).font(.title3.bold()).foregroundStyle(CardTheme.accent)
            }
            .padding(20)
        }
    }
}

// MARK: 14. 期限カレンダー
struct DeadlineCalendarHint: View {
    let params: [String: String]
    var body: some View {
        let years = params.string("years", default: "?")
        let label = params.string("label", default: "期限")
        HintPanel {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CardTheme.ink.opacity(0.4), lineWidth: 3))
                        .frame(width: 140, height: 140)
                    VStack(spacing: 2) {
                        Rectangle().fill(CardTheme.accent).frame(height: 30)
                        Spacer()
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text(years).font(.system(size: 44, weight: .black)).foregroundStyle(CardTheme.ink)
                        .offset(y: 20)
                }
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(CardTheme.sub)
            }
            .padding(20)
        }
    }
}

// MARK: 15. 人員配置
struct StaffingHint: View {
    let params: [String: String]
    var body: some View {
        let role = params.string("role", default: "？？？")
        HintPanel {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(i == 1 ? CardTheme.accent : CardTheme.sub.opacity(0.5))
                        }
                    }
                }
                Text(role).font(.headline.bold()).foregroundStyle(CardTheme.accent)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }
}
