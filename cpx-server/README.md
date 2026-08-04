# CPX Research Postback Server

Self-contained Express server that receives CPX Research survey-reward postbacks
and credits the user's wallet in Firestore — **no Firebase Cloud Functions
required** (works on the Spark free plan; deploy on Render's free tier).

All reward logic lives in `cpx.js`, shared with the Cloud Functions variant at
`functions/cpx.js`. Both are covered by the same smoke test.

## Deploy to Render — EASIEST (from this repo)

This folder lives inside the `cashspark` repo (already on GitHub). Render can
build just this folder as a brand-new service — no need to touch your existing
`cashspark-cpx-server` repo.

1. Push this repo to GitHub.
2. Render Dashboard → **New + → Web Service** → connect to the `funpay` repo:
   - **Root Directory:** `cpx-server`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
3. Set env vars (see `.env.example`):
   - `CPX_SECRET` — the postback verification secret (MUST match the "secure
     hash" configured in the CPX publisher dashboard).
   - `FIREBASE_SERVICE_ACCOUNT` — your Firebase service account key as a JSON
     string (or set `GOOGLE_APPLICATION_CREDENTIALS`).

A `render.yaml` blueprint at the repo root automates steps 2–3 via
**New + → Blueprint** (it prompts for `CPX_SECRET` and
`FIREBASE_SERVICE_ACCOUNT`).

### render.yaml (optional blueprint)

```yaml
services:
  - type: web
    name: cpx-postback-server
    runtime: node
    plan: free
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: CPX_SECRET
        sync: false      # set in the Render dashboard
      - key: FIREBASE_SERVICE_ACCOUNT
        sync: false
```

## Add the route to your EXISTING cpx-server instead (recommended)

If you already run the CashSpark backend on Render
(`cashspark-cpx-server.onrender.com`), drop in `route.js` (the one-line
integration — it already initializes Firebase Admin):

```js
// 1. Copy route.js + cpx.js into your server repo.
const { registerCpxPostback } = require('./route');

// 2. Register the postback endpoint — use whatever your server calls its
//    Firestore instance and firebase-admin import.
registerCpxPostback(app, {
  db: <your admin.firestore() instance>,
  admin: <your firebase-admin module>,
});
```

Then set `CPX_SECRET` (and optionally `CPX_ALLOW_UNSIGNED`) in that service's
env vars and redeploy. The route is registered at `/cpx/postback` (and
`/cpx-postback`) and deliberately does NOT require the app's `x-api-key` —
the postback `hash` is the authentication.

## CPX Research dashboard setup

1. Go to **publisher.cpx-research.com → Postback Settings**.
2. Set the **Main Postback URL** to:
   ```
   https://<your-render-service>.onrender.com/cpx/postback?trans_id={trans_id}&user_id={user_id}&amount={amount_local}&amount_usd={amount_usd}&status={status}&hash={hash}
   ```
   (If adding to the existing server: `https://cashspark-cpx-server.onrender.com/cpx/postback?...`)
3. Set the **secure hash** to the same value as `CPX_SECRET`.
4. The endpoint accepts GET or POST. Parameter aliases handled:
   `trans_id`/`transaction_id`, `user_id`/`ext_user_id`, `amount`/`payout`/
   `reward`/`verdienst_user_local_money`, `hash`.

## Notes

- **Payouts are 1:1** — the CPX `amount` is credited to the wallet as points.
- **Idempotent** — each `transaction_id` is credited once; retries are safe.
- **Hash formats** — accepts CPX's documented `md5("{value}-{secret}")` style
  plus common concatenations of `transaction_id`/`user_id`/`amount` with the
  secret (amount normalised to strip trailing zeros). If your account's exact
  formula differs, confirm it in the dashboard — only the concatenation order
  changes; the secret is the same.
- **Unsigned postbacks**: if the CPX account does not have "secure hash"
  enabled, postbacks arrive without a `hash` and are accepted automatically.
  Set `CPX_ALLOW_UNSIGNED=true` to skip hash verification **entirely** (no
  `403` even when a hash is missing or invalid). Set it to `false` once CPX
  starts sending valid hashes — verification re-enables automatically.
- **Status gate**: only `completed`/`approved` surveys are credited. Statuses
  like `pending`, `rejected`, `cancelled` are acknowledged (`200`) but not
  credited.

## Local testing

```bash
npm install
node smoke_test.js   # dependency-free tests of the handler logic
```
