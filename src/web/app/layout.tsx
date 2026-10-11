import type { Metadata } from "next";
import { ja } from "../lib/ja";
import "./globals.css";
export const metadata: Metadata = { title:ja.title, description:ja.description };
export default function RootLayout({ children }: Readonly<{children:React.ReactNode}>) {
  return <html lang="ja"><body>{children}</body></html>;
}
