import SEO from "../components/SEO";

const CONTACT_EMAIL = "support@codegoLive.com"; // CONFIGURE: replace with your actual support email

function ContactCard({ icon, title, description, email, subject }) {
  const mailto = `mailto:${email}?subject=${encodeURIComponent(subject)}`;
  return (
    <div style={{
      background: "var(--surface)", border: "1px solid var(--border)",
      borderRadius: 10, padding: "1.25rem",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", marginBottom: "0.5rem" }}>
        <span style={{ fontSize: "1.3rem" }}>{icon}</span>
        <span style={{ fontWeight: 700, color: "var(--text)", fontSize: "0.95rem" }}>{title}</span>
      </div>
      <p style={{ color: "var(--text-2)", fontSize: "0.88rem", lineHeight: 1.65, marginBottom: "0.75rem" }}>
        {description}
      </p>
      <a href={mailto} style={{
        fontSize: "0.82rem", color: "var(--accent)",
        textDecoration: "none", fontWeight: 600,
      }}>
        {email}
      </a>
    </div>
  );
}

export default function ContactPage() {
  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO
        title="Contact"
        description="Get in touch with the CodeGoLive team for course questions, technical issues, or general feedback."
      />

      <div style={{ marginBottom: "2.5rem" }}>
        <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.5rem" }}>
          Contact Us
        </h1>
        <p style={{ color: "var(--text-2)", fontSize: "1rem", lineHeight: 1.7 }}>
          We're a small team — we read every message. Use the right channel below to get the fastest response.
        </p>
      </div>

      {/* Primary contact */}
      <div style={{
        background: "var(--surface-2)", border: "1px solid var(--border)",
        borderRadius: 12, padding: "1.5rem", marginBottom: "2rem",
        display: "flex", flexWrap: "wrap", gap: "1rem",
        alignItems: "center", justifyContent: "space-between",
      }}>
        <div>
          <div style={{ fontWeight: 700, color: "var(--text)", marginBottom: "0.25rem", fontSize: "0.95rem" }}>
            General enquiries
          </div>
          <p style={{ color: "var(--text-2)", fontSize: "0.88rem", margin: 0 }}>
            For anything not listed below, email us directly:
          </p>
        </div>
        <a
          href={`mailto:${CONTACT_EMAIL}`}
          className="btn btn-primary"
          style={{ whiteSpace: "nowrap" }}
        >
          {/* CONFIGURE: update CONTACT_EMAIL at top of file */}
          {CONTACT_EMAIL}
        </a>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "1rem", marginBottom: "2.5rem" }}>
        <ContactCard
          icon="📚"
          title="Course Questions"
          description="Questions about course content, exercises, or explanations? We aim to respond within 2 business days."
          email={CONTACT_EMAIL}
          subject="Course Question"
        />
        <ContactCard
          icon="🐛"
          title="Technical Issues"
          description="If you experience a bug, broken content, or an issue with the platform, please include the page URL and browser."
          email={CONTACT_EMAIL}
          subject="Technical Issue"
        />
        <ContactCard
          icon="💡"
          title="Content Feedback"
          description="Spotted an error or have a suggestion for improving a lesson? We take quality seriously."
          email={CONTACT_EMAIL}
          subject="Content Feedback"
        />
        <ContactCard
          icon="🤝"
          title="Business Enquiries"
          description="Partnerships, licensing, or enterprise enquiries. Please include your company name and use case."
          email={CONTACT_EMAIL}
          subject="Business Enquiry"
        />
      </div>

      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: 10, padding: "1.25rem",
        color: "var(--text-2)", fontSize: "0.85rem", lineHeight: 1.7,
      }}>
        <strong style={{ color: "var(--text)" }}>Community support:</strong> For course-specific questions,
        you may get a faster answer from other learners in the{" "}
        <a href="/community" style={{ color: "var(--accent)" }}>Community</a> section.
        Questions posted there are visible to all learners and often answered quickly.
      </div>
    </div>
  );
}
