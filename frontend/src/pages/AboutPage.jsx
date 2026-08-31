import { Link } from "react-router-dom";
import SEO from "../components/SEO";

function Section({ title, children }) {
  return (
    <section style={{ marginBottom: "2.5rem" }}>
      <h2 style={{ fontSize: "1.15rem", fontWeight: 700, color: "var(--text)", marginBottom: "0.75rem" }}>
        {title}
      </h2>
      {children}
    </section>
  );
}

export default function AboutPage() {
  return (
    <div style={{ maxWidth: 760, margin: "0 auto", padding: "2.5rem 1.25rem 4rem" }}>
      <SEO
        title="About"
        description="Learn about CodeGoLive — the independent platform for hands-on SAP BTP, CAP, SAPUI5, and SAP AI development courses."
      />

      <div style={{ marginBottom: "2.5rem" }}>
        <h1 style={{ fontSize: "1.75rem", fontWeight: 800, color: "var(--text)", marginBottom: "0.5rem" }}>
          About CodeGoLive
        </h1>
        <p style={{ color: "var(--text-2)", fontSize: "1rem", lineHeight: 1.7 }}>
          An independent learning platform built for developers who want to go from zero to production
          with SAP cloud technologies.
        </p>
      </div>

      <Section title="What is CodeGoLive?">
        <p style={{ color: "var(--text-2)", lineHeight: 1.8 }}>
          CodeGoLive is an independent online learning platform focused on practical, hands-on education
          in SAP Business Technology Platform (BTP), CAP (Cloud Application Programming model), SAPUI5,
          SAP AI Core, and related enterprise cloud technologies. Our courses are structured to take you
          from foundational concepts all the way to deploying real applications.
        </p>
      </Section>

      <Section title="What You Can Learn">
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {[
            {
              icon: "🚀",
              title: "SAP BTP & CAP Development",
              desc: "Build full-stack cloud applications on SAP BTP using the CAP framework. Covers data modeling, OData services, SAPUI5 frontends, authentication with XSUAA, deployment to Cloud Foundry, and more.",
            },
            {
              icon: "🤖",
              title: "SAP AI Core & Generative AI",
              desc: "Work with SAP AI Core, the Generative AI Hub, LangChain, and agentic AI patterns. Learn to build, deploy, and orchestrate AI workflows on the SAP platform.",
            },
            {
              icon: "🔌",
              title: "SAP Integration Suite",
              desc: "Connect enterprise systems using SAP Integration Suite. Build iFlows, work with OData, SOAP, REST and SFTP adapters, handle message mapping, and manage security credentials.",
            },
          ].map((c) => (
            <div key={c.title} style={{
              display: "flex", gap: "1rem", alignItems: "flex-start",
              background: "var(--surface)", border: "1px solid var(--border)",
              borderRadius: 10, padding: "1rem 1.25rem",
            }}>
              <span style={{ fontSize: "1.5rem", flexShrink: 0 }}>{c.icon}</span>
              <div>
                <div style={{ fontWeight: 700, color: "var(--text)", marginBottom: "0.25rem" }}>{c.title}</div>
                <div style={{ color: "var(--text-2)", fontSize: "0.88rem", lineHeight: 1.65 }}>{c.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      <Section title="Who Creates the Content?">
        <p style={{ color: "var(--text-2)", lineHeight: 1.8 }}>
          Content on CodeGoLive is created by independent developers with hands-on experience building
          production applications on SAP BTP. All examples are original and based on real-world
          development scenarios. We focus on practical knowledge you can apply immediately — not
          slides or certification cramming.
        </p>
        <p style={{ color: "var(--text-3)", fontSize: "0.85rem", marginTop: "0.75rem", fontStyle: "italic" }}>
          {/* CONFIGURE: Add creator name, bio, and LinkedIn/GitHub link here */}
          [Platform maintained by independent SAP BTP developers — configure creator info here]
        </p>
      </Section>

      <Section title="Our Mission">
        <p style={{ color: "var(--text-2)", lineHeight: 1.8 }}>
          SAP cloud development has a steep learning curve and fragmented documentation. CodeGoLive
          exists to make it accessible — with structured paths, runnable code examples, and a community
          where learners can ask real questions and get real answers. Every topic is built around
          "what you actually need to know to ship something."
        </p>
      </Section>

      <Section title="Community">
        <p style={{ color: "var(--text-2)", lineHeight: 1.8 }}>
          The built-in community lets learners ask questions, share solutions, and help each other
          through tricky concepts. Questions and answers are tagged by topic and searchable, so the
          collective knowledge grows over time. You can earn a certificate of completion for each
          finished course.
        </p>
      </Section>

      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: 12, padding: "1.5rem", display: "flex",
        alignItems: "center", justifyContent: "space-between",
        flexWrap: "wrap", gap: "1rem",
      }}>
        <div>
          <div style={{ fontWeight: 700, color: "var(--text)", marginBottom: "0.25rem" }}>Have a question?</div>
          <div style={{ color: "var(--text-2)", fontSize: "0.88rem" }}>We'd love to hear from you.</div>
        </div>
        <Link to="/contact" className="btn btn-primary">Get in Touch</Link>
      </div>
    </div>
  );
}
