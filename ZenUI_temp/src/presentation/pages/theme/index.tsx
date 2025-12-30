import React from "react";
import { useTheme } from "../../providers/theme-provider";
import { PRESET_THEMES } from "../../constants/theme-loader";
import Grid from "../../components/package/layouts/grid/Grid";
import { cn } from "../../../shared/utils/cn";

const ThemePage: React.FC = () => {
  const { theme, applyPresetTheme } = useTheme();

  // Get current applied preset name from localStorage
  const getCurrentPresetName = () => {
    try {
      const storedPreset = localStorage.getItem("vite-ui-theme-preset");
      if (storedPreset) {
        const preset = JSON.parse(storedPreset);
        return preset.name;
      }
    } catch (error) {
      console.error("Error reading preset from localStorage:", error);
    }
    return null;
  };

  const currentPresetName = getCurrentPresetName();

  // Theme card component
  const ThemeCard: React.FC<{
    preset: any;
    isActive: boolean;
    onClick: () => void;
  }> = ({ preset, isActive, onClick }) => {
    return (
      <button
        onClick={onClick}
        className={cn(
          "relative flex flex-col p-4 rounded-xl transition-all duration-300 overflow-hidden",
          "bg-card-background hover:bg-card-background/80",
          " transition-all",
          isActive
            ? "border-primary shadow-lg scale-[1.02]"
            : "border-border hover:border-border-hover",
          "hover:scale-[1.02] active:scale-[0.98]",
          "group"
        )}
      >
        {/* Active indicator */}
        {isActive && (
          <div className="absolute top-3 right-3 z-10">
            <div className="bg-primary text-white rounded-full p-1">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-4 w-4"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fillRule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clipRule="evenodd"
                />
              </svg>
            </div>
          </div>
        )}

        {/* Theme preview */}
        <div className="w-full h-24 rounded-lg overflow-hidden mb-3 relative shadow-sm">
          {/* Primary color bar */}
          <div
            className="h-4 w-full"
            style={{ backgroundColor: preset.tailwind.primary }}
          />

          {/* Layout preview */}
          <div className="flex h-20">
            {/* Sidebar */}
            <div
              className="w-1/4 h-full"
              style={{
                backgroundColor:
                  preset.tailwind.sidebarBackground ||
                  preset.tailwind.cardBackground,
              }}
            />

            {/* Content area */}
            <div
              className="w-3/4 h-full p-2 flex flex-col gap-1"
              style={{ backgroundColor: preset.tailwind.background }}
            >
              <div
                className="w-full h-4 rounded"
                style={{
                  backgroundColor: preset.tailwind.cardBackground,
                }}
              />
              <div
                className="w-3/4 h-4 rounded"
                style={{
                  backgroundColor: preset.tailwind.cardBackground,
                }}
              />
            </div>
          </div>
        </div>

        {/* Theme info */}
        <div className="flex flex-col items-start w-full mb-2">
          <span className="font-semibold text-base text-text-primary">
            {preset.name}
          </span>
          <span className="text-xs text-text-secondary">
            {preset.monaco.base === "vs" ? "Light theme" : "Dark theme"}
          </span>
        </div>

        {/* Color palette indicators */}
        <div className="flex gap-1 w-full">
          {["primary", "background", "cardBackground", "textPrimary"].map(
            (colorKey) => (
              <div
                key={colorKey}
                className="h-2 flex-1 rounded-full transition-transform group-hover:scale-y-125"
                style={{
                  backgroundColor: (preset.tailwind as any)[colorKey] || "#000",
                }}
                title={colorKey}
              />
            )
          )}
        </div>
      </button>
    );
  };

  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-text-primary mb-2">
            Theme Gallery
          </h1>
          <p className="text-text-secondary text-lg">
            Choose your preferred theme to customize the look and feel of your
            application
          </p>
        </div>

        {/* Light Themes Section */}
        <section className="mb-12">
          <div className="flex items-center gap-3 mb-6">
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
                d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
              />
            </svg>
            <h2 className="text-2xl font-semibold text-text-primary">
              Light Themes
            </h2>
            <span className="text-sm text-text-secondary">
              ({PRESET_THEMES.light.length} themes)
            </span>
          </div>

          <Grid
            columns="repeat(auto-fill, minmax(280px, 1fr))"
            gap="1.5rem"
            className="mb-8"
          >
            {PRESET_THEMES.light.map((preset, idx) => (
              <ThemeCard
                key={idx}
                preset={preset}
                isActive={currentPresetName === preset.name}
                onClick={() => applyPresetTheme(preset)}
              />
            ))}
          </Grid>
        </section>

        {/* Dark Themes Section */}
        <section>
          <div className="flex items-center gap-3 mb-6">
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
                d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
              />
            </svg>
            <h2 className="text-2xl font-semibold text-text-primary">
              Dark Themes
            </h2>
            <span className="text-sm text-text-secondary">
              ({PRESET_THEMES.dark.length} themes)
            </span>
          </div>

          <Grid columns="repeat(auto-fill, minmax(280px, 1fr))" gap="1.5rem">
            {PRESET_THEMES.dark.map((preset, idx) => (
              <ThemeCard
                key={idx}
                preset={preset}
                isActive={currentPresetName === preset.name}
                onClick={() => applyPresetTheme(preset)}
              />
            ))}
          </Grid>
        </section>
      </div>
    </div>
  );
};

export default ThemePage;
