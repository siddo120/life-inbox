# Deploying Life Inbox to Vercel (with Neon Postgres)

Vercel is serverless and has **no persistent disk**, so the app uses a hosted
**Neon Postgres** database instead of the local SQLite file. The schema is
created automatically on first boot (`init_db()` runs `create_all`), so there is
no separate migration step to run in production.

Gmail sync is **not enabled in this deployment** (the OAuth token needs
persistent storage; that's a follow-up). Everything else — typed/voice capture,
file upload, AI organization, the day view — works.

## 1. Create a Neon database
1. Sign up at <https://neon.tech> and create a project (free tier is fine).
2. In the project, open **Connection Details** and copy the **pooled**
   connection string (the host contains `-pooler`). It looks like:
   ```
   postgresql://USER:PASSWORD@ep-xxxx-pooler.REGION.aws.neon.tech/neondb?sslmode=require
   ```
   Use the **pooled** string — serverless functions open many short-lived
   connections, and the pooler (PgBouncer) keeps Neon from running out.

## 2. Import the repo into Vercel
1. Sign in at <https://vercel.com> with your GitHub account.
2. **Add New → Project →** import `siddo120/life-inbox`.
3. Set the **Production Branch** to `gmail-inbound-sync` (or merge it to `main`
   first and deploy `main`).
4. Framework preset: **Other** (the included `vercel.json` handles routing).
   Leave build/output settings empty.

## 3. Set environment variables (Vercel → Settings → Environment Variables)
| Name | Value | Required |
|---|---|---|
| `DATABASE_URL` | your Neon **pooled** connection string | **Yes** — the app fails to boot without it |
| `OPENAI_API_KEY` | your OpenAI key | Yes, for AI parsing (without it the app uses the deterministic fallback) |
| `OPENAI_PARSE_MODEL` | `gpt-4o` | Optional (default) |
| `OPENAI_MODEL` | `gpt-4o-mini` | Optional (default) |

Add them to **Production** (and Preview if you want preview deploys to work).

## 4. Deploy
Click **Deploy**. On the first request the app connects to Neon and creates its
tables. Visit the deployment URL — you should see the Life Inbox capture screen.

### CLI alternative
```bash
npm i -g vercel
vercel          # link the project, first deploy (preview)
vercel --prod   # production deploy
```
Set the env vars with `vercel env add DATABASE_URL production` etc., or in the
dashboard.

## Notes & limits
- **`postgres://` URLs are handled automatically** — the app rewrites them to
  the psycopg driver (`postgresql+psycopg://`).
- **Static files** are served by FastAPI from the function (fine for this size).
- **Gmail** endpoints exist but will report "not configured" in production until
  token-in-DB storage is added.
- **Cold starts**: the first request after idle is slower while the function
  boots and connects to Neon.
- If you prefer a persistent long-running server over serverless, this same code
  runs as-is on Render/Railway/Fly with a disk or a Postgres add-on.
