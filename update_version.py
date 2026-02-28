#!/usr/bin/env python3
"""
Update version for a Noctalia plugin across manifest.json and registry.json
Usage: python update_version.py <new_version> [plugin_name]
Examples: 
  python update_version.py 1.5.0              # Auto-detect plugin from current directory
  python update_version.py 1.5.0 yay-updater  # Specify plugin name
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone

def find_plugin_dir(plugin_name=None):
    """Find the plugin directory"""
    script_dir = Path(__file__).parent
    
    # If plugin name is specified, look for it
    if plugin_name:
        # Check if we're in the plugins root
        if (script_dir / plugin_name / "manifest.json").exists():
            return script_dir / plugin_name
        # Check if the script is in a plugin dir and they specified a different one
        if (script_dir.parent / plugin_name / "manifest.json").exists():
            return script_dir.parent / plugin_name
        raise FileNotFoundError(f"Plugin '{plugin_name}' not found")
    
    # Auto-detect: check if script is in a plugin directory
    if (script_dir / "manifest.json").exists():
        return script_dir
    
    raise FileNotFoundError(
        "Could not auto-detect plugin directory. "
        "Run from within a plugin directory or specify plugin name."
    )

def update_version(new_version, plugin_name=None):
    """Update version in manifest.json and registry.json"""
    
    # Get paths
    plugin_dir = find_plugin_dir(plugin_name)
    manifest_path = plugin_dir / "manifest.json"
    registry_path = plugin_dir.parent / "registry.json"
    
    # Update manifest.json
    print(f"Updating {manifest_path.name} in {plugin_dir.name}/...")
    with open(manifest_path, 'r') as f:
        manifest = json.load(f)
    
    plugin_id = manifest.get('id', 'unknown')
    old_version = manifest.get('version', 'unknown')
    manifest['version'] = new_version
    
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
        f.write('\n')
    
    print(f"  Plugin: {plugin_id}")
    print(f"  Version: {old_version} → {new_version}")
    
    # Update registry.json
    print(f"\nUpdating {registry_path.name}...")
    with open(registry_path, 'r') as f:
        registry = json.load(f)
    
    # Find and update the plugin entry
    updated = False
    for plugin in registry.get('plugins', []):
        if plugin.get('id') == plugin_id:
            old_reg_version = plugin.get('version', 'unknown')
            plugin['version'] = new_version
            plugin['lastUpdated'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
            updated = True
            print(f"  Registry entry: {old_reg_version} → {new_version}")
            print(f"  lastUpdated: {plugin['lastUpdated']}")
            break
    
    if not updated:
        print(f"  WARNING: Plugin '{plugin_id}' not found in registry.json!")
        return False
    
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2)
        f.write('\n')
    
    print(f"\n✓ Version updated to {new_version}")
    return True

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python update_version.py <new_version> [plugin_name]")
        print("\nExamples:")
        print("  python update_version.py 1.5.0              # Auto-detect from current directory")
        print("  python update_version.py 1.5.0 yay-updater  # Update specific plugin")
        sys.exit(1)
    
    new_version = sys.argv[1]
    plugin_name = sys.argv[2] if len(sys.argv) == 3 else None
    
    # Basic version validation
    parts = new_version.split('.')
    if len(parts) not in [2, 3] or not all(part.isdigit() for part in parts):
        print(f"Error: Invalid version format '{new_version}'")
        print("Version should be in format: X.Y or X.Y.Z (e.g., 1.5.0)")
        sys.exit(1)
    
    try:
        success = update_version(new_version, plugin_name)
        sys.exit(0 if success else 1)
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
