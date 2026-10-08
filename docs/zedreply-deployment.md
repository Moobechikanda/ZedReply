# Zedreply Deployment Checklist

## Local startup

Run from the repository root:

```powershell
npm run dev
```

Open `http://localhost:3000` for agents and `http://localhost:8080/zedreply-customer-test.html` for the local customer test page.

Docker Desktop must be running. `npm run dev` starts the Docker services in the background.

`npm run dev` runs the code in this repository. It reuses the pulled `chatwoot/chatwoot` image for gems and the Ruby runtime, and bind-mounts `app/`, `enterprise/`, `config/`, `lib/`, `db/` and `public/vite` over it, so no image build is needed. Image builds fail whenever Docker Desktop cannot reach Alpine, RubyGems or the npm registry.

After changing Ruby, view or config files, run `npm run dev` again to pick them up.

## Local frontend changes

`public/vite` holds the compiled dashboard, widget and portal bundles, and it is not tracked by Git. Build it on the host after changing anything under `app/javascript`:

```powershell
npm run dev:assets
```

The build needs roughly 4 GB of heap and takes around 20 minutes on a memory constrained machine. Override with `NODE_OPTIONS` if needed, then run `npm run dev` again.

## Verifying the Captain business knowledge feature

Run Captain's self-check against the live database:

```powershell
npm run verify:business-knowledge
```

For a full picture of the whole feature set:

```powershell
npm run verify:zedreply
```

This is read-only and reports, per feature: the 8 business knowledge fields, the v1 and v2 prompts, the API strong params, the compiled frontend bundle, whether the website was crawled and how many knowledge responses were generated, and whether every fork feature (WhatsApp manual setup, inbox health, call recording, etc.) is loaded.

## Getting the AI chat working on the customer page

1. Set the OpenAI key. In the app go to **Super Admin → Settings → Config** and add:
   - Name: `CAPTAIN_OPEN_AI_API_KEY`, Value: `sk-...` (default model is `gpt-4.1-mini`).
2. Create a company. The Captain assistant, feature flags, and website crawl are provisioned automatically during onboarding. For an account that already exists, run:
   ```powershell
   npm run captain:provision
   ```
3. Complete the **Business knowledge** fields on the assistant (Captain → the assistant → Settings → Basic).
4. Send a test message from the playground or from `http://localhost:8080/zedreply-customer-test.html`. The assistant answers from the website + business knowledge and offers a human handoff when it cannot answer.

## AI

Configure the OpenAI Project API key through the Chatwoot Super Admin configuration or the protected Rails database configuration. Do not commit API keys or place them in a public file.

Recommended starting model: `gpt-4.1-mini`.

Create one Captain assistant per business or support policy, assign it to the correct inbox, and add the company's verified services, prices, hours, policies, and escalation rules before enabling customer replies.

For a company website, register it with the assistant from PowerShell:

```powershell
.\scripts\zedreply-add-website.ps1 -WebsiteUrl https://company.example
```

Captain queues the crawl and makes the synced website available to the assistant. Review the sync status and remove inaccurate pages before enabling automatic replies.

The assistant distinguishes the Zedreply platform from the current customer company. Company-specific answers must come from approved account knowledge or synced website documents.

## Channel credentials

Each channel has separate credentials. Zedreply does not use one universal social-media key.

| Channel | Credentials needed | Configuration location |
| --- | --- | --- |
| Website chat | Website domain and generated website token | Chatwoot Settings > Inboxes > Website |
| WhatsApp | Meta Business account, WhatsApp Business phone number, permanent access token, phone number ID, business account ID, webhook verification token | Chatwoot Settings > Inboxes > WhatsApp |
| Email | SMTP host, port, username, password, TLS mode, sender address; optional IMAP/inbound settings | `.env` for server mail settings and Chatwoot email inbox settings |
| SMS | Twilio or Bandwidth account SID, auth token, sender phone number, webhook URL | Chatwoot Settings > Inboxes > SMS |
| Telegram | Bot token from BotFather | Chatwoot Settings > Inboxes > Telegram |
| Facebook Messenger | Meta app ID, app secret, verify token, page access token | `.env` and Chatwoot Facebook inbox setup |
| Instagram | Meta app/page credentials and Instagram professional account | Meta setup and Chatwoot inbox setup |
| Slack | Client ID, client secret, signing secret, redirect URL | `.env` and Chatwoot Integrations |
| Google OAuth | Client ID, client secret, callback URL | `.env` |
| Cloud storage | S3 bucket, access key, secret key, region | `.env` |

Only configure channels a company actually uses. Empty optional values are expected for unused channels.

## Backups

For an early pilot, use a VPS provider with managed Postgres and S3-compatible object storage. Good options include:

- Hetzner or DigitalOcean VPS + managed PostgreSQL + Spaces/S3 storage
- AWS Lightsail or EC2 + RDS + S3
- Render or Railway for the application and managed PostgreSQL, where Chatwoot's runtime requirements are supported

Back up both PostgreSQL and `/app/storage`. Database backups alone do not protect uploaded attachments.

Recommended minimum policy:

- Daily automated PostgreSQL backups
- Object-storage versioning for uploaded files
- One weekly backup copied to a separate account or region
- Monthly restore test
- Secrets stored in the hosting provider's secret manager, not Git

## Production readiness

Before serving real customers:

1. Deploy behind HTTPS with a real domain.
2. Replace the demo Zedreply knowledge with verified company information.
3. Configure SMTP and test password resets.
4. Add real agents and define escalation ownership.
5. Connect one real channel and test webhooks.
6. Set OpenAI spending limits and usage alerts.
7. Enable database and storage backups.
8. Run a pilot with one company before adding more accounts.

## Account offboarding

To begin the existing delayed account-deletion workflow:

```powershell
.\scripts\zedreply-delete-account.ps1 -AccountId 2
```

The command requires typing `DELETE` and marks the account for deletion in seven days. This gives an administrator time to cancel the request before permanent cleanup runs.
