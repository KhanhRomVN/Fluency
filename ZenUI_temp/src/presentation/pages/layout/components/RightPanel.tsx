import { useEffect, useState } from "react";

interface RightPanelProps {
  sections: Array<{
    id: string;
    label: string;
  }>;
}

const RightPanel: React.FC<RightPanelProps> = ({ sections }) => {
  const [activeSection, setActiveSection] = useState<string>(sections[0]?.id);

  useEffect(() => {
    const mainContent = document.getElementById("main-content");

    const handleScroll = () => {
      if (!mainContent) return;

      const scrollPosition = mainContent.scrollTop + 100;

      for (const section of sections) {
        const element = document.getElementById(section.id);
        if (element) {
          const offsetTop = element.offsetTop - mainContent.offsetTop;
          const offsetHeight = element.offsetHeight;

          if (
            scrollPosition >= offsetTop &&
            scrollPosition < offsetTop + offsetHeight
          ) {
            setActiveSection(section.id);
            break;
          }
        }
      }
    };

    if (mainContent) {
      mainContent.addEventListener("scroll", handleScroll);
      handleScroll(); // Check initial position
    }

    return () => {
      if (mainContent) {
        mainContent.removeEventListener("scroll", handleScroll);
      }
    };
  }, [sections]);

  const scrollToSection = (sectionId: string) => {
    const mainContent = document.getElementById("main-content");
    const element = document.getElementById(sectionId);
    if (element && mainContent) {
      const offsetTop = element.offsetTop - mainContent.offsetTop - 80;
      mainContent.scrollTo({
        top: offsetTop,
        behavior: "smooth",
      });
    }
  };

  return (
    <aside className="w-56 fixed right-8 top-24 hidden xl:block">
      <div className="border-l border-border-default pl-4">
        <h3 className="text-sm font-semibold text-text-primary mb-3">
          On This Page
        </h3>
        <nav className="space-y-2">
          {sections.map((section) => (
            <button
              key={section.id}
              onClick={() => scrollToSection(section.id)}
              className={`block w-full text-left text-sm py-1 transition-colors ${
                activeSection === section.id
                  ? "text-primary font-medium"
                  : "text-text-secondary hover:text-text-primary"
              }`}
            >
              {section.label}
            </button>
          ))}
        </nav>
      </div>
    </aside>
  );
};

export default RightPanel;
