#!/usr/bin/env bash
# =============================================================================
# One-shot Vercel deploy for Life Inbox.
#
#   1. Fill in DATABASE_URL in the repo-root .env file.
#   2. Run:  bash scripts/deploy_env.sh
#
# It installs the Vercel CLI (via npx, no global install), logs you in,
# links this folder to your Vercel project, pushes every variable from .env
# into Production/Preview/Development, and triggers a production redeploy.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ENV_FILE=".env"
VERCEL="npx --yes vercel@latest"

say() { printf "\n\033[1;36m==> %s\033[0m\n" "$1"; }
die() { printf "\n\033[1;31mERROR: %s\033[0m\n" "$1" >&2; exit 1; }

[ -f "$ENV_FILE" ] || die "No .env file found in $(pwd)."

# Read a KEY=value line from .env (value may contain '=', so keep everything
# after the first '='). Trims surrounding quotes if present.
read_env() {
  local key="$1" val
  val="$(grep -E "^${key}=" "$ENV_FILE" | head -1 | cut -d= -f2-)"
  val="${val%\"}"; val="${val#\"}"
  printf '%s' "$val"
}

DATABASE_URL="$(read_env DATABASE_URL)"
OPENAI_API_KEY="$(read_env OPENAI_API_KEY)"
OPENAI_PARSE_MODEL="$(read_env OPENAI_PARSE_MODEL)"
OPENAI_MODEL="$(read_env OPENAI_MODEL)"
GOOGLE_CLIENT_SECRET_JSON="$(read_env GOOGLE_CLIENT_SECRET_JSON)"
GMAIL_REDIRECT_URI="$(read_env GMAIL_REDIRECT_URI)"

[ -n "$DATABASE_URL" ]  || die "DATABASE_URL is empty in .env — paste your Neon pooled string and rerun."
[ -n "$OPENAI_API_KEY" ] || die "OPENAI_API_KEY is empty in .env."
case "$DATABASE_URL" in
  postgres://*|postgresql://*) : ;;
  *) die "DATABASE_URL does not look like a Postgres URL (should start with postgresql://).";;
esac

say "Logging in to Vercel (a browser window will open — approve it once)…"
$VERCEL whoami >/dev/null 2>&1 || $VERCEL login

say "Linking this folder to your Vercel project…"
$VERCEL link --yes >/dev/null

# Push one variable to all three environments, replacing any existing value.
push() {
  local key="$1" value="$2" env
  for env in production preview development; do
    $VERCEL env rm "$key" "$env" --yes >/dev/null 2>&1 || true
    printf '%s' "$value" | $VERCEL env add "$key" "$env" >/dev/null
  done
  printf "   set %s\n" "$key"
}

say "Pushing environment variables to Vercel…"
push DATABASE_URL       "$DATABASE_URL"
push OPENAI_API_KEY     "$OPENAI_API_KEY"
[ -n "$OPENAI_PARSE_MODEL" ]        && push OPENAI_PARSE_MODEL       "$OPENAI_PARSE_MODEL"
[ -n "$OPENAI_MODEL" ]              && push OPENAI_MODEL             "$OPENAI_MODEL"
[ -n "$GOOGLE_CLIENT_SECRET_JSON" ] && push GOOGLE_CLIENT_SECRET_JSON "$GOOGLE_CLIENT_SECRET_JSON"
[ -n "$GMAIL_REDIRECT_URI" ]        && push GMAIL_REDIRECT_URI       "$GMAIL_REDIRECT_URI"

say "Triggering a production deploy…"
$VERCEL --prod --yes

say "Done. Give it ~30s, then reload https://life-inbox-sigma.vercel.app/"
