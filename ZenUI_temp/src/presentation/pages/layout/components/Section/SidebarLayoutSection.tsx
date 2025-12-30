import { useState } from "react";
import { SidebarLayout } from "../../../../components/package/layouts/sidebar";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  FileCode,
  Home,
  Settings,
  User,
  FileText,
  BarChart,
  Bell,
  HelpCircle,
  LogOut,
  Search,
  Moon,
  Sun,
  ChevronRight,
  Package,
  Layout,
  Palette,
  Code,
  Database,
  Shield,
  Globe,
  Mail,
  Calendar,
  Folder,
  Download,
  Upload,
  Star,
  Heart,
  Bookmark,
  Zap,
  Cloud,
  Terminal,
  Cpu,
  Server,
  Wifi,
  Battery,
  Bluetooth,
  Camera,
  Mic,
  Headphones,
} from "lucide-react";
import RightPanel from "../RightPanel";

const SidebarLayoutSection = () => {
  const [activeItem, setActiveItem] = useState("dashboard");
  const [collapsed, setCollapsed] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    { id: "examples", label: "Examples" },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { SidebarLayout } from "@khanhromvn/zenui";
import { 
  Home, 
  Settings, 
  User, 
  FileText, 
  BarChart 
} from "lucide-react";

function MyComponent() {
  const [activeItem, setActiveItem] = useState("dashboard");
  const [collapsed, setCollapsed] = useState(false);

  const sections = [
    {
      id: "main",
      title: "Main",
      items: [
        { id: "dashboard", label: "Dashboard", icon: Home },
        { id: "analytics", label: "Analytics", icon: BarChart },
        { id: "documents", label: "Documents", icon: FileText },
        { id: "users", label: "Users", icon: User },
        { id: "settings", label: "Settings", icon: Settings },
      ],
    },
  ];

  return (
    <SidebarLayout
      sections={sections}
      activeItem={activeItem}
      onItemClick={setActiveItem}
      collapsed={collapsed}
      onCollapse={setCollapsed}
      collapsible={true}
    >
      <div className="p-8">
        <h1 className="text-2xl font-bold">Main Content</h1>
        <p>Your application content goes here</p>
      </div>
    </SidebarLayout>
  );
}`;

  const advancedUsageCode = `import { SidebarLayout } from "@khanhromvn/zenui";
import { useState } from "react";

function AdvancedSidebar() {
  const [activeItem, setActiveItem] = useState("dashboard");
  const [collapsed, setCollapsed] = useState(false);
  const [theme, setTheme] = useState("dark");

  const sections = [
    // ... sections
  ];

  const user = {
    id: "1",
    name: "John Doe",
    email: "john@example.com",
    avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=John",
    role: "Administrator"
  };

  return (
    <SidebarLayout
      // Layout
      variant="glass"
      size="md"
      collapsed={collapsed}
      onCollapse={setCollapsed}
      
      // Responsive
      responsive={true}
      breakpoint="md"
      mobileOverlay={true}
      
      // Dimensions
      width={280}
      collapsedWidth={80}
      position="left"
      
      // Styling
      enableBlur={true}
      shadow={true}
      border={true}
      
      // Content
      sections={sections}
      activeItem={activeItem}
      onItemClick={setActiveItem}
      
      // Features
      showSearch={true}
      searchPlaceholder="Search..."
      onSearch={(query) => console.log(query)}
      
      theme={theme}
      showThemeToggle={true}
      onThemeToggle={() => setTheme(theme === "dark" ? "light" : "dark")}
      
      showNotifications={true}
      notificationCount={3}
      onNotificationsClick={() => console.log("Notifications clicked")}
      
      user={user}
      onUserClick={(user) => console.log("User clicked", user)}
      
      // Customization
      logo={
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-r from-blue-500 to-cyan-400 flex items-center justify-center">
            <span className="text-white font-bold">Z</span>
          </div>
          <span className="text-xl font-bold">ZenUI</span>
        </div>
      }
    >
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-4">Dashboard</h1>
        <p className="text-gray-600 dark:text-gray-400">
          Welcome to your dashboard. The sidebar is {collapsed ? "collapsed" : "expanded"}.
        </p>
      </div>
    </SidebarLayout>
  );
}`;

  const sections = [
    {
      id: "main",
      title: "Main",
      items: [
        { id: "dashboard", label: "Dashboard", icon: Home },
        { id: "analytics", label: "Analytics", icon: BarChart, badge: "5" },
        { id: "documents", label: "Documents", icon: FileText },
        { id: "users", label: "Users", icon: User, notification: true },
        { id: "settings", label: "Settings", icon: Settings },
      ],
    },
    {
      id: "development",
      title: "Development",
      items: [
        { id: "components", label: "Components", icon: Package },
        { id: "layouts", label: "Layouts", icon: Layout },
        { id: "themes", label: "Themes", icon: Palette },
        { id: "code", label: "Code Editor", icon: Code },
        { id: "database", label: "Database", icon: Database },
      ],
    },
    {
      id: "system",
      title: "System",
      items: [
        { id: "security", label: "Security", icon: Shield },
        { id: "network", label: "Network", icon: Wifi },
        { id: "storage", label: "Storage", icon: Database },
        { id: "backup", label: "Backup", icon: Cloud },
        { id: "logs", label: "System Logs", icon: Terminal },
      ],
    },
  ];

  const user = {
    id: "1",
    name: "Alex Johnson",
    email: "alex@example.com",
    role: "Administrator",
  };

  const handleItemClick = (itemId: string) => {
    setActiveItem(itemId);
    console.log(`Item clicked: ${itemId}`);
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    console.log(`Search query: ${query}`);
  };

  const handleThemeToggle = () => {
    console.log("Theme toggled");
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Sidebar Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A fully-featured, responsive sidebar navigation component with
            collapsible sections, user profiles, search, and theme support.
            Perfect for dashboards, admin panels, and complex applications
            requiring hierarchical navigation.
          </p>
          <div className="mt-4 flex gap-4 flex-wrap">
            <div className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full text-sm">
              <Layout size={14} />
              <span>Responsive</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-full text-sm">
              <Settings size={14} />
              <span>Collapsible</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-full text-sm">
              <Palette size={14} />
              <span>Customizable</span>
            </div>
          </div>
        </section>

        {/* INSTALL SECTION */}
        <section id="install" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Installation
          </h2>
          <CodeBlock
            code={npmInstallCode}
            language="bash"
            theme="vs-dark"
            showLineNumbers={false}
            showGutter={false}
            showLineHighlight={false}
            readOnly={true}
            headerMode="tabs"
            headerIcon={<FileCode size={16} />}
            tabs={[
              {
                id: "npm",
                label: "npm",
                content: npmInstallCode,
                language: "bash",
              },
              {
                id: "yarn",
                label: "yarn",
                content: yarnInstallCode,
                language: "bash",
              },
            ]}
            activeTabId="npm"
          />
        </section>

        {/* USAGE SECTION */}
        <section id="usage" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the SidebarLayout
            component.
          </p>

          {/* Live Demo */}
          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-6 h-[500px] relative">
            <SidebarLayout
              sections={sections}
              activeItem={activeItem}
              onItemClick={handleItemClick}
              collapsed={collapsed}
              onCollapse={setCollapsed}
              collapsible={true}
              showSearch={true}
              searchPlaceholder="Search navigation..."
              onSearch={handleSearch}
              user={user}
              showThemeToggle={true}
              onThemeToggle={handleThemeToggle}
              showNotifications={true}
              notificationCount={3}
              breakpoint="md"
              mobileOverlay={true}
              className="h-full"
              sidebarClassName="border-r border-border-default"
            >
              <div className="p-8 h-full overflow-y-auto">
                <div className="max-w-3xl">
                  <div className="flex items-center justify-between mb-6">
                    <div>
                      <h1 className="text-3xl font-bold text-text-primary capitalize">
                        {activeItem.replace("-", " ")}
                      </h1>
                      <p className="text-text-secondary mt-2">
                        Welcome to your {activeItem} dashboard. The sidebar is{" "}
                        {collapsed ? "collapsed" : "expanded"}.
                      </p>
                    </div>
                    <button
                      onClick={() => setCollapsed(!collapsed)}
                      className="px-4 py-2 bg-button-bg text-button-text rounded-lg hover:bg-button-bg-hover transition-colors"
                    >
                      {collapsed ? "Expand" : "Collapse"} Sidebar
                    </button>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    {[1, 2, 3].map((i) => (
                      <div
                        key={i}
                        className="p-6 bg-gradient-to-br from-card-background to-input-background border border-border-default rounded-xl"
                      >
                        <div className="flex items-center justify-between mb-4">
                          <h3 className="font-semibold text-text-primary">
                            Stat Card {i}
                          </h3>
                          <div className="p-2 bg-primary/10 rounded-lg">
                            <BarChart size={20} className="text-primary" />
                          </div>
                        </div>
                        <p className="text-3xl font-bold text-text-primary mb-2">
                          {i === 1 ? "1,234" : i === 2 ? "$12,345" : "89%"}
                        </p>
                        <p className="text-sm text-text-secondary">
                          {i === 1
                            ? "Active users"
                            : i === 2
                            ? "Total revenue"
                            : "Success rate"}
                        </p>
                      </div>
                    ))}
                  </div>

                  <div className="bg-gradient-to-br from-card-background to-input-background border border-border-default rounded-xl p-6">
                    <h3 className="font-semibold text-lg text-text-primary mb-4">
                      Recent Activity
                    </h3>
                    <div className="space-y-4">
                      {[
                        "User registration completed",
                        "System backup successful",
                        "New component added to library",
                        "Performance optimization applied",
                      ].map((activity, idx) => (
                        <div
                          key={idx}
                          className="flex items-center gap-3 p-3 hover:bg-input-background rounded-lg transition-colors"
                        >
                          <div className="w-2 h-2 rounded-full bg-green-500"></div>
                          <span className="text-text-primary">{activity}</span>
                          <span className="ml-auto text-sm text-text-secondary">
                            2h ago
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </SidebarLayout>
          </div>

          {/* Code Example */}
          <CodeBlock
            code={basicUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            headerMode="path"
            headerIcon={<FileCode size={16} />}
            filePath="src/components/BasicSidebarExample.tsx"
            showLineNumbers={true}
            showGutter={true}
            showLineHighlight={false}
          />
        </section>

        {/* EXAMPLES SECTION */}
        <section id="examples" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Advanced Examples
          </h2>

          {/* Variant Examples */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Different Variants
            </h3>
            <p className="text-text-secondary mb-4">
              SidebarLayout comes with multiple variants for different use
              cases.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Glass Variant */}
              <div className="bg-card-background border border-border-default rounded-lg p-6">
                <h4 className="font-semibold mb-3 flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-gradient-to-r from-blue-400 to-cyan-300"></div>
                  Glass Variant
                </h4>
                <p className="text-sm text-text-secondary mb-4">
                  Modern glass effect with blur backdrop.
                </p>
                <div className="h-32 rounded-lg bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center">
                  <div className="w-3/4 h-12 rounded-lg bg-white/10 backdrop-blur-sm border border-white/20"></div>
                </div>
              </div>

              {/* Floating Variant */}
              <div className="bg-card-background border border-border-default rounded-lg p-6">
                <h4 className="font-semibold mb-3 flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-gradient-to-r from-green-400 to-emerald-300"></div>
                  Floating Variant
                </h4>
                <p className="text-sm text-text-secondary mb-4">
                  Detached sidebar with shadow elevation.
                </p>
                <div className="h-32 rounded-lg bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center">
                  <div className="w-3/4 h-12 rounded-lg shadow-xl border border-gray-700"></div>
                </div>
              </div>
            </div>
          </div>

          {/* Responsive Behavior */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Responsive Behavior
            </h3>
            <p className="text-text-secondary mb-4">
              Automatically adapts to different screen sizes with configurable
              breakpoints.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div className="p-4 bg-input-background rounded-lg">
                  <div className="text-center mb-2">
                    <div className="w-12 h-12 mx-auto rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                      <span className="text-blue-600 dark:text-blue-300 font-bold">
                        S
                      </span>
                    </div>
                  </div>
                  <h4 className="font-semibold text-center">Small Screens</h4>
                  <p className="text-sm text-text-secondary text-center">
                    Auto-collapses or becomes overlay
                  </p>
                </div>
                <div className="p-4 bg-input-background rounded-lg">
                  <div className="text-center mb-2">
                    <div className="w-12 h-12 mx-auto rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                      <span className="text-green-600 dark:text-green-300 font-bold">
                        M
                      </span>
                    </div>
                  </div>
                  <h4 className="font-semibold text-center">Medium Screens</h4>
                  <p className="text-sm text-text-secondary text-center">
                    Collapsible with icon-only mode
                  </p>
                </div>
                <div className="p-4 bg-input-background rounded-lg">
                  <div className="text-center mb-2">
                    <div className="w-12 h-12 mx-auto rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                      <span className="text-purple-600 dark:text-purple-300 font-bold">
                        L
                      </span>
                    </div>
                  </div>
                  <h4 className="font-semibold text-center">Large Screens</h4>
                  <p className="text-sm text-text-secondary text-center">
                    Full sidebar with labels
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Advanced Usage Code */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Advanced Configuration
            </h3>
            <p className="text-text-secondary mb-4">
              Full example with all available props and features.
            </p>
            <CodeBlock
              code={advancedUsageCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/AdvancedSidebar.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for the SidebarLayout component.
          </p>

          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-input-background">
                  <tr>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Prop
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Type
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Default
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Description
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-default">
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      variant
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      "default" | "minimal" | "floating" | "compact" |
                      "gradient" | "glass"
                    </td>
                    <td className="px-6 py-4 text-text-secondary">"default"</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Visual style variant
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      size
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      "sm" | "md" | "lg" | "xl"
                    </td>
                    <td className="px-6 py-4 text-text-secondary">"md"</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Size of sidebar items
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      collapsed
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">false</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Controlled collapsed state
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      onCollapse
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (collapsed: boolean) =&gt; void
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Callback when collapse state changes
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      collapsible
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">true</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Whether sidebar can be collapsed
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      responsive
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">true</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Enable responsive behavior
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      width
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string | number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">256</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Width when expanded (px or string)
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      collapsedWidth
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string | number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">64</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Width when collapsed (px or string)
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      position
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      "left" | "right"
                    </td>
                    <td className="px-6 py-4 text-text-secondary">"left"</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Sidebar position
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      sections
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      SidebarLayoutSection[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">[]</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Navigation sections and items
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      activeItem
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Currently active item ID
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      onItemClick
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (itemId: string) =&gt; void
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Callback when item is clicked
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      showSearch
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">false</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Show search input in header
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      user
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      SidebarLayoutUser
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      User information for footer
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      showThemeToggle
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">false</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Show theme toggle button
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      showNotifications
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">false</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Show notifications indicator
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default SidebarLayoutSection;
