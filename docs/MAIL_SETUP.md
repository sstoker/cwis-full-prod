# Mail Server Setup (Postfix)

Production mail is configured using **Postfix** as an SMTP relay and **Drupal Symfony Mailer** for sending.

## Architecture

```
Drupal → Symfony Mailer (smtp://postfix:25) → Postfix → [External relay or local]
```

## What's Configured

- **Postfix container**: Accepts mail from Drupal on port 25, relays to external SMTP (optional)
- **Drupal**: Uses Symfony Mailer (Drupal 10 core) to send via `postfix:25`
- **Default**: Without relay config, Postfix delivers locally (useful for testing)

## Enabling External Relay (Production)

**Important:** Without an external relay, emails are delivered locally only and will not reach user inboxes (e.g. password reset, new user notifications). The `.env` file already has `MAIL_RELAYHOST`, `MAIL_RELAYHOST_USERNAME`, and `MAIL_RELAYHOST_PASSWORD`—add your credentials to enable delivery.

1. Edit `.env` and set your SMTP relay values:
   ```
   MAIL_RELAYHOST=[smtp.sendgrid.net]:587
   MAIL_RELAYHOST_USERNAME=apikey
   MAIL_RELAYHOST_PASSWORD=your-sendgrid-api-key
   ```

   **Common relay providers:**
   - **SendGrid**: `[smtp.sendgrid.net]:587`, username `apikey`, password = API key (100 emails/day free)
   - **Mailgun**: `[smtp.mailgun.org]:587`, use your SMTP credentials
   - **Amazon SES**: `[email-smtp.REGION.amazonaws.com]:587`
   - **Organization SMTP**: Check with IT for `smtp.yourdomain.org` and credentials

2. Update `MAIL_ALLOWED_DOMAINS` if needed (comma-separated):
   ```
   MAIL_ALLOWED_DOMAINS=localhost,library.cwis.org,yourdomain.com
   ```

3. Restart Postfix to apply changes:
   ```bash
   docker compose up -d postfix
   ```

## Applying Changes

After updating `default_settings.txt` or mail config:

1. **Rebuild the Drupal image** (mail config is in settings):
   ```bash
   make build
   ```

2. **Copy updated default_settings to codebase** (if using `make local`):
   ```bash
   cp default_settings.txt ./codebase/assets/patches/
   ```

3. **Restart containers**:
   ```bash
   docker compose up -d
   ```

## Testing Mail

1. Use Drupal's contact form or password reset
2. Or test via Drush:
   ```bash
   docker compose exec drupal drush php:eval "
     \Drupal::service('plugin.manager.mail')->mail('system', 'test', 'you@example.com', 'en', [], NULL, TRUE);
   "
   ```

## Troubleshooting

- **Mail not sending**: Check Postfix logs: `docker compose logs postfix`
- **Relay errors**: Verify `MAIL_RELAYHOST`, username, and password in `.env`
- **Spam folder**: Use a reputable relay (SendGrid, Mailgun) and configure SPF/DKIM for your domain
