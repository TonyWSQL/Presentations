"""
Publish or update a blog post to Blogger via the API.

Usage:
    python publish.py <path-to-post.json>

Required environment variables:
    BLOGGER_BLOG_ID        — numeric blog ID (visible in Blogger dashboard URL)
    GOOGLE_CLIENT_ID       — OAuth2 client ID from Google Cloud Console
    GOOGLE_CLIENT_SECRET   — OAuth2 client secret
    GOOGLE_REFRESH_TOKEN   — OAuth2 refresh token (obtained once via get_token.py)

The script checks blogposts/published.json for previously published post IDs
so re-running updates the existing post rather than creating a duplicate.
"""

import json
import os
import sys
from pathlib import Path
import urllib.request
import urllib.parse
import urllib.error

PUBLISHED_INDEX = Path(__file__).parent / "published.json"
BASE_URL = "https://www.googleapis.com/blogger/v3/blogs"
TOKEN_URL = "https://oauth2.googleapis.com/token"


def get_access_token():
    data = urllib.parse.urlencode({
        "client_id": os.environ["GOOGLE_CLIENT_ID"],
        "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
        "refresh_token": os.environ["GOOGLE_REFRESH_TOKEN"],
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request(TOKEN_URL, data=data, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]


def load_published():
    if PUBLISHED_INDEX.exists():
        return json.loads(PUBLISHED_INDEX.read_text())
    return {}


def save_published(index):
    PUBLISHED_INDEX.write_text(json.dumps(index, indent=2))


def api_request(method, url, body=None, token=None):
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        raise


def main():
    if len(sys.argv) != 2:
        print("Usage: publish.py <post.json>", file=sys.stderr)
        sys.exit(1)

    meta_path = Path(sys.argv[1])
    meta = json.loads(meta_path.read_text())
    html_path = meta_path.parent / meta["htmlFile"]
    content = html_path.read_text(encoding="utf-8")

    blog_id = os.environ["BLOGGER_BLOG_ID"]
    token = get_access_token()

    published = load_published()
    # Use subfolder/stem as key (e.g. "travel/2026-08-albany") to avoid
    # collisions if posts in different folders share a filename.
    post_key = f"{meta_path.parent.name}/{meta_path.stem}"

    post_body = {
        "title": meta["title"],
        "content": content,
        "labels": meta.get("labels", []),
    }
    if meta.get("publishedAt"):
        post_body["published"] = meta["publishedAt"]
    elif meta.get("updatePublishedDate"):
        from datetime import datetime, timezone
        post_body["published"] = datetime.now(timezone.utc).isoformat()

    if post_key in published:
        post_id = published[post_key]
        url = f"{BASE_URL}/{blog_id}/posts/{post_id}"
        result = api_request("PUT", url, post_body, token)
        print(f"Updated post: {result['url']}")
    else:
        url = f"{BASE_URL}/{blog_id}/posts/?isDraft=false"
        result = api_request("POST", url, post_body, token)
        published[post_key] = result["id"]
        save_published(published)
        print(f"Published post: {result['url']}")

    # Reset updatePublishedDate to false after publish so future pushes
    # don't keep bumping the date.
    if meta.get("updatePublishedDate"):
        meta["updatePublishedDate"] = False
        meta_path.write_text(json.dumps(meta, indent=2))


if __name__ == "__main__":
    main()
