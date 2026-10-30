
"use client";

import { useEffect, useState } from "react";

import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
} from "firebase/firestore";

import { auth, db } from "@/lib/firebase";

type Broadcast = {
  id: string;
  title: string;
  message: string;
  category: "info" | "warning" | "emergency";
  active: boolean;
  createdAt: Timestamp | null;
  createdBy: string;
};

const categoryOptions = [
  {
    value: "info",
    label: "Informasi",
    description: "Pengumuman umum",
    color: "bg-blue-100 text-blue-700",
  },
  {
    value: "warning",
    label: "Waspada",
    description: "Informasi potensi bahaya",
    color: "bg-amber-100 text-amber-700",
  },
  {
    value: "emergency",
    label: "Darurat",
    description: "Informasi kondisi darurat",
    color: "bg-red-100 text-red-700",
  },
] as const;

export default function BroadcastPage() {
  const [broadcasts, setBroadcasts] = useState<Broadcast[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [category, setCategory] = useState<
    "info" | "warning" | "emergency"
  >("info");

  // ==========================================
  // 1. MENGAMBIL DATA BROADCAST REAL-TIME
  // ==========================================

  useEffect(() => {
    const broadcastQuery = query(
      collection(db, "broadcasts"),
      orderBy("createdAt", "desc")
    );

    const unsubscribe = onSnapshot(
      broadcastQuery,
      (snapshot) => {
        const data: Broadcast[] = snapshot.docs.map((item) => {
          const raw = item.data();

          return {
            id: item.id,
            title: raw.title ?? "",
            message: raw.message ?? "",
            category: raw.category ?? "info",
            active: raw.active ?? true,
            createdAt: raw.createdAt ?? null,
            createdBy: raw.createdBy ?? "",
          };
        });

        setBroadcasts(data);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error("Broadcast Firestore error:", err);
        setError("Gagal mengambil data broadcast.");
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  // ==========================================
  // 2. MEMBUAT BROADCAST
  // ==========================================

  const handleCreate = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    setError("");
    setSuccess("");

    if (!title.trim() || !message.trim()) {
      setError("Judul dan isi pengumuman wajib diisi.");
      return;
    }

    const user = auth.currentUser;

    if (!user) {
      setError("Sesi administrator tidak ditemukan. Silakan login ulang.");
      return;
    }

    try {
      setSending(true);

      await addDoc(collection(db, "broadcasts"), {
        title: title.trim(),
        message: message.trim(),
        category,
        active: true,
        createdAt: serverTimestamp(),
        createdBy: user.uid,
      });

      setTitle("");
      setMessage("");
      setCategory("info");

      setSuccess("Broadcast berhasil dibuat dan disimpan.");

    } catch (err) {
      console.error("Gagal membuat broadcast:", err);
      setError("Broadcast gagal dibuat. Periksa Firestore Rules.");
    } finally {
      setSending(false);
    }
  };

  // ==========================================
  // 3. AKTIFKAN / NONAKTIFKAN BROADCAST
  // ==========================================

  const handleToggle = async (item: Broadcast) => {
    setError("");
    setSuccess("");

    try {
      await updateDoc(doc(db, "broadcasts", item.id), {
        active: !item.active,
      });

      setSuccess(
        item.active
          ? "Broadcast berhasil dinonaktifkan."
          : "Broadcast berhasil diaktifkan."
      );
    } catch (err) {
      console.error("Gagal mengubah broadcast:", err);
      setError("Gagal mengubah status broadcast.");
    }
  };

  // ==========================================
  // 4. HAPUS BROADCAST
  // ==========================================

  const handleDelete = async (item: Broadcast) => {
    const confirmed = window.confirm(
      `Yakin ingin menghapus broadcast "${item.title}"?`
    );

    if (!confirmed) return;

    setError("");
    setSuccess("");

    try {
      await deleteDoc(doc(db, "broadcasts", item.id));
      setSuccess("Broadcast berhasil dihapus.");
    } catch (err) {
      console.error("Gagal menghapus broadcast:", err);
      setError("Gagal menghapus broadcast.");
    }
  };

  // ==========================================
  // 5. FORMAT TANGGAL
  // ==========================================

  const formatDate = (timestamp: Timestamp | null) => {
    if (!timestamp) return "Baru saja";

    return timestamp.toDate().toLocaleString("id-ID", {
      day: "2-digit",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getCategory = (value: string) => {
    return (
      categoryOptions.find((item) => item.value === value) ??
      categoryOptions[0]
    );
  };

  const activeCount = broadcasts.filter(
    (item) => item.active
  ).length;

  const inactiveCount = broadcasts.length - activeCount;

  // ==========================================
  // 6. TAMPILAN HALAMAN
  // ==========================================

  return (
    <div className="space-y-8">

      {/* HEADER */}
      <section>
        <p className="text-sm text-slate-500">
          Administrator / Komunikasi
        </p>

        <h1 className="mt-1 text-2xl font-bold text-[#102a43] md:text-3xl">
          Broadcast
        </h1>

        <p className="mt-2 text-sm text-slate-500">
          Kelola pengumuman dan informasi penting untuk pengguna SiagaBanjir.
        </p>
      </section>

      {/* STATISTIK */}
      <section className="grid gap-4 sm:grid-cols-3">

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">
            Total Broadcast
          </p>

          <h2 className="mt-3 text-3xl font-bold text-[#102a43]">
            {loading ? "..." : broadcasts.length}
          </h2>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">
            Aktif
          </p>

          <h2 className="mt-3 text-3xl font-bold text-green-600">
            {loading ? "..." : activeCount}
          </h2>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">
            Nonaktif
          </p>

          <h2 className="mt-3 text-3xl font-bold text-slate-500">
            {loading ? "..." : inactiveCount}
          </h2>
        </div>

      </section>

      {/* NOTIFIKASI */}
      {error && (
        <div className="rounded-xl border border-red-100 bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {success && (
        <div className="rounded-xl border border-green-100 bg-green-50 p-4 text-sm text-green-700">
          {success}
        </div>
      )}

      {/* FORM BROADCAST */}
      <section className="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">

        <div className="mb-6">
          <h2 className="text-lg font-bold text-[#102a43]">
            Buat Pengumuman Baru
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Tulis informasi yang ingin ditampilkan kepada pengguna.
          </p>
        </div>

        <form onSubmit={handleCreate} className="space-y-5">

          {/* JUDUL */}
          <div>
            <label className="mb-2 block text-sm font-semibold text-slate-700">
              Judul Pengumuman
            </label>

            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Contoh: Informasi Kondisi Banjir"
              maxLength={100}
              required
              className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />

            <p className="mt-1 text-right text-xs text-slate-400">
              {title.length}/100
            </p>
          </div>

          {/* KATEGORI */}
          <div>
            <label className="mb-3 block text-sm font-semibold text-slate-700">
              Kategori Informasi
            </label>

            <div className="grid gap-3 md:grid-cols-3">
              {categoryOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setCategory(option.value)}
                  className={`rounded-xl border p-4 text-left transition ${
                    category === option.value
                      ? "border-blue-500 bg-blue-50 ring-2 ring-blue-100"
                      : "border-slate-200 hover:border-slate-300"
                  }`}
                >
                  <span
                    className={`inline-block rounded-full px-3 py-1 text-xs font-bold ${option.color}`}
                  >
                    {option.label}
                  </span>

                  <p className="mt-2 text-xs text-slate-500">
                    {option.description}
                  </p>
                </button>
              ))}
            </div>
          </div>

          {/* ISI PESAN */}
          <div>
            <label className="mb-2 block text-sm font-semibold text-slate-700">
              Isi Pengumuman
            </label>

            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Tuliskan informasi atau instruksi yang ingin disampaikan..."
              rows={5}
              maxLength={2000}
              required
              className="w-full resize-y rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />

            <p className="mt-1 text-right text-xs text-slate-400">
              {message.length}/2000
            </p>
          </div>

          {/* TOMBOL KIRIM */}
          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 pt-5">

            <p className="text-xs text-slate-400">
              Pengumuman akan disimpan dengan status aktif.
            </p>

            <button
              type="submit"
              disabled={sending}
              className="rounded-xl bg-blue-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {sending ? "Menyimpan..." : "Buat Broadcast →"}
            </button>

          </div>
        </form>
      </section>

      {/* DAFTAR BROADCAST */}
      <section className="rounded-2xl border border-slate-100 bg-white shadow-sm">

        <div className="border-b border-slate-100 p-6">
          <h2 className="text-lg font-bold text-[#102a43]">
            Riwayat Broadcast
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Daftar seluruh pengumuman yang pernah dibuat.
          </p>
        </div>

        <div className="space-y-4 p-6">

          {loading ? (
            <p className="py-8 text-center text-sm text-slate-500">
              Memuat riwayat broadcast...
            </p>
          ) : broadcasts.length === 0 ? (
            <div className="py-12 text-center">
              <div className="text-4xl">📢</div>

              <h3 className="mt-3 font-semibold text-slate-700">
                Belum ada broadcast
              </h3>

              <p className="mt-1 text-sm text-slate-500">
                Buat pengumuman pertama melalui formulir di atas.
              </p>
            </div>
          ) : (
            broadcasts.map((item) => {
              const categoryInfo = getCategory(item.category);

              return (
                <article
                  key={item.id}
                  className="rounded-xl border border-slate-100 p-5 transition hover:border-slate-200"
                >
                  <div className="flex flex-wrap items-start justify-between gap-4">

                    <div className="min-w-0 flex-1">

                      <div className="flex flex-wrap items-center gap-2">
                        <span
                          className={`rounded-full px-3 py-1 text-xs font-bold ${categoryInfo.color}`}
                        >
                          {categoryInfo.label}
                        </span>

                        <span
                          className={`rounded-full px-3 py-1 text-xs font-semibold ${
                            item.active
                              ? "bg-green-50 text-green-700"
                              : "bg-slate-100 text-slate-500"
                          }`}
                        >
                          {item.active ? "Aktif" : "Nonaktif"}
                        </span>
                      </div>

                      <h3 className="mt-3 text-base font-bold text-[#102a43]">
                        {item.title}
                      </h3>

                      <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                        {item.message}
                      </p>

                      <p className="mt-3 text-xs text-slate-400">
                        Dibuat: {formatDate(item.createdAt)}
                      </p>
                    </div>

                    <div className="flex shrink-0 gap-2">

                      <button
                        type="button"
                        onClick={() => handleToggle(item)}
                        className={`rounded-lg px-3 py-2 text-xs font-semibold transition ${
                          item.active
                            ? "bg-amber-50 text-amber-700 hover:bg-amber-100"
                            : "bg-green-50 text-green-700 hover:bg-green-100"
                        }`}
                      >
                        {item.active ? "Nonaktifkan" : "Aktifkan"}
                      </button>

                      <button
                        type="button"
                        onClick={() => handleDelete(item)}
                        className="rounded-lg bg-red-50 px-3 py-2 text-xs font-semibold text-red-600 transition hover:bg-red-100"
                      >
                        Hapus
                      </button>

                    </div>
                  </div>
                </article>
              );
            })
          )}

        </div>
      </section>

      {/* DISCLAIMER */}
      <div className="rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm leading-6 text-blue-800">
        <strong>Catatan:</strong> Broadcast saat ini merupakan pengumuman
        yang tersimpan di Firestore. Pengiriman notifikasi langsung ke
        perangkat pengguna memerlukan integrasi Firebase Cloud Messaging.
        Informasi darurat harus tetap berdasarkan kondisi yang telah
        diverifikasi.
      </div>

    </div>
  );
}
