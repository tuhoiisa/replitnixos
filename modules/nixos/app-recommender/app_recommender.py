#!/usr/bin/env python3
"""
NixOS Application Recommendation Engine

This module provides AI-powered application recommendations based on
the user's installed applications, hardware, and usage patterns.
"""

import os
import json
import logging
import sqlite3
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from datetime import datetime, timedelta
import argparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/app-recommender.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("app-recommender")

# Database configuration
DB_PATH = os.environ.get("APP_RECOMMENDER_DB", "/var/lib/app-recommender/database.db")

# Categories of applications for recommendation
CATEGORIES = {
    "development": [
        "vscode", "vim", "neovim", "emacs", "jetbrains", "intellij", "pycharm", 
        "webstorm", "rider", "clion", "rubymine", "idea", "android-studio", "eclipse",
        "git", "github", "gitlab", "subversion", "mercurial", "docker", "podman",
        "node", "python", "ruby", "rust", "go", "java", "kotlin", "scala", "haskell",
        "clang", "gcc", "llvm"
    ],
    "graphic_design": [
        "gimp", "inkscape", "krita", "blender", "darktable", "digikam", "rawtherapee",
        "shotwell", "hugin", "luminance-hdr", "scribus", "photogimp", "figma", "sketch",
        "pinta", "aseprite", "drawio"
    ],
    "productivity": [
        "libreoffice", "onlyoffice", "wpsoffice", "calligra", "gnumeric", "abiword",
        "thunderbird", "evolution", "nextcloud", "joplin", "obsidian", "notion",
        "evernote", "simplenote", "standardnotes", "zotero", "mendeley", "calibre",
        "todoist", "tasks", "planner", "gnome-calendar", "korganizer"
    ],
    "multimedia": [
        "vlc", "mpv", "kodi", "mplayer", "totem", "rhythmbox", "clementine", "strawberry",
        "lollypop", "audacious", "spotify", "audacity", "ardour", "lmms", "musescore",
        "handbrake", "obs", "kdenlive", "shotcut", "davinci", "openshot", "pitivi",
        "ffmpeg"
    ],
    "gaming": [
        "steam", "lutris", "heroic", "wine", "proton", "gamemode", "mangohud", "goverlay",
        "retroarch", "dolphin-emu", "pcsx2", "rpcs3", "yuzu", "citra", "dosbox", "scummvm",
        "itch", "gog", "minigalaxy", "legendary"
    ],
    "system_tools": [
        "gnome-system-monitor", "htop", "btop", "iotop", "powertop", "s-tui", "neofetch",
        "gparted", "baobab", "stacer", "bleachbit", "timeshift", "gtkhash", "gnome-disks",
        "filelight", "ncdu", "glances", "inxi", "hardinfo", "clamav", "gufw", "firewalld"
    ],
    "networking": [
        "firefox", "chromium", "brave", "opera", "vivaldi", "qutebrowser", "wget", "curl",
        "transmission", "deluge", "qbittorrent", "filezilla", "remmina", "teamviewer",
        "anydesk", "wireshark", "nmap", "netcat", "openssh", "mosh", "wireguard", "openvpn",
        "mullvad", "nordvpn", "protonvpn"
    ],
    "security": [
        "keepassxc", "bitwarden", "pass", "gnupg", "cryptsetup", "veracrypt", "tomb",
        "yubikey-manager", "nitrokey-app", "seahorse", "kleopatra", "lastpass",
        "authenticator", "opensnitch", "clamav", "lynis", "chkrootkit", "firejail",
        "apparmor"
    ]
}

# Application recommendation rules
RECOMMENDATION_RULES = {
    "development": {
        "python": ["vscode", "pycharm", "jupyter"],
        "web": ["vscode", "webstorm", "firefox-developer-edition", "postman"],
        "java": ["intellij-idea", "eclipse", "maven", "gradle"],
        "rust": ["vscode", "rust-analyzer", "rustup", "cargo"],
        "gamedev": ["godot", "blender", "aseprite", "gimp"]
    },
    "gaming": {
        "steam": ["gamemode", "mangohud", "steam-run", "gamescope"],
        "emulation": ["retroarch", "lutris", "wine", "proton-ge-custom"],
        "recording": ["obs-studio", "replay-sorcery", "nvidia-shadowplay"]
    },
    "multimedia": {
        "audio_production": ["ardour", "audacity", "lmms", "carla", "jack2"],
        "video_editing": ["kdenlive", "shotcut", "davinci-resolve", "blender"],
        "streaming": ["obs-studio", "streamlink", "yt-dlp", "streamlink-twitch-gui"]
    },
    "hardware_specific": {
        "amd_gpu": ["corectrl", "radeontop", "rocm-smi"],
        "nvidia_gpu": ["nvidia-settings", "nvtop", "gwe"],
        "intel_gpu": ["intel-gpu-tools", "libva-utils"],
        "laptop": ["powertop", "tlp", "auto-cpufreq", "battery-monitor"]
    }
}

class AppRecommender:
    """Provides application recommendations based on user profile and usage patterns."""
    
    def __init__(self):
        """Initialize the recommendation engine."""
        self.db_path = Path(DB_PATH)
        self.ensure_db_exists()
        
    def ensure_db_exists(self):
        """Ensure the database and necessary tables exist."""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create tables if they don't exist
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS installed_apps (
            id INTEGER PRIMARY KEY,
            app_name TEXT NOT NULL UNIQUE,
            category TEXT,
            install_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_used TIMESTAMP,
            usage_count INTEGER DEFAULT 0
        )
        ''')
        
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
            id INTEGER PRIMARY KEY,
            category TEXT NOT NULL UNIQUE,
            score INTEGER DEFAULT 0
        )
        ''')
        
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS recommendations (
            id INTEGER PRIMARY KEY,
            app_name TEXT NOT NULL UNIQUE,
            category TEXT,
            reason TEXT,
            score FLOAT,
            recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        conn.commit()
        conn.close()
        
    def scan_installed_applications(self):
        """Scan the system for installed NixOS applications."""
        try:
            # Use nix-env to list installed packages
            result = subprocess.run(
                ["nix-env", "--query", "--installed", "--json"],
                capture_output=True, text=True, check=True
            )
            installed_packages = json.loads(result.stdout)
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            for pkg_name, pkg_info in installed_packages.items():
                # Determine category based on package name and metadata
                category = self._determine_category(pkg_name, pkg_info)
                
                # Check if app already exists in database
                cursor.execute("SELECT id FROM installed_apps WHERE app_name = ?", (pkg_name,))
                if cursor.fetchone() is None:
                    cursor.execute(
                        "INSERT INTO installed_apps (app_name, category) VALUES (?, ?)",
                        (pkg_name, category)
                    )
            
            conn.commit()
            conn.close()
            logger.info(f"Scanned and updated {len(installed_packages)} installed applications")
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Error scanning installed applications: {e}")
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing package JSON: {e}")
        except Exception as e:
            logger.error(f"Unexpected error during application scan: {e}")
            
    def _determine_category(self, pkg_name: str, pkg_info: Dict) -> str:
        """Determine the category of an application based on its name and metadata."""
        pkg_name_lower = pkg_name.lower()
        
        for category, keywords in CATEGORIES.items():
            for keyword in keywords:
                if keyword in pkg_name_lower:
                    return category
        
        # Default category if we can't determine it
        return "other"
            
    def scan_application_usage(self):
        """Scan the system for application usage information."""
        try:
            # Get recently used applications from various sources
            recently_used = self._get_recently_used_apps()
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            for app_name in recently_used:
                # Update last used timestamp and usage count
                cursor.execute(
                    """
                    UPDATE installed_apps 
                    SET last_used = ?, usage_count = usage_count + 1 
                    WHERE app_name = ?
                    """,
                    (datetime.now().isoformat(), app_name)
                )
            
            conn.commit()
            conn.close()
            logger.info(f"Updated usage statistics for {len(recently_used)} applications")
            
        except Exception as e:
            logger.error(f"Error scanning application usage: {e}")
            
    def _get_recently_used_apps(self) -> List[str]:
        """Get a list of recently used applications from various sources."""
        apps = set()
        
        # Check systemd user journal for application executions
        try:
            result = subprocess.run(
                ["journalctl", "--user", "-u", "*", "--since", "1 day ago", "--output=json"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0:
                for line in result.stdout.splitlines():
                    try:
                        entry = json.loads(line)
                        if "_SYSTEMD_UNIT" in entry:
                            unit = entry["_SYSTEMD_UNIT"]
                            if unit.endswith(".service"):
                                app_name = unit.replace(".service", "")
                                apps.add(app_name)
                    except json.JSONDecodeError:
                        continue
        except Exception as e:
            logger.warning(f"Error getting app usage from systemd journal: {e}")
            
        # Check .desktop file usage
        recent_files_path = os.path.expanduser("~/.local/share/recently-used.xbel")
        if os.path.exists(recent_files_path):
            try:
                # This is a simple approximation; real implementation would parse XML properly
                with open(recent_files_path, 'r') as f:
                    content = f.read()
                    for category in CATEGORIES.values():
                        for app in category:
                            if app in content:
                                apps.add(app)
            except Exception as e:
                logger.warning(f"Error parsing recently-used.xbel: {e}")
        
        return list(apps)
            
    def generate_recommendations(self) -> List[Dict]:
        """Generate application recommendations based on user profile and usage."""
        recommendations = []
        
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get installed apps and their categories
            cursor.execute("SELECT app_name, category, usage_count FROM installed_apps")
            installed_apps = cursor.fetchall()
            
            # Identify user's preferred categories
            categories = {}
            for _, category, usage_count in installed_apps:
                if category:
                    categories[category] = categories.get(category, 0) + usage_count
            
            # Sort categories by usage
            preferred_categories = sorted(
                categories.items(), 
                key=lambda x: x[1], 
                reverse=True
            )
            
            # Generate recommendations based on installed apps and categories
            installed_app_names = set(app[0] for app in installed_apps)
            
            # Clear previous recommendations
            cursor.execute("DELETE FROM recommendations")
            
            # For each preferred category, recommend related apps
            for category, _ in preferred_categories:
                if category in RECOMMENDATION_RULES:
                    for subcategory, apps in RECOMMENDATION_RULES[category].items():
                        for app in apps:
                            if app not in installed_app_names:
                                # Generate a reason for recommendation
                                reason = f"Recommended for {category}/{subcategory} based on your usage patterns"
                                score = 0.8  # Default score
                                
                                # Check hardware compatibility
                                if category == "hardware_specific":
                                    if subcategory == "amd_gpu" and not self._has_amd_gpu():
                                        continue
                                    if subcategory == "nvidia_gpu" and not self._has_nvidia_gpu():
                                        continue
                                    if subcategory == "intel_gpu" and not self._has_intel_gpu():
                                        continue
                                    if subcategory == "laptop" and not self._is_laptop():
                                        continue
                                
                                # Add to database
                                cursor.execute(
                                    """
                                    INSERT OR REPLACE INTO recommendations 
                                    (app_name, category, reason, score, recommendation_date) 
                                    VALUES (?, ?, ?, ?, ?)
                                    """,
                                    (app, category, reason, score, datetime.now().isoformat())
                                )
                                
                                recommendations.append({
                                    "app_name": app,
                                    "category": category,
                                    "reason": reason,
                                    "score": score
                                })
            
            conn.commit()
            
            # Get all recommendations from database for return
            cursor.execute(
                "SELECT app_name, category, reason, score FROM recommendations ORDER BY score DESC"
            )
            recs = cursor.fetchall()
            recommendations = [
                {
                    "app_name": app_name,
                    "category": category,
                    "reason": reason, 
                    "score": score
                }
                for app_name, category, reason, score in recs
            ]
            
            conn.close()
            
        except Exception as e:
            logger.error(f"Error generating recommendations: {e}")
            
        return recommendations
    
    def _has_amd_gpu(self) -> bool:
        """Check if the system has an AMD GPU."""
        try:
            result = subprocess.run(
                ["lspci"], capture_output=True, text=True, check=True
            )
            return "AMD" in result.stdout and ("VGA" in result.stdout or "Display" in result.stdout)
        except:
            return False
            
    def _has_nvidia_gpu(self) -> bool:
        """Check if the system has an NVIDIA GPU."""
        try:
            result = subprocess.run(
                ["lspci"], capture_output=True, text=True, check=True
            )
            return "NVIDIA" in result.stdout and ("VGA" in result.stdout or "Display" in result.stdout)
        except:
            return False
            
    def _has_intel_gpu(self) -> bool:
        """Check if the system has an Intel GPU."""
        try:
            result = subprocess.run(
                ["lspci"], capture_output=True, text=True, check=True
            )
            return "Intel" in result.stdout and ("VGA" in result.stdout or "Display" in result.stdout)
        except:
            return False
            
    def _is_laptop(self) -> bool:
        """Check if the system is a laptop."""
        try:
            # Check for battery
            result = subprocess.run(
                ["cat", "/sys/class/power_supply/*/type"], 
                capture_output=True, text=True, shell=True, check=False
            )
            return "Battery" in result.stdout
        except:
            return False
    
    def get_top_recommendations(self, limit: int = 10) -> List[Dict]:
        """Get the top N recommendations."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                """
                SELECT app_name, category, reason, score 
                FROM recommendations 
                ORDER BY score DESC 
                LIMIT ?
                """, 
                (limit,)
            )
            
            recommendations = [
                {
                    "app_name": app_name,
                    "category": category,
                    "reason": reason,
                    "score": score
                }
                for app_name, category, reason, score in cursor.fetchall()
            ]
            
            conn.close()
            return recommendations
            
        except Exception as e:
            logger.error(f"Error getting top recommendations: {e}")
            return []

def main():
    """Main function for the application recommender."""
    parser = argparse.ArgumentParser(description="AI-powered application recommendation engine")
    parser.add_argument("--scan", action="store_true", help="Scan installed applications")
    parser.add_argument("--usage", action="store_true", help="Scan application usage")
    parser.add_argument("--recommend", action="store_true", help="Generate recommendations")
    parser.add_argument("--show", action="store_true", help="Show top recommendations")
    parser.add_argument("--limit", type=int, default=10, help="Limit the number of recommendations")
    args = parser.parse_args()
    
    recommender = AppRecommender()
    
    if args.scan:
        recommender.scan_installed_applications()
        
    if args.usage:
        recommender.scan_application_usage()
        
    if args.recommend:
        recommender.generate_recommendations()
        
    if args.show or (not args.scan and not args.usage and not args.recommend):
        recommendations = recommender.get_top_recommendations(args.limit)
        print("\nTop Application Recommendations:")
        print("===============================")
        for i, rec in enumerate(recommendations, 1):
            print(f"{i}. {rec['app_name']} ({rec['category']})")
            print(f"   Reason: {rec['reason']}")
            print(f"   Score: {rec['score']:.2f}")
            print()

if __name__ == "__main__":
    main()