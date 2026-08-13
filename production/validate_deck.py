#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""デッキ自己検証スクリプト。
Denko2Card/Resources/deck/*.json を全件読み込み、以下を検証する:
  1. 全JSONファイルがパースできる
  2. id が全ファイル横断で重複ゼロ
  3. 各カードの choices が3件（正解は含まない）
  4. hintImage.template が既存15種テンプレ（別名込み）のいずれか
  5. カード総数が340枚 ±10%（306〜374枚）
  6. 必須フィールドが全て存在する
"""
import json
import sys
from pathlib import Path

DECK_DIR = Path(__file__).resolve().parent.parent / "Denko2Card" / "Resources" / "deck"

# HintImageView.swift の HintTemplateKind と同じ15種（正式名 or 別名）
VALID_TEMPLATES = {
    # 正式名（HintTemplateKind rawValue）
    "thermometer", "drum", "sign_board", "beaker", "fire_compare", "tank",
    "hazard_badge", "safety_ruler", "cross_section", "color_swatch",
    "vapor_weight", "static_electricity", "mixed_table", "deadline_calendar",
    "staffing",
    # 別名（デッキ執筆側が使う簡易表記）
    "signboard", "distance", "structure", "colorChip", "vapor", "static",
    "mixLoad", "calendar", "personnel", "gradeBadge", "extinguish",
}

REQUIRED_FIELDS = {
    "id", "subject", "topic", "question", "answer", "choices",
    "hintImage", "goro", "goroNote", "source", "tags",
}

EXPECTED_TOTAL = 340
TOLERANCE = 0.10


def fail(msg):
    print(f"NG: {msg}")
    return False


def main():
    ok = True
    all_cards = []
    per_file_counts = {}

    if not DECK_DIR.exists():
        print(f"NG: デッキディレクトリが見つかりません: {DECK_DIR}")
        return 1

    deck_files = sorted(DECK_DIR.glob("deck-*.json"))
    if not deck_files:
        print(f"NG: デッキファイルが見つかりません: {DECK_DIR}/deck-*.json")
        return 1

    # 1. 全JSONファイルのパース
    for path in deck_files:
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            ok = fail(f"{path.name} のJSONパースに失敗: {e}")
            continue

        cards = data.get("cards")
        if not isinstance(cards, list):
            ok = fail(f"{path.name}: 'cards' 配列がありません")
            continue

        per_file_counts[path.name] = len(cards)
        for idx, card in enumerate(cards):
            card["_file"] = path.name
            card["_index"] = idx
            all_cards.append(card)

    print(f"読み込んだファイル: {[p.name for p in deck_files]}")
    for name, count in per_file_counts.items():
        print(f"  {name}: {count}枚")

    total = len(all_cards)
    print(f"カード総数: {total}枚")

    # 5. 総数チェック（340±10% = 306〜374）
    lo = EXPECTED_TOTAL * (1 - TOLERANCE)
    hi = EXPECTED_TOTAL * (1 + TOLERANCE)
    if not (lo <= total <= hi):
        ok = fail(f"カード総数が範囲外です: {total}枚（期待範囲: {lo:.0f}〜{hi:.0f}枚）")
    else:
        print(f"OK: カード総数は範囲内です（{lo:.0f}〜{hi:.0f}枚）")

    # 6. 必須フィールド
    missing_field_errors = []
    for card in all_cards:
        missing = REQUIRED_FIELDS - set(card.keys())
        if missing:
            missing_field_errors.append(
                f"{card['_file']}[{card['_index']}] (id={card.get('id', '?')}): 欠落フィールド {sorted(missing)}"
            )
    if missing_field_errors:
        ok = fail(f"必須フィールドの欠落が {len(missing_field_errors)} 件あります")
        for e in missing_field_errors[:10]:
            print(f"    - {e}")
    else:
        print("OK: 必須フィールドはすべて存在します")

    # 2. id重複チェック（全ファイル横断）
    id_to_locations = {}
    for card in all_cards:
        cid = card.get("id")
        if cid is None:
            continue
        id_to_locations.setdefault(cid, []).append(f"{card['_file']}[{card['_index']}]")
    duplicates = {cid: locs for cid, locs in id_to_locations.items() if len(locs) > 1}
    if duplicates:
        ok = fail(f"id重複が {len(duplicates)} 件あります")
        for cid, locs in list(duplicates.items())[:10]:
            print(f"    - id={cid}: {locs}")
    else:
        print(f"OK: id重複はありません（ユニークid数: {len(id_to_locations)}）")

    # 3. choices が3件（正解を含まない前提）
    choice_errors = []
    for card in all_cards:
        choices = card.get("choices")
        if not isinstance(choices, list) or len(choices) != 3:
            choice_errors.append(
                f"{card['_file']}[{card['_index']}] (id={card.get('id', '?')}): choicesが3件ではありません（{choices}）"
            )
            continue
        answer = card.get("answer")
        if answer in choices:
            choice_errors.append(
                f"{card['_file']}[{card['_index']}] (id={card.get('id', '?')}): choicesに正解と同じ値が含まれています"
            )
    if choice_errors:
        ok = fail(f"choicesの問題が {len(choice_errors)} 件あります")
        for e in choice_errors[:10]:
            print(f"    - {e}")
    else:
        print("OK: choicesはすべて3件・正解と重複なしです")

    # 4. hintImage.template が既存15種
    template_errors = []
    for card in all_cards:
        hint = card.get("hintImage", {})
        template = hint.get("template") if isinstance(hint, dict) else None
        if template not in VALID_TEMPLATES:
            template_errors.append(
                f"{card['_file']}[{card['_index']}] (id={card.get('id', '?')}): 未知のテンプレ '{template}'"
            )
    if template_errors:
        ok = fail(f"hintImage.templateの問題が {len(template_errors)} 件あります")
        for e in template_errors[:10]:
            print(f"    - {e}")
    else:
        print("OK: hintImage.templateはすべて既存15種の範囲内です")

    # 参考情報: 科目・トピック集計
    print("\n--- 科目別トピック集計 ---")
    by_subject = {}
    for card in all_cards:
        subj = card.get("subject", "?")
        topic = card.get("topic", "?")
        by_subject.setdefault(subj, {}).setdefault(topic, 0)
        by_subject[subj][topic] += 1
    for subj, topics in by_subject.items():
        subtotal = sum(topics.values())
        print(f"[{subj}] 計{subtotal}枚")
        for topic, count in topics.items():
            print(f"    - {topic}: {count}枚")

    print()
    if ok:
        print("=== 全項目OK ===")
        return 0
    else:
        print("=== NGが見つかりました ===")
        return 1


if __name__ == "__main__":
    sys.exit(main())
