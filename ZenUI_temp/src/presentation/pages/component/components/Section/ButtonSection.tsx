import { useState } from "react";
import { Button } from "../../../../components/package/components/button";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableBody,
  TableHeader,
  TableRow,
  HeaderCell,
  TableCell,
} from "../../../../components/package/components/table";
import { FileCode, Play, Download, Heart, Settings } from "lucide-react";
import RightPanel from "../RightPanel";

const ButtonSection = () => {
  const [loading, setLoading] = useState(false);

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "size", label: "Size Variants" },
        { id: "icon", label: "Icon Positions" },
        { id: "state", label: "Button States" },
        { id: "width", label: "Width Variants" },
        { id: "alignment", label: "Content Alignment" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Button } from "@khanhromvn/zenui";
import { Heart } from "lucide-react";

function MyComponent() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Button className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover">
        Click Me
      </Button>
      
      <Button
        icon={<Heart size={16} />}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover"
      >
        With Icon
      </Button>
      
      <Button
        icon={<Heart size={16} />}
        iconPosition="right"
        className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-button-border hover:border-button-borderHover"
      >
        Icon Right
      </Button>
    </div>
  );
}`;

  const sizeExampleCode = `import { Button } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Button
        size={80}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Small (80%)
      </Button>
      <Button
        size={100}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Default (100%)
      </Button>
      <Button
        size={120}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Large (120%)
      </Button>
      <Button
        size={150}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Extra Large (150%)
      </Button>
    </div>
  );
}`;

  const iconExampleCode = `import { Button } from "@khanhromvn/zenui";
import { Play, Download, Settings, Heart } from "lucide-react";

function IconExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Button
        icon={<Play size={16} />}
        iconPosition="left"
        className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
      >
        Play
      </Button>
      <Button
        icon={<Download size={16} />}
        iconPosition="right"
        className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
      >
        Download
      </Button>
      <Button
        icon={<Settings size={16} />}
        className="bg-gray-600 hover:bg-gray-700 text-white border border-gray-700"
      />
      <Button
        icon={<Heart size={16} />}
        iconPosition="left"
        className="bg-red-600 hover:bg-red-700 text-white border border-red-700"
      >
        ❤️ Like
      </Button>
    </div>
  );
}`;

  const stateExampleCode = `import { Button } from "@khanhromvn/zenui";
import { useState } from "react";

function StateExample() {
  const [loading, setLoading] = useState(false);

  const handleClick = () => {
    setLoading(true);
    setTimeout(() => setLoading(false), 2000);
  };

  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Button
        loading={loading}
        onClick={handleClick}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        {loading ? "Loading..." : "Click to Load"}
      </Button>
      <Button
        disabled={true}
        className="bg-gray-400 text-gray-700 border border-gray-500 cursor-not-allowed"
      >
        Disabled Button
      </Button>
      <Button
        loading={true}
        loadingText="Processing..."
        className="bg-purple-600 hover:bg-purple-700 text-white border border-purple-700"
      >
        With Loading Text
      </Button>
    </div>
  );
}`;

  const handleLoadingDemo = () => {
    setLoading(true);
    setTimeout(() => setLoading(false), 2000);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Button</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible and customizable button component with support for icons,
            loading states, size variations, and extensive styling options.
            Perfect for actions, forms, and interactive elements across your
            application.
          </p>
        </section>

        {/* INSTALL SECTION */}
        <section id="install" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Installation
          </h2>
          <CodeBlock
            items={[
              {
                id: "npm",
                title: "npm",
                code: npmInstallCode,
                language: "bash",
                icon: <FileCode size={16} />,
              },
              {
                id: "yarn",
                title: "yarn",
                code: yarnInstallCode,
                language: "bash",
                icon: <FileCode size={16} />,
              },
            ]}
            theme="vs-dark"
            showLineNumbers={false}
            showGutter={false}
            showLineHighlight={false}
            readOnly={true}
          />
        </section>

        {/* USAGE SECTION */}
        <section id="basic" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the Button
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-4 items-center justify-center flex-wrap">
            <Button className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover">
              Click Me
            </Button>
            <Button
              icon={<Heart size={16} />}
              className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover"
            >
              With Icon
            </Button>
            <Button
              icon={<Heart size={16} />}
              iconPosition="right"
              className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-button-border hover:border-button-borderHover"
            >
              Icon Right
            </Button>
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

          {/* Size Variants */}
          <div id="size" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control button size using percentage scale from 50% to 200%.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 items-center justify-center flex-wrap">
              <Button
                size={80}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Small (80%)
              </Button>
              <Button
                size={100}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Default (100%)
              </Button>
              <Button
                size={120}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Large (120%)
              </Button>
              <Button
                size={150}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Extra Large (150%)
              </Button>
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

          {/* Icon Positions */}
          <div id="icon" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Icon Positions
            </h3>
            <p className="text-text-secondary mb-4">
              Add icons from lucide-react or use emoji, with flexible
              positioning.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 items-center justify-center flex-wrap">
              <Button
                icon={<Play size={16} />}
                iconPosition="left"
                className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
              >
                Play
              </Button>
              <Button
                icon={<Download size={16} />}
                iconPosition="right"
                className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
              >
                Download
              </Button>
              <Button
                icon={<Settings size={16} />}
                className="bg-gray-600 hover:bg-gray-700 text-white border border-gray-700"
              />
              <Button
                icon={<Heart size={16} />}
                iconPosition="left"
                className="bg-red-600 hover:bg-red-700 text-white border border-red-700"
              >
                ❤️ Like
              </Button>
            </div>

            <CodeBlock
              code={iconExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/IconExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Button States */}
          <div id="state" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Button States
            </h3>
            <p className="text-text-secondary mb-4">
              Handle loading and disabled states with built-in visual feedback.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 items-center justify-center flex-wrap">
              <Button
                loading={loading}
                onClick={handleLoadingDemo}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                {loading ? "Loading..." : "Click to Load"}
              </Button>
              <Button
                disabled={true}
                className="bg-gray-400 text-gray-700 border border-gray-500 cursor-not-allowed"
              >
                Disabled Button
              </Button>
              <Button
                loading={true}
                loadingText="Processing..."
                className="bg-purple-600 hover:bg-purple-700 text-white border border-purple-700"
              >
                With Loading Text
              </Button>
            </div>

            <CodeBlock
              code={stateExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/StateExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Width Variants */}
          <div id="width" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Width Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control button width behavior with fit-content or full-width
              options.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-4">
              <Button
                width="fit"
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Fit Content
              </Button>
              <Button
                width="full"
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Full Width
              </Button>
            </div>

            <CodeBlock
              code={`import { Button } from "@khanhromvn/zenui";

function WidthExample() {
  return (
    <div className="flex flex-col gap-4">
      <Button
        width="fit"
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Fit Content
      </Button>
      <Button
        width="full"
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Full Width
      </Button>
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/WidthExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Alignment */}
          <div id="alignment" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Content Alignment
            </h3>
            <p className="text-text-secondary mb-4">
              Align button content to left, center, or right.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-4">
              <Button
                width="full"
                align="left"
                icon={<Play size={16} />}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Left Aligned
              </Button>
              <Button
                width="full"
                align="center"
                icon={<Heart size={16} />}
                className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-button-border"
              >
                Center Aligned
              </Button>
              <Button
                width="full"
                align="right"
                icon={<Download size={16} />}
                className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
              >
                Right Aligned
              </Button>
            </div>

            <CodeBlock
              code={`import { Button } from "@khanhromvn/zenui";
import { Play, Heart, Download } from "lucide-react";

function AlignmentExample() {
  return (
    <div className="flex flex-col gap-4">
      <Button
        width="full"
        align="left"
        icon={<Play size={16} />}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Left Aligned
      </Button>
      <Button
        width="full"
        align="center"
        icon={<Heart size={16} />}
        className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-button-border"
      >
        Center Aligned
      </Button>
      <Button
        width="full"
        align="right"
        icon={<Download size={16} />}
        className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border"
      >
        Right Aligned
      </Button>
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/AlignmentExample.tsx"
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
            Complete list of props available for the Button component.
          </p>

          <div className="border border-table-border rounded-lg overflow-hidden">
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
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      size
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      number
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">100</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Button size (percentage scale: 50-200)
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      width
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      "fit" | "full"
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">"fit"</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Button width behavior
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      children
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      ReactNode
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Button content/text
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      loading
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      boolean
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">false</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">Loading state</span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      disabled
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      boolean
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">false</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">Disabled state</span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      icon
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      LucideIcon | ReactNode
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Icon (Lucide icon, emoji, SVG, text)
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      iconPosition
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      "left" | "right"
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">"left"</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Icon position (when icon and text present)
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      align
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      "left" | "center" | "right"
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">"right"</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Content alignment
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      loadingText
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      string
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Text to display when loading
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      className
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      string
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">""</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Custom CSS classes
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      onClick
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      (e: MouseEvent) =&gt; void
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Click event handler
                    </span>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default ButtonSection;
