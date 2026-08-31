import { Helmet } from "react-helmet-async";

const SITE_NAME = "CodeGoLive";
const SITE_URL = "https://codegoLive.com"; // TODO: replace with actual domain
const DEFAULT_DESC = "Learn SAP BTP, CAP, SAPUI5, and SAP AI development with hands-on courses on CodeGoLive.";

export default function SEO({
  title,
  description = DEFAULT_DESC,
  robots = "index, follow",
  canonical,
  type = "website",
}) {
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME;
  const url = canonical || (typeof window !== "undefined" ? window.location.href : SITE_URL);

  return (
    <Helmet>
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      <meta name="robots" content={robots} />
      <link rel="canonical" href={url} />

      {/* Open Graph */}
      <meta property="og:site_name" content={SITE_NAME} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:type" content={type} />
      <meta property="og:url" content={url} />

      {/* Twitter Card */}
      <meta name="twitter:card" content="summary" />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={description} />
    </Helmet>
  );
}
