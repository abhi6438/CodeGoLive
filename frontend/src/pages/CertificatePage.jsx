import { useEffect, useState } from "react";
import SEO from "../components/SEO";
import QuoteCard from "../components/QuoteCard";
import { QUOTES } from "../constants/quotes";
import { useParams, Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

function CertCard({ cert, isOwn }) {
  const [copied, setCopied] = useState(false);
  const name = cert.profiles?.display_name || "Learner";
  const date = new Date(cert.issued_at).toLocaleDateString("en-GB", {
    day: "numeric", month: "long", year: "numeric",
  });
  const certId = `CGL-${cert.user_id.slice(0, 8).toUpperCase()}`;
  const shareUrl = `${window.location.origin}/certificates/${cert.user_id}`;

  const copyLink = () => {
    navigator.clipboard.writeText(shareUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    });
  };

  return (
    <div className="cert-wrapper">
      {/* ── The Certificate ── */}
      <div className="cert-card">
        {/* Corner ornaments */}
        <div className="cert-corner cert-corner-tr" />
        <div className="cert-corner cert-corner-bl" />
        {/* Ambient glows */}
        <div className="cert-glow-top" />
        <div className="cert-glow-bottom" />

        <div className="cert-inner-grid">
          {/* LEFT — brand + seal */}
          <div className="cert-col-left">
            <div className="cert-brand">
              <svg width="36" height="36" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                <defs>
                  <linearGradient id="cg-cert-grad" x1="0" y1="0" x2="32" y2="32">
                    <stop offset="0%" stopColor="#7c7dfa" />
                    <stop offset="100%" stopColor="#3730a3" />
                  </linearGradient>
                </defs>
                <rect width="32" height="32" rx="7" fill="url(#cg-cert-grad)" />
                <ellipse cx="8" cy="7" rx="10" ry="8" fill="white" fillOpacity="0.07" />
                <path d="M9.5 11.5 L17.5 16 L9.5 20.5" stroke="white" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" />
                <rect x="19.5" y="19" width="5" height="2.6" rx="1.3" fill="white" fillOpacity="0.85" />
                <circle cx="25.5" cy="7.5" r="2.2" fill="#a5f3fc" fillOpacity="0.9" />
              </svg>
              <span className="cert-brand-name">CodeGoLive</span>
            </div>

            <div className="cert-seal-ring">
              <span className="cert-seal-star">✦</span>
            </div>

            <span className="cert-vert-text">Verified Completion</span>
          </div>

          {/* CENTRE — achievement */}
          <div className="cert-col-centre">
            <div className="cert-eyebrow">Certificate of Completion</div>
            <div className="cert-title-text">This certifies that</div>
            <div className="cert-divider-gold" />
            <div className="cert-presented-to">awarded to</div>
            <div className="cert-name">{name}</div>
            <p className="cert-completed">
              has successfully completed all modules and assessments of
            </p>
            <div className="cert-course-pill">SAP BTP Development with CAP</div>
            <div className="cert-meta-row">
              <div className="cert-meta-item">
                <span className="cert-meta-label">Issued</span>
                <span className="cert-meta-val">{date}</span>
              </div>
              <div className="cert-meta-dot" />
              <div className="cert-meta-item">
                <span className="cert-meta-label">Topics</span>
                <span className="cert-meta-val">{cert.completed_topics ?? cert.total_topics}</span>
              </div>
              <div className="cert-meta-dot" />
              <div className="cert-meta-item">
                <span className="cert-meta-label">ID</span>
                <span className="cert-meta-val">{certId}</span>
              </div>
            </div>
          </div>

          {/* RIGHT — validation */}
          <div className="cert-col-right">
            <div className="cert-verified">
              <div className="cert-verified-icon">✓</div>
              <div className="cert-verified-label">Verified<br />Certificate</div>
            </div>

            <div className="cert-skills">
              <div className="cert-skills-title">Skills Covered</div>
              <div className="cert-chips">
                {["CAP", "Node.js", "CDS", "HANA Cloud", "OData", "BTP CF"].map(s => (
                  <span key={s} className="cert-chip">{s}</span>
                ))}
              </div>
            </div>

            <div className="cert-sig">
              <div className="cert-sig-line" />
              <div className="cert-sig-name">CodeGoLive</div>
              <div className="cert-sig-role">Course Platform</div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Actions ── */}
      <div className="cert-actions">
        <button className="btn btn-outline" onClick={() => window.print()}>
          <svg width="13" height="13" viewBox="0 0 16 16" fill="currentColor">
            <path d="M8 12L2 6h3V1h6v5h3L8 12zm-6 3h12v-1.5H2V15z" />
          </svg>
          Download PDF
        </button>

        {isOwn && (
          <>
            <button
              className={"btn " + (copied ? "btn-outline" : "btn-primary")}
              onClick={copyLink}
              style={copied ? { color: "var(--success)", borderColor: "var(--success)" } : {}}
            >
              {copied ? "✓ Link copied!" : "Copy share link"}
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
          </>
        )}
      </div>

      <p className="cert-verify-note">
        Publicly verifiable at {window.location.origin}/certificates/{cert.user_id}
      </p>
    </div>
  );
}

/* ── My certificate (/certificate) ────────────────────────────────────── */
export function MyCertificatePage() {
  const { session } = useAuth();
  const [cert, setCert] = useState(null);
  const [assessmentStatus, setAssessmentStatus] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!session) { setLoading(false); return; }
    Promise.all([
      api.get("/api/certificates/me").catch(() => null),
      api.get("/api/assessment/status").catch(() => null),
    ]).then(([certData, asmtData]) => {
      setCert(certData);
      setAssessmentStatus(asmtData);
    }).finally(() => setLoading(false));
  }, [session]);

  if (!session) return (
    <>
      <SEO title="My Certificate" robots="noindex, nofollow" />
      <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div className="card" style={{ textAlign: "center", padding: "3rem 2rem", maxWidth: 400 }}>
          <div style={{ fontSize: "2.5rem", marginBottom: "0.75rem" }}>🔐</div>
          <h2 style={{ marginBottom: "0.5rem" }}>Sign in to continue</h2>
          <p style={{ color: "var(--text-2)", marginBottom: "1.25rem" }}>You need to be signed in to view your certificate.</p>
          <Link to="/login" className="btn btn-primary">Sign in</Link>
        </div>
      </div>
    </>
  );

  if (loading) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "50vh", color: "var(--text-3)" }}>
      Loading your certificate…
    </div>
  );

  // Certificate earned
  if (cert) return (
    <>
      <SEO title="My Certificate" robots="noindex, nofollow" />
      <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>
        <div style={{ maxWidth: 960, margin: "1.5rem auto 0", padding: "0 1.5rem" }}>
          <QuoteCard quote={QUOTES.CERTIFICATE} emoji="📜" variant="success" />
        </div>
        <CertCard cert={cert} isOwn={true} />
      </div>
    </>
  );

  // Assessment not yet passed
  const assessmentPassed = assessmentStatus?.passed;
  const lastAttempt = assessmentStatus?.last_attempt;

  if (!assessmentPassed) return (
    <>
      <SEO title="My Certificate" robots="noindex, nofollow" />
      <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center", padding: "2rem 1rem" }}>
        <div className="card" style={{ textAlign: "center", padding: "3rem 2rem", maxWidth: 500 }}>
          <div style={{ fontSize: "3rem", marginBottom: "0.75rem" }}>📋</div>
          <QuoteCard quote={QUOTES.ASSESSMENT_RETRY} emoji="🔄" variant="warning" style={{marginBottom:"1rem"}} />
          <h2 style={{ marginBottom: "0.5rem" }}>One step left — Final Assessment</h2>
          <p style={{ color: "var(--text-2)", marginBottom: "1rem", lineHeight: 1.6 }}>
            To earn your certificate, pass the <strong>Final Assessment</strong> with 70% or higher.
            30 questions chosen randomly from a pool of 55+, unlimited retakes.
          </p>
          {lastAttempt && (
            <p style={{ fontSize: "0.85rem", color: "var(--text-3)", marginBottom: "1rem" }}>
              Last attempt: {lastAttempt.score}/{lastAttempt.total} ({Math.round((lastAttempt.score / lastAttempt.total) * 100)}%)
            </p>
          )}
          <div style={{ display: "flex", gap: "0.75rem", justifyContent: "center", flexWrap: "wrap" }}>
            <Link to="/assessment" className="btn btn-primary">Take the Assessment →</Link>
            <Link to="/" className="btn" style={{ background: "var(--bg)", border: "1px solid var(--border)" }}>Back to Courses</Link>
          </div>
        </div>
      </div>
    </>
  );

  // Assessment passed, topics not all done yet
  return (
    <>
      <SEO title="My Certificate" robots="noindex, nofollow" />
      <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div className="card" style={{ textAlign: "center", padding: "3rem 2rem", maxWidth: 440 }}>
          <div style={{ fontSize: "3rem", marginBottom: "0.75rem" }}>📚</div>
          <QuoteCard quote={QUOTES.MILESTONE} emoji="🎯" variant="default" style={{marginBottom:"1rem"}} />
          <h2 style={{ marginBottom: "0.5rem" }}>Almost there!</h2>
          <p style={{ color: "var(--text-2)", marginBottom: "1.25rem" }}>
            You've passed the assessment! Complete all remaining topics to unlock your certificate.
          </p>
          <Link to="/" className="btn btn-primary">Continue learning →</Link>
        </div>
      </div>
    </>
  );
}

/* ── Public share page (/certificates/:userId) ─────────────────────────── */
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
    <>
      <SEO title="Certificate Not Found" />
      <div style={{ minHeight: "calc(100vh - 64px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div className="card" style={{ textAlign: "center", padding: "3rem 2rem" }}>
          <p style={{ color: "var(--text-2)" }}>No certificate found for this user.</p>
          <Link to="/" className="btn btn-outline" style={{ marginTop: "1rem" }}>Go to Course</Link>
        </div>
      </div>
    </>
  );

  const name = cert.profiles?.display_name || "This learner";
  return (
    <>
      <SEO
        title={`${name}'s Certificate`}
        description={`${name} successfully completed the CodeGoLive SAP BTP Development with CAP course.`}
      />
      <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>
        <div style={{ maxWidth: 960, margin: "1.5rem auto 0", padding: "0 1.5rem" }}>
          <QuoteCard quote={QUOTES.SUCCESS} emoji="🎉" variant="success" />
        </div>
        <CertCard cert={cert} isOwn={false} />
      </div>
    </>
  );
}
