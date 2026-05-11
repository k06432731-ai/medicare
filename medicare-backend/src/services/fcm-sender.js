'use strict';

/**
 * Send a push notification to a specific user via FCM.
 * Requires the FIREBASE_SERVICE_ACCOUNT env var (JSON) for the admin SDK.
 *
 * Falls back to no-op if Firebase is not configured.
 */

let admin = null;
let initialized = false;

function init() {
  if (initialized) return admin;
  initialized = true;

  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccount) {
    console.warn('[FCM] FIREBASE_SERVICE_ACCOUNT not set — push notifications disabled');
    return null;
  }

  try {
    admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(serviceAccount)),
      });
    }
    return admin;
  } catch (e) {
    console.warn('[FCM] firebase-admin not installed or invalid service account:', e.message);
    return null;
  }
}

async function sendToUser(fcmToken, { title, body, data = {} }) {
  const a = init();
  if (!a || !fcmToken) return { sent: false, reason: 'fcm-not-configured-or-no-token' };

  try {
    const message = {
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      token: fcmToken,
    };
    const response = await a.messaging().send(message);
    return { sent: true, response };
  } catch (e) {
    console.error('[FCM] send failed:', e.message);
    return { sent: false, error: e.message };
  }
}

module.exports = { sendToUser };
