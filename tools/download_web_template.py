#!/usr/bin/env python3
"""
Downloads only the Web export templates for Godot 4.7.2
using HTTP range requests directly from GitHub releases.
"""

import os
import sys

# Ensure DLL path for Anaconda on Windows
_base_dir = os.path.dirname(sys.executable)
for _sub in ["Library/bin", "Library/mingw-w64/bin", "Library/usr/bin", "bin", ""]:
    _p = os.path.join(_base_dir, _sub.replace("/", os.sep))
    if os.path.isdir(_p):
        if hasattr(os, "add_dll_directory"):
            try:
                os.add_dll_directory(_p)
            except Exception:
                pass
        if _p not in os.environ.get("PATH", ""):
            os.environ["PATH"] = _p + os.pathsep + os.environ.get("PATH", "")

import urllib.request
import struct
import zlib

URL = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"

def main():
    print("Connecting to GitHub release for Godot 4.7.2 export templates...")
    req = urllib.request.Request(URL, method="HEAD")
    with urllib.request.urlopen(req) as resp:
        total_len = int(resp.headers["Content-Length"])
        final_url = resp.geturl()

    print(f"Archive total size: {total_len:,} bytes. Fetching EOCD...")
    # Fetch last 65536 bytes to find EOCD
    req = urllib.request.Request(final_url, headers={"Range": f"bytes={total_len - 65536}-{total_len - 1}"})
    with urllib.request.urlopen(req) as resp:
        tail = resp.read()

    eocd_pos = tail.rfind(b"PK\x05\x06")
    if eocd_pos == -1:
        print("ERROR: EOCD not found.")
        return

    disk, disk_cd, entries_disk, total_entries, cd_size, cd_offset = struct.unpack("<HHHHII", tail[eocd_pos+4:eocd_pos+20])
    print(f"Found central directory: {total_entries} entries, offset={cd_offset:,}, size={cd_size:,}")

    # Fetch central directory
    req = urllib.request.Request(final_url, headers={"Range": f"bytes={cd_offset}-{cd_offset + cd_size - 1}"})
    with urllib.request.urlopen(req) as resp:
        cd_data = resp.read()

    pos = 0
    entries = []
    while pos < len(cd_data) and cd_data[pos:pos+4] == b"PK\x01\x02":
        (
            sig, ver_made, ver_need, flags, comp_method, mod_time, mod_date,
            crc32, comp_size, uncomp_size, name_len, extra_len, comment_len,
            disk_num, int_attr, ext_attr, local_offset
        ) = struct.unpack("<IHHHHHHIIIHHHHHII", cd_data[pos:pos+46])
        name = cd_data[pos+46:pos+46+name_len].decode("utf-8", errors="ignore")
        entries.append({
            "name": name,
            "comp_method": comp_method,
            "comp_size": comp_size,
            "uncomp_size": uncomp_size,
            "offset": local_offset,
        })
        pos += 46 + name_len + extra_len + comment_len

    web_entries = [e for e in entries if "web" in e["name"].lower() and e["name"].endswith(".zip")]
    print(f"Found {len(web_entries)} Web template archives:")
    for e in web_entries:
        print(f"  - {e['name']} (comp: {e['comp_size']:,} bytes, uncomp: {e['uncomp_size']:,} bytes)")

    target_dir = os.path.expandvars(r"%APPDATA%\Godot\export_templates\4.7.2.stable")
    os.makedirs(target_dir, exist_ok=True)

    for e in web_entries:
        basename = os.path.basename(e["name"])
        dest_path = os.path.join(target_dir, basename)
        if os.path.exists(dest_path) and os.path.getsize(dest_path) == e["uncomp_size"]:
            print(f"Already downloaded: {basename}")
            continue

        print(f"\nDownloading {basename} (fetching ~{e['comp_size'] // 1024 // 1024} MB)...")
        # Read local header to get filename + extra field length
        req = urllib.request.Request(final_url, headers={"Range": f"bytes={e['offset']}-{e['offset'] + 30}"})
        with urllib.request.urlopen(req) as resp:
            lh = resp.read()
        n_len, ex_len = struct.unpack("<HH", lh[26:30])
        data_start = e["offset"] + 30 + n_len + ex_len
        data_end = data_start + e["comp_size"] - 1

        req = urllib.request.Request(final_url, headers={"Range": f"bytes={data_start}-{data_end}"})
        with urllib.request.urlopen(req) as resp:
            compressed_data = resp.read()

        if e["comp_method"] == 0:
            payload = compressed_data
        elif e["comp_method"] == 8:
            decompressor = zlib.decompressobj(-zlib.MAX_WBITS)
            payload = decompressor.decompress(compressed_data)
        else:
            print(f"Unsupported compression method: {e['comp_method']}")
            continue

        with open(dest_path, "wb") as f:
            f.write(payload)

        print(f"Saved: {dest_path} ({len(payload):,} bytes)")

    # Also extract version.txt if available
    v_entry = next((e for e in entries if e["name"].endswith("version.txt")), None)
    if v_entry:
        v_path = os.path.join(target_dir, "version.txt")
        req = urllib.request.Request(final_url, headers={"Range": f"bytes={v_entry['offset']}-{v_entry['offset'] + 30}"})
        with urllib.request.urlopen(req) as resp:
            lh = resp.read()
        n_len, ex_len = struct.unpack("<HH", lh[26:30])
        data_start = v_entry["offset"] + 30 + n_len + ex_len
        data_end = data_start + v_entry["comp_size"] - 1
        req = urllib.request.Request(final_url, headers={"Range": f"bytes={data_start}-{data_end}"})
        with urllib.request.urlopen(req) as resp:
            v_data = resp.read()
        if v_entry["comp_method"] == 8:
            v_data = zlib.decompressobj(-zlib.MAX_WBITS).decompress(v_data)
        with open(v_path, "wb") as f:
            f.write(v_data)
        print("Saved: version.txt")

    print("\n[OK] All Web export templates ready!")

if __name__ == "__main__":
    main()
