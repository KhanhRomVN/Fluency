import React, { Suspense, useState } from "react";
import { Moon, Sun, Search } from "lucide-react";
import { useTheme } from "../providers/theme-provider";
import { Link } from "react-router-dom";
import ThemeDrawer from "../components/drawer/ThemeDrawer";

interface MainLayoutProps {
  children: React.ReactNode;
}

const Navbar = () => {
  const { theme } = useTheme();
  const [isThemeDrawerOpen, setIsThemeDrawerOpen] = useState(false);

  return (
    <nav className="h-16 border-b border-border-default bg-background flex items-center px-6">
      <div className="flex items-center gap-8 flex-1">
        <Link to="/" className="text-xl font-bold text-text-primary">
          ZenUI
        </Link>
        <div className="flex items-center gap-6">
          <Link
            to="/docs"
            className="text-text-secondary hover:text-text-primary transition-colors"
          >
            Docs
          </Link>
          <Link
            to="/components"
            className="text-text-secondary hover:text-text-primary transition-colors"
          >
            Components
          </Link>
          <Link
            to="/layout"
            className="text-text-secondary hover:text-text-primary transition-colors"
          >
            Layouts
          </Link>
          <Link
            to="/theme"
            className="text-text-secondary hover:text-text-primary transition-colors"
          >
            Theme
          </Link>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="relative">
          <Search
            className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary"
            size={18}
          />
          <input
            type="text"
            placeholder="Search..."
            className="pl-10 pr-4 py-2 bg-input-background border border-border-default rounded-lg text-text-primary focus:outline-none focus:border-border-focus transition-colors"
          />
        </div>

        <button
          onClick={() => setIsThemeDrawerOpen(true)}
          className="p-2 rounded-lg hover:bg-card-background transition-colors"
        >
          {theme === "dark" ? (
            <Sun size={20} className="text-text-secondary" />
          ) : (
            <Moon size={20} className="text-text-secondary" />
          )}
        </button>
      </div>

      <ThemeDrawer
        isOpen={isThemeDrawerOpen}
        onClose={() => setIsThemeDrawerOpen(false)}
      />
    </nav>
  );
};

const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  return (
    <div className="flex h-screen overflow-hidden flex-col">
      <Navbar />
      <main className="bg-background flex-1 flex flex-col overflow-hidden">
        <div className="flex-1 overflow-y-auto">
          <Suspense
            fallback={
              <div className="flex items-center justify-center h-full"></div>
            }
          >
            {children}
          </Suspense>
        </div>
      </main>
    </div>
  );
};

export default MainLayout;
