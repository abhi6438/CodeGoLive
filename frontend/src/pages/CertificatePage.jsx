import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

function CertCard({ cert, isOwn }) {
  const [copied, setCopied] = useState(false);
  const name = cert.profiles?.display_name || "Learner";
  const date = new Date(cert.issued_at).toLocaleDateString("en-IN", {
    day: "numeric", month: "long", year: "numeric",
  });
  const shareUrl = `${window.location.origin}/certificates/${cert.user_id}`;

  const copyLink = () => {
    navigator.clipboard.writeText(shareUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    });
  };

  return (
    <div className="cert-wrapper">
      <div className="cert-card">
        {/* Decorative top bar */}
        <div className="cert-top-bar" />

        <div className="cert-logo-row">
          <span className="cert-trophy">🎓</span>
        </div>

        <div className="cert-eyebrow">Certificate of Completion</div>

        <div className="cert-course-name">CodeGoLive</div>
        <div className="cert-course-sub">SAP BTP · CAP · SAPUI5 Full Course</div>

        <div className="cert-divider" />

        <p className="cert-certifies">This certifies that</p>
        <div className="cert-name">{name}</div>
        <p className="cert-completed">
          successfully completed all {cert.completed_topics ?? cert.total_topics} topics
        </p>

        <div className="cert-divider" />

        <div className="cert-date">Issued on {date}</div>

        {/* Decorative seal */}
        <div className="cert-seal">
          <div className="cert-seal-inner">✦</div>
        </div>
      </div>

      {/* Share actions */}
      {isOwn && (
        <div className="cert-actions">
          <button
            className={"btn" + (copied ? " btn-outline" : " btn-primary")}
            onClick={copyLink}
            style={copied ? { color: "var(--success)", borderColor: "var(--success)" } : {}}
          >
            {copied ? (
              <>
                <svg width="14" height="14" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <path d="M2 6l3 3 5-5" />
                </svg>
                Link copied!
              </>
            ) : "Copy share link"}
          </button>
          <a
            className="btn btn-outline"
            href={`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(shareUrl)}`}
            target="_blank" rel="noopener noreferrer"
          >
            Share on LinkedIn
          </a>
          <a
            className="btn btn-outline"
            href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(`I just completed the CodeGoLive SAP BTP course! 🎓 ${shareUrl}`)}`}
            target="_blank" rel="noopener noreferrer"
          >
            Share on X
          </a>
        </div>
      )}
    </div>
  );
}

// My certificate (/certificate)
export function MyCertificatePage() {
  const { session } = useAuth();
  const [cert, setCert] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!session) { setLoading(false); return; }
    api.get("/api/certificates/me")
      .then(setCert)
      .catch(() => setCert(null))
      .finally(() => setLoading(false));
  }, [session]);

  if (!session) return (
    <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div className="card" style={{ textAlign: "center", padding: "3rem 2rem", maxWidth: 400 }}>
        <div style={{ fontSize: "2.5rem", marginBottom: "0.75rem" }}>🔐</div>
        <h2 style={{ marginBottom: "0.5rem" }}>Sign in to continue</h2>
        <p style={{ color: "var(--text-2)", marginBottom: "1.25rem" }}>You need to be signed in to view your certificate.</p>
        <Link to="/login" className="btn btn-primary">Sign in</Link>
      </div>
    </div>
  );

  if (loading) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "50vh", color: "var(--text-3)" }}>
      Loading your certificate…
    </div>
  );

  if (!cert) return (
    <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div className="card" style={{ textAlign: "center", padding: "3rem 2rem", maxWidth: 440 }}>
        <div style={{ fontSize: "3rem", marginBottom: "0.75rem", opacity: 0.6 }}>🔒</div>
        <h2 style={{ marginBottom: "0.5rem" }}>Not yet earned</h2>
        <p style={{ color: "var(--text-2)", marginBottom: "1.25rem" }}>
          Complete all 17 topics to unlock your certificate of completion.
        </p>
        <Link to="/" className="btn btn-primary">Continue learning →</Link>
      </div>
    </div>
  );

  return (
    <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>
      <CertCard cert={cert} isOwn={true} />
    </div>
  );
}

// Public share page (/certificates/:userId)
export function PublicCertificatePage() {
  const { userId } = useParams();
  const [cert, setCert] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get(`/api/certificates/${userId}/public`)
      .then(setCert)
      .catch(() => setCert(null))
      .finally(() => setLoading(false));
  }, [userId]);

  if (loading) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "50vh", color: "var(--text-3)" }}>
      Loading certificate…
    </div>
  );

  if (!cert) return (
    <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div className="card" style={{ textAlign: "center", padding: "3rem 2rem" }}>
        <p style={{ color: "var(--text-2)" }}>No certificate found for this user.</p>
        <Link to="/" className="btn btn-outline" style={{ marginTop: "1rem" }}>Go to Course</Link>
      </div>
    </div>
  );

  return (
    <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>
      <CertCard cert={cert} isOwn={false} />
    </div>
  );
}
