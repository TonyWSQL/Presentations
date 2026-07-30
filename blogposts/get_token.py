"""
Run once locally to get your OAuth2 refresh token.
DO NOT commit client_secret.json or the printed token to the repo.

Setup:
    pip install google-auth-oauthlib

Usage:
    python get_token.py path/to/client_secret.json
"""

import sys
from google_auth_oauthlib.flow import InstalledAppFlow

if len(sys.argv) != 2:
    print("Usage: python get_token.py <client_secret.json>")
    sys.exit(1)

flow = InstalledAppFlow.from_client_secrets_file(
    sys.argv[1],
    scopes=["https://www.googleapis.com/auth/blogger"]
)
creds = flow.run_local_server(port=0)

print("\n--- Copy these to GitHub Secrets ---")
print(f"GOOGLE_CLIENT_ID:      {creds.client_id}")
print(f"GOOGLE_CLIENT_SECRET:  {creds.client_secret}")
print(f"GOOGLE_REFRESH_TOKEN:  {creds.refresh_token}")
