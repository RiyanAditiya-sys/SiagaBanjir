
"use client";

import { useEffect, useMemo, useState } from "react";
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  Timestamp,
  updateDoc,
} from "firebase/firestore";
import { onAuthStateChanged } from "firebase/auth";
import { auth, db } from "@/lib/firebase";

type FilterStatus = "all" | "pending" | "verified" | "rejected";

type AIAnalysis = {
  summary: string;
  urgency: "low" | "medium" | "high";
  potentialImpact: string[];
  recommendations: string[];
  adminChecks: string[];
  limitations: string;
  generatedAt?: Timestamp | null;
  model?: string;
};

type Report = {
  id: string;
  userId?: string;
  userEmail?: string;
  location?: string;
  latitude?: number;
  longitude?: number;
  waterHeightCm?: number;
  severity?: "low" | "medium" | "high";
  description?: string;
  photoUrl?: string;
  status?: "pending" | "verified" | "rejected";
  createdAt?: Timestamp;
  aiAnalysis?: AIAnalysis;
};

const statusLabels: Record<string, string> = {
  pending: "Menunggu",
  verified: "Terverifikasi",
  rejected: "Ditolak",
};

const severityLabels: Record<string, string> = {
  low: "Rendah",
  medium: "Sedang",
  high: "Tinggi",
};

export default function LaporanPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] =
    useState<FilterStatus>("all");

  const [selectedReport, setSelectedReport] =
    useState<Report | null>(null);

  const [updating, setUpdating] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [actionMessage, setActionMessage] = useState("");

  // Mengambil laporan secara realtime
  useEffect(() => {
    const reportsQuery = query(
      collection(db, "reports"),
      orderBy("createdAt", "desc")
    );

    const unsubscribe = onSnapshot(
      reportsQuery,
      (snapshot) => {
        const data = snapshot.docs.map((item) => ({
          id: item.id,
          ...item.data(),
        })) as Report[];

        setReports(data);
        setLoading(false);
      },
      (error) => {
        console.error("Gagal mengambil laporan:", error);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  // Mengikuti perubahan data laporan yang sedang dibuka
  useEffect(() => {
    if (!selectedReport) return;

    const updatedReport = reports.find(
      (report) => report.id === selectedReport.id
    );

    if (updatedReport) {
      setSelectedReport(updatedReport);
    }
  }, [reports, selectedReport?.id]);

  // Filter dan pencarian laporan
  const filteredReports = useMemo(() => {
    return reports.filter((report) => {
      const keyword = search.toLowerCase();

      const matchesSearch =
        (report.location ?? "").toLowerCase().includes(keyword) ||
        (report.description ?? "").toLowerCase().includes(keyword) ||
        (report.userEmail ?? "").toLowerCase().includes(keyword);

      const matchesStatus =
        filterStatus === "all" ||
        report.status === filterStatus;

      return matchesSearch && matchesStatus;
    });
  }, [reports, search, filterStatus]);

  // Statistik laporan
  const totalReports = reports.length;
  const pendingReports = reports.filter(
    (report) => report.status === "pending"
  ).length;
  const verifiedReports = reports.filter(
    (report) => report.status === "verified"
  ).length;
  const rejectedReports = reports.filter(
    (report) => report.status === "rejected"
  ).length;

  // Format tanggal
  const formatDate = (date?: Timestamp) => {
    if (!date) return "-";

    return date.toDate().toLocaleString("id-ID", {
      dateStyle: "medium",
      timeStyle: "short",
    });
  };

  // Warna status
  const getStatusStyle = (status?: string) => {
    switch (status) {
      case "verified":
        return "bg-green-100 text-green-700";
      case "rejected":
        return "bg-red-100 text-red-700";
      default:
        return "bg-yellow-100 text-yellow-700";
    }
  };

  // Warna tingkat keparahan
  const getSeverityStyle = (severity?: string) => {
    switch (severity) {
      case "high":
        return "bg-red-100 text-red-700";
      case "medium":
        return "bg-orange-100 text-orange-700";
      case "low":
        return "bg-green-100 text-green-700";
      default:
        return "bg-gray-100 text-gray-600";
    }
  };

  // Update status laporan
  const handleUpdateStatus = async (
    reportId: string,
    status: "verified" | "rejected"
  ) => {
    const confirmation = window.confirm(
      status === "verified"
        ? "Verifikasi laporan ini?"
        : "Tolak laporan ini?"
    );

    if (!confirmation) return;

    try {
      setUpdating(true);
      setActionMessage("");

      await updateDoc(doc(db, "reports", reportId), {
        status,
      });

      setActionMessage("Status laporan berhasil diperbarui.");
    } catch (error) {
      console.error("Gagal memperbarui status:", error);
      setActionMessage("Gagal memperbarui status laporan.");
    } finally {
      setUpdating(false);
    }
  };

  // Analisis laporan menggunakan Gemini AI
  const handleAnalyzeAI = async (reportId: string) => {
    try {
      setAnalyzing(true);
      setActionMessage("");

      const currentUser = auth.currentUser;

      if (!currentUser) {
        throw new Error("Sesi login tidak ditemukan. Silakan login kembali.");
      }

      const idToken = await currentUser.getIdToken();

      const response = await fetch("/api/ai/analyze", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          reportId,
        }),
      });

      const result = await response.json();

      if (!response.ok || !result.success) {
        throw new Error(
          result.message || "Analisis AI gagal dilakukan."
        );
      }

      setActionMessage("Analisis AI berhasil dibuat dan disimpan.");
    } catch (error) {
      console.error("Analisis AI gagal:", error);

      setActionMessage(
        error instanceof Error
          ? error.message
          : "Terjadi kesalahan saat melakukan analisis AI."
      );
    } finally {
      setAnalyzing(false);
    }
  };

  // Tampilan halaman
  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Manajemen Laporan
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Kelola, verifikasi, dan analisis laporan banjir masyarakat.
        </p>
      </div>

      {/* Statistik */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Total Laporan"
          value={totalReports}
          color="blue"
        />
        <StatCard
          title="Menunggu Verifikasi"
          value={pendingReports}
          color="yellow"
        />
        <StatCard
          title="Terverifikasi"
          value={verifiedReports}
          color="green"
        />
        <StatCard
          title="Ditolak"
          value={rejectedReports}
          color="red"
        />
      </div>

      {/* Pesan aksi */}
      {actionMessage && (
        <div className="rounded-lg border border-blue-200 bg-blue-50 p-3 text-sm text-blue-700">
          {actionMessage}
        </div>
      )}

      {/* Daftar laporan */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="flex flex-col gap-4 border-b border-gray-200 p-5 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="font-semibold text-gray-900">
              Daftar Laporan Banjir
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Data laporan yang masuk dari aplikasi SiagaBanjir.
            </p>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row">
            <input
              type="text"
              placeholder="Cari lokasi atau laporan..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
            />

            <select
              value={filterStatus}
              onChange={(e) =>
                setFilterStatus(e.target.value as FilterStatus)
              }
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
            >
              <option value="all">Semua Status</option>
              <option value="pending">Menunggu</option>
              <option value="verified">Terverifikasi</option>
              <option value="rejected">Ditolak</option>
            </select>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[850px] text-left text-sm">
            <thead className="bg-gray-50 text-xs uppercase text-gray-500">
              <tr>
                <th className="px-5 py-4">Lokasi</th>
                <th className="px-5 py-4">Ketinggian Air</th>
                <th className="px-5 py-4">Keparahan</th>
                <th className="px-5 py-4">Status</th>
                <th className="px-5 py-4">Tanggal</th>
                <th className="px-5 py-4">Aksi</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr>
                  <td
                    colSpan={6}
                    className="px-5 py-10 text-center text-gray-500"
                  >
                    Memuat data laporan...
                  </td>
                </tr>
              ) : filteredReports.length === 0 ? (
                <tr>
                  <td
                    colSpan={6}
                    className="px-5 py-10 text-center text-gray-500"
                  >
                    Tidak ada laporan ditemukan.
                  </td>
                </tr>
              ) : (
                filteredReports.map((report) => (
                  <tr
                    key={report.id}
                    className="transition hover:bg-gray-50"
                  >
                    <td className="px-5 py-4">
                      <p className="font-medium text-gray-900">
                        {report.location || "Lokasi tidak tersedia"}
                      </p>
                      <p className="mt-1 max-w-xs truncate text-xs text-gray-500">
                        {report.description || "-"}
                      </p>
                    </td>

                    <td className="px-5 py-4 font-medium text-gray-700">
                      {report.waterHeightCm ?? "-"} cm
                    </td>

                    <td className="px-5 py-4">
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-medium ${getSeverityStyle(
                          report.severity
                        )}`}
                      >
                        {severityLabels[report.severity ?? ""] ?? "-"}
                      </span>
                    </td>

                    <td className="px-5 py-4">
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-medium ${getStatusStyle(
                          report.status
                        )}`}
                      >
                        {statusLabels[report.status ?? ""] ?? "Menunggu"}
                      </span>
                    </td>

                    <td className="px-5 py-4 text-gray-500">
                      {formatDate(report.createdAt)}
                    </td>

                    <td className="px-5 py-4">
                      <button
                        onClick={() => {
                          setSelectedReport(report);
                          setActionMessage("");
                        }}
                        className="rounded-lg bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700 transition hover:bg-blue-100"
                      >
                        Detail
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="border-t border-gray-200 px-5 py-3 text-xs text-gray-500">
          Menampilkan {filteredReports.length} dari {totalReports} laporan.
        </div>
      </div>

      {/* Modal detail laporan */}
      {selectedReport && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-black/50 p-4"
          onClick={() => setSelectedReport(null)}
        >
          <div
            className="my-8 w-full max-w-3xl rounded-2xl bg-white shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="flex items-center justify-between border-b border-gray-200 p-5">
              <div>
                <h2 className="text-lg font-bold text-gray-900">
                  Detail Laporan
                </h2>
                <p className="mt-1 text-xs text-gray-500">
                  ID: {selectedReport.id}
                </p>
              </div>

              <button
                onClick={() => setSelectedReport(null)}
                className="rounded-lg p-2 text-gray-500 hover:bg-gray-100"
              >
                ✕
              </button>
            </div>

            <div className="max-h-[75vh] space-y-6 overflow-y-auto p-5">
              {/* Foto laporan */}
              {selectedReport.photoUrl && (
                <div>
                  <h3 className="mb-2 text-sm font-semibold text-gray-800">
                    Foto Kondisi
                  </h3>
                  <img
                    src={selectedReport.photoUrl}
                    alt="Foto laporan banjir"
                    className="max-h-72 w-full rounded-xl border border-gray-200 object-cover"
                  />
                </div>
              )}

              {/* Informasi laporan */}
              <div>
                <h3 className="mb-3 font-semibold text-gray-900">
                  Informasi Laporan
                </h3>

                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <InfoItem
                    label="Lokasi"
                    value={selectedReport.location || "-"}
                  />
                  <InfoItem
                    label="Pelapor"
                    value={selectedReport.userEmail || "-"}
                  />
                  <InfoItem
                    label="Ketinggian Air"
                    value={`${selectedReport.waterHeightCm ?? "-"} cm`}
                  />
                  <InfoItem
                    label="Tingkat Keparahan"
                    value={
                      severityLabels[selectedReport.severity ?? ""] ?? "-"
                    }
                  />
                  <InfoItem
                    label="Status"
                    value={
                      statusLabels[selectedReport.status ?? ""] ?? "Menunggu"
                    }
                  />
                  <InfoItem
                    label="Tanggal Laporan"
                    value={formatDate(selectedReport.createdAt)}
                  />
                </div>

                <div className="mt-4">
                  <p className="mb-1 text-xs font-medium text-gray-500">
                    Deskripsi
                  </p>
                  <p className="rounded-lg bg-gray-50 p-3 text-sm leading-relaxed text-gray-700">
                    {selectedReport.description || "Tidak ada deskripsi."}
                  </p>
                </div>

                {selectedReport.latitude != null &&
                  selectedReport.longitude != null && (
                    <div className="mt-4">
                      <p className="mb-1 text-xs font-medium text-gray-500">
                        Koordinat
                      </p>
                      <p className="text-sm text-gray-700">
                        {selectedReport.latitude},{" "}
                        {selectedReport.longitude}
                      </p>
                      <a
                        href={`https://www.google.com/maps?q=${selectedReport.latitude},${selectedReport.longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-2 inline-block text-sm font-medium text-blue-600 hover:underline"
                      >
                        Buka di Google Maps →
                      </a>
                    </div>
                  )}
              </div>

              {/* Analisis AI */}
              <div className="rounded-xl border border-purple-200 bg-purple-50/50 p-4">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h3 className="font-semibold text-gray-900">
                      Analisis AI SiagaBanjir
                    </h3>
                    <p className="mt-1 text-xs text-gray-500">
                      Analisis awal berdasarkan informasi laporan masyarakat.
                    </p>
                  </div>

                  <button
                    onClick={() => handleAnalyzeAI(selectedReport.id)}
                    disabled={analyzing}
                    className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-purple-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {analyzing
                      ? "Menganalisis..."
                      : selectedReport.aiAnalysis
                        ? "Analisis Ulang"
                        : "Analisis dengan AI"}
                  </button>
                </div>

                {selectedReport.aiAnalysis ? (
                  <div className="mt-5 space-y-4">
                    <div>
                      <div className="mb-2 flex flex-wrap items-center gap-2">
                        <span className="text-sm font-semibold text-gray-800">
                          Tingkat Urgensi:
                        </span>
                        <span
                          className={`rounded-full px-3 py-1 text-xs font-semibold ${getSeverityStyle(
                            selectedReport.aiAnalysis.urgency
                          )}`}
                        >
                          {severityLabels[
                            selectedReport.aiAnalysis.urgency
                          ] ?? selectedReport.aiAnalysis.urgency}
                        </span>
                      </div>

                      <p className="text-sm leading-relaxed text-gray-700">
                        {selectedReport.aiAnalysis.summary}
                      </p>
                    </div>

                    <AIList
                      title="Potensi Dampak"
                      items={selectedReport.aiAnalysis.potentialImpact}
                    />

                    <AIList
                      title="Rekomendasi Penanganan"
                      items={selectedReport.aiAnalysis.recommendations}
                    />

                    <AIList
                      title="Hal yang Perlu Diverifikasi Admin"
                      items={selectedReport.aiAnalysis.adminChecks}
                    />

                    <div className="rounded-lg border border-yellow-200 bg-yellow-50 p-3">
                      <p className="text-xs font-semibold text-yellow-800">
                        Batasan Analisis
                      </p>
                      <p className="mt-1 text-sm text-yellow-800">
                        {selectedReport.aiAnalysis.limitations}
                      </p>
                    </div>

                    <p className="text-xs text-gray-400">
                      Model: {selectedReport.aiAnalysis.model || "Gemini"}
                      {selectedReport.aiAnalysis.generatedAt && (
                        <>
                          {" "}• Dibuat:{" "}
                          {formatDate(
                            selectedReport.aiAnalysis.generatedAt
                          )}
                        </>
                      )}
                    </p>
                  </div>
                ) : (
                  <div className="mt-4 rounded-lg border border-dashed border-purple-200 p-5 text-center">
                    <p className="text-sm text-gray-600">
                      Belum ada hasil analisis AI untuk laporan ini.
                    </p>
                    <p className="mt-1 text-xs text-gray-400">
                      Klik tombol di atas untuk memulai analisis.
                    </p>
                  </div>
                )}
              </div>

              {/* Disclaimer */}
              <div className="rounded-lg border border-yellow-200 bg-yellow-50 p-3">
                <p className="text-xs leading-relaxed text-yellow-800">
                  <strong>Catatan:</strong> Analisis AI merupakan informasi
                  pendukung berdasarkan data yang dilaporkan masyarakat,
                  bukan peringatan resmi atau pengganti verifikasi lapangan.
                  Keputusan verifikasi dan penanganan tetap berada pada
                  admin dan pihak berwenang.
                </p>
              </div>
            </div>

            {/* Modal footer */}
            <div className="flex flex-col-reverse justify-between gap-3 border-t border-gray-200 p-5 sm:flex-row sm:items-center">
              <button
                onClick={() => setSelectedReport(null)}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Tutup
              </button>

              {selectedReport.status === "pending" && (
                <div className="flex gap-2">
                  <button
                    onClick={() =>
                      handleUpdateStatus(selectedReport.id, "rejected")
                    }
                    disabled={updating}
                    className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                  >
                    Tolak
                  </button>

                  <button
                    onClick={() =>
                      handleUpdateStatus(selectedReport.id, "verified")
                    }
                    disabled={updating}
                    className="rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-50"
                  >
                    {updating ? "Memproses..." : "Verifikasi"}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Komponen statistik
function StatCard({
  title,
  value,
  color,
}: {
  title: string;
  value: number;
  color: "blue" | "yellow" | "green" | "red";
}) {
  const colors = {
    blue: "bg-blue-50 text-blue-700",
    yellow: "bg-yellow-50 text-yellow-700",
    green: "bg-green-50 text-green-700",
    red: "bg-red-50 text-red-700",
  };

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
      <p className="text-sm text-gray-500">{title}</p>
      <p
        className={`mt-3 inline-flex rounded-lg px-3 py-1 text-2xl font-bold ${colors[color]}`}
      >
        {value}
      </p>
    </div>
  );
}

// Komponen informasi detail
function InfoItem({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div>
      <p className="mb-1 text-xs font-medium text-gray-500">{label}</p>
      <p className="break-words text-sm font-medium text-gray-800">
        {value}
      </p>
    </div>
  );
}

// Komponen daftar hasil AI
function AIList({
  title,
  items,
}: {
  title: string;
  items: string[];
}) {
  if (!items || items.length === 0) return null;

  return (
    <div>
      <h4 className="mb-2 text-sm font-semibold text-gray-800">
        {title}
      </h4>
      <ul className="list-disc space-y-1 pl-5 text-sm text-gray-700">
        {items.map((item, index) => (
          <li key={`${title}-${index}`}>{item}</li>
        ))}
      </ul>
    </div>
  );
}
