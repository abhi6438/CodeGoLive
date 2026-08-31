/**
 * AdSlot — placeholder component for future Google AdSense integration.
 * In development mode, renders a labelled placeholder box.
 * In production, renders nothing until actual ad code is added.
 *
 * Usage:
 *   <AdSlot slot="lesson-header" format="horizontal" />
 *
 * Approved placement zones (do NOT insert actual ads until AdSense is approved):
 *   1. Below lesson header in CourseWorkspace — slot="lesson-header"
 *   2. Between modules on Dashboard — slot="dashboard-mid"
 *   3. Sidebar bottom area — slot="sidebar-bottom"
 */
export default function AdSlot({ slot = "default", format = "horizontal" }) {
  if (!import.meta.env.DEV) return null;

  const dimensions = {
    horizontal: { width: "100%", height: 90 },
    rectangle:  { width: 336, height: 280 },
    vertical:   { width: 160, height: 600 },
  };
  const dim = dimensions[format] || dimensions.horizontal;

  return (
    <div
      style={{
        ...dim,
        maxWidth: "100%",
        border: "2px dashed var(--border)",
        borderRadius: 6,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--surface-2)",
        color: "var(--text-3)",
        fontSize: "0.72rem",
        fontFamily: "monospace",
        margin: "0.5rem 0",
      }}
      aria-hidden="true"
    >
      [AdSlot: {slot} / {format}]
    </div>
  );
}
