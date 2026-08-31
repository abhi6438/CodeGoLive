import { useEffect, useRef } from "react";
import { useLocation } from "react-router-dom";
import { api } from "../lib/api";

const GA_ID = "G-HS2RZYBJ2Y";

/* Inject GA4 script tags once, only in production */
function loadGA4() {
  if (!import.meta.env.PROD) return;
  if (window.__ga4Loaded) return;
  window.__ga4Loaded = true;

  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`;
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag() { window.dataLayer.push(arguments); };
  window.gtag("js", new Date());
  window.gtag("config", GA_ID, { send_page_view: false });
}

/**
 * Silently records a page view on every route change.
 * Also records time spent on the previous page when the user navigates away.
 * Renders nothing — mount once inside <App>.
 */
export function usePageView() {
  useEffect(() => { loadGA4(); }, []);
  const location = useLocation();
  const entryTimeRef = useRef(Date.now());
  const viewIdRef    = useRef(null);

  useEffect(() => {
    const path     = location.pathname;
    const referrer = document.referrer || null;

    // Record time spent on the PREVIOUS page before starting a new view
    const prevId       = viewIdRef.current;
    const prevEntry    = entryTimeRef.current;
    if (prevId) {
      const duration = Math.round((Date.now() - prevEntry) / 1000);
      if (duration > 0 && duration < 86400) {
        api.patch(`/api/analytics/${prevId}`, { duration_seconds: duration }).catch(() => {});
      }
    }

    // Reset timer for the new page
    entryTimeRef.current = Date.now();
    viewIdRef.current    = null;

    // Fire GA4 page-view (production only)
    if (import.meta.env.PROD && typeof window.gtag === "function") {
      window.gtag("event", "page_view", { page_path: path });
    }

    // Record the new page view (fire-and-forget)
    api.post("/api/analytics", { path, referrer })
      .then((res) => { if (res?.id) viewIdRef.current = res.id; })
      .catch(() => {});

    // On tab close / visibility hide — record duration for current page
    const handleVisibility = () => {
      if (document.visibilityState === "hidden" && viewIdRef.current) {
        const duration = Math.round((Date.now() - entryTimeRef.current) / 1000);
        if (duration > 0 && duration < 86400) {
          // Use sendBeacon so it fires even during unload
          const payload = JSON.stringify({ duration_seconds: duration });
          const url = `/api/analytics/${viewIdRef.current}`;
          if (navigator.sendBeacon) {
            navigator.sendBeacon(url, new Blob([payload], { type: "application/json" }));
          } else {
            api.patch(url, { duration_seconds: duration }).catch(() => {});
          }
        }
      }
    };

    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [location.pathname]);
}

export default function PageViewTracker() {
  usePageView();
  return null;
}
