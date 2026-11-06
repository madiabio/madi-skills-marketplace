#!/usr/bin/env python3
"""Print the newest EliteMx OTP from LocalStack SES (local dev).

Usage: latest-otp.py [email]
Output: one line "<code>\t<recipient>\t<timestamp UTC>", or an error on stderr (exit 1).
LocalStack keeps sent mail at http://localhost:4667/_aws/ses (ADR-0046, no MailHog).
"""
import json
import re
import sys
import urllib.request

email = sys.argv[1].lower() if len(sys.argv) > 1 else None
try:
    with urllib.request.urlopen("http://localhost:4667/_aws/ses", timeout=5) as r:
        messages = json.load(r)["messages"]
except Exception as e:
    sys.exit(f"LocalStack SES unreachable on :4667 ({e}). Is the local stack up? (./local/scripts/up.sh)")

otps = []
for m in messages:
    match = re.search(r"\b(\d{6})\b", m.get("Subject", ""))
    to = m.get("Destination", {}).get("ToAddresses", [])
    if match and (email is None or email in (a.lower() for a in to)):
        otps.append((m.get("Timestamp", ""), match.group(1), ", ".join(to)))

if not otps:
    sys.exit("No OTP emails found" + (f" for {email}" if email else "") + ".")
ts, code, to = max(otps)
print(f"{code}\t{to}\t{ts}")
