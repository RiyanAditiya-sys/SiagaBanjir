
import "server-only";

import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync } from "fs";
import { join } from "path";

function getServiceAccount() {
  // Production: gunakan Environment Variables Vercel
  if (process.env.VERCEL) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;

    if (!projectId || !clientEmail || !privateKey) {
      throw new Error("Firebase Admin environment variables belum lengkap.");
    }

    return {
      projectId,
      clientEmail,
      privateKey: privateKey.replace(/\\n/g, "\n"),
    };
  }

  // Lokal: gunakan file service account
  const serviceAccountPath = join(
    process.cwd(),
    "credentials",
    "firebase-service-account.json"
  );

  return JSON.parse(readFileSync(serviceAccountPath, "utf8"));
}

const adminApp =
  getApps().find((app) => app.name === "admin") ??
  initializeApp(
    {
      credential: cert(getServiceAccount()),
    },
    "admin"
  );

export const adminDb = getFirestore(adminApp);
export const adminAuth = getAuth(adminApp);
