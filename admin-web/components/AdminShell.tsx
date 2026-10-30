"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

const menus = [
  { name: "Dashboard", href: "/", icon: "▦" },
  { name: "Laporan Banjir", href: "/laporan", icon: "▤" },
  { name: "Peta Pemantauan", href: "/peta", icon: "⌖" },
  { name: "Regional Alerts", href: "/regional-alerts", icon: "⚑" },
  { name: "Broadcast", href: "/broadcast", icon: "◉" },
];
export default function AdminShell({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [checking, setChecking] = useState(true);
  const [adminName, setAdminName] = useState("Administrator");

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        router.replace("/login");
        setChecking(false);
        return;
      }

      try {
        const userSnapshot = await getDoc(doc(db, "users", user.uid));

        if (!userSnapshot.exists() || userSnapshot.data().role !== "admin") {
          await signOut(auth);
          router.replace("/login");
          return;
        }

        setAdminName(userSnapshot.data().name || user.email || "Administrator");
        setChecking(false);
      } catch (error) {
        console.error("Gagal memeriksa akun admin:", error);
        router.replace("/login");
      }
    });

    return () => unsubscribe();
  }, [router]);

  const handleLogout = async () => {
    await signOut(auth);
    router.replace("/login");
  };

  if (checking) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        Memeriksa akses administrator...
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <aside className="fixed inset-y-0 left-0 z-30 flex w-64 flex-col bg-[#102a43] text-white">
        <div className="border-b border-white/10 px-6 py-7">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-500 text-2xl">
              🌊
            </div>
            <div>
              <h1 className="text-xl font-bold">SiagaBanjir</h1>
              <p className="text-xs text-slate-300">Administrator Panel</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-2 px-4 py-6">
          <p className="mb-4 px-3 text-xs font-semibold uppercase tracking-wider text-slate-400">
            Menu Utama
          </p>

          {menus.map((menu) => {
            const active =
              menu.href === "/"
                ? pathname === "/"
                : pathname.startsWith(menu.href);

            return (
              <Link
                key={menu.href}
                href={menu.href}
                className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
                  active
                    ? "bg-blue-600 text-white"
                    : "text-slate-300 hover:bg-white/10 hover:text-white"
                }`}
              >
                <span className="text-lg">{menu.icon}</span>
                {menu.name}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-white/10 p-4">
          <p className="truncate px-3 text-sm font-semibold">{adminName}</p>
          <p className="px-3 pb-3 text-xs text-slate-400">Administrator</p>

          <button
            onClick={handleLogout}
            className="w-full rounded-xl px-4 py-3 text-left text-sm text-red-300 hover:bg-white/10"
          >
            ↪ Keluar
          </button>
        </div>
      </aside>

      <main className="ml-64 min-h-screen w-[calc(100%-16rem)]">
        <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-slate-200 bg-white px-8">
          <div>
            <p className="text-sm font-semibold text-slate-700">
              Sistem Pemantauan Banjir
            </p>
          </div>
          <span className="text-sm text-slate-500">Admin Panel</span>
        </header>

        <div className="p-8">{children}</div>
      </main>
    </div>
  );
}