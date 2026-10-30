
"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  collection,
  onSnapshot,
  Timestamp,
} from "firebase/firestore";

import { db } from "@/lib/firebase";

type Report = {
  id: string;
  location: string;
  waterHeightCm: number;
  severity: "low" | "medium" | "high";
  status: "pending" | "verified" | "rejected";
  createdAt: Timestamp | null;
};

export default function DashboardPage() {
  const router = useRouter();

  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // ==========================================
  // 1. MENGAMBIL DATA FIRESTORE REAL-TIME
  // ==========================================

  useEffect(() => {
    setLoading(true);

    const unsubscribe = onSnapshot(
      collection(db, "reports"),
      (snapshot) => {
        const data: Report[] = snapshot.docs.map((item) => {
          const raw = item.data();

          return {
            id: item.id,
            location: raw.location ?? "Lokasi tidak diketahui",
            waterHeightCm: Number(raw.waterHeightCm ?? 0),
            severity: raw.severity ?? "low",
            status: raw.status ?? "pending",
            createdAt: raw.createdAt ?? null,
          };
        });

        data.sort((a, b) => {
          const timeA = a.createdAt?.toMillis() ?? 0;
          const timeB = b.createdAt?.toMillis() ?? 0;

          return timeB - timeA;
        });

        setReports(data);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error("Firestore error:", err);
        setError(
          "Gagal mengambil data. Periksa koneksi dan Firestore Rules."
        );
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  // ==========================================
  // 2. STATISTIK DASHBOARD
  // ==========================================

  const stats = useMemo(() => {
    const pending = reports.filter(
      (report) => report.status === "pending"
    ).length;

    const verified = reports.filter(
      (report) => report.status === "verified"
    ).length;

    const locations = new Set(
      reports
        .filter((report) => report.status !== "rejected")
        .map((report) => report.location.trim().toLowerCase())
        .filter(Boolean)
    );

    return [
      {
        title: "Total Laporan",
        value: reports.length,
        detail: "Seluruh laporan masyarakat",
        icon: "📋",
        color: "bg-blue-50 text-blue-600",
      },
      {
        title: "Menunggu Verifikasi",
        value: pending,
        detail: "Perlu ditinjau administrator",
        icon: "⏳",
        color: "bg-amber-50 text-amber-600",
      },
      {
        title: "Terverifikasi",
        value: verified,
        detail: "Laporan telah divalidasi",
        icon: "✓",
        color: "bg-green-50 text-green-600",
      },
      {
        title: "Wilayah Terdampak",
        value: locations.size,
        detail: "Lokasi dalam laporan",
        icon: "📍",
        color: "bg-purple-50 text-purple-600",
      },
    ];
  }, [reports]);

  // ==========================================
  // 3. REGIONAL ALERTS
  // ==========================================

  const regionalAlerts = useMemo(() => {
    const severityRank = {
      low: 1,
      medium: 2,
      high: 3,
    };

    const grouped = new Map<string, Report>();

    reports
      .filter((report) => report.status === "verified")
      .forEach((report) => {
        const key = report.location.trim().toLowerCase();
        const current = grouped.get(key);

        if (
          !current ||
          severityRank[report.severity] >
            severityRank[current.severity]
        ) {
          grouped.set(key, report);
        }
      });

    return Array.from(grouped.values())
      .sort(
        (a, b) =>
          severityRank[b.severity] -
          severityRank[a.severity]
      )
      .slice(0, 3);
  }, [reports]);

  // ==========================================
  // 4. FORMAT WAKTU
  // ==========================================

  const formatTime = (timestamp: Timestamp | null) => {
    if (!timestamp) return "-";

    const diff = Math.max(
      0,
      Date.now() - timestamp.toDate().getTime()
    );

    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return "Baru saja";
    if (minutes < 60) return `${minutes} menit lalu`;

    const hours = Math.floor(minutes / 60);

    if (hours < 24) return `${hours} jam lalu`;

    const days = Math.floor(hours / 24);

    return `${days} hari lalu`;
  };

  // ==========================================
  // 5. LABEL DAN WARNA
  // ==========================================

  const severityLabel = (severity: string) => {
    if (severity === "high") return "Tinggi";
    if (severity === "medium") return "Sedang";
    return "Rendah";
  };

  const statusLabel = (status: string) => {
    if (status === "verified") return "Terverifikasi";
    if (status === "rejected") return "Ditolak";
    return "Menunggu";
  };

  const severityColor = (severity: string) => {
    if (severity === "high") {
      return "bg-red-50 text-red-600";
    }

    if (severity === "medium") {
      return "bg-amber-50 text-amber-600";
    }

    return "bg-green-50 text-green-600";
  };

  const statusColor = (status: string) => {
    if (status === "verified") {
      return "bg-green-50 text-green-700";
    }

    if (status === "rejected") {
      return "bg-red-50 text-red-700";
    }

    return "bg-amber-50 text-amber-700";
  };

  const alertColor = (severity: string) => {
    if (severity === "high") return "text-red-600";
    if (severity === "medium") return "text-amber-600";
    return "text-green-600";
  };

  const alertDotColor = (severity: string) => {
    if (severity === "high") return "bg-red-500";
    if (severity === "medium") return "bg-amber-500";
    return "bg-green-500";
  };

  // ==========================================
  // 6. TAMPILAN DASHBOARD
  // ==========================================

  return (
    <div className="space-y-8">

      {/* HEADER */}
      <section>
        <p className="text-sm text-slate-500">
          Administrator / Overview
        </p>

        <h1 className="mt-1 text-2xl font-bold text-[#102a43] md:text-3xl">
          Dashboard
        </h1>

        <p className="mt-2 text-sm text-slate-500">
          Pantau kondisi dan aktivitas laporan banjir masyarakat.
        </p>
      </section>

      {/* ERROR */}
      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* WELCOME BANNER */}
      <section className="overflow-hidden rounded-2xl bg-gradient-to-r from-[#102a43] to-[#1769e0] p-6 text-white shadow-lg md:p-8">
        <p className="text-sm font-medium text-blue-100">
          SIAGABANJIR MONITORING SYSTEM
        </p>

        <h2 className="mt-3 text-2xl font-bold md:text-3xl">
          Selamat Datang, Administrator!
        </h2>

        <p className="mt-3 max-w-xl text-sm leading-6 text-blue-100">
          Kelola laporan masyarakat, pantau wilayah terdampak,
          dan sebarkan informasi penting untuk mendukung
          penanganan banjir.
        </p>

        <div className="mt-5 inline-flex items-center gap-2 rounded-lg bg-white/15 px-4 py-2 text-sm">
          <span className="h-2 w-2 rounded-full bg-green-400" />
          Data terhubung dengan Firestore
        </div>
      </section>

      {/* STATISTIK */}
      <section>
        <div className="mb-4">
          <h2 className="text-lg font-bold text-[#102a43]">
            Statistik Laporan
          </h2>

          <p className="text-sm text-slate-500">
            Ringkasan aktivitas sistem SiagaBanjir
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {stats.map((stat) => (
            <div
              key={stat.title}
              className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm"
            >
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium text-slate-500">
                  {stat.title}
                </p>

                <span
                  className={`flex h-10 w-10 items-center justify-center rounded-xl text-xl ${stat.color}`}
                >
                  {stat.icon}
                </span>
              </div>

              <h3 className="mt-4 text-3xl font-bold text-[#102a43]">
                {loading ? "..." : stat.value}
              </h3>

              <p className="mt-2 text-xs text-slate-500">
                {stat.detail}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* REGIONAL ALERTS */}
      <section className="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-bold text-[#102a43]">
              Regional Alerts
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              Wilayah berdasarkan laporan terverifikasi dengan urgensi tertinggi
            </p>
          </div>

          <button
            onClick={() => router.push("/regional-alerts")}
            className="rounded-lg bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 transition hover:bg-blue-100"
          >
            Lihat Regional Alerts →
          </button>
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-3">
          {loading ? (
            <p className="text-sm text-slate-500">
              Memuat data wilayah...
            </p>
          ) : regionalAlerts.length === 0 ? (
            <p className="text-sm text-slate-500">
              Belum ada laporan terverifikasi.
            </p>
          ) : (
            regionalAlerts.map((alert) => (
              <div
                key={alert.location.toLowerCase()}
                className="rounded-xl border border-slate-100 p-4"
              >
                <div className="flex items-center gap-2">
                  <span
                    className={`h-2.5 w-2.5 rounded-full ${alertDotColor(alert.severity)}`}
                  />

                  <p className="font-semibold text-slate-800">
                    {alert.location}
                  </p>
                </div>

                <p
                  className={`mt-3 text-sm font-semibold ${alertColor(alert.severity)}`}
                >
                  Risiko {severityLabel(alert.severity)}
                </p>

                <p className="mt-1 text-xs text-slate-500">
                  Ketinggian air: {alert.waterHeightCm} cm
                </p>
              </div>
            ))
          )}
        </div>

        <p className="mt-4 text-xs text-slate-400">
          Indikator ini berdasarkan laporan masyarakat yang telah diverifikasi,
          bukan peringatan resmi atau prediksi banjir.
        </p>
      </section>

      {/* LAPORAN TERBARU */}
      <section className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 p-6">
          <div>
            <h2 className="text-lg font-bold text-[#102a43]">
              Laporan Terbaru
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              Aktivitas laporan banjir masyarakat
            </p>
          </div>

          <button
            onClick={() => router.push("/laporan")}
            className="rounded-lg bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 transition hover:bg-blue-100"
          >
            Lihat Semua →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[700px] text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-6 py-4">ID Laporan</th>
                <th className="px-6 py-4">Lokasi</th>
                <th className="px-6 py-4">Ketinggian</th>
                <th className="px-6 py-4">Urgensi</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Waktu</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100">
              {reports.slice(0, 5).map((report) => (
                <tr
                  key={report.id}
                  className="transition hover:bg-slate-50"
                >
                  <td className="px-6 py-4 font-semibold text-blue-700">
                    {report.id.slice(0, 8)}
                  </td>

                  <td className="px-6 py-4">
                    {report.location}
                  </td>

                  <td className="px-6 py-4">
                    {report.waterHeightCm} cm
                  </td>

                  <td className="px-6 py-4">
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-semibold ${severityColor(report.severity)}`}
                    >
                      {severityLabel(report.severity)}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-semibold ${statusColor(report.status)}`}
                    >
                      {statusLabel(report.status)}
                    </span>
                  </td>

                  <td className="px-6 py-4 text-slate-500">
                    {formatTime(report.createdAt)}
                  </td>
                </tr>
              ))}

              {!loading && reports.length === 0 && (
                <tr>
                  <td
                    colSpan={6}
                    className="px-6 py-10 text-center text-slate-500"
                  >
                    Belum ada laporan di Firestore.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="pb-4 text-center text-xs text-slate-400">
        © 2026 SiagaBanjir — Admin Monitoring Panel
      </footer>
    </div>
  );
}
