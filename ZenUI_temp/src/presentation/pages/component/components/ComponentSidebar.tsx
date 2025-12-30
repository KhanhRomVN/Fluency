import { Link, useLocation } from "react-router-dom";
const ComponentSidebar = () => {
  const location = useLocation();
  const currentSection =
    new URLSearchParams(location.search).get("section") || "drawer";

  const components = [
    { name: "Accordion", slug: "accordion" },
    { name: "Avatar", slug: "avatar" },
    { name: "Badge", slug: "badge" },
    { name: "Breadcrumb", slug: "breadcrumb" },
    { name: "Button", slug: "button" },
    { name: "Card", slug: "card" },
    { name: "Carousel", slug: "carousel" },
    { name: "Checkbox", slug: "checkbox" },
    { name: "Code Block", slug: "codeblock" },
    { name: "Color Picker", slug: "colorpicker" },
    { name: "Divider", slug: "divider" },
    { name: "Drag & Drop Zone", slug: "dndzone" },
    { name: "Drawer", slug: "drawer" },
    { name: "Dropdown", slug: "dropdown" },
    { name: "Input", slug: "input" },
    { name: "Input OTP", slug: "input-otp" },
    { name: "Modal", slug: "modal" },
    { name: "Pagination", slug: "pagination" },
    { name: "Table", slug: "table" },
    { name: "Tab", slug: "tab" },
    { name: "Textarea", slug: "textarea" },
    { name: "Tree", slug: "tree" },
  ].sort((a, b) => a.name.localeCompare(b.name));

  return (
    <aside className="w-64 h-full overflow-y-auto p-4">
      <nav className="space-y-1">
        {components.map((component) => (
          <Link
            key={component.slug}
            to={`/components?section=${component.slug}`}
            className={`block px-4 py-2 rounded-lg transition-colors ${
              currentSection === component.slug
                ? "bg-sidebar-item-focus text-text-primary font-medium"
                : "text-text-secondary hover:bg-sidebar-item-hover hover:text-text-primary"
            }`}
          >
            {component.name}
          </Link>
        ))}
      </nav>
    </aside>
  );
};
export default ComponentSidebar;
