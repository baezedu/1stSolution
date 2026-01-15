# Site123 Domain Verification - TXT Record Setup

This document explains how to configure DNS TXT records in Site123 for domain verification when hosting the DOGO2 application.

## What is a TXT Record?

A TXT (Text) record is a type of DNS record that contains text information for sources outside your domain. It's commonly used for domain verification, email authentication (SPF, DKIM), and site ownership verification.

## How to Add a TXT Record in Site123

Follow these steps to add a TXT record for domain verification in Site123:

### Step 1: Access Site123 Settings

1. Log in to your [Site123 account](https://www.site123.com)
2. Go to your site's **Dashboard**
3. Navigate to **Settings** > **Domain**

### Step 2: Connect Your Custom Domain

1. Click on **Connect Domain** or **Custom Domain**
2. Enter your domain name (e.g., `yourdomain.com`)
3. Site123 will provide you with DNS configuration instructions

### Step 3: Add the TXT Record

1. Open your domain registrar's DNS management panel (e.g., GoDaddy, Namecheap, Google Domains, etc.)
2. Navigate to the DNS settings or DNS zone editor
3. Click **Add Record** or **Add DNS Record**
4. Select **TXT** as the record type
5. Configure the TXT record with the following details:

   | Field | Value |
   |-------|-------|
   | **Type** | TXT |
   | **Host/Name** | @ (or leave blank for root domain) |
   | **Value/Data** | The verification code provided by Site123 |
   | **TTL** | 3600 (or default) |

### Step 4: Save and Verify

1. **Save** the DNS record changes
2. Return to Site123
3. Click **Verify** or **Check DNS**
4. Wait for DNS propagation (typically 5-60 minutes, but can take up to 48 hours)

## Common TXT Record Values for Site123

Site123 may require one or more of the following TXT records:

### Domain Verification
```
Name: @ or yourdomain.com
Value: site123-verify=XXXXXXXXXXXXXXXXXXXXXXXX
```

### Email Authentication (SPF)
```
Name: @ or yourdomain.com
Value: v=spf1 include:_spf.site123.com ~all
```

### DKIM Record
```
Name: default._domainkey
Value: [DKIM key provided by Site123]
```

## Troubleshooting

### DNS Not Propagating

- **Wait longer**: DNS changes can take up to 48 hours to propagate globally
- **Clear DNS cache**: 
  - Windows: `ipconfig /flushdns`
  - macOS: `sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder`
  - Linux: `sudo systemd-resolve --flush-caches` (systemd) or `sudo /etc/init.d/nscd restart` (nscd)
- **Check DNS propagation**: Use [whatsmydns.net](https://www.whatsmydns.net) to verify

### Verification Failing

- **Double-check the value**: Ensure there are no extra spaces or characters
- **Check the host name**: Make sure you're using `@` or blank for the root domain
- **Remove old records**: Delete any conflicting TXT records
- **Contact support**: Reach out to Site123 support if issues persist

### Multiple TXT Records

Some domain registrars allow multiple TXT records for the same host. If you need to add multiple verification codes:

1. Don't delete existing TXT records (especially SPF, DKIM, or other verifications)
2. Add the new TXT record as an additional entry
3. Each TXT record should be on its own line

## Verification Code Location

The verification code that Site123 provides will be displayed:

- In the Site123 dashboard under **Settings** > **Domain** > **Verification**
- In an email sent to your registered email address
- On the domain connection page after entering your domain name

## Example: Complete DNS Configuration

Here's an example of what your DNS records might look like after configuration:

```
Type    Host              Value                                          TTL
----    ----              -----                                          ---
TXT     @                 site123-verify=abc123def456ghi789              3600
TXT     @                 v=spf1 include:_spf.site123.com ~all          3600
A       @                 35.201.97.12                                   3600
CNAME   www               yourdomain.site123.me                          3600
```

## Additional Resources

- [Site123 Support Documentation](https://www.site123.com/support)
- [DNS Record Types Explained](https://www.cloudflare.com/learning/dns/dns-records/)
- [Check DNS Propagation](https://www.whatsmydns.net/)

## Support

If you need assistance with domain verification:

1. Contact Site123 support through their help center
2. Consult your domain registrar's documentation for DNS management
3. Check Site123 community forums for common issues and solutions

---

**Note**: The specific TXT record value will be unique to your domain and will be provided by Site123 during the domain connection process. Never share your verification codes publicly.
