import React from "react";
import { useTheme } from "../../providers/theme-provider";
import { PRESET_THEMES } from "../../constants/theme-loader";
import { Drawer } from "../package/components/drawer";

interface ThemeDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

const ThemeDrawer: React.FC<ThemeDrawerProps> = ({ isOpen, onClose }) => {
  const { theme, setTheme, applyPresetTheme } = useTheme();

  // Icons for theme modes
  const LightIcon = () => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
      />
    </svg>
  );

  const DarkIcon = () => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
      />
    </svg>
  );

  // Theme mode buttons - minimalist design
  const renderThemeSelector = () => (
    <div className="mb-8">
      <h3 className="text-lg font-semibold mb-4 text-text-primary">
        Theme Mode
      </h3>
      <div className="grid grid-cols-2 gap-3">
        {["light", "dark"].map((mode) => {
          const Icon = mode === "light" ? LightIcon : DarkIcon;
          return (
            <button
              key={mode}
              onClick={() => setTheme(mode as any)}
              className={`flex flex-col items-center justify-center p-3 rounded-lg transition-all duration-200 ${
                theme === mode
                  ? "bg-primary/10 text-primary shadow-sm"
                  : "bg-card-background hover:bg-card-background/80 text-text-secondary"
              } hover:scale-[1.02] active:scale-[0.98]`}
            >
              <div
                className={`mb-2 p-2 rounded-full transition-colors ${
                  theme === mode
                    ? "bg-primary/20 text-primary"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400"
                }`}
              >
                <Icon />
              </div>
              <span className="font-medium capitalize text-sm">{mode}</span>
            </button>
          );
        })}
      </div>
    </div>
  );

  // Preset color swatches - minimalist design
  const renderPresetThemes = (t: "light" | "dark") => (
    <div className="mb-6">
      <h3 className="text-lg font-semibold mb-4 text-text-primary">
        Preset Themes
      </h3>
      <div className="grid grid-cols-1 gap-3">
        {PRESET_THEMES[t].map((preset, idx) => {
          return (
            <button
              key={idx}
              onClick={() => applyPresetTheme(preset)}
              className="relative flex flex-col p-3 rounded-xl transition-all overflow-hidden bg-card-background hover:bg-card-background/80 hover:scale-[1.02] duration-200"
            >
              <div className="w-full h-20 rounded-lg overflow-hidden mb-2 relative">
                <div
                  className="h-3 w-full"
                  style={{ backgroundColor: preset.tailwind.primary }}
                />
                <div className="flex h-17">
                  <div
                    className="w-1/4 h-full"
                    style={{
                      backgroundColor:
                        preset.tailwind.sidebarBackground ||
                        preset.tailwind.cardBackground,
                    }}
                  />
                  <div
                    className="w-3/4 h-full p-2"
                    style={{ backgroundColor: preset.tailwind.background }}
                  >
                    <div
                      className="w-full h-3 rounded mb-1"
                      style={{
                        backgroundColor: preset.tailwind.cardBackground,
                      }}
                    />
                    <div
                      className="w-3/4 h-3 rounded"
                      style={{
                        backgroundColor: preset.tailwind.cardBackground,
                      }}
                    />
                  </div>
                </div>
                <div className="absolute top-1 right-1 bg-white/90 dark:bg-black/90 p-1 rounded-full">
                  <div
                    className="w-4 h-4 rounded-full"
                    style={{ backgroundColor: preset.tailwind.primary }}
                  />
                </div>
              </div>
              <div className="flex justify-between items-center w-full">
                <div>
                  <span className="font-medium text-sm block">
                    {preset.name}
                  </span>
                  <span className="text-xs text-text-secondary">
                    Modern theme
                  </span>
                </div>
              </div>
              <div className="flex mt-2 gap-1 w-full">
                {["primary", "background", "cardBackground", "textPrimary"].map(
                  (k) => (
                    <div
                      key={k}
                      className="h-1 flex-1 rounded-full"
                      style={{
                        backgroundColor: (preset.tailwind as any)[k] || "#000",
                      }}
                    />
                  )
                )}
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );

  return (
    <Drawer
      isOpen={isOpen}
      onClose={onClose}
      title="Theme Settings"
      subtitle="Customize the look and feel of your app"
      width="400px"
      direction="right"
      animationType="elastic"
      enableBlur={true}
      closeOnOverlayClick={true}
      showCloseButton={true}
      overlayOpacity={0.3}
      headerActions={
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="h-6 w-6 text-primary"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"
          />
        </svg>
      }
      footerActions={
        <>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg bg-button-second-bg hover:bg-button-second-bg-hover transition-colors text-text-primary"
          >
            Cancel
          </button>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg bg-button-bg text-button-text hover:bg-button-bg-hover transition-colors"
          >
            Apply Changes
          </button>
        </>
      }
    >
      <div className="h-full overflow-y-auto px-5 py-4">
        {renderThemeSelector()}

        {(theme === "light" || theme === "dark") && renderPresetThemes(theme)}
      </div>
    </Drawer>
  );
};

export default ThemeDrawer;
