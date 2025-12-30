import { useState } from "react";
import {
  SplitLayout,
  SplitLayoutItem,
} from "../../../../components/package/layouts/split";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  FileCode,
  Layout,
  Columns,
  Rows,
  PanelLeft,
  PanelRight,
  Sidebar,
  Terminal,
  Code,
  Eye,
  Settings,
  FileText,
  Database,
  Server,
  Network,
  Cpu,
  HardDrive,
  Users,
  Calendar,
  MessageSquare,
  Bell,
  Search,
  Filter,
} from "lucide-react";
import RightPanel from "../RightPanel";

const SplitLayoutSection = () => {
  const [horizontalSizes, setHorizontalSizes] = useState<(number | string)[]>([
    300,
    "auto",
    300,
  ]);
  const [verticalSizes, setVerticalSizes] = useState<(number | string)[]>([
    200,
    "auto",
    150,
  ]);
  const [collapsedItems, setCollapsedItems] = useState<string[]>([]);

  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    { id: "examples", label: "Examples" },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { SplitLayout, SplitLayoutItem } from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <div className="h-[500px]">
      <SplitLayout direction="horizontal" gutter="md">
        <SplitLayoutItem size={250} minSize={200} maxSize={400}>
          <div className="p-4 h-full bg-card-background border-r border-border-default">
            <h3 className="font-semibold mb-4">Sidebar</h3>
            <p>Left panel content</p>
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem size="auto" minSize={300}>
          <div className="p-4 h-full bg-background">
            <h3 className="font-semibold mb-4">Main Content</h3>
            <p>Main content area that fills remaining space</p>
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem size={300} minSize={200} maxSize={400}>
          <div className="p-4 h-full bg-card-background border-l border-border-default">
            <h3 className="font-semibold mb-4">Right Panel</h3>
            <p>Right panel content</p>
          </div>
        </SplitLayoutItem>
      </SplitLayout>
    </div>
  );
}`;

  const resizableExampleCode = `import { SplitLayout, SplitLayoutItem } from "@khanhromvn/zenui";

function ResizableSplit() {
  const handleSizeChange = (sizes, itemId) => {
    console.log("Size changed:", sizes, "Item:", itemId);
  };

  const handleDragEnd = (event) => {
    console.log("Drag ended:", event);
  };

  return (
    <div className="h-[400px]">
      <SplitLayout
        direction="horizontal"
        gutter="md"
        showDragHandles={true}
        dragHandleSize={8}
        onSizeChange={handleSizeChange}
        onDragEnd={handleDragEnd}
        resizable={true}
        animationDuration={200}
      >
        <SplitLayoutItem 
          id="sidebar" 
          size={250} 
          minSize={150} 
          maxSize={500}
          resizable={true}
        >
          <div className="p-4 h-full bg-gradient-to-b from-blue-50 to-white dark:from-gray-800 dark:to-gray-900">
            <div className="flex items-center gap-3 mb-6">
              <Sidebar size={20} className="text-primary" />
              <h3 className="font-bold text-lg">Navigation</h3>
            </div>
            {/* Navigation items */}
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem 
          id="content" 
          size="auto"
          minSize={400}
        >
          <div className="p-4 h-full bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-bold text-2xl">Dashboard</h3>
              <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
                New Action
              </button>
            </div>
            {/* Main content */}
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem 
          id="right-panel" 
          size={300} 
          minSize={200} 
          maxSize={400}
          collapsible={true}
          collapsedSize={50}
        >
          <div className="p-4 h-full bg-gradient-to-b from-purple-50 to-white dark:from-gray-800 dark:to-gray-900">
            <div className="flex items-center gap-3 mb-6">
              <Settings size={20} className="text-purple-600" />
              <h3 className="font-bold text-lg">Settings</h3>
            </div>
            {/* Settings content */}
          </div>
        </SplitLayoutItem>
      </SplitLayout>
    </div>
  );
}`;

  const verticalSplitCode = `import { SplitLayout, SplitLayoutItem } from "@khanhromvn/zenui";

function VerticalSplit() {
  return (
    <div className="h-[600px]">
      <SplitLayout direction="vertical" gutter="md">
        <SplitLayoutItem 
          size={60}
          className="border-b border-border-default"
        >
          <div className="p-4 h-full flex items-center justify-between bg-card-background">
            <div className="flex items-center gap-4">
              <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                <Layout size={20} className="text-primary" />
              </div>
              <h1 className="text-xl font-bold">Application Title</h1>
            </div>
            <div className="flex items-center gap-3">
              <button className="p-2 hover:bg-input-background rounded-lg">
                <Search size={18} />
              </button>
              <button className="p-2 hover:bg-input-background rounded-lg">
                <Bell size={18} />
              </button>
              <button className="p-2 hover:bg-input-background rounded-lg">
                <Settings size={18} />
              </button>
            </div>
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem size="auto">
          <SplitLayout direction="horizontal" gutter="md">
            <SplitLayoutItem size={250} minSize={200}>
              <div className="p-4 h-full bg-card-background border-r border-border-default">
                <h3 className="font-semibold mb-4">Sidebar</h3>
                {/* Sidebar content */}
              </div>
            </SplitLayoutItem>
            
            <SplitLayoutItem size="auto">
              <div className="p-4 h-full bg-background">
                <h3 className="font-semibold mb-4">Main Content</h3>
                {/* Main content */}
              </div>
            </SplitLayoutItem>
          </SplitLayout>
        </SplitLayoutItem>
        
        <SplitLayoutItem size={40} className="border-t border-border-default">
          <div className="p-2 h-full flex items-center justify-between bg-card-background text-sm text-text-secondary">
            <div>Status: Connected</div>
            <div>© 2024 My Application</div>
            <div>Version 1.0.0</div>
          </div>
        </SplitLayoutItem>
      </SplitLayout>
    </div>
  );
}`;

  const responsiveExampleCode = `import { SplitLayout, SplitLayoutItem } from "@khanhromvn/zenui";

function ResponsiveSplit() {
  return (
    <div className="h-[500px]">
      <SplitLayout
        direction="horizontal"
        responsive={{
          xs: { direction: "vertical" },
          sm: { direction: "vertical" },
          md: { direction: "horizontal" },
          lg: { direction: "horizontal" },
          xl: { direction: "horizontal" }
        }}
        gutter={{ xs: "sm", md: "md", lg: "lg" }}
        collapsible={true}
      >
        <SplitLayoutItem 
          size={{ xs: 60, md: 250 }}
          minSize={{ xs: 60, md: 200 }}
          maxSize={{ xs: 100, md: 400 }}
          collapsible={true}
          className="bg-card-background"
        >
          <div className="p-4 h-full">
            <h3 className="font-semibold">Responsive Sidebar</h3>
            <p className="text-sm text-text-secondary mt-2">
              This panel adapts to screen size
            </p>
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem 
          size="auto"
          minSize={300}
          className="bg-background"
        >
          <div className="p-4 h-full">
            <h3 className="font-semibold">Main Content</h3>
            <p className="text-text-secondary mt-2">
              Adjusts automatically based on available space
            </p>
          </div>
        </SplitLayoutItem>
        
        <SplitLayoutItem 
          size={{ xs: 100, md: 300 }}
          minSize={{ xs: 80, md: 200 }}
          collapsible={true}
          className="bg-card-background"
        >
          <div className="p-4 h-full">
            <h3 className="font-semibold">Right Panel</h3>
            <p className="text-sm text-text-secondary mt-2">
              Collapsible on mobile, expanded on desktop
            </p>
          </div>
        </SplitLayoutItem>
      </SplitLayout>
    </div>
  );
}`;

  const handleHorizontalSizeChange = (
    sizes: (number | string)[],
    itemId?: string
  ) => {
    setHorizontalSizes(sizes);
    console.log("Horizontal size changed:", sizes, "Item:", itemId);
  };

  const handleVerticalSizeChange = (
    sizes: (number | string)[],
    itemId?: string
  ) => {
    setVerticalSizes(sizes);
    console.log("Vertical size changed:", sizes, "Item:", itemId);
  };

  const handleCollapse = (itemId: string, collapsed: boolean) => {
    if (collapsed) {
      setCollapsedItems([...collapsedItems, itemId]);
    } else {
      setCollapsedItems(collapsedItems.filter((id) => id !== itemId));
    }
    console.log("Item collapsed:", itemId, collapsed);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Split Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A powerful, resizable split layout component for creating draggable,
            collapsible, and responsive split panes. Perfect for code editors,
            dashboards, admin panels, and any application requiring adjustable
            workspace areas.
          </p>
          <div className="mt-4 flex gap-4 flex-wrap">
            <div className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full text-sm">
              <Columns size={14} />
              <span>Resizable Panes</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-full text-sm">
              <Rows size={14} />
              <span>Multiple Directions</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-full text-sm">
              <Layout size={14} />
              <span>Responsive</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300 rounded-full text-sm">
              <PanelLeft size={14} />
              <span>Collapsible</span>
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
            Here's a simple example to get you started with the SplitLayout
            component.
          </p>

          {/* Live Demo - Horizontal Split */}
          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-6">
            <div className="p-6 border-b border-border-default">
              <h3 className="font-semibold text-text-primary mb-2">
                Horizontal Split Layout
              </h3>
              <p className="text-sm text-text-secondary">
                Drag the vertical handles between panels to resize. Click
                collapse buttons to toggle panels.
              </p>
            </div>

            <div className="h-[400px] p-1">
              <SplitLayout
                direction="horizontal"
                gutter="md"
                showDragHandles={true}
                dragHandleSize={8}
                onSizeChange={handleHorizontalSizeChange}
                onCollapse={handleCollapse}
                resizable={true}
                collapsible={true}
                collapsedSize={60}
                animationDuration={200}
                className="h-full"
              >
                <SplitLayoutItem
                  id="left-panel"
                  size={horizontalSizes[0]}
                  minSize={150}
                  maxSize={500}
                  collapsible={true}
                  className="bg-card-background border-r border-border-default"
                >
                  <div className="p-4 h-full overflow-y-auto">
                    <div className="flex items-center gap-3 mb-6">
                      <PanelLeft size={20} className="text-primary" />
                      <h3 className="font-bold text-lg">Left Panel</h3>
                    </div>
                    <div className="space-y-3">
                      {[1, 2, 3, 4, 5].map((i) => (
                        <div
                          key={i}
                          className="p-3 bg-input-background rounded-lg hover:bg-input-background/80 transition-colors cursor-pointer"
                        >
                          <div className="flex items-center gap-3">
                            <FileText
                              size={16}
                              className="text-text-secondary"
                            />
                            <span>Item {i}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </SplitLayoutItem>

                <SplitLayoutItem
                  id="center-panel"
                  size="auto"
                  minSize={300}
                  className="bg-background"
                >
                  <div className="p-4 h-full overflow-y-auto">
                    <div className="flex items-center gap-3 mb-6">
                      <Layout size={20} className="text-primary" />
                      <h3 className="font-bold text-lg">Main Content</h3>
                    </div>
                    <div className="grid grid-cols-2 gap-4 mb-6">
                      {[1, 2, 3, 4].map((i) => (
                        <div
                          key={i}
                          className="p-4 bg-card-background rounded-lg border border-border-default"
                        >
                          <div className="flex items-center gap-3 mb-2">
                            <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                              <Cpu size={16} className="text-primary" />
                            </div>
                            <h4 className="font-semibold">Card {i}</h4>
                          </div>
                          <p className="text-sm text-text-secondary">
                            This is some sample content for card {i}
                          </p>
                        </div>
                      ))}
                    </div>
                    <div className="p-4 bg-card-background rounded-lg border border-border-default">
                      <h4 className="font-semibold mb-3">
                        Additional Information
                      </h4>
                      <p className="text-text-secondary">
                        This area automatically resizes based on available
                        space. Try dragging the handles or collapsing side
                        panels.
                      </p>
                    </div>
                  </div>
                </SplitLayoutItem>

                <SplitLayoutItem
                  id="right-panel"
                  size={horizontalSizes[2]}
                  minSize={150}
                  maxSize={500}
                  collapsible={true}
                  className="bg-card-background border-l border-border-default"
                >
                  <div className="p-4 h-full overflow-y-auto">
                    <div className="flex items-center gap-3 mb-6">
                      <PanelRight size={20} className="text-primary" />
                      <h3 className="font-bold text-lg">Right Panel</h3>
                    </div>
                    <div className="space-y-4">
                      <div className="p-3 bg-input-background rounded-lg">
                        <div className="flex items-center gap-3 mb-2">
                          <Settings size={16} className="text-text-secondary" />
                          <h4 className="font-semibold">Settings</h4>
                        </div>
                        <p className="text-sm text-text-secondary">
                          Configuration options
                        </p>
                      </div>
                      <div className="p-3 bg-input-background rounded-lg">
                        <div className="flex items-center gap-3 mb-2">
                          <Users size={16} className="text-text-secondary" />
                          <h4 className="font-semibold">Users</h4>
                        </div>
                        <p className="text-sm text-text-secondary">
                          Active user list
                        </p>
                      </div>
                      <div className="p-3 bg-input-background rounded-lg">
                        <div className="flex items-center gap-3 mb-2">
                          <Database size={16} className="text-text-secondary" />
                          <h4 className="font-semibold">Database</h4>
                        </div>
                        <p className="text-sm text-text-secondary">
                          Storage statistics
                        </p>
                      </div>
                    </div>
                  </div>
                </SplitLayoutItem>
              </SplitLayout>
            </div>
          </div>

          {/* Code Example */}
          <CodeBlock
            code={basicUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            headerMode="path"
            headerIcon={<FileCode size={16} />}
            filePath="src/components/BasicSplitExample.tsx"
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

          {/* Resizable Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Resizable Panes with Callbacks
            </h3>
            <p className="text-text-secondary mb-4">
              Full control over resizing with event callbacks and constraints.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-6">
              <div className="h-[350px] p-1">
                <SplitLayout
                  direction="horizontal"
                  gutter="lg"
                  showDragHandles={true}
                  dragHandleSize={10}
                  onSizeChange={handleHorizontalSizeChange}
                  onDragStart={(itemId) => console.log("Drag started:", itemId)}
                  onDragEnd={(event) => console.log("Drag ended:", event)}
                  resizable={true}
                  animationDuration={150}
                  snapGridSize={20}
                  className="h-full"
                >
                  <SplitLayoutItem
                    size={200}
                    minSize={100}
                    maxSize={300}
                    resizable={true}
                    className="bg-gradient-to-b from-blue-50 to-white dark:from-gray-800 dark:to-gray-900"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center gap-3 mb-4">
                        <Sidebar
                          size={20}
                          className="text-blue-600 dark:text-blue-400"
                        />
                        <h3 className="font-bold">Editor</h3>
                      </div>
                      <div className="font-mono text-sm space-y-1">
                        <div className="text-blue-600">
                          function example() {"{"}
                        </div>
                        <div className="pl-4 text-green-600">
                          console.log("Hello");
                        </div>
                        <div className="pl-4 text-green-600">
                          return "World";
                        </div>
                        <div className="text-blue-600">{"}"}</div>
                      </div>
                    </div>
                  </SplitLayoutItem>

                  <SplitLayoutItem
                    size="auto"
                    minSize={200}
                    className="bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-3">
                          <Terminal
                            size={20}
                            className="text-green-600 dark:text-green-400"
                          />
                          <h3 className="font-bold">Terminal</h3>
                        </div>
                        <div className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300 rounded">
                          Connected
                        </div>
                      </div>
                      <div className="font-mono text-sm bg-black/5 dark:bg-white/5 p-3 rounded">
                        <div className="text-green-600">$ npm start</div>
                        <div className="text-gray-600 dark:text-gray-400">
                          Starting development server...
                        </div>
                        <div className="text-blue-600">
                          Server running at http://localhost:3000
                        </div>
                      </div>
                    </div>
                  </SplitLayoutItem>

                  <SplitLayoutItem
                    size={250}
                    minSize={150}
                    maxSize={350}
                    resizable={true}
                    collapsible={true}
                    collapsedSize={60}
                    className="bg-gradient-to-b from-purple-50 to-white dark:from-gray-800 dark:to-gray-900"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center gap-3 mb-4">
                        <Eye
                          size={20}
                          className="text-purple-600 dark:text-purple-400"
                        />
                        <h3 className="font-bold">Preview</h3>
                      </div>
                      <div className="border border-border-default rounded p-3">
                        <div className="text-center py-8">
                          <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                            <Layout
                              size={24}
                              className="text-purple-600 dark:text-purple-400"
                            />
                          </div>
                          <p className="text-sm text-text-secondary">
                            Live preview content
                          </p>
                        </div>
                      </div>
                    </div>
                  </SplitLayoutItem>
                </SplitLayout>
              </div>
            </div>

            <CodeBlock
              code={resizableExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/ResizableSplit.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Vertical Split Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Vertical Split Layout
            </h3>
            <p className="text-text-secondary mb-4">
              Create vertical splits for header-content-footer layouts or
              stacked panels.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-6">
              <div className="h-[500px] p-1">
                <SplitLayout
                  direction="vertical"
                  gutter="md"
                  showDragHandles={true}
                  dragHandleSize={8}
                  onSizeChange={handleVerticalSizeChange}
                  resizable={true}
                  className="h-full"
                >
                  <SplitLayoutItem
                    size={60}
                    minSize={40}
                    maxSize={100}
                    className="bg-card-background border-b border-border-default"
                  >
                    <div className="p-4 h-full flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                          <Server size={20} className="text-primary" />
                        </div>
                        <div>
                          <h1 className="font-bold text-lg">Dashboard</h1>
                          <p className="text-sm text-text-secondary">
                            Real-time monitoring
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button className="px-3 py-1.5 bg-primary text-white text-sm rounded-lg hover:bg-primary/90">
                          Refresh
                        </button>
                        <button className="p-2 hover:bg-input-background rounded-lg">
                          <Filter size={18} />
                        </button>
                      </div>
                    </div>
                  </SplitLayoutItem>

                  <SplitLayoutItem size="auto" minSize={200}>
                    <SplitLayout
                      direction="horizontal"
                      gutter="md"
                      className="h-full"
                    >
                      <SplitLayoutItem
                        size={200}
                        minSize={150}
                        className="bg-card-background border-r border-border-default"
                      >
                        <div className="p-4 h-full">
                          <h3 className="font-semibold mb-4">Systems</h3>
                          <div className="space-y-2">
                            {[
                              "API Server",
                              "Database",
                              "Cache",
                              "Queue",
                              "Storage",
                            ].map((system, i) => (
                              <div
                                key={i}
                                className="p-3 bg-input-background rounded-lg flex items-center justify-between"
                              >
                                <span>{system}</span>
                                <div className="w-2 h-2 rounded-full bg-green-500"></div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </SplitLayoutItem>

                      <SplitLayoutItem size="auto" className="bg-background">
                        <div className="p-4 h-full">
                          <h3 className="font-semibold mb-4">Metrics</h3>
                          <div className="grid grid-cols-3 gap-4">
                            {[
                              {
                                label: "CPU",
                                value: "45%",
                                icon: Cpu,
                                color: "blue",
                              },
                              {
                                label: "Memory",
                                value: "78%",
                                icon: HardDrive,
                                color: "green",
                              },
                              {
                                label: "Network",
                                value: "1.2 Gbps",
                                icon: Network,
                                color: "purple",
                              },
                              {
                                label: "Requests",
                                value: "12.5k",
                                icon: MessageSquare,
                                color: "orange",
                              },
                              {
                                label: "Users",
                                value: "1,234",
                                icon: Users,
                                color: "red",
                              },
                              {
                                label: "Uptime",
                                value: "99.9%",
                                icon: Calendar,
                                color: "cyan",
                              },
                            ].map((metric, i) => (
                              <div
                                key={i}
                                className="p-4 bg-card-background rounded-lg border border-border-default"
                              >
                                <div className="flex items-center justify-between mb-2">
                                  <metric.icon
                                    size={18}
                                    className={`text-${metric.color}-600`}
                                  />
                                  <span className="text-2xl font-bold">
                                    {metric.value}
                                  </span>
                                </div>
                                <p className="text-sm text-text-secondary">
                                  {metric.label}
                                </p>
                              </div>
                            ))}
                          </div>
                        </div>
                      </SplitLayoutItem>
                    </SplitLayout>
                  </SplitLayoutItem>

                  <SplitLayoutItem
                    size={40}
                    minSize={30}
                    maxSize={80}
                    className="bg-card-background border-t border-border-default"
                  >
                    <div className="p-2 h-full flex items-center justify-between text-sm">
                      <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2">
                          <div className="w-2 h-2 rounded-full bg-green-500"></div>
                          <span className="text-text-secondary">
                            All systems operational
                          </span>
                        </div>
                        <span className="text-text-secondary">
                          Last updated: Just now
                        </span>
                      </div>
                      <div className="flex items-center gap-4">
                        <span className="text-text-secondary">v2.1.4</span>
                        <button className="text-primary hover:text-primary/80">
                          View logs
                        </button>
                      </div>
                    </div>
                  </SplitLayoutItem>
                </SplitLayout>
              </div>
            </div>

            <CodeBlock
              code={verticalSplitCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/VerticalSplit.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Responsive Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Responsive Behavior
            </h3>
            <p className="text-text-secondary mb-4">
              Adapts to different screen sizes with breakpoint-based
              configuration.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-6">
              <div className="p-4 border-b border-border-default">
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm">
                    <span>Try resizing your browser window</span>
                  </div>
                  <span className="text-sm text-text-secondary">
                    Layout changes based on screen width
                  </span>
                </div>
              </div>

              <div className="h-[400px] p-1">
                <SplitLayout
                  direction="horizontal"
                  responsive={{
                    xs: { direction: "vertical" },
                    sm: { direction: "vertical" },
                    md: { direction: "horizontal" },
                    lg: { direction: "horizontal" },
                    xl: { direction: "horizontal" },
                  }}
                  gutter="md"
                  collapsible={true}
                  className="h-full"
                >
                  <SplitLayoutItem
                    size={200}
                    minSize={150}
                    maxSize={300}
                    collapsible={true}
                    className="bg-card-background"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center gap-3 mb-4">
                        <Sidebar size={20} className="text-primary" />
                        <h3 className="font-semibold">Navigation</h3>
                      </div>
                      <p className="text-sm text-text-secondary">
                        {window.innerWidth < 768
                          ? "Collapsible on mobile"
                          : "Full sidebar on desktop"}
                      </p>
                    </div>
                  </SplitLayoutItem>

                  <SplitLayoutItem
                    size="auto"
                    minSize={200}
                    className="bg-background"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center gap-3 mb-4">
                        <Layout size={20} className="text-primary" />
                        <h3 className="font-semibold">Content Area</h3>
                      </div>
                      <p className="text-text-secondary mb-4">
                        Current layout:{" "}
                        {window.innerWidth < 768 ? "Vertical" : "Horizontal"}
                      </p>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="p-4 bg-card-background rounded-lg">
                          <h4 className="font-semibold mb-2">Responsive</h4>
                          <p className="text-sm text-text-secondary">
                            Adjusts automatically to screen size
                          </p>
                        </div>
                        <div className="p-4 bg-card-background rounded-lg">
                          <h4 className="font-semibold mb-2">Adaptive</h4>
                          <p className="text-sm text-text-secondary">
                            Optimized for all devices
                          </p>
                        </div>
                      </div>
                    </div>
                  </SplitLayoutItem>

                  <SplitLayoutItem
                    size={250}
                    minSize={150}
                    collapsible={true}
                    className="bg-card-background"
                  >
                    <div className="p-4 h-full">
                      <div className="flex items-center gap-3 mb-4">
                        <Settings size={20} className="text-primary" />
                        <h3 className="font-semibold">Settings</h3>
                      </div>
                      <p className="text-sm text-text-secondary">
                        {window.innerWidth < 768
                          ? "Compact on mobile"
                          : "Expanded on desktop"}
                      </p>
                    </div>
                  </SplitLayoutItem>
                </SplitLayout>
              </div>
            </div>

            <CodeBlock
              code={responsiveExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/ResponsiveSplit.tsx"
              showLineNumbers={true}
            />
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for SplitLayout components.
          </p>

          {/* SplitLayout Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              SplitLayout Props
            </h3>
            <div className="bg-card-background border border-border-default rounded-lg overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-table-headerBg">
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
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        direction
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "horizontal" | "vertical"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        "horizontal"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        Split direction
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        gutter
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "none" | "sm" | "md" | "lg" | "xl"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"md"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Gap size between items
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        showDragHandles
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">true</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Show drag handles between items
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        dragHandleSize
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">8</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Size of drag handles in pixels
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        resizable
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">true</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Allow resizing of items
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        collapsible
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">false</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Allow collapsing of items
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        responsive
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        object
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Responsive configuration by breakpoint
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onSizeChange
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (sizes, itemId?) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Callback when item sizes change
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onDragStart
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (itemId) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Callback when drag starts
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onDragEnd
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (event) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Callback when drag ends
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onCollapse
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (itemId, collapsed) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Callback when item is collapsed/expanded
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* SplitLayoutItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              SplitLayoutItem Props
            </h3>
            <div className="bg-card-background border border-border-default rounded-lg overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-table-headerBg">
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
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        size
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"auto"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Initial size of item
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        minSize
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Minimum size of item
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        maxSize
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Maximum size of item
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        resizable
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">true</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Allow resizing this item
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        collapsible
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">false</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Allow collapsing this item
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        collapsedSize
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">50</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Size when collapsed (pixels)
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        defaultCollapsed
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">false</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Initially collapsed state
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        collapsedOverlay
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        ReactNode
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Content to show when collapsed
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default SplitLayoutSection;
