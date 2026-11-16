import os
import sys
import json
import urllib.request
import urllib.error
import subprocess

def get_github_token():
    # Attempt to retrieve token from git credential manager
    try:
        p = subprocess.Popen(
            ['git', 'credential', 'fill'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = p.communicate(input="protocol=https\nhost=github.com\n\n", timeout=5)
        creds = {}
        for line in stdout.splitlines():
            if '=' in line:
                k, v = line.split('=', 1)
                creds[k.strip()] = v.strip()
        if 'password' in creds and creds['password']:
            return creds['password']
    except Exception as e:
        print(f"Error fetching credentials from git: {e}")
    
    # Fallback to env var
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        return token
    raise RuntimeError("No GitHub token found via git credential fill or environment variables.")

def api_request(url, token, data=None, headers=None, method=None):
    req_headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "FORMA-Release-Publisher",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    if headers:
        req_headers.update(headers)
    
    body = None
    if data is not None:
        if isinstance(data, (dict, list)):
            body = json.dumps(data).encode('utf-8')
            req_headers["Content-Type"] = "application/json"
        elif isinstance(data, bytes):
            body = data
        elif isinstance(data, str):
            body = data.encode('utf-8')
    
    req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read()
            if response.status == 204 or not res_body:
                return {}
            return json.loads(res_body.decode('utf-8'))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8', errors='ignore')
        return {"error_status": e.code, "error_message": err_msg}

def main():
    repo = "anandakrishnano-bit/FORMA"
    tag = "v1.0.1"
    release_name = "FORMA v1.0.1 - Bug Reporting, Smooth Transitions & Auto-Updates"
    
    changelog_path = os.path.join("release_dist", "CHANGELOG.md")
    if os.path.exists(changelog_path):
        with open(changelog_path, "r", encoding="utf-8") as f:
            body_content = f.read()
    else:
        body_content = f"Release {tag} for FORMA app."

    print("Retrieving GitHub credentials...")
    token = get_github_token()
    
    # Check user identity
    user_info = api_request("https://api.github.com/user", token)
    if "login" in user_info:
        print(f"Authenticated as: {user_info['login']}")
    else:
        print("Warning: Could not verify user info:", user_info)

    # Check if release exists for tag
    print(f"Checking if release exists for tag {tag}...")
    release_check = api_request(f"https://api.github.com/repos/{repo}/releases/tags/{tag}", token)
    
    release_id = None
    if "id" in release_check:
        release_id = release_check["id"]
        print(f"Found existing release with ID: {release_id}")
    else:
        print(f"Creating new GitHub release for {tag}...")
        create_payload = {
            "tag_name": tag,
            "target_commitish": "master",
            "name": release_name,
            "body": body_content,
            "draft": False,
            "prerelease": False
        }
        create_res = api_request(f"https://api.github.com/repos/{repo}/releases", token, data=create_payload, method="POST")
        if "id" in create_res:
            release_id = create_res["id"]
            print(f"Created release successfully with ID: {release_id}")
        else:
            print("Failed to create release:", create_res)
            sys.exit(1)

    # Fetch release details to inspect existing assets
    rel_details = api_request(f"https://api.github.com/repos/{repo}/releases/{release_id}", token)
    existing_assets = {a["name"]: a["id"] for a in rel_details.get("assets", [])}
    print(f"Existing assets in release: {list(existing_assets.keys())}")

    # Files to upload
    files_to_upload = [
        ("forma-v1.0.1.apk", "application/vnd.android.package-archive"),
        ("forma-v1.0.1.apk.sha256", "text/plain"),
        ("release-metadata.json", "application/json")
    ]

    for filename, content_type in files_to_upload:
        filepath = os.path.join("release_dist", filename)
        if not os.path.exists(filepath):
            print(f"Warning: File {filepath} does not exist, skipping.")
            continue
        
        # If asset already exists, delete it first
        if filename in existing_assets:
            asset_id = existing_assets[filename]
            print(f"Deleting existing asset '{filename}' (ID: {asset_id})...")
            del_res = api_request(f"https://api.github.com/repos/{repo}/releases/assets/{asset_id}", token, method="DELETE")
            print(f"Delete response: {del_res}")

        file_size = os.path.getsize(filepath)
        print(f"Uploading '{filename}' ({file_size} bytes) with MIME '{content_type}'...")
        with open(filepath, "rb") as f:
            file_bytes = f.read()

        upload_url = f"https://uploads.github.com/repos/{repo}/releases/{release_id}/assets?name={filename}"
        upload_res = api_request(
            upload_url,
            token,
            data=file_bytes,
            headers={"Content-Type": content_type, "Content-Length": str(file_size)},
            method="POST"
        )
        if "id" in upload_res:
            print(f"Successfully uploaded {filename} (Asset ID: {upload_res['id']})")
        else:
            print(f"Error uploading {filename}:", upload_res)

    print("\nRelease verification:")
    final_rel = api_request(f"https://api.github.com/repos/{repo}/releases/{release_id}", token)
    html_url = final_rel.get("html_url", f"https://github.com/{repo}/releases/tag/{tag}")
    print(f"Release URL: {html_url}")
    print(f"Assets uploaded: {[a['name'] for a in final_rel.get('assets', [])]}")

if __name__ == "__main__":
    main()
