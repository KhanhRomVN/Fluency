import { useState } from "react";
import { Flex, FlexItem } from "../../../../components/package/layouts/flex";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  FileCode,
  Box,
  Grid,
  Layout,
  AlignLeft,
  AlignCenter,
  AlignRight,
} from "lucide-react";
import RightPanel from "../RightPanel";

const FlexLayoutSection = () => {
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

  const basicUsageCode = `import { Flex, FlexItem } from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <Flex 
      direction="row" 
      justify="space-between" 
      align="center"
      gap={16}
      className="p-4"
    >
      <FlexItem grow={1} className="p-4 bg-blue-100 rounded-lg">
        Item 1
      </FlexItem>
      <FlexItem grow={2} className="p-4 bg-green-100 rounded-lg">
        Item 2
      </FlexItem>
      <FlexItem grow={1} className="p-4 bg-purple-100 rounded-lg">
        Item 3
      </FlexItem>
    </Flex>
  );
}`;

  const responsiveUsageCode = `import { Flex, FlexItem } from "@khanhromvn/zenui";

function ResponsiveFlex() {
  return (
    <Flex
      direction={{ xs: "column", md: "row" }}
      justify={{ xs: "center", md: "space-between" }}
      align={{ xs: "stretch", md: "center" }}
      gap={{ xs: 8, md: 16 }}
      responsive={{
        xs: { direction: "column", justify: "center" },
        sm: { direction: "row", justify: "flex-start" },
        md: { direction: "row", justify: "space-between" },
        lg: { direction: "row", justify: "space-evenly" }
      }}
      className="p-4"
    >
      <FlexItem
        grow={{ xs: 0, md: 1 }}
        basis={{ xs: "100%", md: "auto" }}
        className="p-4 bg-gradient-to-r from-blue-500 to-cyan-400 text-white rounded-lg"
      >
        Responsive Item 1
      </FlexItem>
      <FlexItem
        grow={{ xs: 0, md: 2 }}
        basis={{ xs: "100%", md: "auto" }}
        className="p-4 bg-gradient-to-r from-green-500 to-emerald-400 text-white rounded-lg"
      >
        Responsive Item 2
      </FlexItem>
      <FlexItem
        grow={{ xs: 0, md: 1 }}
        basis={{ xs: "100%", md: "auto" }}
        className="p-4 bg-gradient-to-r from-purple-500 to-pink-400 text-white rounded-lg"
      >
        Responsive Item 3
      </FlexItem>
    </Flex>
  );
}`;

  const complexLayoutCode = `import { Flex, FlexItem } from "@khanhromvn/zenui";

function ComplexLayout() {
  return (
    <Flex direction="column" gap={24} className="min-h-screen p-6">
      {/* Header */}
      <Flex 
        justify="space-between" 
        align="center"
        className="p-4 bg-gradient-to-r from-gray-800 to-gray-900 text-white rounded-xl shadow-lg"
      >
        <FlexItem>
          <h1 className="text-2xl font-bold">Dashboard</h1>
        </FlexItem>
        <FlexItem>
          <nav className="flex gap-4">
            <a href="#" className="hover:text-cyan-300">Home</a>
            <a href="#" className="hover:text-cyan-300">Analytics</a>
            <a href="#" className="hover:text-cyan-300">Settings</a>
          </nav>
        </FlexItem>
      </Flex>

      {/* Main Content */}
      <Flex gap={20} wrap="wrap">
        {/* Sidebar */}
        <FlexItem 
          basis={{ xs: "100%", md: "250px" }}
          shrink={0}
          className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow"
        >
          <div className="space-y-4">
            <h2 className="font-semibold text-lg">Navigation</h2>
            {/* Navigation items */}
          </div>
        </FlexItem>

        {/* Content Area */}
        <FlexItem 
          grow={1} 
          basis={{ xs: "100%", md: "0" }}
          className="space-y-6"
        >
          {/* Cards Grid */}
          <Flex gap={16} wrap="wrap">
            {[1, 2, 3, 4].map((i) => (
              <FlexItem 
                key={i}
                grow={1}
                basis={{ xs: "100%", sm: "calc(50% - 8px)", lg: "calc(25% - 12px)" }}
                className="p-6 bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-gray-800 dark:to-gray-900 rounded-xl shadow"
              >
                <h3 className="font-bold text-lg">Card {i}</h3>
                <p className="text-gray-600 dark:text-gray-400 mt-2">
                  Card content goes here
                </p>
              </FlexItem>
            ))}
          </Flex>

          {/* Table Section */}
          <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow">
            <h3 className="font-bold text-xl mb-4">Data Table</h3>
            {/* Table content */}
          </div>
        </FlexItem>
      </Flex>

      {/* Footer */}
      <Flex 
        justify="center" 
        align="center"
        className="p-4 mt-auto bg-gray-100 dark:bg-gray-900 rounded-xl"
      >
        <span className="text-gray-600 dark:text-gray-400">
          © 2024 My Application
        </span>
      </Flex>
    </Flex>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Flex Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A comprehensive Flexbox layout component system for building
            responsive, flexible, and complex layouts with ease. Provides a
            declarative API for all Flexbox properties with full responsive
            support.
          </p>
          <div className="mt-4 flex gap-4 flex-wrap">
            <div className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full text-sm">
              <Layout size={14} />
              <span>Flexbox Grid</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-full text-sm">
              <Grid size={14} />
              <span>Responsive</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-full text-sm">
              <Box size={14} />
              <span>CSS-in-JS</span>
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
            Here's a simple example to get you started with the Flex component.
          </p>

          {/* Live Demo */}
          <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
            <Flex
              direction="row"
              justify="space-between"
              align="center"
              gap={16}
              className="p-4 bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-xl"
            >
              <FlexItem
                grow={1}
                onClick={() => setSelectedItem("Item 1")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 1"
                    ? "bg-gradient-to-r from-blue-500 to-cyan-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Box className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 1</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </FlexItem>
              <FlexItem
                grow={2}
                onClick={() => setSelectedItem("Item 2")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 2"
                    ? "bg-gradient-to-r from-green-500 to-emerald-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Grid className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 2 (2x grow)</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Double width item
                </p>
              </FlexItem>
              <FlexItem
                grow={1}
                onClick={() => setSelectedItem("Item 3")}
                className={`p-6 text-center cursor-pointer transition-all duration-200 rounded-lg ${
                  selectedItem === "Item 3"
                    ? "bg-gradient-to-r from-purple-500 to-pink-400 text-white shadow-lg transform scale-105"
                    : "bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
                }`}
              >
                <Layout className="mx-auto mb-2" size={24} />
                <h3 className="font-semibold">Item 3</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Click to select
                </p>
              </FlexItem>
            </Flex>

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
            filePath="src/components/BasicFlexExample.tsx"
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
              Responsive Layout
            </h3>
            <p className="text-text-secondary mb-4">
              Flex component supports responsive props that adapt to different
              screen sizes.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
              <Flex
                direction={{ xs: "column", md: "row" }}
                justify={{ xs: "center", md: "space-between" }}
                align={{ xs: "stretch", md: "center" }}
                gap={{ xs: 8, md: 16 }}
                className="p-4"
              >
                <FlexItem
                  grow={{ xs: 0, md: 1 }}
                  basis={{ xs: "100%", md: "auto" }}
                  className="p-6 bg-gradient-to-r from-blue-500 to-cyan-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]"
                >
                  <h4 className="font-bold text-lg">Mobile Column</h4>
                  <p className="text-sm opacity-90 mt-1">Desktop Row</p>
                </FlexItem>
                <FlexItem
                  grow={{ xs: 0, md: 2 }}
                  basis={{ xs: "100%", md: "auto" }}
                  className="p-6 bg-gradient-to-r from-green-500 to-emerald-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]"
                >
                  <h4 className="font-bold text-lg">Responsive Width</h4>
                  <p className="text-sm opacity-90 mt-1">2x on desktop</p>
                </FlexItem>
                <FlexItem
                  grow={{ xs: 0, md: 1 }}
                  basis={{ xs: "100%", md: "auto" }}
                  className="p-6 bg-gradient-to-r from-purple-500 to-pink-400 text-white rounded-xl text-center transition-transform hover:scale-[1.02]"
                >
                  <h4 className="font-bold text-lg">Flexible Layout</h4>
                  <p className="text-sm opacity-90 mt-1">Auto adjusts</p>
                </FlexItem>
              </Flex>
            </div>

            <CodeBlock
              code={responsiveUsageCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/ResponsiveFlex.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Complex Layout Example */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Complex Layout
            </h3>
            <p className="text-text-secondary mb-4">
              Build complex application layouts with nested Flex components.
            </p>

            <div className="bg-card-background border border-border-default rounded-lg p-8 mb-6">
              <Flex direction="column" gap={24} className="min-h-[400px]">
                {/* Header */}
                <Flex
                  justify="space-between"
                  align="center"
                  className="p-4 bg-gradient-to-r from-gray-800 to-gray-900 text-white rounded-xl"
                >
                  <FlexItem>
                    <div className="flex items-center gap-3">
                      <Layout className="text-cyan-300" size={20} />
                      <h2 className="font-bold text-xl">Dashboard</h2>
                    </div>
                  </FlexItem>
                  <FlexItem>
                    <div className="flex gap-3">
                      <button className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors">
                        Home
                      </button>
                      <button className="px-3 py-1 bg-cyan-600 hover:bg-cyan-500 rounded-lg transition-colors">
                        Analytics
                      </button>
                    </div>
                  </FlexItem>
                </Flex>

                {/* Main Content */}
                <Flex gap={20} wrap="wrap">
                  {/* Sidebar */}
                  <FlexItem
                    basis={{ xs: "100%", md: "200px" }}
                    shrink={0}
                    className="p-4 bg-white dark:bg-gray-800 rounded-xl shadow"
                  >
                    <div className="space-y-3">
                      <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                        Navigation 1
                      </div>
                      <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                        Navigation 2
                      </div>
                      <div className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
                        Navigation 3
                      </div>
                    </div>
                  </FlexItem>

                  {/* Content Area */}
                  <FlexItem
                    grow={1}
                    basis={{ xs: "100%", md: "0" }}
                    className="space-y-4"
                  >
                    {/* Cards Grid */}
                    <Flex gap={16} wrap="wrap">
                      {[1, 2, 3, 4].map((i) => (
                        <FlexItem
                          key={i}
                          grow={1}
                          basis={{
                            xs: "100%",
                            sm: "calc(50% - 8px)",
                            lg: "calc(25% - 12px)",
                          }}
                          className="p-6 bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-gray-800 dark:to-gray-900 rounded-xl shadow text-center"
                        >
                          <div className="w-12 h-12 mx-auto mb-3 rounded-full bg-gradient-to-r from-blue-400 to-cyan-300 flex items-center justify-center">
                            <span className="text-white font-bold">{i}</span>
                          </div>
                          <h4 className="font-bold">Card {i}</h4>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                            Content here
                          </p>
                        </FlexItem>
                      ))}
                    </Flex>

                    {/* Stats */}
                    <Flex gap={16}>
                      <FlexItem
                        grow={1}
                        className="p-4 bg-green-50 dark:bg-green-900/20 rounded-xl"
                      >
                        <h4 className="font-bold text-green-700 dark:text-green-300">
                          Active Users
                        </h4>
                        <p className="text-2xl font-bold mt-2">1,234</p>
                      </FlexItem>
                      <FlexItem
                        grow={1}
                        className="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-xl"
                      >
                        <h4 className="font-bold text-purple-700 dark:text-purple-300">
                          Revenue
                        </h4>
                        <p className="text-2xl font-bold mt-2">$12,345</p>
                      </FlexItem>
                    </Flex>
                  </FlexItem>
                </Flex>
              </Flex>
            </div>

            <CodeBlock
              code={complexLayoutCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              headerMode="path"
              headerIcon={<FileCode size={16} />}
              filePath="src/components/ComplexLayout.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Alignment Examples */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Alignment Options
            </h3>
            <p className="text-text-secondary mb-4">
              Explore different justify and align options.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Justify Content */}
              <div className="bg-card-background border border-border-default rounded-lg p-6">
                <h4 className="font-semibold mb-4 flex items-center gap-2">
                  <AlignCenter size={16} />
                  Justify Content
                </h4>
                <div className="space-y-4">
                  {[
                    "flex-start",
                    "center",
                    "flex-end",
                    "space-between",
                    "space-around",
                  ].map((justify) => (
                    <div key={justify}>
                      <p className="text-sm text-text-secondary mb-2 capitalize">
                        {justify}
                      </p>
                      <Flex
                        justify={justify as any}
                        className="h-12 p-2 bg-gray-100 dark:bg-gray-800 rounded-lg"
                      >
                        {[1, 2, 3].map((i) => (
                          <FlexItem
                            key={i}
                            className={`w-8 h-8 rounded flex items-center justify-center ${
                              i === 2
                                ? "bg-blue-500 text-white"
                                : "bg-gray-300 dark:bg-gray-700"
                            }`}
                          >
                            {i}
                          </FlexItem>
                        ))}
                      </Flex>
                    </div>
                  ))}
                </div>
              </div>

              {/* Align Items */}
              <div className="bg-card-background border border-border-default rounded-lg p-6">
                <h4 className="font-semibold mb-4 flex items-center gap-2">
                  <AlignRight size={16} />
                  Align Items
                </h4>
                <div className="space-y-4">
                  {["flex-start", "center", "flex-end", "stretch"].map(
                    (align) => (
                      <div key={align}>
                        <p className="text-sm text-text-secondary mb-2 capitalize">
                          {align}
                        </p>
                        <Flex
                          align={align as any}
                          className="h-12 p-2 bg-gray-100 dark:bg-gray-800 rounded-lg"
                        >
                          {[1, 2, 3].map((i) => (
                            <FlexItem
                              key={i}
                              className={`${
                                align === "stretch" ? "h-auto" : "h-6"
                              } w-8 rounded flex items-center justify-center ${
                                i === 2
                                  ? "bg-green-500 text-white"
                                  : "bg-gray-300 dark:bg-gray-700"
                              }`}
                            >
                              {i}
                            </FlexItem>
                          ))}
                        </Flex>
                      </div>
                    )
                  )}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for Flex components.
          </p>

          {/* Flex Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Flex Props
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
                        direction
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        FlexDirection
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"row"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Main axis direction
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        justify
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        JustifyContent
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        "flex-start"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        Main axis alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        align
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        AlignItems
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        "stretch"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        Cross axis alignment
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        wrap
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        FlexWrap
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        "nowrap"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        Flex wrapping behavior
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

          {/* FlexItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              FlexItem Props
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
                        grow
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "initial" | "inherit"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Flex grow factor
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        shrink
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        number | "initial" | "inherit"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Flex shrink factor
                      </td>
                    </tr>
                    <tr className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        basis
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string | "auto" | "initial" | "inherit"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Initial size of item
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
                        alignSelf
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Individual alignment
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

export default FlexLayoutSection;
