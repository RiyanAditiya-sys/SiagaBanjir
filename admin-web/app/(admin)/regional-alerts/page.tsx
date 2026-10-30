
"use client";

import { useEffect, useMemo, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";

type Report = {
  id: string;
  location?: string;
  severity?: "low" | "medium" | "high";
  status?: "pending" | "verified" | "rejected";
  waterHeightCm?: number;
  latitude?: number;
  longitude?: number;
};

type Region = {
  location: string;
  total: number;
  low: number;
  medium: number;
  high: number;
  highestSeverity: string;
  maxWaterHeight: number;
  reports: Report[];
};

const severityRank: Record<string, number> = {
  low: 1,
  medium: 2,
  high: 3,
};

export default function RegionalAlertsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "reports"),
      (snapshot) => {
        const data = snapshot.docs.map((item) => ({
          id: item.id,
          ...item.data(),
        })) as Report[];

        setReports(data);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error(err);
        setError("Gagal mengambil data laporan dari Firebase.");
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  // Regional Alerts hanya menghitung laporan terverifikasi.
  const verifiedReports = useMemo(
    () => reports.filter((report) => report.status === "verified"),
    [reports]
  );

  // Mengelompokkan laporan berdasarkan lokasi.
  const regions = useMemo(() => {
    const grouped = new Map<string, Report[]>();

    verifiedReports.forEach((report) => {
      const location = report.location?.trim() || "Lokasi tidak diketahui";
      const key = location.toLowerCase();

      if (!grouped.has(key)) {
        grouped.set(key, []);
      }

      grouped.get(key)!.push(report);
    });

    const result: Region[] = [];

    grouped.forEach((items) => {
      const low = items.filter((r) => r.severity === "low").length;
      const medium = items.filter((r) => r.severity === "medium").length;
      const high = items.filter((r) => r.severity === "high").length;

      const highestSeverity =
        high > 0 ? "high" : medium > 0 ? "medium" : low > 0 ? "low" : "unknown";

      const maxWaterHeight = Math.max(
        0,
        ...items.map((r) => Number(r.waterHeightCm) || 0)
      );

      result.push({
        location: items[0].location?.trim() || "Lokasi tidak diketahui",
        total: items.length,
        low,
        medium,
        high,
        highestSeverity,
        maxWaterHeight,
        reports: items,
      });
    });

    return result.sort((a, b) => {
      const severityDifference =
        (severityRank[b.highestSeverity] || 0) -
        (severityRank[a.highestSeverity] || 0);

      if (severityDifference !== 0) return severityDifference;
      return b.total - a.total;
    });
  }, [verifiedReports]);

  const filteredRegions = regions.filter((region) =>
    region.location.toLowerCase().includes(search.toLowerCase())
  );

  const highRisk = regions.filter(
    (region) => region.highestSeverity === "high"
  ).length;

  const mediumRisk = regions.filter(
    (region) => region.highestSeverity === "medium"
  ).length;

  const lowRisk = regions.filter(
    (region) => region.highestSeverity === "low"
  ).length;

  const getSeverityStyle = (severity: string) => {
    switch (severity) {
      case "high":
        return {
          label: "Risiko Tinggi",
          style: "bg-red-100 text-red-700",
          dot: "bg-red-500",
        };
      case "medium":
        return {
          label: "Risiko Sedang",
          style: "bg-orange-100 text-orange-700",
          dot: "bg-orange-500",
        };
      case "low":
        return {
          label: "Risiko Rendah",
          style: "bg-green-100 text-green-700",
          dot: "bg-green-500",
        };
      default:
        return {
          label: "Belum diketahui",
          style: "bg-slate-100 text-slate-600",
          dot: "bg-slate-400",
        };
    }
  };

  return (
    <div className="space-y-7">
      <div>
        <h1 className="text-2xl font-bold text-slate-800">
          Regional Alerts
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Pemantauan tingkat keparahan banjir berdasarkan wilayah laporan
          masyarakat yang telah diverifikasi.
        </p>
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* STATISTIK WILAYAH */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Total Wilayah</p>
          <p className="mt-3 text-3xl font-bold text-blue-600">
            {loading ? "..." : regions.length}
          </p>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Risiko Tinggi</p>
          <p className="mt-3 text-3xl font-bold text-red-600">
            {loading ? "..." : highRisk}
          </p>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Risiko Sedang</p>
          <p className="mt-3 text-3xl font-bold text-orange-600">
            {loading ? "..." : mediumRisk}
          </p>
        </div>

        <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Risiko Rendah</p>
          <p className="mt-3 text-3xl font-bold text-green-600">
            {loading ? "..." : lowRisk}
          </p>
        </div>
      </div>

      {/* INFORMASI */}
      <div className="rounded-xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-sm leading-6 text-blue-800">
          <strong>Metode pengelompokan:</strong> laporan dikelompokkan
          berdasarkan nama lokasi. Tingkat risiko wilayah mengikuti tingkat
          keparahan tertinggi dari laporan terverifikasi di lokasi tersebut.
          Ini merupakan indikator pemantauan, bukan prediksi banjir atau
          peringatan resmi.
        </p>
      </div>

      {/* DAFTAR WILAYAH */}
      <section className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
          <div>
            <h2 className="font-bold text-slate-800">
              Kondisi Wilayah
            </h2>
            <p className="mt-1 text-xs text-slate-500">
              Berdasarkan {verifiedReports.length} laporan terverifikasi.
            </p>
          </div>

          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari nama wilayah..."
            className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-blue-500 sm:w-64"
          />
        </div>

        {loading ? (
          <div className="py-16 text-center text-sm text-slate-500">
            Memuat data wilayah...
          </div>
        ) : filteredRegions.length === 0 ? (
          <div className="py-16 text-center">
            <p className="text-slate-500">
              {regions.length === 0
                ? "Belum ada laporan terverifikasi."
                : "Wilayah tidak ditemukan."}
            </p>
          </div>
        ) : (
          <div className="mt-6 space-y-4">
            {filteredRegions.map((region) => {
              const severity = getSeverityStyle(region.highestSeverity);

              return (
                <div
                  key={region.location}
                  className="rounded-xl border border-slate-100 p-5 transition hover:border-blue-200"
                >
                  <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
                    <div>
                      <div className="flex items-center gap-2">
                        <span
                          className={`h-3 w-3 rounded-full ${severity.dot}`}
                        />
                        <h3 className="font-bold text-slate-800">
                          {region.location}
                        </h3>
                      </div>

                      <p className="mt-2 text-sm text-slate-500">
                        {region.total} laporan terverifikasi
                      </p>
                    </div>

                    <span
                      className={`w-fit rounded-full px-3 py-2 text-xs font-semibold ${severity.style}`}
                    >
                      {severity.label}
                    </span>
                  </div>

                  <div className="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-xs text-slate-500">Tinggi</p>
                      <p className="mt-1 font-bold text-red-600">
                        {region.high}
                      </p>
                    </div>

                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-xs text-slate-500">Sedang</p>
                      <p className="mt-1 font-bold text-orange-600">
                        {region.medium}
                      </p>
                    </div>

                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-xs text-slate-500">Rendah</p>
                      <p className="mt-1 font-bold text-green-600">
                        {region.low}
                      </p>
                    </div>

                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-xs text-slate-500">
                        Air Tertinggi
                      </p>
                      <p className="mt-1 font-bold text-slate-800">
                        {region.maxWaterHeight} cm
                      </p>
                    </div>
                  </div>

                  {region.reports.some(
                    (report) =>
                      typeof report.latitude === "number" &&
                      typeof report.longitude === "number"
                  ) && (
                    <a
                      href={`https://www.google.com/maps?q=${region.reports.find(
                        (report) =>
                          typeof report.latitude === "number" &&
                          typeof report.longitude === "number"
                      )?.latitude},${region.reports.find(
                        (report) =>
                          typeof report.latitude === "number" &&
                          typeof report.longitude === "number"
                      )?.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="mt-4 inline-block text-sm font-semibold text-blue-600 hover:underline"
                    >
                      Lihat lokasi di Google Maps ↗
                    </a>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
