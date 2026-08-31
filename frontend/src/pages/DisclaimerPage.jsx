import SEO from "../components/SEO";
import { Link } from "react-router-dom";

function H2({ children }) {
  return <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "var(--text)", margin: "2rem 0 0.6rem" }}>{children}</h2>;
}
function P({ children }) {
  return <p style={{ color: "var(--text-2)", lineHeight: 1.8, marginBottom: "0.75rem" }}>{children}</p>;
}

export default function DisclaimerPage() {
  return (
    <div style={{ maxWidth: 760, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO title="Disclaimer" description="CodeGoLive educational disclaimer — content is for learning purposes and not professional advice." robots="noindex" />
      <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.4rem" }}>Disclaimer</h1>

      <H2>Educational Purpose</H2>
      <P>
        All content on CodeGoLive — including lessons, code examples, architecture diagrams, and
        community answers — is provided strictly for educational and learning purposes. The goal is to
        help developers understand concepts and techniques in SAP cloud development through practical examples.
      </P>

      <H2>No Warranty on Code Examples</H2>
      <P>
        Code examples and snippets are written to illustrate concepts, not to serve as production-ready
        solutions. You should independently review, test, and validate any code before deploying it to a
        production environment. CodeGoLive accepts no liability for issues arising from direct use of
        example code in production systems.
      </P>

      <H2>Technical Information Accuracy</H2>
      <P>
        SAP technologies, APIs, and platform features change over time. While we aim to keep content
        current, some information may become outdated. Always refer to the official{" "}
        <a href="https://help.sap.com" target="_blank" rel="noopener noreferrer" style={{ color: "var(--accent)" }}>
          SAP Help Portal
        </a>{" "}
        and official SAP documentation for authoritative guidance on production deployments.
      </P>

      <H2>Third-Party Trademarks</H2>
      <P>
        SAP, SAP Business Technology Platform (BTP), SAPUI5, CAP (Cloud Application Programming model),
        SAP AI Core, SAP Integration Suite, and related product names are trademarks or registered
        trademarks of SAP SE. CodeGoLive is an independent educational platform and is not affiliated
        with, endorsed by, sponsored by, or in any way officially connected to SAP SE or any of its
        subsidiaries or affiliates.
      </P>
      <P>
        References to third-party tools, libraries, and platforms (including but not limited to Node.js,
        Python, GitHub, Vercel, Supabase, and OpenAI) are for educational context only and do not
        constitute endorsement, partnership, or affiliation.
      </P>

      <H2>Community Content</H2>
      <P>
        Questions, answers, and discussions posted in the CodeGoLive Community are contributed by
        individual learners. We do not verify or endorse community-contributed content. Always apply
        professional judgment before acting on community advice.
      </P>

      <H2>No Professional Advice</H2>
      <P>
        Nothing on CodeGoLive constitutes professional, legal, financial, or business advice. Course
        content is educational material, not consulting. For decisions that require professional
        guidance — such as enterprise architecture, licensing, or legal compliance — consult a
        qualified professional.
      </P>

      <H2>Limitation of Liability</H2>
      <P>
        CodeGoLive and its contributors shall not be liable for any direct, indirect, incidental, or
        consequential damages resulting from the use or inability to use the Platform or its content,
        even if advised of the possibility of such damage.
      </P>

      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: 10, padding: "1.25rem", marginTop: "2rem",
        color: "var(--text-2)", fontSize: "0.88rem", lineHeight: 1.7,
      }}>
        Questions about this disclaimer?{" "}
        <Link to="/contact" style={{ color: "var(--accent)" }}>Contact us</Link>. See also our{" "}
        <Link to="/terms" style={{ color: "var(--accent)" }}>Terms &amp; Conditions</Link> and{" "}
        <Link to="/privacy" style={{ color: "var(--accent)" }}>Privacy Policy</Link>.
      </div>
    </div>
  );
}
