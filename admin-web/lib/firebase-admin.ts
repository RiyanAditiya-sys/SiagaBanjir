
import "server-only";

import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync } from "fs";
import { join } from "path";

const serviceAccountPath = join(
  process.cwd(),
  "credentials",
  "firebase-service-account.json"
);

const serviceAccount = JSON.parse(
  readFileSync(serviceAccountPath, "utf8")
);

const adminApp =
  getApps().find((app) => app.name === "admin") ??
  initializeApp(
    {
      credential: cert(serviceAccount),
    },
    "admin"
  );

export const adminDb = getFirestore(adminApp);
export const adminAuth = getAuth(adminApp);
