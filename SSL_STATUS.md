
## SSL Certificate Summary

**Current Status:**
✅ HTTPS is working on library.cwis.org
⚠️  Using self-signed certificates (browsers will show 'Not Secure')
⚠️  Let's Encrypt certificates not being obtained automatically

**What's Configured:**
- ACME/Let's Encrypt: Enabled (USE_ACME=true)
- Email: sam@cwis.org
- Key Type: EC256
- HTTP Challenge: Enabled
- Certificate Resolver: Configured on routers

**Why Let's Encrypt Isn't Working:**
Traefik's ACME provider is running but not requesting certificates. Possible causes:
1. Traefik generates default cert before ACME can request
2. HTTP challenge handler not serving challenges properly
3. May need firewall/network configuration
4. Could be a Traefik version/configuration issue

**Next Steps to Get Let's Encrypt Working:**
1. Check firewall allows Let's Encrypt servers (port 80 from internet)
2. Verify DNS propagation (library.cwis.org → 209.188.114.51)
3. Consider using DNS challenge instead of HTTP challenge
4. Check Traefik documentation for ACME troubleshooting
5. May need to update Traefik version

**For Now:**
Site is accessible via HTTPS with self-signed certificates.
Users will see browser warning but can proceed.

