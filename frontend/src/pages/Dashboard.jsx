import { Link } from "react-router-dom";
import { useEffect, useState } from "react";
import { COURSES } from "../lib/courses";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const COURSE_MODULES = {
  "sap-btp": [
    { emoji: "🧭", label: "Orientation" },
    { emoji: "🎨", label: "UI5 Fundamentals" },
    { emoji: "⚙️", label: "CAP Fundamentals" },
    { emoji: "🔗", label: "Full-Stack Integration" },
    { emoji: "🚀", label: "Production Ready" },
    { emoji: "🏆", label: "Capstone Project" },
  ],
  "sap-ai": [
    { emoji: "🤖", label: "AI Core Setup" },
    { emoji: "💬", label: "LLM & Prompting" },
    { emoji: "🔧", label: "Gen AI Hub" },
    { emoji: "🔗", label: "App Integration" },
    { emoji: "🚀", label: "Production Deploy" },
  ],
  "sap-is": [
    { emoji: "🏗️", label: "IS Foundations" },
    { emoji: "🔌", label: "Adapters & Connectivity" },
    { emoji: "🗺️", label: "Message Mapping" },
    { emoji: "🛡️", label: "Error Handling & Security" },
    { emoji: "📊", label: "Deploy & Monitor" },
  ],
  "sde-to-fde": [
    { emoji: "🤝", label: "Customer Foundations" },
    { emoji: "🏛️", label: "Technical Breadth" },
    { emoji: "🎯", label: "Pre-Sales & Solutioning" },
    { emoji: "🚢", label: "Delivery Excellence" },
    { emoji: "🗣️", label: "Stakeholder Mastery" },
    { emoji: "📈", label: "FDE Career & Growth" },
  ],
};

function MetaItem({ icon, text }) {
  return (
    <span style={{ display:"flex", alignItems:"center", gap:"0.3rem", fontSize:"0.8rem", color:"var(--text-3)" }}>
      {icon} {text}
    </span>
  );
}

function CourseStats({ course }) {
  return (
    <div style={{
      display: "flex", gap: "2rem", flexWrap: "wrap",
      marginTop: "0.5rem", paddingTop: "0.75rem",
      borderTop: "1px solid var(--border)",
    }}>
      {[
        { num: course.modules, label: "Modules" },
        { num: course.topics + "+", label: "Topics" },
        { num: course.estimatedHours + "h", label: "Content" },
        { num: "Free", label: "Forever" },
      ].map(({ num, label }) => (
        <div key={label} style={{ display:"flex", flexDirection:"column" }}>
          <span style={{ fontSize:"1rem", fontWeight:800, color:"var(--text)", lineHeight:1 }}>{num}</span>
          <span style={{ fontSize:"0.68rem", color:"var(--text-3)", marginTop:"0.25rem", textTransform:"uppercase", letterSpacing:"0.06em" }}>{label}</span>
        </div>
      ))}
    </div>
  );
}

// Module number → emoji fallback for visual richness
const MODULE_EMOJIS = ["🧭","🎨","⚙️","🔗","🚀","🏆","🤖","💬","🔧","📡","🛡️","📊","🤝","🏛️","🎯","🚢","🗣️","📈"];

function FeaturedCard({ course }) {
  // Use DB modules array if available, fall back to static COURSE_MODULES
  const dbMods = Array.isArray(course.modulesList) && course.modulesList.length > 0 ? course.modulesList : null;
  const staticMods = COURSE_MODULES[course.id] || [];
  const modules = dbMods
    ? dbMods.map((m, i) => ({ label: m.title, emoji: staticMods[i]?.emoji || MODULE_EMOJIS[i % MODULE_EMOJIS.length] }))
    : staticMods;
  const card = (
    <div className="featured-card">
      <div className="featured-card-left">
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
          <div className="featured-card-eyebrow">Available Now</div>
          <span style={{ fontSize:"0.72rem", fontWeight:600, color:"var(--text-3)", letterSpacing:"0.03em" }}>{course.level}</span>
        </div>
        <div style={{ display:"flex", alignItems:"center", gap:"0.6rem" }}>
          <div className="featured-card-icon">{course.icon}</div>
          <h2 className="featured-card-title">{course.title}</h2>
        </div>
        <p className="featured-card-desc">{course.description}</p>
        <div className="featured-card-tags">
          {course.tags.map((t) => (
            <span key={t} style={{ fontSize:"0.72rem", padding:"0.2rem 0.55rem", borderRadius:"999px", border:"1px solid var(--border)", color:"var(--text-2)", background:"var(--surface-2)" }}>{t}</span>
          ))}
        </div>

        <CourseStats course={course} />
        <div className="featured-card-btn" style={{ marginTop:"0.75rem" }}>Start Learning →</div>
      </div>
      <div className="featured-card-right">
        <div className="featured-path-label">Course Modules</div>
        <ol className="featured-path-steps">
          {modules.slice(0, 6).map((m) => (
            <li key={m.label} className="featured-path-step">
              <span className="path-step-emoji">{m.emoji}</span>
              <span className="path-step-label">{m.label}</span>
            </li>
          ))}
        </ol>
        {modules.length > 6 && (
          <div style={{ fontSize:"0.72rem", color:"var(--text-3)", marginTop:"0.5rem", paddingLeft:"0.25rem" }}>
            +{modules.length - 6} more modules
          </div>
        )}
      </div>
    </div>
  );
  return <Link to={`/course/${course.id}`} style={{ textDecoration:"none" }}>{card}</Link>;
}

function SoonCard({ course }) {
  return (
    <div className="soon-card" style={{ "--card-accent": course.accentColor }}>
      <div className="soon-card-accent-bar" />
      <div className="soon-card-inner">
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
          <span style={{ fontSize:"1.6rem" }}>{course.icon}</span>
          <span style={{ fontSize:"0.7rem", fontWeight:700, padding:"0.2rem 0.6rem", borderRadius:"999px", border:`1px solid ${course.accentColor}`, color:course.accentColor }}>Coming Soon</span>
        </div>
        <h3 style={{ margin:0, fontSize:"0.95rem", fontWeight:700, color:"var(--text)" }}>{course.title}</h3>
        <p style={{ margin:0, fontSize:"0.82rem", color:"var(--text-2)", lineHeight:1.5 }}>{course.subtitle}</p>
        <div style={{ display:"flex", flexWrap:"wrap", gap:"0.3rem" }}>
          {course.tags.map((t) => (
            <span key={t} style={{ fontSize:"0.7rem", padding:"0.15rem 0.45rem", borderRadius:"999px", border:"1px solid var(--border)", color:"var(--text-3)" }}>{t}</span>
          ))}
        </div>
        <div style={{ display:"flex", gap:"0.75rem", marginTop:"auto" }}>
          <MetaItem icon="⏱" text={`${course.estimatedHours}h`} />
          <MetaItem icon="📖" text={course.level} />
        </div>
      </div>
    </div>
  );
}

export default function Dashboard() {
  const [courses, setCourses] = useState(COURSES); // start with static data as fallback

  useEffect(() => {
    api.get("/api/courses").then((dbCourses) => {
      // DB is the source of truth — loop over DB courses, supplement with static for visual fields
      const merged = dbCourses.map((db) => {
        const staticC = COURSES.find((s) => s.id === db.id) || {};
        return {
          // Visual / static-only fields (defaults for DB-only courses)
          accentColor: staticC.accentColor ?? "#4B5563",
          accentLight: staticC.accentLight ?? "#f3f4f6",
          tags: staticC.tags ?? [],
          level: staticC.level ?? "All levels",
          highlights: staticC.highlights ?? [],
          apiBase: staticC.apiBase ?? "/api",
          badge: staticC.badge ?? null,
          // DB fields (authoritative)
          id: db.id,
          title: db.title ?? staticC.title,
          subtitle: db.subtitle ?? staticC.subtitle,
          description: db.description ?? staticC.description,
          status: db.status ?? staticC.status ?? "coming_soon",
          icon: db.icon ?? staticC.icon ?? "📚",
          estimatedHours: db.estimated_hours ?? staticC.estimatedHours,
          modules: db.module_count ?? staticC.modules,
          topics: db.topic_count ?? staticC.topics,
          modulesList: db.modules ?? [],  // array of {title, subtitle, number} from DB
        };
      });
      setCourses(merged);
    }).catch(() => {}); // fallback to static on error
  }, []);

  const available = courses.filter((c) => c.status === "available");
  const soon = courses.filter((c) => c.status !== "available");

  return (
    <div className="dash-page">
      <SEO title="Courses" description="Browse hands-on SAP BTP, SAP AI Core, and SAP Integration Suite courses on CodeGoLive." />

      {/* ── Dark Hero ── */}
      <div className="dash-hero-dark">
        <div className="dash-hero-dark-inner">
          <div className="dash-hero-eyebrow-dark">SAP Learning Platform</div>
          <h1 className="dash-hero-title-dark">Learn SAP.<br /><span className="dash-hero-accent">Ship real things.</span></h1>
          <p className="dash-hero-sub-dark">
            Hands-on courses covering BTP, CAP, SAPUI5, AI Core and more —<br />
            built by practitioners, free forever.
          </p>
        </div>
      </div>

      <div className="dash-body">
        {/* Available courses — featured two-column card */}
        {available.length > 0 && (
          <div className="dash-section">
            <div className="dash-section-hdr">
              <h2>Available Now</h2>
              <span>{available.length} course{available.length !== 1 ? "s" : ""}</span>
            </div>
            <div style={{ display:"flex", flexDirection:"column", gap:"1rem" }}>
              {available.map((c) => <FeaturedCard key={c.id} course={c} />)}
            </div>
          </div>
        )}

        {/* Coming soon — compact grid */}
        {soon.length > 0 && (
          <div className="dash-section">
            <div className="dash-section-hdr">
              <h2>Coming Soon</h2>
              <span>{soon.length} course{soon.length !== 1 ? "s" : ""}</span>
            </div>
            <div className="dash-soon-grid">
              {soon.map((c) => <SoonCard key={c.id} course={c} />)}
            </div>
          </div>
        )}
      </div>

    </div>
  );
}
