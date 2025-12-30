import { useLocation } from "react-router-dom";
import LayoutSidebar from "./components/LayoutSidebar";
import GridLayoutSection from "./components/Section/GridLayoutSection";
import KanbanLayoutSection from "./components/Section/KanbanLayoutSection";
import MasonryLayoutSection from "./components/Section/MasonryLayoutSection";
import DiagramLayoutSection from "./components/Section/DiagramLayoutSection";

const LayoutPage = () => {
  const location = useLocation();
  const section = new URLSearchParams(location.search).get("section") || "grid";

  const renderSection = () => {
    switch (section) {
      case "grid":
        return <GridLayoutSection />;
      case "kanban":
        return <KanbanLayoutSection />;
      case "masonry":
        return <MasonryLayoutSection />;
      case "diagram":
        return <DiagramLayoutSection />;
      default:
        return <GridLayoutSection />;
    }
  };

  return (
    <div className="flex h-full relative">
      <LayoutSidebar />
      <main className="flex-1 overflow-y-auto p-8 pr-64" id="main-content">
        {renderSection()}
      </main>
    </div>
  );
};

export default LayoutPage;
