# Nurse Singles Web Domain Setup

Firebase Hosting site:

- `nurse-singles-international`
- Live Firebase URL: `https://nurse-singles-international.web.app`

Custom domains created in Firebase Hosting:

- `nurse-singles.com`
- `www.nurse-singles.com`

Add these DNS records in Cloudflare with proxy status set to **DNS only** until Firebase shows the certificates as connected.

| Type | Name | Value |
| --- | --- | --- |
| A | `@` | `199.36.158.100` |
| TXT | `@` | `hosting-site=nurse-singles-international` |
| TXT | `_acme-challenge` | `BQXSxlko3LZWeWIss9aOmM-lL5I-j_SRsO5epXBbdTY` |
| CNAME | `www` | `nurse-singles-international.web.app` |
| TXT | `_acme-challenge.www` | `HBuQkulTcYE-vyw3rOqNJYeuUsloW5zDFotZ1rdai9s` |

After DNS propagates, check Firebase Hosting custom domain status. HTTPS can take time to provision after the records are visible.
