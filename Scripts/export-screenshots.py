#!/usr/bin/env python3
"""Exports the screenshots in a UI test result bundle, using each attachment's name.

usage: export-screenshots.py <result.xcresult> <output-directory>

The screenshot tests name each attachment, for example "home". Those names become the file names.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bundle, output = sys.argv[1], pathlib.Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        subprocess.check_call(
            ["xcrun", "xcresulttool", "export", "attachments", "--path", bundle, "--output-path", temporary]
        )
        manifest = json.loads((pathlib.Path(temporary) / "manifest.json").read_text())
        count = 0
        for test in manifest:
            for attachment in test.get("attachments", []):
                name = attachment.get("suggestedHumanReadableName", attachment["exportedFileName"])
                # Names look like "home_0_<identifier>.png", so keep the part before the suffix.
                stem = name.split("_")[0]
                target = output / f"{stem}{pathlib.Path(name).suffix}"
                shutil.copy(pathlib.Path(temporary) / attachment["exportedFileName"], target)
                count += 1
        print(f"Exported {count} screenshots to {output}")


if __name__ == "__main__":
    main()
