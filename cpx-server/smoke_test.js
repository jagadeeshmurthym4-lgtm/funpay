/**
 * Dependency-free smoke test for the CPX postback handler (cpx.js).
 *
 * Exercises the exact code path the Express route / Cloud Function wrapper
 * calls, using an in-memory fake Firestore. No Firebase or network needed.
 *
 * Run:  node smoke_test.js
 */

const assert = require('node:assert/strict');
const { md5, handleCpxPostback } = require('./cpx');

const SECRET = 'test-secret-value';

// ── Fake Firestore ────────────────────────────────────────────
const fakeFieldValue = {
  increment: (n) => ({ __op: 'increment', value: n }),
  serverTimestamp: () => new Date('2026-01-01T00:00:00.000Z'),
};

function createFakeDb() {
  const store = new Map();
  let autoId = 0;

  function ref(collection, id) {
    const key = `${collection}/${id}`;
    return {
      id,
      get: async () => ({ exists: store.has(key), data: () => store.get(key) }),
      set: async (data) => {
        store.set(key, data);
      },
      update: async (patch) => {
        const next = { ...(store.get(key) || {}) };
        for (const [k, v] of Object.entries(patch)) {
          if (v && v.__op === 'increment') next[k] = (next[k] ?? 0) + v.value;
          else next[k] = v;
        }
        store.set(key, next);
      },
    };
  }

  return {
    store,
    collection(name) {
      return { doc: (id) => ref(name, id ?? `auto-${++autoId}`) };
    },
    runTransaction: async (fn) => {
      // Note: real Firestore retries on write conflicts; this fake runs the
      // callback once, so the concurrent-double-credit race is NOT simulated.
      // The sequential duplicate case (guard prevents re-credit) is covered
      // by test 5 below.
      const tx = {
        get: async (r) => r.get(),
        set: async (r, data) => r.set(data),
        update: async (r, patch) => r.update(patch),
      };
      await fn(tx);
    },
    seed(collection, id, data) {
      store.set(`${collection}/${id}`, data);
    },
    get(collection, id) {
      return store.get(`${collection}/${id}`);
    },
    entries(collection) {
      const prefix = `${collection}/`;
      return [...store.entries()].filter(([k]) => k.startsWith(prefix));
    },
  };
}

const silentLogger = { log() {}, warn() {}, error() {} };

const makeReq = (query = {}, method = 'GET', body = undefined) => ({
  method,
  query,
  body,
});

const signed = (tx, user, amount) => ({
  transaction_id: tx,
  user_id: user,
  amount: String(amount),
  hash: md5(`${tx}-${SECRET}`),
});

const handler =
  (db, allowUnsigned = false) =>
  (req) =>
    handleCpxPostback({
      req,
      db,
      getConfig: () => ({ cpx: { secret: SECRET, allow_unsigned: String(allowUnsigned) } }),
      fieldValue: fakeFieldValue,
      messaging: { send: async () => {} },
      logger: silentLogger,
    });

// ── Tests ─────────────────────────────────────────────────────
async function run() {
  // 1. Valid signed postback credits the wallet (1:1) + records + notifies
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(makeReq(signed('tx-1', 'u1', 0.86)));
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 0.86);
    assert.equal(db.entries('transactions').length, 1);
    assert.equal(db.entries('transactions')[0][1].source, 'offerwall');
    assert.equal(db.entries('notifications').length, 1);
    assert.equal(db.get('cpx_transactions', 'tx-1').hashVerified, true);
    console.log('✓ valid signed postback credits wallet 1:1');
  }

  // 2. Invalid hash → 403, nothing written
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(
      makeReq({ transaction_id: 'tx-2', user_id: 'u1', amount: '1', hash: md5('forged') })
    );
    assert.equal(res.statusCode, 403);
    assert.equal(db.entries('wallets').length, 0);
    assert.equal(db.entries('cpx_transactions').length, 0);
    console.log('✓ invalid hash rejected with 403, no writes');
  }

  // 3. No secret configured → 503
  {
    const db = createFakeDb();
    const res = await handleCpxPostback({
      req: makeReq(signed('tx-3', 'u1', 1)),
      db,
      getConfig: () => ({ cpx: {} }),
      fieldValue: fakeFieldValue,
      messaging: { send: async () => {} },
      logger: silentLogger,
    });
    assert.equal(res.statusCode, 503);
    console.log('✓ missing secret returns 503');
  }

  // 4. Unknown user → 200, no phantom wallet
  {
    const db = createFakeDb();
    const res = await handler(db)(makeReq(signed('tx-4', 'ghost-user', 5)));
    assert.equal(res.statusCode, 200);
    assert.equal(db.entries('wallets').length, 0);
    assert.equal(db.entries('cpx_transactions').length, 0);
    console.log('✓ unknown user ignored, no phantom wallet');
  }

  // 5. Duplicate postback → no double-credit
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const h = handler(db);
    await h(makeReq(signed('tx-dup', 'u1', 2)));
    const balance = db.get('wallets', 'u1').walletBalance;
    const res = await h(makeReq(signed('tx-dup', 'u1', 2)));
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, balance);
    assert.equal(db.entries('transactions').length, 1);
    console.log('✓ duplicate postback does not double-credit');
  }

  // 6. Postback without hash is accepted by default (no verify needed)
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(makeReq({ transaction_id: 'tx-6', user_id: 'u1', amount: '3' }));
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 3);
    assert.equal(db.get('cpx_transactions', 'tx-6').hashVerified, false);
    console.log('✓ postback without hash accepted by default (no hash verification needed)');
  }

  // 7. Hash provided but invalid (and allowUnsigned=false) → 403
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(
      makeReq({ transaction_id: 'tx-7', user_id: 'u1', amount: '1', hash: md5('forged') })
    );
    assert.equal(res.statusCode, 403);
    assert.equal(db.entries('wallets').length, 0);
    assert.equal(db.entries('cpx_transactions').length, 0);
    console.log('✓ hash provided but invalid → 403');
  }

  // 8. Hash provided but invalid + allowUnsigned=true → 200 (skip verification)
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db, true)(
      makeReq({ transaction_id: 'tx-8', user_id: 'u1', amount: '1', hash: md5('forged') })
    );
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 1);
    assert.equal(db.get('cpx_transactions', 'tx-8').hashVerified, false);
    console.log('✓ invalid hash accepted when allowUnsigned=true (verification skipped)');
  }

  // 9. Missing params → 400
  {
    const db = createFakeDb();
    const res = await handler(db)(makeReq({ user_id: 'u1', amount: '1' }));
    assert.equal(res.statusCode, 400);
    console.log('✓ missing params return 400');
  }

  // 10. allowUnsigned=true + hash present + NO secret configured → 200 (never 503)
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handleCpxPostback({
      req: makeReq({ transaction_id: 'tx-10', user_id: 'u1', amount: '2.5', hash: md5('whatever') }),
      db,
      getConfig: () => ({ cpx: { allow_unsigned: 'true' } }), // no secret at all
      fieldValue: fakeFieldValue,
      messaging: { send: async () => {} },
      logger: silentLogger,
    });
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 2.5);
    console.log('✓ allowUnsigned=true skips verification even without CPX_SECRET (no 503)');
  }

  // 11. allowUnsigned=true + no hash → 200 credit (the Render scenario)
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db, true)(
      makeReq({ transaction_id: 'tx-11', user_id: 'u1', amount: '3.75' })
    );
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 3.75);
    assert.equal(db.entries('transactions').length, 1);
    console.log('✓ unsigned postback credited when allowUnsigned=true');
  }

  // 12. Non-credited status (pending) → 200 ack, no credit
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db, true)(
      makeReq({ transaction_id: 'tx-12', user_id: 'u1', amount: '1', status: 'pending' })
    );
    assert.equal(res.statusCode, 200);
    assert.equal(db.entries('wallets').length, 0);
    assert.equal(db.entries('cpx_transactions').length, 0);
    console.log('✓ pending status acknowledged but not credited');
  }

  // 13. Non-credited status (rejected) → 200 ack, no credit
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(
      makeReq({ transaction_id: 'tx-13', user_id: 'u1', amount: '1', status: 'rejected' })
    );
    assert.equal(res.statusCode, 200);
    assert.equal(db.entries('wallets').length, 0);
    console.log('✓ rejected status acknowledged but not credited');
  }

  // 14. completed/approved status → credited
  {
    const db = createFakeDb();
    db.seed('users', 'u1', { uid: 'u1' });
    const res = await handler(db)(
      makeReq({ transaction_id: 'tx-14', user_id: 'u1', amount: '4.2', status: 'completed' })
    );
    assert.equal(res.statusCode, 200);
    assert.equal(db.get('wallets', 'u1').walletBalance, 4.2);
    console.log('✓ completed status credited');
  }

  console.log('\nAll smoke tests passed ✅');
}

run().catch((err) => {
  console.error('Smoke test FAILED:', err);
  process.exit(1);
});
