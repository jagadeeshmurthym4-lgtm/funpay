/**
 * CPX Research postback server (Express) — standalone service for Render.
 *
 * Exposes the CPX survey-reward postback endpoint without needing Firebase
 * Cloud Functions (which require the Blaze plan). All reward logic lives in
 * ./cpx.js (shared with functions/cpx.js) and is unit-tested in smoke_test.js.
 *
 * Postback URL to configure in the CPX publisher dashboard (Postback Settings):
 *
 *   https://<your-render-service>.onrender.com/cpx/postback?trans_id={trans_id}&user_id={user_id}&amount={amount_local}&amount_usd={amount_usd}&status={status}&hash={hash}
 *
 * Env vars:
 *   CPX_SECRET           — postback verification secret (must match the
 *                          "secure hash" configured in the CPX dashboard)
 *   CPX_ALLOW_UNSIGNED   — "true" only for dev; accept postbacks without a hash
 *   FIREBASE_SERVICE_ACCOUNT — JSON string of the service account (preferred)
 *   GOOGLE_APPLICATION_CREDENTIALS — path to a service account key file
 *   PORT                 — defaults to 3001
 */

const express = require('express');
const admin = require('firebase-admin');

const { handleCpxPostback } = require('./cpx');

// ── Firebase Admin ───────────────────────────────────────────
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    admin.initializeApp({
      credential: admin.credential.cert(
        JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
      ),
    });
  } else {
    // Falls back to GOOGLE_APPLICATION_CREDENTIALS (Render free tier has no
    // metadata server, so applicationDefault requires that env var).
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
} catch (error) {
  console.error('Firebase Admin failed to initialize:', error.message);
  console.error('Set FIREBASE_SERVICE_ACCOUNT (JSON string) or GOOGLE_APPLICATION_CREDENTIALS.');
  process.exit(1);
}

const db = admin.firestore();

// ── Express app ──────────────────────────────────────────────
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (_req, res) => res.send('CPX Research postback server OK'));
app.get('/health', (_req, res) =>
  res.json({
    status: 'ok',
    firebaseInitialized: true,
    timestamp: new Date().toISOString(),
  })
);

/**
 * CPX Research S2S postback (accepts GET query params and POST JSON/form).
 *
 * NOTE: this route intentionally does NOT require the app's x-api-key header —
 * CPX's servers call it directly and authentication is the postback `hash`
 * (verified server-side with CPX_SECRET).
 */
app.all(['/cpx/postback', '/cpx-postback'], async (req, res) => {
  try {
    const result = await handleCpxPostback({
      req,
      db,
      getConfig: () => ({
        cpx: {
          secret: process.env.CPX_SECRET || '',
          allow_unsigned: process.env.CPX_ALLOW_UNSIGNED === 'true' ? 'true' : 'false',
        },
      }),
      fieldValue: admin.firestore.FieldValue,
      messaging: admin.messaging(),
    });

    res.status(result.statusCode).send(result.body);
  } catch (error) {
    // Express 4 does not catch rejected promises from async handlers — if
    // anything outside handleCpxPostback's internal try/catch throws (e.g. a
    // Firestore read), always answer 500 so CPX retries. The idempotency
    // guard keeps retries safe.
    console.error('CPX: unhandled postback error:', error);
    res.status(500).send('Internal error');
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`CPX Research postback server listening on port ${PORT}`);
});
