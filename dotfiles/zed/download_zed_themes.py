#!/usr/bin/env python3

import os
import re
import requests
import json
import time
from datetime import datetime
from dotenv import load_dotenv

# --- Configuration & Setup ---
load_dotenv()

# --- Path-Aware Configuration ---
# Get the absolute directory where this script is located to build robust paths.
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
# Define output directory relative to the script's location.
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "zed-themes-analysis")

GALLERY_URL = "https://zed-themes.com/"
GITHUB_API_BASE = "https://api.github.com/repos"
REQUEST_HEADERS = { "User-Agent": "ZedThemeAnalysisScript/1.0" }
FALLBACK_RETRY_DELAY_SECONDS = 61

# --- GitHub API Authentication ---
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
if GITHUB_TOKEN:
    print("✅ Found GITHUB_TOKEN. Using authenticated requests.")
    REQUEST_HEADERS["Authorization"] = f"Bearer {GITHUB_TOKEN}"
else:
    print("⚠️  Warning: GITHUB_TOKEN not found.")

# --- Core Functions ---

def make_api_request(url):
    """
    Makes a GET request to the specified URL, intelligently handling GitHub API
    rate limiting by using the 'X-RateLimit-Reset' header.
    """
    while True:
        try:
            response = requests.get(url, headers=REQUEST_HEADERS)

            if response.status_code == 403 and 'x-ratelimit-remaining' in response.headers and int(response.headers['x-ratelimit-remaining']) == 0:
                reset_timestamp = int(response.headers.get('x-ratelimit-reset', 0))
                wait_duration = max(0, reset_timestamp - int(time.time())) + 1
                if wait_duration > 1:
                    reset_time_str = datetime.fromtimestamp(reset_timestamp).strftime('%H:%M:%S')
                    print(f"\n[!] Rate limit hit. Pausing for {wait_duration}s until {reset_time_str}...")
                    time.sleep(wait_duration)
                    print("[!] Resuming...")
                else: # Fallback
                    time.sleep(FALLBACK_RETRY_DELAY_SECONDS)
                continue

            response.raise_for_status()
            return response

        except requests.exceptions.RequestException as e:
            print(f"  -> HTTP Request Error: {e}. This request will be skipped.")
            return None

def sanitize_and_save_theme(raw_text, filepath):
    """
    Tries to parse raw text as JSON. If it fails, it strips comments
    and tries again. If successful, saves the cleaned, valid JSON.
    Returns True on success, False on failure.
    """
    try:
        loaded_json = json.loads(raw_text)
    except json.JSONDecodeError:
        print(f"    -> Invalid JSON. Attempting to strip comments...")
        no_single = re.sub(r"//.*", "", raw_text)
        no_multi = re.sub(r"/\*.*?\*/", "", no_single, flags=re.DOTALL)
        try:
            loaded_json = json.loads(no_multi)
            print(f"    -> Successfully sanitized and validated.")
        except json.JSONDecodeError as e:
            print(f"    -> ERROR: Could not rescue file. Final parsing error: {e}")
            return False
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(loaded_json, f, indent=2)
        return True
    except IOError as e:
        print(f"  -> ERROR: Failed to save sanitized file {os.path.basename(filepath)}: {e}")
        return False

def get_theme_repo_urls():
    """
    Scrapes the zed-themes.com gallery to find all unique GitHub repository URLs.
    """
    print(f"Fetching theme gallery from {GALLERY_URL}...")
    response = make_api_request(GALLERY_URL)
    if not response:
        print("Fatal: Could not fetch the main gallery page. Aborting.")
        return []
    github_urls = re.findall(r'href="(https://github.com/[\w.-]+/[\w.-]+)"', response.text)
    unique_urls = sorted(list(set(github_urls)))
    if not unique_urls:
        print("Warning: Could not find any GitHub repository links on the page.")
        return []
    print(f"Found {len(unique_urls)} unique theme repositories.")
    return unique_urls

def download_themes_from_repos(repo_urls):
    """
    Iterates through repos, downloads theme files, validates/sanitizes them,
    and saves only the valid ones, skipping existing files.
    """
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    newly_downloaded = 0
    skipped_count = 0
    failed_count = 0

    for url in repo_urls:
        repo_id = "/".join(url.split('/')[-2:])
        api_url = f"{GITHUB_API_BASE}/{repo_id}/contents/themes"
        print(f"\nChecking repository: {repo_id}")

        dir_contents_response = make_api_request(api_url)
        if not dir_contents_response:
            print(f"  -> Could not fetch contents. Skipping.")
            continue
        try:
            files_in_dir = dir_contents_response.json()
            if not isinstance(files_in_dir, list):
                print(f"  -> Unexpected API response format. Skipping.")
                continue

            for item in files_in_dir:
                if isinstance(item, dict) and item.get("name", "").endswith(".json"):
                    download_url = item.get("download_url")
                    if not download_url: continue
                    safe_name = f"{repo_id.replace('/', '_')}_{item['name']}"
                    filepath = os.path.join(OUTPUT_DIR, safe_name)

                    if os.path.exists(filepath):
                        skipped_count += 1
                        continue

                    print(f"  -> Downloading {item['name']}...")
                    theme_res = make_api_request(download_url)
                    if theme_res:
                        if sanitize_and_save_theme(theme_res.text, filepath):
                            newly_downloaded += 1
                        else:
                            failed_count += 1
        except json.JSONDecodeError as e:
            print(f"  -> ERROR: Failed to parse directory contents for {repo_id}: {e}")

    print(f"\n--- Download Process Complete ---")
    print(f"Newly downloaded & validated themes: {newly_downloaded}")
    print(f"Skipped (already existed): {skipped_count}")
    print(f"Failed (could not rescue): {failed_count}")

if __name__ == "__main__":
    urls = get_theme_repo_urls()
    if urls:
        download_themes_from_repos(urls)
    else:
        print("\nNo theme repositories found to download.")
