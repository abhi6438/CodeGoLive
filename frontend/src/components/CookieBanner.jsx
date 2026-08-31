import { useState, useEffect } from "react";
import { Link } from "react-router-dom";

const STORAGE_KEY = "cgl-cookie-consent";

export default function CookieBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    try {
      const accepted = localStorage.getItem(STORAGE_KEY);
      if (!accepted) setVisible(true);
    } catch {
      // localStorage unavailable — don't show banner
    }
  }, []);

  const accept = () => {
    try { localStorage.setItem(STORAGE_KEY, "accepted"); } catch {}
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div className="cookie-banner" role="region" aria-label="Cookie notice">
      <p className="cookie-banner-text">
        We use essential cookies for authentication and store your theme preference locally.{" "}
        <Link to="/cookies" className="cookie-banner-link">Learn more</Link>
      </p>
      <div className="cookie-banner-actions">
        <Link to="/cookies" className="btn btn-outline cookie-banner-policy">Cookie Policy</Link>
        <button className="btn btn-primary cookie-banner-accept" onClick={accept}>
          Got it
        </button>
      </div>
    </div>
  );
}
