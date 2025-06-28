#!/usr/bin/env python3

import os
import json
import numpy as np
from collections import defaultdict
import math
import colorsys

# --- Path-Aware Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
THEMES_SOURCE_DIR = os.path.join(SCRIPT_DIR, "zed-themes-analysis")
OUTPUT_THEME_DIR = os.path.join(SCRIPT_DIR, "dot-config", "zed", "themes")

# --- Analysis Configuration ---
UI_KEYS_TO_AVERAGE = [
    "background", "border", "border.focused", "text", "text.muted", "text.accent",
    "element.background", "element.hover", "element.selected", "editor.background",
    "editor.gutter.background", "editor.line_number", "editor.line_number.active",
    "editor.active_line.background", "cursor", "selection", "warning", "warning.background",
    "error", "error.background", "info", "info.background", "success", "success.background",
    "panel.background", "panel.focused_border", "created", "modified", "deleted",
    "status_bar.background", "title_bar.background", "tab_bar.background",
    "tab.active_background", "tab.inactive_background", "terminal.background",
    "terminal.foreground", "terminal.ansi.black", "terminal.ansi.red",
    "terminal.ansi.green", "terminal.ansi.yellow", "terminal.ansi.blue",
    "terminal.ansi.magenta", "terminal.ansi.cyan", "terminal.ansi.white",
    "terminal.ansi.bright_black", "terminal.ansi.bright_red",
    "terminal.ansi.bright_green", "terminal.ansi.bright_yellow",
    "terminal.ansi.bright_blue", "terminal.ansi.bright_magenta",
    "terminal.ansi.bright_cyan", "terminal.ansi.bright_white"
]
BLACK_LUMINANCE_THRESHOLD = 35
BG_SATURATION_THRESHOLD = 0.01
OUTLIER_PERCENTILE = 90

# --- ACCESSIBLE COLOR PALETTE (Tailwind CSS v4.0) ---
TAILWIND_PALETTE = {
    "slate": ["#f8fafc", "#f1f5f9", "#e2e8f0", "#cbd5e1", "#94a3b8", "#64748b", "#475569", "#334155", "#1e293b", "#0f172a", "#020617"],
    "gray": ["#f9fafb", "#f3f4f6", "#e5e7eb", "#d1d5db", "#9ca3af", "#6b7280", "#4b5563", "#374151", "#1f2937", "#111827", "#030712"],
    "zinc": ["#fafafa", "#f4f4f5", "#e4e4e7", "#d4d4d8", "#a1a1aa", "#71717a", "#52525b", "#3f3f46", "#27272a", "#18181b", "#09090b"],
    "neutral": ["#fafafa", "#f5f5f5", "#e5e5e5", "#d4d4d4", "#a3a3a3", "#737373", "#525252", "#404040", "#262626", "#171717", "#0a0a0a"],
    "stone": ["#fafaf9", "#f5f5f4", "#e7e5e4", "#d6d3d1", "#a8a29e", "#78716c", "#57534e", "#44403c", "#292524", "#1c1917", "#0c0a09"],
    "red": ["#fef2f2", "#fee2e2", "#fecaca", "#fca5a5", "#f87171", "#ef4444", "#dc2626", "#b91c1c", "#991b1b", "#7f1d1d", "#450a0a"],
    "orange": ["#fff7ed", "#ffedd5", "#fed7aa", "#fdba74", "#fb923c", "#f97316", "#ea580c", "#c2410c", "#9a3412", "#7c2d12", "#431407"],
    "amber": ["#fffbeb", "#fef3c7", "#fde68a", "#fcd34d", "#fbbf24", "#f59e0b", "#d97706", "#b45309", "#92400e", "#78350f", "#451a03"],
    "yellow": ["#fefce8", "#fef9c3", "#fef08a", "#fde047", "#facc15", "#eab308", "#ca8a04", "#a16207", "#854d0e", "#713f12", "#422006"],
    "lime": ["#f7fee7", "#ecfccb", "#d9f99d", "#bef264", "#a3e635", "#84cc16", "#65a30d", "#4d7c0f", "#3f6212", "#365314", "#1a2e05"],
    "green": ["#f0fdf4", "#dcfce7", "#bbf7d0", "#86efac", "#4ade80", "#22c55e", "#16a34a", "#15803d", "#166534", "#14532d", "#052e16"],
    "emerald": ["#ecfdf5", "#d1fae5", "#a7f3d0", "#6ee7b7", "#34d399", "#10b981", "#059669", "#047857", "#065f46", "#064e3b", "#022c22"],
    "teal": ["#f0fdfa", "#ccfbf1", "#99f6e4", "#5eead4", "#2dd4bf", "#14b8a6", "#0d9488", "#0f766e", "#115e59", "#134e4a", "#042f2e"],
    "cyan": ["#ecfeff", "#cffafe", "#a5f3fd", "#67e8f9", "#22d3ee", "#06b6d4", "#0891b2", "#0e7490", "#155e75", "#164e63", "#083344"],
    "sky": ["#f0f9ff", "#e0f2fe", "#bae6fd", "#7dd3fc", "#38bdf8", "#0ea5e9", "#0284c7", "#0369a1", "#075985", "#0c4a6e", "#082f49"],
    "blue": ["#eff6ff", "#dbeafe", "#bfdbfe", "#93c5fd", "#60a5fa", "#3b82f6", "#2563eb", "#1d4ed8", "#1e40af", "#1e3a8a", "#172554"],
    "indigo": ["#eef2ff", "#e0e7ff", "#c7d2fe", "#a5b4fc", "#818cf8", "#6366f1", "#4f46e5", "#4338ca", "#3730a3", "#312e81", "#1e1b4b"],
    "violet": ["#f5f3ff", "#ede9fe", "#ddd6fe", "#c4b5fd", "#a78bfa", "#8b5cf6", "#7c3aed", "#6d28d9", "#5b21b6", "#4c1d95", "#2e1065"],
    "purple": ["#faf5ff", "#f3e8ff", "#e9d5ff", "#d8b4fe", "#c084fc", "#a855f7", "#9333ea", "#7e22ce", "#6b21a8", "#581c87", "#3b0764"],
    "fuchsia": ["#fdf4ff", "#fae8ff", "#f5d0fe", "#f0abfc", "#e879f9", "#d946ef", "#c026d3", "#a21caf", "#86198f", "#701a75", "#4a044e"],
    "pink": ["#fdf2f8", "#fce7f3", "#fbcfe8", "#f9a8d4", "#f472b6", "#ec4899", "#db2777", "#be185d", "#9d174d", "#831843", "#500724"],
    "rose": ["#fff1f2", "#ffe4e6", "#fecdd3", "#fda4af", "#fb7185", "#f43f5e", "#e11d48", "#be123c", "#9f1239", "#881337", "#4c0519"]
}

# --- Vendored Color Math ---

def hex_to_rgb(hex_color):
    if not isinstance(hex_color, str): return None
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 8: hex_color = hex_color[:6]
    if len(hex_color) == 3: hex_color = "".join([c*2 for c in hex_color])
    if len(hex_color) != 6: return None
    try: return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    except ValueError: return None

def srgb_to_lab(srgb_tuple):
    if not srgb_tuple: return None
    """Converts an sRGB tuple (0-255) to a CIELAB tuple."""
    if not srgb_tuple: return None
    linear_rgb = []
    for val in srgb_tuple:
        v = val / 255.0
        v = v / 12.92 if v <= 0.04045 else math.pow((v + 0.055) / 1.055, 2.4)
        linear_rgb.append(v)
    matrix = [[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]]
    xyz = [sum(matrix[i][j] * linear_rgb[j] for j in range(3)) for i in range(3)]
    xyz_ref = [xyz[i] / ref for i, ref in enumerate([0.95047, 1.0, 1.08883])]
    def f(t): return math.pow(t, 1/3) if t > 0.008856 else (7.787 * t) + (16/116)
    f_xyz = [f(v) for v in xyz_ref]
    l = (116 * f_xyz[1]) - 16
    a = 500 * (f_xyz[0] - f_xyz[1])
    b = 200 * (f_xyz[1] - f_xyz[2])
    return (l, a, b)

def delta_e_cie2000(lab1, lab2):
    L1, a1, b1 = lab1; L2, a2, b2 = lab2
    C1 = math.sqrt(a1**2 + b1**2); C2 = math.sqrt(a2**2 + b2**2)
    avg_C = (C1 + C2) / 2.0
    G = 0.5 * (1 - math.sqrt(avg_C**7 / (avg_C**7 + 25**7)))
    a1p = (1 + G) * a1; a2p = (1 + G) * a2
    C1p = math.sqrt(a1p**2 + b1**2); C2p = math.sqrt(a2p**2 + b2**2)
    avg_Cp = (C1p + C2p) / 2.0
    h1p = math.degrees(math.atan2(b1, a1p)); h1p += 360 if h1p < 0 else 0
    h2p = math.degrees(math.atan2(b2, a2p)); h2p += 360 if h2p < 0 else 0
    if C1p * C2p == 0: delta_hp = 0
    elif abs(h1p - h2p) <= 180: delta_hp = h2p - h1p
    else: delta_hp = (h2p - h1p) - 360 if h2p > h1p else (h2p - h1p) + 360
    delta_Lp = L2 - L1
    delta_Cp = C2p - C1p
    delta_Hp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(delta_hp / 2.0))
    avg_Lp = (L1 + L2) / 2.0
    if C1p * C2p == 0: avg_Hp = h1p + h2p
    elif abs(h1p - h2p) <= 180: avg_Hp = (h1p + h2p) / 2.0
    else: avg_Hp = (h1p + h2p + 360) / 2.0 if (h1p + h2p) < 360 else (h1p + h2p - 360) / 2.0
    T = 1 - 0.17 * math.cos(math.radians(avg_Hp - 30)) + 0.24 * math.cos(math.radians(2 * avg_Hp)) + 0.32 * math.cos(math.radians(3 * avg_Hp + 6)) - 0.2 * math.cos(math.radians(4 * avg_Hp - 63))
    S_L = 1 + (0.015 * (avg_Lp - 50)**2) / math.sqrt(20 + (avg_Lp - 50)**2)
    S_C = 1 + 0.045 * avg_Cp
    S_H = 1 + 0.015 * avg_Cp * T
    delta_ro = 30 * math.exp(-(((avg_Hp - 275) / 25)**2))
    R_C = 2 * math.sqrt(avg_Cp**7 / (avg_Cp**7 + 25**7))
    R_T = -R_C * math.sin(2 * math.radians(delta_ro))
    return math.sqrt((delta_Lp / S_L)**2 + (delta_Cp / S_C)**2 + (delta_Hp / S_H)**2 + R_T * (delta_Cp / S_C) * (delta_Hp / S_H))

# --- Pre-computation for Palette Snapping ---
FLAT_PALETTE = [color for family in TAILWIND_PALETTE.values() for color in family]
FLAT_PALETTE_LAB = [srgb_to_lab(hex_to_rgb(color)) for color in FLAT_PALETTE]

def find_closest_palette_color(lab_color):
    if not lab_color: return None
    min_diff = float('inf')
    closest_color_hex = None
    for i, palette_lab in enumerate(FLAT_PALETTE_LAB):
        if not palette_lab: continue
        diff = delta_e_cie2000(lab_color, palette_lab)
        if diff < min_diff:
            min_diff = diff
            closest_color_hex = FLAT_PALETTE[i]
    return closest_color_hex

# --- Basic Color & Schema Helpers ---

def rgb_to_hex(rgb):
    return f'#{int(rgb[0]):02x}{int(rgb[1]):02x}{int(rgb[2]):02x}'

def get_luminance(rgb):
    if not rgb: return 0
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]

def get_background_saturation(rgb_tuple):
    if not rgb_tuple: return 0
    r, g, b = [x / 255.0 for x in rgb_tuple]
    _, _, s = colorsys.rgb_to_hls(r, g, b)
    return s

def get_average_saturation(style):
    saturations = []
    for key in ["text.accent", "keyword", "function", "type", "string", "number", "boolean"]:
        rgb = hex_to_rgb(style.get(key))
        if rgb:
            _, _, s = colorsys.rgb_to_hls(rgb[0]/255.0, rgb[1]/255.0, rgb[2]/255.0)
            saturations.append(s)
    return np.mean(saturations) if saturations else 0

def get_background_saturation(rgb_tuple):
    """Calculates the saturation of a single RGB color tuple."""
    if not rgb_tuple: return 0
    r, g, b = [x / 255.0 for x in rgb_tuple]
    _, _, s = colorsys.rgb_to_hls(r, g, b)
    return s

def get_background_saturation(rgb_tuple):
    if not rgb_tuple: return 0
    r, g, b = [x / 255.0 for x in rgb_tuple]
    _, _, s = colorsys.rgb_to_hls(r, g, b)
    return s

def classify_theme_by_background(style_data):
    bg_hex = style_data.get("editor.background")
    bg_rgb = hex_to_rgb(bg_hex)
    if not bg_rgb: return None
    luminance = get_luminance(bg_rgb)
    if luminance < BLACK_LUMINANCE_THRESHOLD:
        saturation = get_background_saturation(bg_rgb)
        return "Pure Black" if saturation < BG_SATURATION_THRESHOLD else "Chromatic Black"
    else:
        h, _, _ = colorsys.rgb_to_hls(bg_rgb[0]/255.0, bg_rgb[1]/255.0, bg_rgb[2]/255.0)
        return "Cool Chromatic"
        h, _, _ = colorsys.rgb_to_hls(bg_rgb[0]/255.0, bg_rgb[1]/255.0, bg_rgb[2]/255.0)
        return "Cool Chromatic"

def normalize_style_data(data):
    normalized = data.copy()
    key_map = {"focused_border": "border.focused", "active_line_background": "editor.active_line.background"}
    for old_key, new_key in key_map.items():
        if old_key in normalized: normalized[new_key] = normalized.pop(old_key)
    if isinstance(normalized.get("selection"), dict):
        normalized["selection"] = normalized["selection"].get("background", "#555555")
    # New normalization for `players` array
    if isinstance(normalized.get("players"), list) and normalized["players"]:
        # Just use the first player's cursor color as representative
        normalized["players"] = normalized["players"][0].get("cursor")
    return normalized

# --- Main Analysis Logic ---

def analyze_themes():
    clusters = defaultdict(list)
    for filename in os.listdir(THEMES_SOURCE_DIR):
        if not filename.endswith(".json"): continue
        filepath = os.path.join(THEMES_SOURCE_DIR, filename)
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f: data = json.load(f)
            for theme_data in data.get("themes", []):
                if theme_data.get("appearance") == "dark":
                    style_block = theme_data.get("style") or theme_data.get("styles")
                    if style_block:
                        style = normalize_style_data(style_block)
                        cluster_name = classify_theme_by_background(style)
                        if cluster_name: clusters[cluster_name].append(style)
        except Exception as e:
            print(f"Warning: Could not process file {filename}: {e}")

    final_results = {}
    for name, theme_styles in clusters.items():
        if len(theme_styles) < 5:
            print(f"\nCluster '{name}' has too few themes ({len(theme_styles)}). Skipping.")
            continue
        print(f"\nProcessing cluster '{name}' with {len(theme_styles)} themes...")

        archetype_colors = {key: rgb_to_hex(np.median([hex_to_rgb(theme.get(key)) for theme in theme_styles if hex_to_rgb(theme.get(key))], axis=0)) for key in UI_KEYS_TO_AVERAGE if any(hex_to_rgb(theme.get(key)) for theme in theme_styles)}

        harmonized_colors = {}
        for key, archetype_hex in archetype_colors.items():
            core_colors = []
            archetype_lab = srgb_to_lab(hex_to_rgb(archetype_hex))
            if not archetype_lab: continue

            color_deviations = []
            for style in theme_styles:
                color_hex = style.get(key)
                if color_hex:
                    color_lab = srgb_to_lab(hex_to_rgb(color_hex))
                    if color_lab:
                        diff = delta_e_cie2000(archetype_lab, color_lab)
                        color_deviations.append((diff, color_hex))

            if not color_deviations: continue
            deviation_scores = [d[0] for d in color_deviations]
            outlier_threshold = np.percentile(deviation_scores, OUTLIER_PERCENTILE)
            core_colors = [rgb for diff, rgb in color_deviations if diff < outlier_threshold]

            # Check if all colors were discarded as outliers
            if not core_colors:
                # If so, fall back to the robust median color for this key
                harmonized_colors[key] = archetype_hex
                continue

            # Calculate the mean RGB values. np.mean might return a scalar or an array.
            # We must ensure it is iterable for tuple().
            mean_rgb_result = np.mean([hex_to_rgb(c) for c in core_colors], axis=0)

            # np.atleast_1d ensures that the result is always an array, which tuple() can handle.
            avg_rgb = tuple(np.atleast_1d(mean_rgb_result))

            raw_average_lab = srgb_to_lab(avg_rgb)
            snapped_hex = find_closest_palette_color(raw_average_lab)
            harmonized_colors[key] = snapped_hex if snapped_hex else rgb_to_hex(avg_rgb)

        final_results[name] = harmonized_colors
        print(f"  -> Generated final harmonized theme.")

    return final_results

def create_valid_theme_file(name, colors):
    if not colors: return
    style_block = colors.copy()
    # Handle the 'players' array specifically.
    # We are averaging the first player cursor color as a representative value.
    if "players" in style_block:
        base_color = style_block["players"]
        style_block["players"] = [{"cursor": base_color}]

    style_block["syntax"] = {
        "comment": {"color": colors.get("text.muted", "#888888"), "font_style": "italic"},
        "string": {"color": colors.get("terminal.ansi.green", "#a3be8c")},
        "keyword": {"color": colors.get("terminal.ansi.magenta", "#81a1c1")},
        "function": {"color": colors.get("terminal.ansi.blue", "#88c0d0")},
        "type": {"color": colors.get("terminal.ansi.yellow", "#8fbcbb")},
        "variable": {"color": colors.get("text", "#d8dee9")},
        "number": {"color": colors.get("terminal.ansi.magenta", "#b48ead")},
        "boolean": {"color": colors.get("terminal.ansi.magenta", "#b48ead")},
        "constant": {"color": colors.get("terminal.ansi.cyan", "#8fbcbb")},
        "property": {"color": colors.get("terminal.ansi.blue", "#88c0d0")},
        "tag": {"color": colors.get("terminal.ansi.red", "#bf616a")},
        "punctuation": {"color": colors.get("text.muted", "#bbbbbb")},
        "title": {"color": colors.get("terminal.ansi.green", "#a3be8c"), "font_weight": 700},
        "emphasis": {"color": colors.get("terminal.ansi.yellow", "#b48ead"), "font_style": "italic"},
        "emphasis.strong": {"color": colors.get("terminal.ansi.yellow", "#b48ead"), "font_weight": 700},
        "link_uri": {"color": colors.get("text.accent", "#88c0d0"), "underline": True}
    }
    theme_json = {"name": f"Average {name}", "author": "Harmonized Analysis", "themes": [{"name": f"Average {name}", "appearance": "dark", "style": style_block}]}
    output_path = os.path.join(OUTPUT_THEME_DIR, f"average-{name.lower().replace(' ', '')}.json")
    os.makedirs(OUTPUT_THEME_DIR, exist_ok=True)
    try:
        with open(output_path, 'w', encoding='utf-8') as f: json.dump(theme_json, f, indent=2)
        print(f"  -> Successfully created theme at: {output_path}")
    except IOError as e: print(f"Error writing file for {name}: {e}")

if __name__ == "__main__":
    print("Starting harmonized analysis of themes...")
    clustered_results = analyze_themes()
    if clustered_results:
        print("\n--- Generating Final Harmonized Themes ---")
        for cluster_name, avg_colors in clustered_results.items():
            create_valid_theme_file(cluster_name, avg_colors)
        print("\nAnalysis complete. Restart Zed to find the new themes.")
    else:
        print("\nAnalysis finished with no data to generate themes from.")
