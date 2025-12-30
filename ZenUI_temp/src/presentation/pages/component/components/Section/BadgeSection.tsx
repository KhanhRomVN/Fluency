import { useState } from "react";
import { Badge } from "../../../../components/package/components/badge";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { FileCode, Bell, CheckCircle, AlertTriangle } from "lucide-react";
import RightPanel from "../RightPanel";

const BadgeSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "dot", label: "Dot Indicator" },
        { id: "size", label: "Size Variants" },
        { id: "kbd", label: "Keyboard Input" },
        { id: "real-world", label: "Real-world Usage" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Badge } from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <div className="flex gap-4 items-center flex-wrap">
      <Badge variant="default">Default</Badge>
      <Badge variant="primary">Primary</Badge>
      <Badge variant="secondary">Secondary</Badge>
      <Badge variant="success">Success</Badge>
      <Badge variant="warning">Warning</Badge>
      <Badge variant="error">Error</Badge>
      <Badge variant="outline">Outline</Badge>
      <Badge variant="kbd">Kbd</Badge>
    </div>
  );
}`;

  const dotExampleCode = `import { Badge } from "@khanhromvn/zenui";
import { Bell, CheckCircle, AlertTriangle } from "lucide-react";

function DotExample() {
  return (
    <div className="flex gap-4 items-center flex-wrap">
      <Badge variant="default" dot>
        Default
      </Badge>
      <Badge variant="primary" dot>
        Primary
      </Badge>
      <Badge variant="success" dot>
        Success
      </Badge>
      <Badge variant="warning" dot dotColor="#f59e0b">
        Custom Dot
      </Badge>
      <Badge variant="error" dot>
        <AlertTriangle size={12} />
        With Icon
      </Badge>
    </div>
  );
}`;

  const sizeExampleCode = `import { Badge } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div className="flex gap-4 items-center flex-wrap">
      <Badge size={80} variant="primary">
        Small (80%)
      </Badge>
      <Badge size={100} variant="primary">
        Default (100%)
      </Badge>
      <Badge size={120} variant="primary">
        Large (120%)
      </Badge>
      <Badge size={150} variant="primary">
        Extra Large (150%)
      </Badge>
    </div>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Badge</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible badge component for displaying status, categories, or
            counts. Supports multiple variants, sizes, and dot indicators for
            various use cases like notifications, labels, and status markers.
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
            Here's a simple example to get you started with the Badge component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-4 items-center flex-wrap">
            <Badge variant="default">Default</Badge>
            <Badge variant="primary">Primary</Badge>
            <Badge variant="secondary">Secondary</Badge>
            <Badge variant="success">Success</Badge>
            <Badge variant="warning">Warning</Badge>
            <Badge variant="error">Error</Badge>
            <Badge variant="outline">Outline</Badge>
            <Badge variant="kbd">Kbd</Badge>
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

          {/* Dot Indicator */}
          <div id="dot" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Dot Indicator
            </h3>
            <p className="text-text-secondary mb-4">
              Add dot indicators to badges for status visualization.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 items-center flex-wrap">
              <Badge variant="default" dot>
                Default
              </Badge>
              <Badge variant="primary" dot>
                Primary
              </Badge>
              <Badge variant="success" dot>
                Success
              </Badge>
              <Badge variant="warning" dot dotColor="#f59e0b">
                Custom Dot
              </Badge>
              <Badge variant="error" dot>
                <AlertTriangle size={12} />
                With Icon
              </Badge>
            </div>

            <CodeBlock
              code={dotExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/DotExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Size Variants */}
          <div id="size" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control badge size using percentage scale from 50% to 200%.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 items-center flex-wrap">
              <Badge size={80} variant="primary">
                Small (80%)
              </Badge>
              <Badge size={100} variant="primary">
                Default (100%)
              </Badge>
              <Badge size={120} variant="primary">
                Large (120%)
              </Badge>
              <Badge size={150} variant="primary">
                Extra Large (150%)
              </Badge>
            </div>

            <CodeBlock
              code={sizeExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SizeExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Keyboard Input (kbd) Variant */}
          <div id="kbd" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Keyboard Input (kbd) Variant
            </h3>
            <p className="text-text-secondary mb-4">
              Use the kbd variant to display keyboard shortcuts and user input
              from keyboard.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-6">
              {/* Single Keys */}
              <div className="flex gap-3 items-center flex-wrap">
                <Badge variant="kbd">Ctrl</Badge>
                <Badge variant="kbd">Alt</Badge>
                <Badge variant="kbd">Shift</Badge>
                <Badge variant="kbd">Enter</Badge>
                <Badge variant="kbd">Esc</Badge>
                <Badge variant="kbd">Tab</Badge>
              </div>

              {/* Key Combinations */}
              <div className="flex flex-col gap-3">
                <div className="flex gap-2 items-center">
                  <span className="text-text-secondary">Copy:</span>
                  <Badge variant="kbd">Ctrl</Badge>
                  <span className="text-text-secondary">+</span>
                  <Badge variant="kbd">C</Badge>
                </div>
                <div className="flex gap-2 items-center">
                  <span className="text-text-secondary">Paste:</span>
                  <Badge variant="kbd">Ctrl</Badge>
                  <span className="text-text-secondary">+</span>
                  <Badge variant="kbd">V</Badge>
                </div>
                <div className="flex gap-2 items-center">
                  <span className="text-text-secondary">Save:</span>
                  <Badge variant="kbd">Ctrl</Badge>
                  <span className="text-text-secondary">+</span>
                  <Badge variant="kbd">S</Badge>
                </div>
                <div className="flex gap-2 items-center">
                  <span className="text-text-secondary">Search:</span>
                  <Badge variant="kbd">Ctrl</Badge>
                  <span className="text-text-secondary">+</span>
                  <Badge variant="kbd">K</Badge>
                </div>
              </div>

              {/* Arrow Keys */}
              <div className="flex gap-3 items-center flex-wrap">
                <Badge variant="kbd">↑</Badge>
                <Badge variant="kbd">↓</Badge>
                <Badge variant="kbd">←</Badge>
                <Badge variant="kbd">→</Badge>
              </div>

              {/* Function Keys */}
              <div className="flex gap-2 items-center flex-wrap">
                <Badge variant="kbd">F1</Badge>
                <Badge variant="kbd">F2</Badge>
                <Badge variant="kbd">F3</Badge>
                <Badge variant="kbd">F4</Badge>
                <Badge variant="kbd">F5</Badge>
                <Badge variant="kbd">F12</Badge>
              </div>
            </div>

            <CodeBlock
              code={`import { Badge } from "@khanhromvn/zenui";

function KbdExample() {
  return (
    <div className="flex flex-col gap-6">
      {/* Single Keys */}
      <div className="flex gap-3 items-center flex-wrap">
        <Badge variant="kbd">Ctrl</Badge>
        <Badge variant="kbd">Alt</Badge>
        <Badge variant="kbd">Shift</Badge>
        <Badge variant="kbd">Enter</Badge>
        <Badge variant="kbd">Esc</Badge>
        <Badge variant="kbd">Tab</Badge>
      </div>

      {/* Key Combinations */}
      <div className="flex flex-col gap-3">
        <div className="flex gap-2 items-center">
          <span>Copy:</span>
          <Badge variant="kbd">Ctrl</Badge>
          <span>+</span>
          <Badge variant="kbd">C</Badge>
        </div>
        <div className="flex gap-2 items-center">
          <span>Paste:</span>
          <Badge variant="kbd">Ctrl</Badge>
          <span>+</span>
          <Badge variant="kbd">V</Badge>
        </div>
        <div className="flex gap-2 items-center">
          <span>Save:</span>
          <Badge variant="kbd">Ctrl</Badge>
          <span>+</span>
          <Badge variant="kbd">S</Badge>
        </div>
        <div className="flex gap-2 items-center">
          <span>Search:</span>
          <Badge variant="kbd">Ctrl</Badge>
          <span>+</span>
          <Badge variant="kbd">K</Badge>
        </div>
      </div>

      {/* Arrow Keys */}
      <div className="flex gap-3 items-center flex-wrap">
        <Badge variant="kbd">↑</Badge>
        <Badge variant="kbd">↓</Badge>
        <Badge variant="kbd">←</Badge>
        <Badge variant="kbd">→</Badge>
      </div>

      {/* Function Keys */}
      <div className="flex gap-2 items-center flex-wrap">
        <Badge variant="kbd">F1</Badge>
        <Badge variant="kbd">F2</Badge>
        <Badge variant="kbd">F3</Badge>
        <Badge variant="kbd">F4</Badge>
        <Badge variant="kbd">F5</Badge>
        <Badge variant="kbd">F12</Badge>
      </div>
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/KbdExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Usage with Avatars */}
          <div id="real-world" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Real-world Usage
            </h3>
            <p className="text-text-secondary mb-4">
              Common use cases for badges in applications.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-6">
              {/* Notification Badges */}
              <div className="flex gap-6 items-center flex-wrap">
                <div className="flex items-center gap-2">
                  <Bell size={20} />
                  <Badge variant="error" dot>
                    Notifications
                  </Badge>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle size={20} />
                  <Badge variant="success">Active</Badge>
                </div>
                <Badge variant="outline">Category: Technology</Badge>
              </div>

              {/* Status Indicators */}
              <div className="flex gap-4 items-center flex-wrap">
                <Badge variant="success">Completed</Badge>
                <Badge variant="warning">Pending</Badge>
                <Badge variant="error">Failed</Badge>
                <Badge variant="default">Draft</Badge>
              </div>

              {/* Count Badges */}
              <div className="flex gap-4 items-center flex-wrap">
                <Badge variant="primary">42 Messages</Badge>
                <Badge variant="secondary">7 Updates</Badge>
                <Badge variant="outline">99+</Badge>
              </div>
            </div>

            <CodeBlock
              code={`import { Badge } from "@khanhromvn/zenui";
import { Bell, CheckCircle } from "lucide-react";

function RealWorldExample() {
  return (
    <div className="flex flex-col gap-6">
      {/* Notification Badges */}
      <div className="flex gap-6 items-center flex-wrap">
        <div className="flex items-center gap-2">
          <Bell size={20} />
          <Badge variant="error" dot>
            Notifications
          </Badge>
        </div>
        <div className="flex items-center gap-2">
          <CheckCircle size={20} />
          <Badge variant="success">Active</Badge>
        </div>
        <Badge variant="outline">Category: Technology</Badge>
      </div>

      {/* Status Indicators */}
      <div className="flex gap-4 items-center flex-wrap">
        <Badge variant="success">Completed</Badge>
        <Badge variant="warning">Pending</Badge>
        <Badge variant="error">Failed</Badge>
        <Badge variant="default">Draft</Badge>
      </div>

      {/* Count Badges */}
      <div className="flex gap-4 items-center flex-wrap">
        <Badge variant="primary">42 Messages</Badge>
        <Badge variant="secondary">7 Updates</Badge>
        <Badge variant="outline">99+</Badge>
      </div>
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/RealWorldExample.tsx"
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
            Complete list of props available for the Badge component.
          </p>

          <Table>
            <TableHeader>
              <TableRow className="bg-table-headerBg">
                <HeaderCell showVerticalDivider showHorizontalDivider>
                  Prop
                </HeaderCell>
                <HeaderCell showVerticalDivider showHorizontalDivider>
                  Type
                </HeaderCell>
                <HeaderCell showVerticalDivider showHorizontalDivider>
                  Default
                </HeaderCell>
                <HeaderCell showVerticalDivider showHorizontalDivider>
                  Description
                </HeaderCell>
              </TableRow>
            </TableHeader>
            <TableBody className="bg-table-bodyBg">
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">children</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Badge content
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">variant</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "default" | "primary" | "secondary" | "success" | "warning"
                    | "error" | "outline" | "kbd"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  "default"
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Badge variant style
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">size</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  100
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Badge size (percentage scale: 50-200)
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">dot</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  false
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Show dot indicator
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">dotColor</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom dot color
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">className</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  ""
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom CSS classes
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default BadgeSection;
