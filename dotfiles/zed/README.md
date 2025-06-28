# Zed Editor Configuration

This directory contains the configuration for the Zed editor.

## Files

- `settings.json` - Main Zed configuration file with:
  - Vim mode enabled
  - Copilot AI agent configuration
  - Font settings (Fira Code with ligatures)
  - Language-specific settings for Python, TypeScript, Terraform, etc.
  - Theme and UI preferences
  - LSP configurations

## Installation

To install this configuration, use stow from the dotfiles directory:

```bash
cd /path/to/enchiridion/dotfiles
stow -t ~ -S zed
```

This will create symlinks in `~/.config/zed/` pointing to the files in this directory.

---

## Zed Theme Analysis Engine

This directory also contains a set of scripts designed to programmatically analyze the entire ecosystem of community-created themes for the Zed editor. The engine downloads all available themes, performs a sophisticated statistical analysis, and generates a set of "average" themes based on common aesthetic clusters.

### The Goal

The primary goal of this project is to answer the question: "What does the average Zed theme *really* look like?" Instead of relying on a single person's taste, this engine uses a data-driven approach to find the mathematical center of different popular styles (e.g., very dark themes, cool-toned themes).

The result is a set of unique, high-quality, and schema-compliant themes that represent a "platonic ideal" for each major category.

### Comprehensive Scope

The analysis is not limited to just the editor background and text. The `UI_KEYS_TO_AVERAGE` list in the script has been expanded to include a wide range of UI elements for a more complete and usable final theme, including:

-   **Core UI**: Backgrounds, borders, text, and standard element states.
-   **Bars & Tabs**: The background colors for the status bar, title bar, and active/inactive tabs.
-   **UI States**: Colors for `info`, `success`, `warning`, and `error` states.
-   **Panels**: Colors for the project panel (file tree), terminal panel, and other UI surfaces.
-   **Version Control**: Colors for `created`, `modified`, and `deleted` file text in the project panel.
-   **Terminal**: The full 16-color ANSI palette (normal and bright) as well as the default terminal foreground and background.

This comprehensive approach ensures that the generated "average" themes are not just conceptually interesting but also immediately usable and complete.

### The Workflow

The entire process is designed to be run from the root of the `enchiridion` repository.

#### 1. Initial Setup

First, ensure all dependencies are installed and the environment is configured correctly.

```bash
just setup
```

This command, defined in the root `Justfile`, will:
- Install required system packages (like `stow`, `python`, `pip`).
- Install necessary Python libraries (`numpy`, `colormath`, `python-dotenv`, `requests`).
- **Securely fetch your GitHub Personal Access Token (PAT)** from your Bitwarden vault using the `bw` CLI. This creates a local `.env` file (which is git-ignored) to enable a high rate limit for the GitHub API. This step is idempotent and will be skipped if the token already exists.

#### 2. Download the Themes

Next, run the downloader script.

```bash
python3 dotfiles/zed/download_zed_themes.py
```

This script will:
- Scrape the official `zed-themes.com` gallery to get a list of all theme repositories.
- Incrementally download the `.json` file for each theme into the `zed-themes-analysis/` directory, skipping any that have already been downloaded.
- **Intelligently handle GitHub API rate limits** by pausing and resuming automatically based on the API's feedback.
- **Validate and Sanitize**: Attempt to parse each downloaded file. If it fails due to comments or other common errors, it will attempt to strip them and re-validate before saving. This rescues many otherwise-invalid theme files.

#### 3. Analyze and Generate

Finally, run the analysis script.

```bash
python3 dotfiles/zed/analyze_themes.py
```

This script performs the advanced three-pass statistical analysis:
1.  **Clustering**: It first categorizes every dark theme into one of five, highly-specific groups based on the properties of the background color itself:
    *   **Pure Black**: For themes with a true black or near-black background that has very low saturation.
    *   **Chromatic Black**: For themes with a very dark background that has a discernible, intentional color tint.
    *   **Cool Chromatic**: For non-black themes with a distinct blue or green-tinted background.
2.  **Pass 1: Archetype Calculation**: For each cluster, it calculates the **median** color for every UI element. This robustly defines a theoretical "archetype" for that style, as the median is resistant to statistical outliers.
3.  **Pass 2: Granular Outlier Rejection**: For *each individual UI element* (e.g., the set of all `warning` colors within a cluster), it performs the following:
    *   It measures the perceptual color difference (using the CIEDE2000 formula) of every color in that set from the archetype's corresponding color.
    *   It identifies and **discards the top 20% of most visually deviant colors** for that specific element. This prevents a single theme's bad `warning` color from spoiling the average, without discarding that theme's perfectly good `text` and `border` colors.
4.  **Pass 3: Final Averaging**: For *each individual UI element*, it calculates the **mean** of the remaining "core" 80% of colors. This provides a highly accurate, "raw" average color for each UI element.
5.  **Harmonization Pass (Final Pass)**: As a final step, each "raw" averaged color is perceptually compared against the entire accessible **Tailwind CSS color palette**. The script then **"snaps"** the final color to the closest available Tailwind color. This ensures the final theme is not just an average, but is also aesthetically cohesive and uses a professionally-designed, accessible set of colors.
6.  **Generation**: Finally, it generates four new, schema-compliant theme files, one for each of the refined clusters.

After running this workflow, the new "Average" themes will be available in Zed's theme selector.
