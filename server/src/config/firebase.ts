import * as admin from 'firebase-admin';
import { env } from './env';
import { logger } from '../utils/logger';

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App | null {
  if (!env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    logger.warn('Firebase service account not configured; push notifications disabled');
    return null;
  }

  try {
    const serviceAccountJson = Buffer.from(
      env.FIREBASE_SERVICE_ACCOUNT_BASE64,
      'base64'
    ).toString('utf-8');
    const serviceAccount = JSON.parse(serviceAccountJson);

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    logger.info('Firebase Admin SDK initialized');
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialize Firebase', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    return null;
  }
}

export function getFirebaseApp(): admin.app.App | null {
  return firebaseApp;
}

export function getMessaging(): admin.messaging.Messaging | null {
  if (!firebaseApp) return null;
  return admin.messaging(firebaseApp);
}
