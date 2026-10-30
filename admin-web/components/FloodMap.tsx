
"use client";

import { useEffect, useState } from "react";
import {
  CircleMarker,
  MapContainer,
  Popup,
  TileLayer,
  useMap,
} from "react-leaflet";

import {
  collection,
  onSnapshot,
  query,
  where,
} from "firebase/firestore";

import { db } from "@/lib/firebase";

type FloodReport = {
  id: string;
  location: string;
  latitude: number;
  longitude: number;
  waterHeightCm: number;
  severity: "low" | "medium" | "high";
  description?: string;
};

const severityConfig = {
  low: {
    label: "Rendah",
    color: "#16a34a",
  },
  medium: {
    label: "Sedang",
    color: "#f59e0b",
  },
  high: {
    label: "Tinggi",
    color: "#dc2626",
  },
};

function MapController({ reports }: { reports: FloodReport[] }) {
  const map = useMap();

  useEffect(() => {
    const refreshMap = () => {
      map.invalidateSize();

      const validReports = reports.filter(
        (report) =>
          Number.isFinite(report.latitude) &&
          Number.isFinite(report.longitude) &&
          Math.abs(report.latitude) <= 90 &&
          Math.abs(report.longitude) <= 180
      );

      if (validReports.length === 1) {
        map.setView(
          [validReports[0].latitude, validReports[0].longitude],
          13
        );
      } else if (validReports.length > 1) {
        const bounds = validReports.map(
          (report) =>
            [report.latitude, report.longitude] as [number, number]
        );

        map.fitBounds(bounds, {
          padding: [40, 40],
          maxZoom: 13,
        });
      }
    };

    const frame = requestAnimationFrame(refreshMap);

    const resizeObserver = new ResizeObserver(() => {
      map.invalidateSize();
    });

    resizeObserver.observe(map.getContainer());

    return () => {
      cancelAnimationFrame(frame);
      resizeObserver.disconnect();
    };
  }, [map, reports]);

  return null;
}

export default function FloodMap() {
  const [reports, setReports] = useState<FloodReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const reportsQuery = query(
      collection(db, "reports"),
      where("status", "==", "verified")
    );

    const unsubscribe = onSnapshot(
      reportsQuery,
      (snapshot) => {
        const data = snapshot.docs.map((item) => ({
          id: item.id,
          ...item.data(),
        })) as FloodReport[];

        setReports(data);
        setLoading(false);
        setError("");
      },
      (err) => {
        console.error("Firebase map error:", err);
        setError(
          "Gagal mengambil data laporan. Periksa koneksi Firebase dan Firestore Rules."
        );
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const validReports = reports.filter(
    (report) =>
      Number.isFinite(report.latitude) &&
      Number.isFinite(report.longitude) &&
      Math.abs(report.latitude) <= 90 &&
      Math.abs(report.longitude) <= 180
  );

  return (
    <div className="space-y-4">
      {/* Informasi tingkat bahaya */}
      <div className="flex flex-wrap items-center gap-5 rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <div>
          <p className="text-xs text-slate-500">
            Total titik terverifikasi
          </p>
          <p className="text-2xl font-bold text-[#102a43]">
            {validReports.length}
          </p>
        </div>

        <div className="h-10 w-px bg-slate-200" />

        {Object.entries(severityConfig).map(([key, value]) => (
          <div key={key} className="flex items-center gap-2">
            <span
              className="h-3 w-3 rounded-full"
              style={{ backgroundColor: value.color }}
            />
            <span className="text-sm text-slate-600">
              {value.label}
            </span>
          </div>
        ))}
      </div>

      {/* Status */}
      {loading && (
        <div className="rounded-xl bg-blue-50 p-4 text-sm text-blue-700">
          Sedang memuat data laporan...
        </div>
      )}

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Peta */}
      <div className="relative z-0 h-[600px] w-full overflow-hidden rounded-2xl border border-slate-200 bg-slate-100 shadow-sm">
        <MapContainer
          center={[-2.5, 118]}
          zoom={5}
          minZoom={4}
          maxZoom={18}
          scrollWheelZoom={true}
          preferCanvas={true}
          className="h-full w-full"
          style={{
            height: "100%",
            width: "100%",
            background: "#e8eef2",
          }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            maxZoom={19}
            updateWhenIdle={false}
            keepBuffer={4}
          />

          <MapController reports={validReports} />

          {validReports.map((report) => {
            const severity =
              severityConfig[report.severity] ||
              severityConfig.low;

            return (
              <CircleMarker
                key={report.id}
                center={[
                  report.latitude,
                  report.longitude,
                ]}
                radius={10}
                pathOptions={{
                  color: "#ffffff",
                  weight: 3,
                  fillColor: severity.color,
                  fillOpacity: 0.9,
                }}
              >
                <Popup>
                  <div className="min-w-[190px] space-y-2">
                    <h3 className="text-sm font-bold">
                      {report.location || "Lokasi tidak diketahui"}
                    </h3>

                    <p className="text-sm">
                      Tingkat bahaya:{" "}
                      <strong>{severity.label}</strong>
                    </p>

                    <p className="text-sm">
                      Ketinggian air:{" "}
                      <strong>
                        {report.waterHeightCm ?? 0} cm
                      </strong>
                    </p>

                    {report.description && (
                      <p className="text-sm">
                        {report.description}
                      </p>
                    )}

                    <a
                      href={`https://www.google.com/maps?q=${report.latitude},${report.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-block text-sm font-semibold text-blue-600"
                    >
                      Buka Google Maps ↗
                    </a>
                  </div>
                </Popup>
              </CircleMarker>
            );
          })}
        </MapContainer>
      </div>

      {!loading && validReports.length === 0 && !error && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          Belum ada laporan terverifikasi dengan koordinat GPS yang valid.
        </div>
      )}

      <p className="text-xs text-slate-400">
        Data peta diperbarui secara otomatis berdasarkan laporan
        terverifikasi di Firebase.
      </p>
    </div>
  );
}
