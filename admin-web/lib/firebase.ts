import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDOsGVripzWj3goNq2oOrho7RgloC7mn6s",
  authDomain: "siagabanjir-327b7.firebaseapp.com",
  projectId: "siagabanjir-327b7",
  storageBucket: "siagabanjir-327b7.firebasestorage.app",
  messagingSenderId: "909131885449",
  appId: "1:909131885449:web:29ca0f23842fd870d0cf58",
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;