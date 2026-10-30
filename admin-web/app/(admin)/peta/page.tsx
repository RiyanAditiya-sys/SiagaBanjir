
import FloodMapClient from "@/components/FloodMapClient";

export default function PetaPage() {
  return (
    <div className="space-y-7">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">
            Peta Pemantauan Banjir
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Pantau persebaran laporan banjir yang telah diverifikasi.
          </p>
        </div>

        <div className="flex items-center gap-2 rounded-xl bg-green-50 px-4 py-3 text-sm font-semibold text-green-700">
          <span className="h-2.5 w-2.5 rounded-full bg-green-500" />
          Data laporan terverifikasi
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-slate-100 bg-white p-4 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full bg-green-500" />
            <span className="text-sm text-slate-600">Risiko Rendah</span>
          </div>
        </div>

        <div className="rounded-xl border border-slate-100 bg-white p-4 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full bg-orange-500" />
            <span className="text-sm text-slate-600">Risiko Sedang</span>
          </div>
        </div>

        <div className="rounded-xl border border-slate-100 bg-white p-4 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full bg-red-500" />
            <span className="text-sm text-slate-600">Risiko Tinggi</span>
          </div>
        </div>
      </div>

      <section className="overflow-hidden rounded-2xl border border-slate-100 bg-white p-3 shadow-sm">
        <div className="mb-3 px-2 py-2">
          <h2 className="font-bold text-slate-800">
            Sebaran Titik Banjir
          </h2>
          <p className="mt-1 text-xs text-slate-500">
            Pilih marker pada peta untuk melihat informasi laporan.
          </p>
        </div>

        <FloodMapClient />
      </section>

      <div className="rounded-xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-sm leading-6 text-blue-800">
          <strong>Informasi:</strong> Titik pada peta berasal dari laporan
          masyarakat yang telah diverifikasi administrator. Informasi ini
          merupakan data pemantauan dan bukan pengganti peringatan resmi
          dari instansi berwenang.
        </p>
      </div>
    </div>
  );
}
