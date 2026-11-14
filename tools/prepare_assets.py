#!/usr/bin/env python3
"""Package selected local CC0 glTF files as self-contained GLBs for M0/M1.

Raw packs must already be extracted outside the repository. No downloads occur.
Existing output files may only be reused when byte-identical.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
BASE = "Universal Base Characters[Standard]"
OUTFITS = "Modular Character Outfits - Fantasy[Standard]"
UAL1 = "Universal Animation Library[Standard]"
UAL2 = "Universal Animation Library 2[Standard]"


def selections():
    result = []
    for sex in ["Male", "Female"]:
        result.append((f"{BASE}/Base Characters/Godot - UE/Superhero_{sex}_FullBody.gltf",
                       f"assets/characters/base/superhero_{sex.lower()}.glb", "base_characters"))
        for outfit in ["Peasant", "Ranger"]:
            result.append((f"{OUTFITS}/Exports/glTF (Godot-Unreal)/Outfits/{sex}_{outfit}.gltf",
                           f"assets/characters/outfits/{sex.lower()}_{outfit.lower()}.glb", "fantasy_outfits"))
    for index, pack in [(1, UAL1), (2, UAL2)]:
        result.append((f"{pack}/Unreal-Godot/UAL{index}_Standard.glb",
                       f"assets/animations/ual{index}/ual{index}_standard.glb", f"ual{index}"))
    return result


def read_gltf(path):
    data = path.read_bytes()
    if path.suffix == ".glb":
        magic, version, size = struct.unpack_from("<III", data)
        if magic != 0x46546C67 or version != 2 or size != len(data):
            raise ValueError(f"Invalid GLB: {path}")
        length, kind = struct.unpack_from("<II", data, 12)
        if kind != 0x4E4F534A:
            raise ValueError("GLB missing JSON chunk")
        document = json.loads(data[20:20 + length])
        offset = 20 + length
        bin_length, bin_kind = struct.unpack_from("<II", data, offset)
        if bin_kind != 0x004E4942:
            raise ValueError("GLB missing binary chunk")
        binary = data[offset + 8:offset + 8 + bin_length]
    else:
        document = json.loads(data)
        if len(document["buffers"]) != 1:
            raise ValueError("Expected a single external buffer")
        binary = dependency(path, document["buffers"][0]["uri"]).read_bytes()
    return document, binary


def dependency(source, uri):
    path = (source.parent / unquote(uri)).resolve()
    if not path.is_relative_to(source.parent.resolve()):
        raise ValueError(f"Dependency escapes source folder: {uri}")
    # The supplied base pack references two names with an extra '_png' suffix.
    # Resolve only that exact export typo to an existing sibling texture.
    if not path.exists() and path.name.endswith("_png.png"):
        corrected = path.with_name(path.name.removesuffix("_png.png") + ".png")
        if corrected.is_file():
            return corrected
    return path


def package_glb(source):
    if source.suffix == ".glb":
        return source.read_bytes()
    document, buffer = read_gltf(source)
    binary = bytearray(buffer)
    views = document.setdefault("bufferViews", [])
    for image in document.get("images", []):
        if "uri" not in image:
            continue
        path = dependency(source, image.pop("uri"))
        payload = path.read_bytes()
        mime = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}[path.suffix.lower()]
        binary.extend(b"\0" * (-len(binary) % 4))
        image["bufferView"] = len(views)
        image["mimeType"] = mime
        views.append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(payload)})
        binary.extend(payload)
    document["buffers"] = [{"byteLength": len(binary)}]
    json_chunk = json.dumps(document, separators=(",", ":")).encode()
    json_chunk += b" " * (-len(json_chunk) % 4)
    binary.extend(b"\0" * (-len(binary) % 4))
    size = 12 + 8 + len(json_chunk) + 8 + len(binary)
    return (struct.pack("<III", 0x46546C67, 2, size)
            + struct.pack("<II", len(json_chunk), 0x4E4F534A) + json_chunk
            + struct.pack("<II", len(binary), 0x004E4942) + binary)


def write_new_or_identical(path, data):
    if path.exists() and path.read_bytes() != data:
        raise ValueError(f"Refusing to overwrite different output: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_bytes(data)


def rig(document, binary):
    skin = document["skins"][0]
    nodes = document["nodes"]
    joints = skin["joints"]
    joint_set = set(joints)
    parents = {child: index for index, node in enumerate(nodes) for child in node.get("children", [])}
    hierarchy = {nodes[index]["name"]: nodes[parents[index]]["name"]
                 if parents.get(index) in joint_set else None for index in joints}
    accessor = document["accessors"][skin["inverseBindMatrices"]]
    view = document["bufferViews"][accessor["bufferView"]]
    offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    matrices = {nodes[index]["name"]: struct.unpack_from("<16f", binary,
                offset + row * view.get("byteStride", 64)) for row, index in enumerate(joints)}
    return hierarchy, matrices


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", type=Path, default=Path.home() / "bp-assets-raw")
    args = parser.parse_args()
    entries = []
    reference = None
    for relative, target, pack in selections():
        source = args.raw / relative
        document, binary = read_gltf(source)
        hierarchy, matrices = rig(document, binary)
        if reference is None:
            reference = (hierarchy, matrices)
        delta = max(abs(a - b) for name, matrix in matrices.items()
                    for a, b in zip(matrix, reference[1][name]))
        output = package_glb(source)
        destination = ROOT / target
        write_new_or_identical(destination, output)
        # Confirm embedded GLB preserves every original accessor/buffer byte.
        packaged_document, packaged_buffer = read_gltf(destination)
        assert packaged_buffer[:len(binary)] == binary
        assert packaged_document["accessors"] == document["accessors"]
        entries.append({"source": relative, "path": target, "pack": pack,
                        "license": "CC0-1.0", "sha256": hashlib.sha256(output).hexdigest(),
                        "bytes": len(output), "joint_count": len(hierarchy),
                        "same_joint_hierarchy_as_first": hierarchy == reference[0],
                        "max_inverse_bind_delta_from_first": delta,
                        "texture_uri_fixes": {image["uri"]: dependency(source, image["uri"]).name
                            for image in document.get("images", []) if "uri" in image
                            and unquote(image["uri"]) != dependency(source, image["uri"]).name},
                        "animations": [clip["name"] for clip in document.get("animations", [])]})
        print(f"Prepared {target}: {len(output):,} bytes, {len(hierarchy)} joints")
    for pack, key, filename in [(BASE, "base_characters", "License_Standard.txt"),
                                (OUTFITS, "fantasy_outfits", "License_Standard.txt"),
                                (UAL1, "ual1", "License.txt"), (UAL2, "ual2", "License.txt")]:
        text = (args.raw / pack / filename).read_bytes()
        if b"CC0" not in text:
            raise ValueError(f"License not verified: {pack}")
        write_new_or_identical(ROOT / "assets/licenses" / f"{key}.txt", text)
    report = {"reference_rig": entries[0]["path"], "assets": entries,
              "limitations": ["Shared names and hierarchy do not imply identical bind poses.",
                              "Visual animation transfer and body clipping must be checked in M1.",
                              "Only ranger and peasant outfits are present in the free outfit pack."]}
    write_new_or_identical(ROOT / "docs/asset_manifest.json", (json.dumps(report, indent=2) + "\n").encode())
    print(f"Prepared {len(entries)} self-contained assets; source packs remain outside the repository.")


if __name__ == "__main__":
    main()
