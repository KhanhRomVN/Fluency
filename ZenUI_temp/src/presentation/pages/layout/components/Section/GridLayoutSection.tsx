import { useState } from "react";
import { Grid, GridItem } from "../../../../components/package/layouts/grid";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  FileCode,
  LayoutGrid,
  Maximize2,
  Grid3x3,
  Rows,
  Columns,
} from "lucide-react";
import RightPanel from "../RightPanel";

const GridLayoutSection = () => {
  const [selectedItem, setSelectedItem] = useState<string>("");

  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    { id: "examples", label: "Examples" },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Grid, GridItem } from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <Grid 
      columns={3} 
      gap={16}
      className="p-4"
    >
      <GridItem className="p-4 bg-blue-100 rounded-lg">
        Item 1
      </GridItem>
      <GridItem className="p-4 bg-green-100 rounded-lg">
        Item 2
      </GridItem>
      <GridItem className="p-4 bg-purple-100 rounded-lg">
        Item 3
      </GridItem>
      <GridItem colSpan={2} className="p-4 bg-orange-100 rounded-lg">
        Item 4 (spans 2 columns)
      </GridItem>
      <GridItem className="p-4 bg-pink-100 rounded-lg">
        Item 5
      </GridItem>
    </Grid>
  );
}`;

  const responsiveUsageCode = `import { Grid, GridItem } from "@khanhromvn/zenui";

function ResponsiveGrid() {
  return (
    <Grid
      columns={4}
      gap={20}
      responsive={{
        xs: { columns: 1 },
        sm: { columns: 2 },
        md: { columns: 3 },
        lg: { columns: 4 }
      }}
      className="p-4"
    >
      <GridItem
        colSpan={2}
        responsive={{
          xs: { colSpan: 1 },
          md: { colSpan: 2 }
        }}
        className="p-6 bg-gradient-to-r from-blue-500 to-cyan-400 text-white rounded-xl"
      >
        Wide Item (2 columns on desktop)
      </GridItem>
      <GridItem className="p-6 bg-gradient-to-r from-green-500 to-emerald-400 text-white rounded-xl">
        Regular Item
      </GridItem>
      <GridItem className="p-6 bg-gradient-to-r from-purple-500 to-pink-400 text-white rounded-xl">
        Regular Item
      </GridItem>
    </Grid>
  );
}`;

  const complexLayoutCode = `import { Grid, GridItem } from "@khanhromvn/zenui";

function DashboardLayout() {
  return (
    <Grid 
      columns={12} 
      rows="auto 1fr auto" 
      gap={20}
      className="min-h-screen p-6"
    >
      {/* Header - Full Width */}
      <GridItem 
        colSpan="full"
        className="p-4 bg-gradient-to-r from-gray-800 to-gray-900 text-white rounded-xl"
      >
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </GridItem>

      {/* Sidebar */}
      <GridItem 
        colSpan={3}
        rowSpan={2}
        className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow"
      >
        <h2 className="font-semibold text-lg mb-4">Navigation</h2>
        {/* Navigation items */}
      </GridItem>

      {/* Main Content Area */}
      <GridItem 
        colSpan={9}
        className="space-y-4"
      >
        {/* Stats Cards */}
        <Grid columns={3} gap={16}>
          <GridItem className="p-6 bg-blue-50 dark:bg-blue-900/20 rounded-xl">
            <h3 className="font-bold text-blue-700 dark:text-blue-300">Users</h3>
            <p className="text-2xl font-bold mt-2">1,234</p>
          </GridItem>
          <GridItem className="p-6 bg-green-50 dark:bg-green-900/20 rounded-xl">
            <h3 className="font-bold text-green-700 dark:text-green-300">Revenue</h3>
            <p className="text-2xl font-bold mt-2">$12,345</p>
          </GridItem>
          <GridItem className="p-6 bg-purple-50 dark:bg-purple-900/20 rounded-xl">
            <h3 className="font-bold text-purple-700 dark:text-purple-300">Orders</h3>
            <p className="text-2xl font-bold mt-2">567</p>
          </GridItem>
        </Grid>
      </GridItem>

      {/* Footer - Full Width */}
      <GridItem 
        colSpan="full"
        className="p-4 bg-gray-100 dark:bg-gray-900 rounded-xl text-center"
      >
        <span className="text-gray-600 dark:text-gray-400">
          © 2024 My Application
        </span>
      </GridItem>
    </Grid>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Grid Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A powerful CSS Grid layout component system for building complex,
            responsive 2D layouts with ease. Provides a declarative API for all
            CSS Grid properties including spanning, positioning, and alignment
            with full responsive support.
          </p>
          <div className="mt-4 flex gap-4 flex-wrap">
            <div className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full text-sm">
              <LayoutGrid size={14} />
              <span>CSS Grid</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-full text-sm">
              <Grid3x3 size={14} />
              <span>2D Layouts</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-full text-sm">
              <Maximize2 size={14} />
              <span>Responsive</span>
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
            Here's a simple example to get you started with the Grid component.
          </p>

          {/* Live Demo */}
          <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
            <Grid
              columns={3}
              gap={16}
              className="p-4 bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-xl"
            >
              <GridItem
                onClick={() => setSelectedItem("Item 1")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 1"
                    ? "bg-gradient-to-r from-blue-500 to-cyan-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <LayoutGrid className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 1</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </GridItem>
              <GridItem
                onClick={() => setSelectedItem("Item 2")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 2"
                    ? "bg-gradient-to-r from-green-500 to-emerald-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Grid3x3 className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 2</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </GridItem>
              <GridItem
                onClick={() => setSelectedItem("Item 3")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 3"
                    ? "bg-gradient-to-r from-purple-500 to-pink-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Maximize2 className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 3</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </GridItem>
              <GridItem
                colSpan={2}
                onClick={() => setSelectedItem("Item 4")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 4"
                    ? "bg-gradient-to-r from-orange-500 to-red-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Columns className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 4 (Spans 2 columns)</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Wide item
                </p>
              </GridItem>
              <GridItem
                onClick={() => setSelectedItem("Item 5")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 5"
                    ? "bg-gradient-to-r from-pink-500 to-rose-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Rows className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 5</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </GridItem>
            </Grid>

            {selectedItem && (
              <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                <p className="text-center text-blue-700 dark:text-blue-300">
                  Selected:{" "}
                  <span className="font-semibold">{selectedItem}</span>
                </p>
              </div>
            )}
          </div>

          {/* Code Example */}
          <CodeBlock
            code={basicUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            headerMode="path"
            headerIcon={<FileCode size={16} />}
            filePath="src/components/BasicGridExample.tsx"
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

          {/* Responsive Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Responsive Grid Layout
            </h3>
            <p className="text-text-secondary mb-4">
              Grid component supports responsive props that adapt to different
              screen sizes. Resize your browser to see the layout change.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
              <Grid
                columns={4}
                gap={20}
                responsive={{
                  xs: { columns: 1 },
                  sm: { columns: 2 },
                  md: { columns: 3 },
                  lg: { columns: 4 },
                }}
              >
                <GridItem
                  colSpan={2}
                  responsive={{
                    xs: { colSpan: 1 },
                    md: { colSpan: 2 },
                  }}
                  className="p-6 bg-gradient-to-r from-blue-500 to-cyan-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]"
                >
                  <h4 className="font-bold text-lg">Wide on Desktop</h4>
                  <p className="text-sm opacity-90 mt-1">
                    Spans 2 columns on medium+ screens
                  </p>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-r from-green-500 to-emerald-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]">
                  <h4 className="font-bold text-lg">Regular Item</h4>
                  <p className="text-sm opacity-90 mt-1">Single column</p>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-r from-purple-500 to-pink-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]">
                  <h4 className="font-bold text-lg">Regular Item</h4>
                  <p className="text-sm opacity-90 mt-1">Single column</p>
                </GridItem>
                <GridItem
                  colSpan="full"
                  className="p-6 bg-gradient-to-r from-orange-500 to-red-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]"
                >
                  <h4 className="font-bold text-lg">Full Width</h4>
                  <p className="text-sm opacity-90 mt-1">Spans all columns</p>
                </GridItem>
              </Grid>
            </div>

            <CodeBlock
              code={responsiveUsageCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/ResponsiveGrid.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Complex Layout Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Complex Dashboard Layout
            </h3>
            <p className="text-text-secondary mb-4">
              Build complex application layouts with nested Grid components and
              precise control over rows and columns.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
              <Grid
                columns={12}
                rows="auto 1fr auto"
                gap={20}
                className="min-h-[500px]"
              >
                {/* Header */}
                <GridItem
                  colSpan="full"
                  className="p-4 bg-gradient-to-r from-gray-800 to-gray-900 text-white rounded-xl"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <LayoutGrid className="text-cyan-300" size={20} />
                      <h2 className="font-bold text-xl">Dashboard</h2>
                    </div>
                    <div className="flex gap-3">
                      <button className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors">
                        Home
                      </button>
                      <button className="px-3 py-1 bg-cyan-600 hover:bg-cyan-500 rounded-lg transition-colors">
                        Analytics
                      </button>
                    </div>
                  </div>
                </GridItem>

                {/* Sidebar */}
                <GridItem
                  colSpan={3}
                  rowSpan={2}
                  className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow"
                >
                  <h3 className="font-semibold text-lg mb-4">Navigation</h3>
                  <div className="space-y-3">
                    <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                      Dashboard
                    </div>
                    <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                      Analytics
                    </div>
                    <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                      Settings
                    </div>
                  </div>
                </GridItem>

                {/* Main Content */}
                <GridItem colSpan={9} className="space-y-4">
                  {/* Stats Cards */}
                  <Grid columns={3} gap={16}>
                    <GridItem className="p-6 bg-blue-50 dark:bg-blue-900/20 rounded-xl">
                      <h4 className="font-bold text-blue-700 dark:text-blue-300">
                        Active Users
                      </h4>
                      <p className="text-2xl font-bold mt-2">1,234</p>
                    </GridItem>
                    <GridItem className="p-6 bg-green-50 dark:bg-green-900/20 rounded-xl">
                      <h4 className="font-bold text-green-700 dark:text-green-300">
                        Revenue
                      </h4>
                      <p className="text-2xl font-bold mt-2">$12,345</p>
                    </GridItem>
                    <GridItem className="p-6 bg-purple-50 dark:bg-purple-900/20 rounded-xl">
                      <h4 className="font-bold text-purple-700 dark:text-purple-300">
                        Orders
                      </h4>
                      <p className="text-2xl font-bold mt-2">567</p>
                    </GridItem>
                  </Grid>

                  {/* Chart Area */}
                  <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow">
                    <h4 className="font-bold text-lg mb-4">Analytics Chart</h4>
                    <div className="h-32 bg-gradient-to-r from-blue-100 to-cyan-100 dark:from-blue-900/20 dark:to-cyan-900/20 rounded-lg flex items-center justify-center">
                      <span className="text-gray-500">Chart Placeholder</span>
                    </div>
                  </div>
                </GridItem>

                {/* Footer */}
                <GridItem
                  colSpan="full"
                  className="p-4 bg-gray-100 dark:bg-gray-900 rounded-xl text-center"
                >
                  <span className="text-gray-600 dark:text-gray-400">
                    © 2024 My Application
                  </span>
                </GridItem>
              </Grid>
            </div>

            <CodeBlock
              code={complexLayoutCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/DashboardLayout.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Spanning Examples */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Column & Row Spanning
            </h3>
            <p className="text-text-secondary mb-4">
              Control how items span across columns and rows for flexible
              layouts.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-8">
              <Grid columns={4} rows={3} gap={16}>
                <GridItem
                  colSpan={2}
                  rowSpan={2}
                  className="p-6 bg-gradient-to-br from-blue-400 to-cyan-300 text-white rounded-xl flex items-center justify-center"
                >
                  <div className="text-center">
                    <h4 className="font-bold text-lg">Large Item</h4>
                    <p className="text-sm opacity-90 mt-1">2 cols × 2 rows</p>
                  </div>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-br from-green-400 to-emerald-300 text-white rounded-xl flex items-center justify-center">
                  <span className="font-semibold">1×1</span>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-br from-purple-400 to-pink-300 text-white rounded-xl flex items-center justify-center">
                  <span className="font-semibold">1×1</span>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-br from-orange-400 to-red-300 text-white rounded-xl flex items-center justify-center">
                  <span className="font-semibold">1×1</span>
                </GridItem>
                <GridItem className="p-6 bg-gradient-to-br from-yellow-400 to-orange-300 text-white rounded-xl flex items-center justify-center">
                  <span className="font-semibold">1×1</span>
                </GridItem>
                <GridItem
                  colSpan={2}
                  className="p-6 bg-gradient-to-br from-indigo-400 to-purple-300 text-white rounded-xl flex items-center justify-center"
                >
                  <div className="text-center">
                    <h4 className="font-bold">Wide Item</h4>
                    <p className="text-sm opacity-90 mt-1">2 cols × 1 row</p>
                  </div>
                </GridItem>
                <GridItem
                  colSpan={2}
                  className="p-6 bg-gradient-to-br from-pink-400 to-rose-300 text-white rounded-xl flex items-center justify-center"
                >
                  <div className="text-center">
                    <h4 className="font-bold">Wide Item</h4>
                    <p className="text-sm opacity-90 mt-1">2 cols × 1 row</p>
                  </div>
                </GridItem>
              </Grid>
            </div>
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for Grid components.
          </p>

          {/* Grid Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Grid Props
            </h3>
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
                        columns
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Grid template columns
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rows
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Grid template rows
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        gap
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string | number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Gap between items
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        columnGap
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string | number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Gap between columns
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rowGap
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string | number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Gap between rows
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        autoFlow
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        GridAutoFlow
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Grid auto flow direction
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        justifyItems
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        JustifyItems
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Justify items alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        alignItems
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        AlignItems
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Align items alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        responsive
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        object
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Responsive breakpoint props
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* GridItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              GridItem Props
            </h3>
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
                        colSpan
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto" | "full"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Number of columns to span
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rowSpan
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto" | "full"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Number of rows to span
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        colStart
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Column start position
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        colEnd
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Column end position
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rowStart
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Row start position
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rowEnd
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "auto"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Row end position
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        justifySelf
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "auto" | "start" | "end" | "center" | "stretch"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Justify self alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        alignSelf
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "auto" | "start" | "end" | "center" | "stretch" |
                        "baseline"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Align self alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        order
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Display order
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        responsive
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        object
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Responsive breakpoint props
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

export default GridLayoutSection;
