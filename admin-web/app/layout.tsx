import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SiagaBanjir | Admin Panel",
  description: "Panel administrator pemantauan laporan banjir",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}