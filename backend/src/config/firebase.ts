import path from 'path';
import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

if (!admin.apps.length) {
  if (!process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_PATH is not defined');
  }

  const serviceAccountPath = path.resolve(
    process.cwd(),
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH
  );

  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });

  console.log('✅ Firebase Admin initialized');
}

export const db = admin.firestore();
export const auth = admin.auth();
export default admin;
