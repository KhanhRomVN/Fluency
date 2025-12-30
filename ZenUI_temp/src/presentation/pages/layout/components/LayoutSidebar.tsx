import { Link, useLocation } from "react-router-dom";

const LayoutSidebar = () => {
  const location = useLocation();
  const currentSection =
    new URLSearchParams(location.search).get("section") || "grid";

  const layouts = [
    { name: "Grid Layout", slug: "grid" },
    { name: "Flex Layout", slug: "flex" },
    { name: "Sidebar Layout", slug: "sidebar" },
    { name: "Split Layout", slug: "split" },
    { name: "Masonry Layout", slug: "masonry" },
    { name: "Kanban Layout", slug: "kanban" },
    { name: "Diagram Layout", slug: "diagram" },
  ].sort((a, b) => a.name.localeCompare(b.name));

  return (
    <aside className="w-64 h-full overflow-y-auto p-4">
      <nav className="space-y-1">
        {layouts.map((layout) => (
          <Link
            key={layout.slug}
            to={`/layout?section=${layout.slug}`}
            className={`block px-4 py-2 rounded-lg transition-colors ${
              currentSection === layout.slug
                ? "bg-sidebar-item-focus text-text-primary font-medium"
                : " hover:bg-sidebar-item-hover hover:text-text-primary"
            }`}
          >
            {layout.name}
          </Link>
        ))}
      </nav>
    </aside>
  );
};

export default LayoutSidebar;
