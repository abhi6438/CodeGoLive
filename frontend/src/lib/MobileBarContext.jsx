import { createContext, useContext, useState } from "react";

const MobileBarContext = createContext(null);

export function MobileBarProvider({ children }) {
  const [bar, setBar] = useState(null); // { title, onToggle }
  return (
    <MobileBarContext.Provider value={{ bar, setBar }}>
      {children}
    </MobileBarContext.Provider>
  );
}

export function useMobileBar() {
  return useContext(MobileBarContext);
}
