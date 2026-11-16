#!/usr/bin/env python3
"""Run project import, GUT, all-script parse check, and 600-tick smoke test."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PINNED_VERSION = "4.7.2.stable.official.ed1daf0bf"
DEFAULT_BINARY = Path.home() / "Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"


def run(label, command, env, marker=None, timeout=120):
    print(f"\n{label}", flush=True)
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    output = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
    log_path = ROOT / ".local" / (label.lower().replace(" ", "-") + ".log")
    log_path.write_text(output)
    lines = output.splitlines()
    if len(lines) > 65:
        print(f"Full output: {log_path}", flush=True)
        for line in lines:
            if "ERROR:" in line or "at: " in line:
                print(line)
        print("\n".join(lines[-20:]), flush=True)
    else:
        print(output, end="", flush=True)
    errors = ("SCRIPT ERROR:", "ERROR:", "Parse Error", "Failed to load script")
    # The managed Windows sandbox can deny querying the system certificate
    # store. The game is offline-only; this does not affect import or runtime.
    actionable_output = "\n".join(
        line for line in output.splitlines()
        if "Failed to read the root certificate store." not in line
        and "at: get_system_ca_certificates" not in line
    )
    if result.returncode or any(message in actionable_output for message in errors):
        raise RuntimeError(f"{label} failed (exit {result.returncode})")
    if marker and marker not in result.stdout:
        raise RuntimeError(f"{label} did not report completion")


def main():
    binary = os.environ.get("GODOT_BIN") or (str(DEFAULT_BINARY) if DEFAULT_BINARY.is_file()
                                            else shutil.which("godot") or shutil.which("godot4"))
    if not binary:
        raise RuntimeError("Godot not found. Set GODOT_BIN to the Godot 4.7.2 executable.")
    env = os.environ.copy()
    # Keep verification writes inside the project, away from existing app configs.
    for variable, folder in [("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                             ("XDG_CACHE_HOME", "cache")]:
        path = ROOT / ".local" / folder
        path.mkdir(parents=True, exist_ok=True)
        env[variable] = str(path)
    if sys.platform == "win32":
        # Godot uses APPDATA for editor settings and user:// logs on Windows;
        # XDG paths alone do not redirect those writes.
        for variable, folder in [("APPDATA", "appdata"), ("LOCALAPPDATA", "localappdata")]:
            path = ROOT / ".local" / folder
            path.mkdir(parents=True, exist_ok=True)
            env[variable] = str(path)
    version = subprocess.check_output([binary, "--version"], text=True, env=env).strip()
    if version != PINNED_VERSION:
        raise RuntimeError(f"Expected {PINNED_VERSION}; got {version}")
    common = [binary, "--headless", "--path", str(ROOT)]
    gut_command = common + ["--script", "res://addons/gut/gut_cmdln.gd"]
    if sys.platform != "win32":
        # Keep the prior fixed render delta on Linux; on Windows it makes
        # frame-driven GUT tests wait in real time and destabilizes their timing.
        gut_command += ["--fixed-fps", "60"]
    checks = [
        ("Import and editor parse", common + ["--import"], None),
        ("All-script parse", common + ["--script", "res://tools/parse_all.gd"], "PARSE PASS:"),
        ("Stock asset imports", common + ["--script", "res://tools/check_assets.gd"], "ASSETS PASS:"),
        ("GUT suite", gut_command, "All tests passed!"),
        ("600-tick main-scene smoke test", common + ["--script", "res://tools/smoke.gd",
            "--fixed-fps", "60"], "SMOKE PASS:"),
    ]
    checks.append(("600-tick Hunter smoke test", common + ["--script", "res://tools/smoke_hunter.gd", "--fixed-fps", "60"], "SMOKE PASS:"))
    checks.append(("600-tick Challenge smoke test", common + ["--script", "res://tools/smoke_challenge.gd", "--fixed-fps", "60"], "SMOKE PASS:"))
    failures = []
    for label, command, marker in checks:
        try:
            run(label, command, env, marker, timeout=1200 if label == "GUT suite" else 120)
        except (RuntimeError, OSError, subprocess.SubprocessError) as error:
            failures.append(str(error))
            print(f"CHECK FAILED: {error}", flush=True)
    if failures:
        raise RuntimeError("; ".join(failures))
    print("\nVERIFICATION PASSED")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError) as error:
        print(f"VERIFICATION FAILED: {error}", file=sys.stderr)
        sys.exit(1)
