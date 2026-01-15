# Quick Guide: Site123 TXT Record Configuration

## Overview
This guide helps you configure DNS TXT records in Site123 for domain verification.

## Quick Steps

1. **Get Your Verification Code**
   - Log in to Site123
   - Go to Settings > Domain
   - Click "Connect Domain"
   - Copy the TXT record value provided

2. **Add TXT Record to Your DNS**
   - Go to your domain registrar (GoDaddy, Namecheap, etc.)
   - Access DNS settings
   - Add a new TXT record:
     - **Type**: TXT
     - **Host**: @ (or blank)
     - **Value**: [paste the verification code from Site123]
     - **TTL**: 3600 (or default)

3. **Verify in Site123**
   - Return to Site123
   - Click "Verify Domain"
   - Wait for DNS propagation (5-60 minutes)

## Example TXT Record

```
Type: TXT
Host: @
Value: site123-verify=abc123xyz789...
TTL: 3600
```

## Common Issues

- **Not verifying?** Wait up to 48 hours for DNS propagation
- **Error message?** Double-check there are no extra spaces in the value
- **Still not working?** Clear your DNS cache and try again

## Need More Help?

See the complete guide in `SITE123_DOMAIN_SETUP.md` for detailed instructions and troubleshooting.

---

**Important**: The TXT record value is unique to your domain and provided by Site123 during domain setup.
