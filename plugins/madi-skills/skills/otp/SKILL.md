---
name: otp
description: Fetch the latest EliteMx sign-in OTP from the local dev stack (LocalStack SES) so the user can sign in to localhost. Use when the user says "/otp", "get my OTP", "what's my sign-in code", or "OTP for elitemx localhost". Optional argument is an email to filter by.
---

# OTP

Local sends land in LocalStack's SES store, not a real inbox (ADR-0046, no MailHog).

1. Run `~/.claude/skills/otp/latest-otp.py [email]` (pass the email from the args if given). It prints `<code>\t<recipient>\t<timestamp UTC>`.
2. Reply in this shape and nothing more:

   > Your OTP is **882902**. It was sent to madi.abio@vptech.com.au at 01:15:43 UTC today.
   >
   > If it's expired, click resend and ask me again.

   Say "today" only if the timestamp's date is today in UTC; otherwise give the date. Codes expire after 10 minutes, so if the timestamp is older than that, say it has likely expired.

## If it fails

- **SES unreachable**: the local stack isn't running; tell the user to run `./local/scripts/up.sh`.
- **No OTP found**: fall back to BetterAuth's verification table (the code is written before the email is sent; `value` is `<code>:<attempts>`):
  `docker exec -e PGPASSWORD=dev elitemx-postgres-1 psql -U dev -d app_dev -t -c "select identifier, value, \"createdAt\" from verification where identifier like 'sign-in-otp-%' order by \"createdAt\" desc limit 1;"`
  If that is empty too, no code was requested. Sign-in is enumeration-safe, so an email with no user row silently sends nothing.
