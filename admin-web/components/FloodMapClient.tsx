
"use client";

import dynamic from "next/dynamic";

const FloodMap = dynamic(() => import("./FloodMap"), {
  ssr: false,
  loading: () => (
    <div className="flex h-[600px] items-center justify-center rounded-2xl bg-white text-slate-500">
      Memuat peta SiagaBanjir...
    </div>
  ),
});

export default function FloodMapClient() {
  return <FloodMap />;
}
