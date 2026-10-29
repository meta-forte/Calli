import csv
import json
import urllib.request
import os

def main():
    csv_path = "docs/hsk-3.0-characters-all.csv"
    output_dir = "Calli/Resources"
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
    dict_map = {}
    if os.path.exists(dictionary_cache):
        with open(dictionary_cache, "r", encoding="utf-8") as f:
            for line in f:
                item = json.loads(line)
                dict_map[item.get("character")] = item

    strokes_data = {}
    with open(graphics_cache, "r", encoding="utf-8") as f:
        for line in f:
            item = json.loads(line)
            char = item["character"]
            if char in char_map:
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

                strokes_data[char] = {
                    "strokes": item["strokes"],
                    "medians": item["medians"],
                    "components": components
                }

    print(f"Matched {len(strokes_data)} characters with stroke data.")

    characters_out = os.path.join(output_dir, "characters.json")
    with open(characters_out, "w", encoding="utf-8") as f:
        json.dump(characters, f, ensure_ascii=False)

    strokes_out = os.path.join(output_dir, "strokes.json")
    with open(strokes_out, "w", encoding="utf-8") as f:
        json.dump(strokes_data, f, ensure_ascii=False)

    print("Data preparation complete.")

if __name__ == "__main__":
    main()
