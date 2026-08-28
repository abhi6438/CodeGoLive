import { useState } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import TopBar from "./components/TopBar";
import { MobileBarProvider } from "./lib/MobileBarContext";
import Dashboard from "./pages/Dashboard";
import Home from "./pages/Home";
import ModulePage from "./pages/ModulePage";
import TopicPage from "./pages/TopicPage";
import CourseWorkspace from "./pages/CourseWorkspace";
import Community from "./pages/Community";
import Login from "./pages/Login";
import AdminDashboard from "./pages/AdminDashboard";
import AdminModeration from "./pages/AdminModeration";
import AdminTopics from "./pages/AdminTopics";
import AdminUsers from "./pages/AdminUsers";
import AdminCourses from "./pages/AdminCourses";
import AdminTagMerge from "./pages/AdminTagMerge";
import RequireRole from "./components/RequireRole";
import SearchPage from "./pages/SearchPage";
import { MyCertificatePage, PublicCertificatePage } from "./pages/CertificatePage";

function NotFound() {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "60vh" }}>
      <div style={{ textAlign: "center", padding: "2rem" }}>
        <div style={{ fontSize: "4rem", marginBottom: "1rem", opacity: 0.2 }}>404</div>
        <h2 style={{ marginBottom: "0.5rem" }}>Page not found</h2>
        <p style={{ color: "var(--text-2)", marginBottom: "1.25rem" }}>The page you're looking for doesn't exist.</p>
        <a href="/" className="btn btn-primary">Go home</a>
      </div>
    </div>
  );
}

export default function App() {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <MobileBarProvider>
    <div className={"app-shell" + (collapsed ? " sidebar-collapsed" : "") + (mobileOpen ? " mobile-sidebar-open" : "")}>
      {mobileOpen && (
        <div className="sidebar-overlay" onClick={() => setMobileOpen(false)} />
      )}

      <Sidebar
        collapsed={collapsed}
        onToggle={() => setCollapsed((c) => !c)}
      />

      <div className="app-main">
        <TopBar onMobileMenuToggle={() => setMobileOpen((o) => !o)} />

        <div className="app-content">
          <Routes>
            {/* Learner routes */}
            <Route path="/" element={<Dashboard />} />
            <Route path="/dashboard" element={<Navigate to="/" replace />} />
            <Route path="/course/:courseId" element={<CourseWorkspace />} />
            <Route path="/course/:courseId/:topicSlug" element={<CourseWorkspace />} />
            <Route path="/modules/:moduleId" element={<ModulePage />} />
            <Route path="/topics/:slug" element={<TopicPage />} />
            <Route path="/community" element={<Community />} />
            <Route path="/login" element={<Login />} />
            <Route path="/search" element={<SearchPage />} />
            <Route path="/certificate" element={<MyCertificatePage />} />
            <Route path="/certificates/:userId" element={<PublicCertificatePage />} />

            {/* Admin routes */}
            <Route path="/admin" element={<RequireRole roles={["admin"]}><AdminDashboard /></RequireRole>} />
            <Route path="/admin/courses" element={<RequireRole roles={["admin"]}><AdminCourses /></RequireRole>} />
            <Route path="/admin/topics" element={<RequireRole roles={["admin"]}><AdminTopics /></RequireRole>} />
            <Route path="/admin/users" element={<RequireRole roles={["admin"]}><AdminUsers /></RequireRole>} />
            <Route path="/admin/tags" element={<RequireRole roles={["admin"]}><AdminTagMerge /></RequireRole>} />
            <Route path="/admin/moderation" element={<RequireRole roles={["moderator","admin"]}><AdminModeration /></RequireRole>} />

            <Route path="*" element={<NotFound />} />
          </Routes>
        </div>
      </div>
    </div>
    </MobileBarProvider>
  );
}
