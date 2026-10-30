import argparse
import csv
import json
import urllib.request
import os

OTHERS_LEVEL = 0
OTHERS_ID_OFFSET = 100000


def stroke_components(item, dict_map):
    char = item["character"]
    total_strokes = len(item["strokes"])
    components = [list(range(total_strokes))]
    if char in dict_map:
        matches = dict_map[char].get("matches", [])
        if matches and len(matches) == total_strokes:
            groups = []
            curr = [0]
            for i in range(1, total_strokes):
                if matches[i] == matches[i - 1]:
                    curr.append(i)
                else:
                    groups.append(curr)
                    curr = [i]
            if curr:
                groups.append(curr)
            components = groups
    return components


def stroke_entry(item, dict_map):
    return {
        "strokes": item["strokes"],
        "medians": item["medians"],
        "components": stroke_components(item, dict_map)
    }


def build_others(char_map, dict_map):
    others = []
    for char, entry in dict_map.items():
        if char in char_map:
            continue
        readings = [p for p in entry.get("pinyin") or [] if p]
        if not readings:
            continue
        others.append({
            "id": OTHERS_ID_OFFSET + len(others),
            "level": OTHERS_LEVEL,
            "hanzi": char,
            "pinyin": ", ".join(readings),
            "tones": "",
            "meaning": entry.get("definition") or "",
            "exampleChinese": "",
            "examplePinyin": "",
            "exampleEnglish": ""
        })
    return others


def write_json(path, payload):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)


def main(output_dir):
    csv_path = "docs/hsk-3.0-characters-all.csv"
    os.makedirs(output_dir, exist_ok=True)

    characters = []
    char_map = {}

    with open(csv_path, mode="r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for idx, row in enumerate(reader):
            entry = {
                "id": idx,
                "level": int(row["level"]),
                "hanzi": row["hanzi"],
                "pinyin": row["pinyin"],
                "tones": row.get("tones", ""),
                "meaning": row.get("meaning", ""),
                "exampleChinese": row.get("exampleChinese", ""),
                "examplePinyin": row.get("examplePinyin", ""),
                "exampleEnglish": row.get("exampleEnglish", "")
            }
            characters.append(entry)
            char_map[entry["hanzi"]] = entry

    print(f"Loaded {len(characters)} characters from CSV.")

    graphics_cache = "docs/makemeahanzi_graphics.txt"
    if not os.path.exists(graphics_cache):
        print("Downloading MakeMeAHanzi graphics data...")
        url = "https://raw.githubusercontent.com/skishore/makemeahanzi/master/graphics.txt"
        urllib.request.urlretrieve(url, graphics_cache)
        print("Downloaded graphics data.")

    dictionary_cache = "docs/makemeahanzi_dictionary.txt"
    if not os.path.exists(dictionary_cache):
        print("Downloading MakeMeAHanzi dictionary data...")
        url = "https://raw.githubusercontent.com/skishore/makemeahanzi/master/dictionary.txt"
        urllib.request.urlretrieve(url, dictionary_cache)
        print("Downloaded dictionary data.")

    dict_map = {}
    with open(dictionary_cache, "r", encoding="utf-8") as f:
        for line in f:
            item = json.loads(line)
            dict_map[item.get("character")] = item

    others = build_others(char_map, dict_map)
    others_map = {entry["hanzi"]: entry for entry in others}

    strokes_data = {}
    others_strokes_data = {}
    with open(graphics_cache, "r", encoding="utf-8") as f:
        for line in f:
            item = json.loads(line)
            char = item["character"]
            if char in char_map:
                strokes_data[char] = stroke_entry(item, dict_map)
            elif char in others_map:
                others_strokes_data[char] = stroke_entry(item, dict_map)

    print(f"Matched {len(strokes_data)} HSK characters with stroke data.")
    print(f"Prepared {len(others)} other characters, {len(others_strokes_data)} with stroke data.")

    write_json(os.path.join(output_dir, "characters.json"), characters)
    write_json(os.path.join(output_dir, "strokes.json"), strokes_data)
    write_json(os.path.join(output_dir, "others.json"), others)
    write_json(os.path.join(output_dir, "others_strokes.json"), others_strokes_data)

    print("Data preparation complete.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="Calli/Resources")
    main(parser.parse_args().output_dir)
