import { useEffect, useState, useRef } from "react";
import { toPng } from "html-to-image";
import SEO from "../components/SEO";
import { useParams, Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

function CertCard({ cert, isOwn }) {
  const [copied, setCopied] = useState(false);
  const [format, setFormat] = useState("landscape");
  const [imgLoading, setImgLoading] = useState(false);
  const certRef = useRef(null); // landscape | portrait | whatsapp

  const handleDownload = () => {
    const existing = document.getElementById("cgl-print-page");
    if (existing) existing.remove();
    const style = document.createElement("style");
    style.id = "cgl-print-page";
    style.textContent = format === "landscape"
      ? "@page { size: landscape; }"
      : "@page { size: portrait; }";
    document.head.appendChild(style);
    window.print();
    setTimeout(() => document.getElementById("cgl-print-page")?.remove(), 1500);
  };

  const handleDownloadImage = async () => {
    const el = certRef.current;
    if (!el) return;
    setImgLoading(true);
    try {
      await document.fonts.ready;
      const rect = el.getBoundingClientRect();

      // Pass style overrides directly to html-to-image so it applies them
      // to its internal clone — the real DOM element is never touched,
      // no flash, and the clone inherits the full CSS cascade.
      // position:fixed + top/left:0 moves the clone to the viewport origin
      // so the capture doesn't include the margin:0 auto offset whitespace.
      const dataUrl = await toPng(el, {
        pixelRatio: 2,
        width: rect.width,
        height: rect.height,
        cacheBust: true,
        style: {
          width:       rect.width  + "px",
          height:      rect.height + "px",
          minWidth:    rect.width  + "px",
          minHeight:   rect.height + "px",
          maxWidth:    rect.width  + "px",
          aspectRatio: "unset",
          position:    "fixed",
          top:         "0",
          left:        "0",
          margin:      "0",
        },
      });

      const link = document.createElement("a");
      link.download = `codegolive-certificate-${format === "whatsapp" ? "mobile" : format}.png`;
      link.href = dataUrl;
      link.click();
    } catch (e) { console.error(e); }
    finally { setImgLoading(false); }
  };
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
      {/* ── Format Picker ── */}
      <div className="cert-format-picker">
        {[
          { key: "landscape", icon: "⬛", label: "Landscape" },
          { key: "portrait",  icon: "📄", label: "Portrait" },
          { key: "whatsapp",  icon: "📱", label: "Mobile" },
        ].map((f) => (
          <button
            key={f.key}
            className={`cert-fmt-btn${format === f.key ? " cert-fmt-btn--active" : ""}`}
            onClick={() => setFormat(f.key)}
          >
            <span className="cert-fmt-icon">{f.icon}</span>
            <span>{f.label}</span>
          </button>
        ))}
      </div>

      {/* ── WhatsApp Status Card ── */}
      {format === "whatsapp" && (
        <div className="cert-wa-card" ref={certRef}>
          <div className="cert-corner cert-corner-tr" />
          <div className="cert-corner cert-corner-bl" />
          <div className="cert-wa-circle cert-wa-circle--tl" />
          <div className="cert-wa-circle cert-wa-circle--br" />

          {/* ── Row 1: brand | label | seal ── */}
          <div className="cert-wa-top">
            <div className="cert-wa-brand">
              <svg width="26" height="26" viewBox="0 0 32 32" fill="none">
                <defs>
                  <linearGradient id="cg-wa-grad" x1="0" y1="0" x2="32" y2="32">
                    <stop offset="0%" stopColor="#a5b4fc"/>
                    <stop offset="100%" stopColor="#6366f1"/>
                  </linearGradient>
                </defs>
                <rect width="32" height="32" rx="7" fill="url(#cg-wa-grad)"/>
                <path d="M9.5 11.5 L17.5 16 L9.5 20.5" stroke="white" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"/>
                <rect x="19.5" y="19" width="5" height="2.6" rx="1.3" fill="white" fillOpacity="0.85"/>
              </svg>
              <span className="cert-wa-brand-name">CodeGoLive</span>
            </div>
            <div className="cert-wa-top-label">Verified<br/>Completion</div>
            <div className="cert-wa-seal-col">
              <div className="cert-wa-top-ring" style={{width:44,height:44,minWidth:44,minHeight:44,borderRadius:"50%",flexShrink:0}}>
                <span className="cert-wa-top-star">✦</span>
              </div>
            </div>
          </div>

          <div className="cert-wa-divider" />

          {/* ── Row 2: certificate body ── */}
          <div className="cert-wa-center">
            <div className="cert-wa-eyebrow">Certificate of Completion</div>
            <div className="cert-wa-title-text">This certifies that</div>
            <div className="cert-wa-line" />
            <div className="cert-wa-awarded">awarded to</div>
            <div className="cert-wa-name">{name}</div>
            <div className="cert-wa-completed-text">has successfully completed all modules and assessments of</div>
            <div className="cert-wa-course" style={{display:"block",textAlign:"center",alignSelf:"center",width:"100%",boxSizing:"border-box"}}>SAP BTP Development with CAP</div>
            <div className="cert-wa-meta-inline">
              <div className="cert-wa-meta-col">
                <span className="cert-wa-meta-label">Issued</span>
                <span className="cert-wa-meta-val">{date}</span>
              </div>
              <span className="cert-wa-meta-dot">·</span>
              <div className="cert-wa-meta-col">
                <span className="cert-wa-meta-label">Topics</span>
                <span className="cert-wa-meta-val">{cert.completed_topics ?? cert.total_topics ?? "—"}</span>
              </div>
              <span className="cert-wa-meta-dot">·</span>
              <div className="cert-wa-meta-col">
                <span className="cert-wa-meta-label">Certificate No.</span>
                <span className="cert-wa-meta-val">CGL-{cert.user_id.slice(0,8).toUpperCase()}</span>
              </div>
            </div>
          </div>

          <div className="cert-wa-divider" />

          {/* ── Row 3: verified | sig ── */}
          <div className="cert-wa-bottom">
            <div className="cert-wa-verified">
              <div className="cert-verified-icon" style={{width:28,height:28,minWidth:28,minHeight:28,borderRadius:"50%",fontSize:"0.75rem",flexShrink:0}}>✓</div>
              <div className="cert-verified-label" style={{fontSize:"0.5rem"}}>Verified<br/>Certificate</div>
            </div>
            <div className="cert-wa-footer-sep" />
            <div className="cert-wa-sig">
              <div className="cert-wa-sig-line" />
              <div className="cert-wa-sig-name">CodeGoLive</div>
              <div className="cert-wa-url">codegolive.com</div>
            </div>
          </div>
        </div>
      )}

      {/* ── The Certificate (landscape / portrait) ── */}
      {format === "portrait" && (
        <div className="cert-card cert-card--portrait" ref={certRef}>
          <div className="cert-corner cert-corner-tr" /><div className="cert-corner cert-corner-bl" />
          <div className="cert-glow-top" /><div className="cert-glow-bottom" />
          <div className="cert-portrait-body">
            {/* Header row */}
            <div className="cert-pt-header">
              <div className="cert-brand">
                <svg width="30" height="30" viewBox="0 0 32 32" fill="none">
                  <defs><linearGradient id="cg-pt-grad" x1="0" y1="0" x2="32" y2="32">
                    <stop offset="0%" stopColor="#7c7dfa"/><stop offset="100%" stopColor="#3730a3"/>
                  </linearGradient></defs>
                  <rect width="32" height="32" rx="7" fill="url(#cg-pt-grad)"/>
                  <path d="M9.5 11.5 L17.5 16 L9.5 20.5" stroke="white" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"/>
                  <rect x="19.5" y="19" width="5" height="2.6" rx="1.3" fill="white" fillOpacity="0.85"/>
                </svg>
                <span className="cert-brand-name">CodeGoLive</span>
              </div>
              <div className="cert-pt-header-label">Verified<br/>Completion</div>
              <div className="cert-pt-seal-col">
                <div className="cert-pt-top-ring" style={{width:52,height:52,minWidth:52,minHeight:52,borderRadius:"50%",flexShrink:0}}>
                  <span className="cert-seal-star">✦</span>
                </div>
              </div>
            </div>
            <div className="cert-pt-divider" />
            {/* Main content */}
            <div className="cert-pt-main">
              <div className="cert-eyebrow">Certificate of Completion</div>
              <div className="cert-title-text">This certifies that</div>
              <div className="cert-divider-gold" />
              <div className="cert-presented-to">awarded to</div>
              <div className="cert-name">{name}</div>
              <p className="cert-completed">has successfully completed all modules and assessments of</p>
              <div className="cert-course-pill" style={{display:"block",textAlign:"center",alignSelf:"center"}}>SAP BTP Development with CAP</div>
              <div className="cert-meta-row" style={{justifyContent:"center",marginTop:"1.5rem"}}>
                <div className="cert-meta-item"><span className="cert-meta-label">Issued</span><span className="cert-meta-val">{date}</span></div>
                <div className="cert-meta-dot"/>
                <div className="cert-meta-item"><span className="cert-meta-label">Topics</span><span className="cert-meta-val">{cert.completed_topics ?? cert.total_topics}</span></div>
                <div className="cert-meta-dot"/>
                <div className="cert-meta-item"><span className="cert-meta-label">Certificate No.</span><span className="cert-meta-val">{certId}</span></div>
              </div>
            </div>
            <div className="cert-pt-divider" />
            {/* Footer — 3 sections: verified | skills | sig */}
            <div className="cert-pt-footer">
              {/* Section 1: Verified Certificate */}
              <div className="cert-verified" style={{flexDirection:"column",gap:"0.4rem"}}>
                <div className="cert-verified-icon" style={{width:32,height:32,minWidth:32,minHeight:32,borderRadius:"50%",flexShrink:0}}>✓</div>
                <div className="cert-verified-label">Verified<br/>Certificate</div>
              </div>
              <div className="cert-pt-footer-sep" />
              {/* Section 2: Skills */}
              <div className="cert-skills" style={{flex:1}}>
                <div className="cert-skills-title">Skills Covered</div>
                <div className="cert-chips">
                  {["CAP","Node.js","CDS","HANA Cloud","OData","BTP CF"].map(s=>(
                    <span key={s} className="cert-chip">{s}</span>
                  ))}
                </div>
              </div>
              <div className="cert-pt-footer-sep" />
              {/* Section 3: Signature */}
              <div className="cert-sig">
                <div className="cert-sig-line"/>
                <div className="cert-sig-name">CodeGoLive</div>
                <div className="cert-sig-role">Course Platform</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {format === "landscape" && <div className={`cert-card cert-card--landscape`} ref={certRef}>
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

            <div className="cert-seal-ring" style={{width:70,height:70,minWidth:70,minHeight:70,borderRadius:"50%",flexShrink:0}}>
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
            <div className="cert-course-pill" style={{display:"block",textAlign:"center",alignSelf:"center"}}>SAP BTP Development with CAP</div>
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
                <span className="cert-meta-label">Certificate No.</span>
                <span className="cert-meta-val">{certId}</span>
              </div>
            </div>
          </div>

          {/* RIGHT — validation */}
          <div className="cert-col-right">
            <div className="cert-verified">
              <div className="cert-verified-icon" style={{width:32,height:32,minWidth:32,minHeight:32,borderRadius:"50%",flexShrink:0}}>✓</div>
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
      </div>}

      {/* ── Actions ── */}
      <div className="cert-actions">
        <button className="btn btn-outline" onClick={handleDownload}>
          <svg width="13" height="13" viewBox="0 0 16 16" fill="currentColor">
            <path d="M8 12L2 6h3V1h6v5h3L8 12zm-6 3h12v-1.5H2V15z" />
          </svg>
          Download PDF
        </button>
        <button
          className="btn btn-outline"
          onClick={handleDownloadImage}
          disabled={imgLoading}
          style={{display:"flex",alignItems:"center",gap:"0.5rem"}}
        >
          {imgLoading ? "Generating…" : "⬇ Download Image"}
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
          <h2 style={{ marginBottom: "0.5rem" }}>One step left — Final Assessment</h2>
          <p style={{ color: "var(--text-2)", marginBottom: "1rem", lineHeight: 1.6 }}>
            To earn your certificate, pass the <strong>Final Assessment</strong> with 70% or higher.

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
        </div>
        <CertCard cert={cert} isOwn={false} />
      </div>
    </>
  );
}

/* ── Certificate Verification page (/verify) ──────────────────────────── */
export function VerifyCertificatePage() {
  const [query, setQuery] = useState("");
  const [cert, setCert] = useState(null);
  const [status, setStatus] = useState("idle"); // idle | loading | found | notfound | error
  const [errMsg, setErrMsg] = useState("");

  const handleSearch = async (e) => {
    e.preventDefault();
    const raw = query.trim().toUpperCase();
    if (!raw) return;
    setStatus("loading");
    setCert(null);
    try {
      const data = await api.get(`/api/certificates/verify/${encodeURIComponent(raw)}`);
      setCert(data);
      setStatus("found");
    } catch (err) {
      if (err?.response?.status === 404) {
        setStatus("notfound");
      } else if (err?.response?.status === 400) {
        setErrMsg(err?.response?.data?.detail || "Invalid ID format.");
        setStatus("error");
      } else {
        setErrMsg("Something went wrong. Please try again.");
        setStatus("error");
      }
    }
  };

  return (
    <>
      <SEO title="Verify Certificate" description="Verify the authenticity of a CodeGoLive certificate using its Cert No." />
      <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>

        {/* Hero search area */}
        <div style={{
          background: "linear-gradient(135deg, #0d1526 0%, #0e1d3a 100%)",
          borderBottom: "1px solid var(--border)",
          padding: "3rem 1.5rem 2.5rem",
          textAlign: "center"
        }}>
          <div style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>🎓</div>
          <h1 style={{ fontSize: "1.6rem", fontWeight: 700, color: "#f0ede4", marginBottom: "0.5rem" }}>
            Verify a Certificate
          </h1>
          <p style={{ color: "rgba(240,237,228,0.6)", marginBottom: "2rem", fontSize: "0.92rem" }}>
            Enter a Certificate No. (e.g. <code style={{ background: "rgba(201,150,58,0.15)", color: "#e8b96a", padding: "2px 6px", borderRadius: 4 }}>CGL-7CBE4AE0</code>) to confirm its authenticity.
          </p>

          <form onSubmit={handleSearch} style={{ display: "flex", gap: "0.75rem", maxWidth: 460, margin: "0 auto", justifyContent: "center", flexWrap: "wrap" }}>
            <input
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="CGL-XXXXXXXX"
              spellCheck={false}
              style={{
                flex: 1, minWidth: 200,
                padding: "0.65rem 1rem",
                borderRadius: 8,
                border: "1.5px solid rgba(201,150,58,0.5)",
                background: "rgba(255,255,255,0.06)",
                color: "#f0ede4",
                fontSize: "1rem",
                letterSpacing: "0.05em",
                outline: "none",
              }}
            />
            <button
              type="submit"
              disabled={status === "loading"}
              style={{
                padding: "0.65rem 1.5rem",
                borderRadius: 8,
                border: "none",
                background: "#c9963a",
                color: "#fff",
                fontWeight: 600,
                fontSize: "0.95rem",
                cursor: "pointer",
                opacity: status === "loading" ? 0.7 : 1,
              }}
            >
              {status === "loading" ? "Searching…" : "Verify"}
            </button>
          </form>
        </div>

        {/* Results */}
        <div style={{ maxWidth: 960, margin: "2rem auto", padding: "0 1.5rem" }}>

          {status === "notfound" && (
            <div style={{
              textAlign: "center", padding: "3rem 1.5rem",
              background: "var(--surface)", borderRadius: 12,
              border: "1.5px solid rgba(239,68,68,0.35)"
            }}>
              <div style={{ fontSize: "2.5rem", marginBottom: "0.75rem" }}>🚫</div>
              <p style={{ color: "var(--text-1)", fontWeight: 700, fontSize: "1.05rem", marginBottom: "0.4rem" }}>
                No certificate found
              </p>
              <p style={{ color: "var(--text-2)", fontSize: "0.9rem", marginBottom: "0.3rem" }}>
                We couldn't find a certificate matching <strong style={{ color: "var(--text-1)" }}>{query.trim().toUpperCase()}</strong>.
              </p>
              <p style={{ color: "var(--text-3)", fontSize: "0.85rem" }}>
                Certificate IDs look like <code style={{ background: "rgba(201,150,58,0.15)", color: "#e8b96a", padding: "2px 6px", borderRadius: 4 }}>CGL-7CBE4AE0</code>. Check the ID on the certificate and try again.
              </p>
            </div>
          )}

          {status === "error" && (
            <div style={{
              textAlign: "center", padding: "3rem 1.5rem",
              background: "var(--surface)", borderRadius: 12,
              border: "1.5px solid rgba(239,68,68,0.35)"
            }}>
              <div style={{ fontSize: "2.5rem", marginBottom: "0.75rem" }}>⚠️</div>
              <p style={{ color: "var(--text-1)", fontWeight: 700, fontSize: "1.05rem", marginBottom: "0.4rem" }}>
                Invalid Certificate ID
              </p>
              <p style={{ color: "var(--text-2)", fontSize: "0.9rem", marginBottom: "0.3rem" }}>
                {errMsg}
              </p>
              <p style={{ color: "var(--text-3)", fontSize: "0.85rem" }}>
                The correct format is <code style={{ background: "rgba(201,150,58,0.15)", color: "#e8b96a", padding: "2px 6px", borderRadius: 4 }}>CGL-XXXXXXXX</code> — 8 characters after the dash.
              </p>
            </div>
          )}

          {status === "found" && cert && (
            <div>
              <div style={{
                display: "flex", alignItems: "center", gap: "0.6rem",
                marginBottom: "1.25rem", justifyContent: "center"
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: "50%",
                  background: "rgba(34,197,94,0.15)", border: "1.5px solid #22c55e",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  color: "#22c55e", fontSize: "0.8rem", fontWeight: 700, flexShrink: 0
                }}>✓</div>
                <span style={{ color: "#22c55e", fontWeight: 600, fontSize: "0.95rem" }}>
                  Certificate verified — this is an authentic CodeGoLive certificate
                </span>
              </div>
              <CertCard cert={cert} isOwn={false} />
            </div>
          )}

          {status === "idle" && (
            <div style={{ textAlign: "center", color: "var(--text-3)", fontSize: "0.88rem", paddingTop: "1rem" }}>
              Enter a certificate ID above to get started.
            </div>
          )}
        </div>
      </div>
    </>
  );
}
