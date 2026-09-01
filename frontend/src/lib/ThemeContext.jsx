import { createContext, useContext, useEffect, useState } from "react";

const ThemeContext = createContext(null);

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(() => { const t = localStorage.getItem("cgl-theme"); return (t === "dark" || t === "light") ? t : "dark"; });

  useEffect(() => {
    const root = document.documentElement;
    if (theme === "dark") root.setAttribute("data-theme", "dark");
    else if (theme === "light") root.setAttribute("data-theme", "light");
    else root.removeAttribute("data-theme");
    localStorage.setItem("cgl-theme", theme);
  }, [theme]);

  const toggle = () =>
    setTheme((t) => {
      if (t === "system")
        return window.matchMedia("(prefers-color-scheme: dark)").matches ? "light" : "dark";
      return t === "dark" ? "light" : "dark";
    });

  const isDark =
    theme === "dark" ||
    (theme === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);

  return (
    <ThemeContext.Provider value={{ theme, isDark, toggle }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
