import os
import shutil
import hashlib
import json
from datetime import datetime, timezone

os.makedirs("release_dist", exist_ok=True)
src_apk = os.path.join("build", "app", "outputs", "flutter-apk", "app-release.apk")
dest_apk = os.path.join("release_dist", "forma-v1.0.1.apk")

shutil.copyfile(src_apk, dest_apk)

with open(dest_apk, "rb") as f:
    sha = hashlib.sha256(f.read()).hexdigest().lower()

with open("release_dist/forma-v1.0.1.apk.sha256", "w", encoding="utf-8") as f:
    f.write(f"{sha}  forma-v1.0.1.apk\n")

meta = {
    "version": "1.0.1",
    "versionCode": 2,
    "tagName": "v1.0.1",
    "priority": "normal",
    "minSupportedVersion": "1.0.0",
    "apkFileName": "forma-v1.0.1.apk",
    "sha256": sha,
    "publishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
}

with open("release_dist/release-metadata.json", "w", encoding="utf-8") as f:
    json.dump(meta, f, indent=2)

changelog = f"""## What's Changed in FORMA v1.0.1

### Highlights & Features
- **In-App GitHub Update System**: Real-time progress bar, speed indicator, checksum integrity verification, and instant package installer handoff.
- **Smooth Page Transitions**: Fluid iOS/Cupertino physical slide with 20% parallax depth, subtle drop-shadow boundary, and clean reverse pop.
- **Enhanced Profile Picture System**: Offline Base64 fallback sync, resilient avatar preview, and camera capture support.
- **Upgraded Dependencies**: Upgraded core packages to latest compatible releases with zero static analysis warnings.
- **Production Release Signing**: Hardened Android release pipeline signed with permanent key.

### Verification
- **APK File:** `forma-v1.0.1.apk`
- **SHA-256 Checksum:** `{sha}`
- **Certificate SHA-256:** `86:8C:0D:B4:39:19:C6:A3:E8:32:58:98:38:CB:00:F3:FE:CE:48:E6:77:1D:9B:D1:05:6E:94:30:8B:93:09:53`
- **Certificate SHA-1:** `27:77:45:0F:5A:23:21:9B:A4:9E:4B:CE:EB:CD:6E:9D:CC:9C:C2:FA`
"""

with open("release_dist/CHANGELOG.md", "w", encoding="utf-8") as f:
    f.write(changelog)

print(f"Packaged release v1.0.1 successfully with SHA: {sha}")
