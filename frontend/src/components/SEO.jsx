import { useEffect } from "react";

const SITE_NAME = "CodeGoLive";
const SITE_URL = "https://codegolive.com";
const DEFAULT_DESC = "Learn SAP BTP, CAP, SAPUI5, and SAP AI development with hands-on courses on CodeGoLive.";

function setMeta(name, content, isProperty = false) {
  const attr = isProperty ? "property" : "name";
  let el = document.querySelector(`meta[${attr}="${name}"]`);
  if (!el) {
    el = document.createElement("meta");
    el.setAttribute(attr, name);
    document.head.appendChild(el);
  }
  el.setAttribute("content", content);
}

function setLink(rel, href) {
  let el = document.querySelector(`link[rel="${rel}"]`);
  if (!el) {
    el = document.createElement("link");
    el.setAttribute("rel", rel);
    document.head.appendChild(el);
  }
  el.setAttribute("href", href);
}

export default function SEO({
  title,
  description = DEFAULT_DESC,
  robots = "index, follow",
  canonical,
}) {
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME;
  const url = canonical || (typeof window !== "undefined" ? window.location.href : SITE_URL);

  useEffect(() => {
    document.title = fullTitle;
    setMeta("description", description);
    setMeta("robots", robots);
    setLink("canonical", url);
    setMeta("og:title", fullTitle, true);
    setMeta("og:description", description, true);
    setMeta("og:url", url, true);
    setMeta("twitter:title", fullTitle, true);
    setMeta("twitter:description", description, true);
  }, [fullTitle, description, robots, url]);

  return null;
}
