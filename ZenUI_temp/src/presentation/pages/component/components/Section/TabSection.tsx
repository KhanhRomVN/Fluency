import { useState } from "react";
import { Tab, TabItem } from "../../../../components/package/components/tab";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Home, User, Settings, Bell, Mail } from "lucide-react";
import RightPanel from "../RightPanel";

const TabSection = () => {
  const [activeTab, setActiveTab] = useState("home");
  const [controlledTab, setControlledTab] = useState("profile");

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "controlled", label: "Controlled" },
        { id: "pill", label: "Pill Style" },
        { id: "vertical", label: "Vertical Border" },
        { id: "minimal", label: "Minimal Style" },
        { id: "alignment", label: "Alignment" },
        { id: "icon", label: "Icon Position" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Tab, TabItem } from "@khanhromvn/zenui";
import { Home, User, Settings } from "lucide-react";

function MyComponent() {
  return (
    <Tab defaultActive="home" width="full">
      <TabItem id="home" icon={<Home size={16} />}>
        Home
      </TabItem>
      <TabItem id="profile" icon={<User size={16} />}>
        Profile
      </TabItem>
      <TabItem id="settings" icon={<Settings size={16} />}>
        Settings
      </TabItem>
    </Tab>
  );
}`;

  const controlledExampleCode = `import { Tab, TabItem } from "@khanhromvn/zenui";

function ControlledExample() {
  const [activeTab, setActiveTab] = useState("home");

  return (
    <Tab 
      active={activeTab} 
      onActiveChange={setActiveTab}
      width="full"
    >
      <TabItem id="home">
        Home
      </TabItem>
      <TabItem id="profile">
        Profile
      </TabItem>
      <TabItem id="settings">
        Settings
      </TabItem>
    </Tab>
  );
}`;

  const customStylesCode = `import { Tab, TabItem } from "@khanhromvn/zenui";

function CustomStylesExample() {
  return (
    <Tab width="full" className="bg-gray-50 p-1 rounded-lg">
      <TabItem 
        id="home"
        className="rounded-md"
        hoverClassName="hover:bg-white hover:shadow-sm"
        activeClassName="bg-white shadow-sm text-purple-600 border-purple-600"
      >
        Home
      </TabItem>
      <TabItem 
        id="profile"
        className="rounded-md"
        hoverClassName="hover:bg-white hover:shadow-sm"
        activeClassName="bg-white shadow-sm text-purple-600 border-purple-600"
      >
        Profile
      </TabItem>
    </Tab>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Tab</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible and customizable tab component with support for icons,
            custom styling for different states, controlled/uncontrolled modes,
            and various alignment options. Perfect for navigation, content
            switching, and organization across your application.
          </p>
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
        <section id="basic" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the Tab component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Tab
              defaultActive="home"
              width="full"
              className="bg-tab-background border-b border-tab-border"
            >
              <TabItem
                id="home"
                icon={<Home size={16} />}
                className="border-b-2 border-tab-item-border"
                hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                activeClassName="border-tab-item-focusBorder text-primary"
              >
                Home
              </TabItem>
              <TabItem
                id="profile"
                icon={<User size={16} />}
                className="border-b-2 border-tab-item-border"
                hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                activeClassName="border-tab-item-focusBorder text-primary"
              >
                Profile
              </TabItem>
              <TabItem
                id="settings"
                icon={<Settings size={16} />}
                className="border-b-2 border-tab-item-border"
                hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                activeClassName="border-tab-item-focusBorder text-primary"
              >
                Settings
              </TabItem>
              <TabItem
                id="notifications"
                icon={<Bell size={16} />}
                className="border-b-2 border-tab-item-border"
                hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                activeClassName="border-tab-item-focusBorder text-primary"
              >
                Notifications
              </TabItem>
            </Tab>
          </div>

          {/* Code Example */}
          <CodeBlock
            code={basicUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            filename="src/components/BasicExample.tsx"
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

          {/* Controlled Tab Example */}
          <div id="controlled" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Controlled Tab
            </h3>
            <p className="text-text-secondary mb-4">
              You can control the active tab externally using the{" "}
              <code className="px-2 py-1 bg-card-background border border-border-default rounded text-sm">
                active
              </code>{" "}
              and{" "}
              <code className="px-2 py-1 bg-card-background border border-border-default rounded text-sm">
                onActiveChange
              </code>{" "}
              props.
            </p>

            {/* Live Demo */}
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <div className="mb-4 text-text-secondary text-sm">
                Active Tab:{" "}
                <span className="font-semibold text-primary">
                  {controlledTab}
                </span>
              </div>
              <Tab
                active={controlledTab}
                onActiveChange={setControlledTab}
                width="full"
                className="bg-tab-background border-b border-tab-border"
              >
                <TabItem
                  id="profile"
                  icon={<User size={16} />}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Profile
                </TabItem>
                <TabItem
                  id="settings"
                  icon={<Settings size={16} />}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Settings
                </TabItem>
                <TabItem
                  id="notifications"
                  icon={<Bell size={16} />}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-tab-item-hoverBorder"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Notifications
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={controlledExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ControlledExample.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Pill Style Example */}
          <div id="pill" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Pill Style Tabs
            </h3>
            <p className="text-text-secondary mb-4">
              Create modern pill-style tabs with rounded corners and background
              colors.
            </p>

            {/* Live Demo */}
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <Tab
                width="full"
                className="bg-gray-100 dark:bg-gray-800 p-1 rounded-lg"
              >
                <TabItem
                  id="home"
                  icon={<Home size={16} />}
                  className="rounded-md border-0"
                  hoverClassName="hover:bg-white/50 dark:hover:bg-gray-700/50"
                  activeClassName="bg-white dark:bg-gray-900 shadow-sm text-primary"
                >
                  Home
                </TabItem>
                <TabItem
                  id="profile"
                  icon={<User size={16} />}
                  className="rounded-md border-0"
                  hoverClassName="hover:bg-white/50 dark:hover:bg-gray-700/50"
                  activeClassName="bg-white dark:bg-gray-900 shadow-sm text-primary"
                >
                  Profile
                </TabItem>
                <TabItem
                  id="settings"
                  icon={<Settings size={16} />}
                  className="rounded-md border-0"
                  hoverClassName="hover:bg-white/50 dark:hover:bg-gray-700/50"
                  activeClassName="bg-white dark:bg-gray-900 shadow-sm text-primary"
                >
                  Settings
                </TabItem>
                <TabItem
                  id="mail"
                  icon={<Mail size={16} />}
                  className="rounded-md border-0"
                  hoverClassName="hover:bg-white/50 dark:hover:bg-gray-700/50"
                  activeClassName="bg-white dark:bg-gray-900 shadow-sm text-primary"
                >
                  Mail
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={customStylesCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/PillStyleExample.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Vertical Border Style Example */}
          <div id="vertical" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Vertical Border Style
            </h3>
            <p className="text-text-secondary mb-4">
              Create tabs with left border indicator instead of bottom border.
            </p>

            {/* Live Demo */}
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <Tab width="full" className="border-l-0">
                <TabItem
                  id="home"
                  icon={<Home size={16} />}
                  className="border-l-4 border-transparent"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
                  activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
                >
                  Home
                </TabItem>
                <TabItem
                  id="profile"
                  icon={<User size={16} />}
                  className="border-l-4 border-transparent"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
                  activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
                >
                  Profile
                </TabItem>
                <TabItem
                  id="settings"
                  icon={<Settings size={16} />}
                  className="border-l-4 border-transparent"
                  hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
                  activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
                >
                  Settings
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={`import { Tab, TabItem } from "@khanhromvn/zenui";
import { Home, User, Settings } from "lucide-react";

function VerticalBorderExample() {
  return (
    <Tab width="full" className="border-l-0">
      <TabItem
        id="home"
        icon={<Home size={16} />}
        className="border-l-4 border-transparent"
        hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
        activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
      >
        Home
      </TabItem>
      <TabItem
        id="profile"
        icon={<User size={16} />}
        className="border-l-4 border-transparent"
        hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
        activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
      >
        Profile
      </TabItem>
      <TabItem
        id="settings"
        icon={<Settings size={16} />}
        className="border-l-4 border-transparent"
        hoverClassName="hover:bg-tab-item-hoverBg hover:border-l-gray-300"
        activeClassName="border-l-primary bg-tab-item-focusBg text-primary"
      >
        Settings
      </TabItem>
    </Tab>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/VerticalBorderExample.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Minimal Style Example */}
          <div id="minimal" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Minimal Style Tabs
            </h3>
            <p className="text-text-secondary mb-4">
              Clean, minimal tabs with subtle hover effects and no borders.
            </p>

            {/* Live Demo */}
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <Tab width="full" className="gap-2">
                <TabItem
                  id="home"
                  className="border-0 rounded-md"
                  hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
                  activeClassName="bg-primary/10 text-primary"
                >
                  Home
                </TabItem>
                <TabItem
                  id="profile"
                  className="border-0 rounded-md"
                  hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
                  activeClassName="bg-primary/10 text-primary"
                >
                  Profile
                </TabItem>
                <TabItem
                  id="settings"
                  className="border-0 rounded-md"
                  hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
                  activeClassName="bg-primary/10 text-primary"
                >
                  Settings
                </TabItem>
                <TabItem
                  id="notifications"
                  className="border-0 rounded-md"
                  hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
                  activeClassName="bg-primary/10 text-primary"
                >
                  Notifications
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={`import { Tab, TabItem } from "@khanhromvn/zenui";

function MinimalStyleExample() {
  return (
    <Tab width="full" className="gap-2">
      <TabItem
        id="home"
        className="border-0 rounded-md"
        hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
        activeClassName="bg-primary/10 text-primary"
      >
        Home
      </TabItem>
      <TabItem
        id="profile"
        className="border-0 rounded-md"
        hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
        activeClassName="bg-primary/10 text-primary"
      >
        Profile
      </TabItem>
      <TabItem
        id="settings"
        className="border-0 rounded-md"
        hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
        activeClassName="bg-primary/10 text-primary"
      >
        Settings
      </TabItem>
      <TabItem
        id="notifications"
        className="border-0 rounded-md"
        hoverClassName="hover:bg-gray-100 dark:hover:bg-gray-800"
        activeClassName="bg-primary/10 text-primary"
      >
        Notifications
      </TabItem>
    </Tab>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/MinimalStyleExample.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Alignment Examples */}
          <div id="alignment" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Tab Alignment
            </h3>
            <p className="text-text-secondary mb-4">
              Control the alignment of tabs using the{" "}
              <code className="px-2 py-1 bg-card-background border border-border-default rounded text-sm">
                align
              </code>{" "}
              prop.
            </p>

            {/* Left Align Demo */}
            <div className="mb-6">
              <p className="text-sm text-text-secondary mb-2">
                Left Aligned (default)
              </p>
              <div className="border-2 border-dashed border-border-default rounded-lg p-8">
                <Tab
                  width="full"
                  align="left"
                  className="bg-tab-background border-b border-tab-border"
                >
                  <TabItem
                    id="home"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Home
                  </TabItem>
                  <TabItem
                    id="profile"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Profile
                  </TabItem>
                </Tab>
              </div>
            </div>

            {/* Center Align Demo */}
            <div className="mb-6">
              <p className="text-sm text-text-secondary mb-2">Center Aligned</p>
              <div className="border-2 border-dashed border-border-default rounded-lg p-8">
                <Tab
                  width="full"
                  align="center"
                  className="bg-tab-background border-b border-tab-border"
                >
                  <TabItem
                    id="home"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Home
                  </TabItem>
                  <TabItem
                    id="profile"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Profile
                  </TabItem>
                </Tab>
              </div>
            </div>

            {/* Right Align Demo */}
            <div className="mb-6">
              <p className="text-sm text-text-secondary mb-2">Right Aligned</p>
              <div className="border-2 border-dashed border-border-default rounded-lg p-8">
                <Tab
                  width="full"
                  align="right"
                  className="bg-tab-background border-b border-tab-border"
                >
                  <TabItem
                    id="home"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Home
                  </TabItem>
                  <TabItem
                    id="profile"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Profile
                  </TabItem>
                </Tab>
              </div>
            </div>

            {/* Space Between Demo */}
            <div className="mb-6">
              <p className="text-sm text-text-secondary mb-2">Space Between</p>
              <div className="border-2 border-dashed border-border-default rounded-lg p-8">
                <Tab
                  width="full"
                  align="space-between"
                  className="bg-tab-background border-b border-tab-border"
                >
                  <TabItem
                    id="home"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Home
                  </TabItem>
                  <TabItem
                    id="profile"
                    className="border-b-2 border-tab-item-border"
                    hoverClassName="hover:bg-tab-item-hoverBg"
                    activeClassName="border-tab-item-focusBorder text-primary"
                  >
                    Profile
                  </TabItem>
                </Tab>
              </div>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={`import { Tab, TabItem } from "@khanhromvn/zenui";

function AlignmentExamples() {
  return (
    <>
      {/* Left Aligned (default) */}
      <Tab width="full" align="left">
        <TabItem id="home">Home</TabItem>
        <TabItem id="profile">Profile</TabItem>
      </Tab>

      {/* Center Aligned */}
      <Tab width="full" align="center">
        <TabItem id="home">Home</TabItem>
        <TabItem id="profile">Profile</TabItem>
      </Tab>

      {/* Right Aligned */}
      <Tab width="full" align="right">
        <TabItem id="home">Home</TabItem>
        <TabItem id="profile">Profile</TabItem>
      </Tab>

      {/* Space Between */}
      <Tab width="full" align="space-between">
        <TabItem id="home">Home</TabItem>
        <TabItem id="profile">Profile</TabItem>
      </Tab>
    </>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/AlignmentExamples.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Icon Position Example */}
          <div id="icon" className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Icon Position
            </h3>
            <p className="text-text-secondary mb-4">
              Control icon position using the{" "}
              <code className="px-2 py-1 bg-card-background border border-border-default rounded text-sm">
                iconPosition
              </code>{" "}
              prop.
            </p>

            {/* Live Demo */}
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <Tab
                width="full"
                className="bg-tab-background border-b border-tab-border mb-4"
              >
                <TabItem
                  id="home"
                  icon={<Home size={16} />}
                  iconPosition="left"
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Icon Left
                </TabItem>
                <TabItem
                  id="profile"
                  icon={<User size={16} />}
                  iconPosition="right"
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Icon Right
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={`import { Tab, TabItem } from "@khanhromvn/zenui";
import { Home, User } from "lucide-react";

function IconPositionExample() {
  return (
    <Tab width="full">
      <TabItem 
        id="home" 
        icon={<Home size={16} />} 
        iconPosition="left"
      >
        Icon Left
      </TabItem>
      <TabItem 
        id="profile" 
        icon={<User size={16} />} 
        iconPosition="right"
      >
        Icon Right
      </TabItem>
    </Tab>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/IconPositionExample.tsx"
              showLineNumbers={true}
              showGutter={true}
              showLineHighlight={false}
            />
          </div>

          {/* Disabled State Example */}
          <div className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Disabled State
            </h3>
            <p className="text-text-secondary mb-4">
              Disable specific tabs using the{" "}
              <code className="px-2 py-1 bg-card-background border border-border-default rounded text-sm">
                disabled
              </code>{" "}
              prop.
            </p>

            {/* Live Demo */}
            <div className="bg-card-background border border-border-default rounded-md p-8 mb-6">
              <Tab
                width="full"
                className="bg-tab-background border-b border-tab-border"
              >
                <TabItem
                  id="home"
                  icon={<Home size={16} />}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Home
                </TabItem>
                <TabItem
                  id="profile"
                  icon={<User size={16} />}
                  disabled={true}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Profile (Disabled)
                </TabItem>
                <TabItem
                  id="settings"
                  icon={<Settings size={16} />}
                  className="border-b-2 border-tab-item-border"
                  hoverClassName="hover:bg-tab-item-hoverBg"
                  activeClassName="border-tab-item-focusBorder text-primary"
                >
                  Settings
                </TabItem>
              </Tab>
            </div>

            {/* Code Example */}
            <CodeBlock
              code={`import { Tab, TabItem } from "@khanhromvn/zenui";
import { Home, User, Settings } from "lucide-react";

function DisabledExample() {
  return (
    <Tab width="full">
      <TabItem id="home" icon={<Home size={16} />}>
        Home
      </TabItem>
      <TabItem 
        id="profile" 
        icon={<User size={16} />}
        disabled={true}
      >
        Profile (Disabled)
      </TabItem>
      <TabItem id="settings" icon={<Settings size={16} />}>
        Settings
      </TabItem>
    </Tab>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/DisabledExample.tsx"
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
            Complete list of props available for Tab components.
          </p>

          {/* Tab Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Tab Props
            </h3>
            <div className="bg-card-background border border-border-default rounded-md overflow-hidden">
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
                        defaultActive
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">""</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Default active tab ID (uncontrolled)
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        active
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Controlled active tab
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onActiveChange
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (tabId: string) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Active tab change callback
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        width
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "full" | "fit"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"full"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Width mode
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        align
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "left" | "center" | "right" | "space-between"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"left"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Alignment of tabs
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* TabItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              TabItem Props
            </h3>
            <div className="bg-card-background border border-border-default rounded-md overflow-hidden">
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
                        id
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Unique tab identifier (required)
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        className
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">""</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Default state className
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        hoverClassName
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">""</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Hover state className
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        activeClassName
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">""</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Active/focused state className
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        icon
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        ReactNode
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Icon element
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        iconPosition
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "left" | "right"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"left"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Icon position relative to text
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        disabled
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">false</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Disabled state
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

export default TabSection;
