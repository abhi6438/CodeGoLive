import { useEffect, useRef } from "react";
import { useLocation } from "react-router-dom";
import { api } from "../lib/api";

/**
 * Silently records a page view on every route change.
 * Also records time spent on the previous page when the user navigates away.
 * Renders nothing — mount once inside <App>.
 */
export function usePageView() {
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
