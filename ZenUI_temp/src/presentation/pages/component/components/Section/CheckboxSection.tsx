import { useState } from "react";
import { Checkbox } from "../../../../components/package/components/checkbox";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { FileCode } from "lucide-react";
import RightPanel from "../RightPanel";

const CheckboxSection = () => {
  const [checked1, setChecked1] = useState(false);
  const [checked2, setChecked2] = useState(true);
  const [checked3, setChecked3] = useState(false);
  const [indeterminate, setIndeterminate] = useState(true);
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
        { id: "state", label: "State Variants" },
        { id: "label", label: "Label Positions" },
        { id: "group", label: "Checkbox Group" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Checkbox } from "@khanhromvn/zenui";
import { useState } from "react";

function MyComponent() {
  const [checked, setChecked] = useState(false);

  return (
    <div className="flex flex-col gap-4">
      <Checkbox
        checked={checked}
        onChange={setChecked}
        label="Basic Checkbox"
      />
      
      <Checkbox
        checked={true}
        label="Checked by default"
      />
      
      <Checkbox
        disabled={true}
        label="Disabled checkbox"
      />
    </div>
  );
}`;

  const sizeExampleCode = `import { Checkbox } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div className="flex flex-col gap-4">
      <Checkbox
        size={80}
        label="Small Checkbox (80%)"
      />
      
      <Checkbox
        size={100}
        label="Default Checkbox (100%)"
      />
      
      <Checkbox
        size={120}
        label="Large Checkbox (120%)"
      />
      
      <Checkbox
        size={150}
        label="Extra Large Checkbox (150%)"
      />
    </div>
  );
}`;

  const stateExampleCode = `import { Checkbox } from "@khanhromvn/zenui";
import { useState } from "react";

function StateExample() {
  const [checked, setChecked] = useState(false);
  const [indeterminate, setIndeterminate] = useState(true);
  const [loading, setLoading] = useState(false);

  const handleLoadingClick = () => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setChecked(true);
    }, 2000);
  };

  return (
    <div className="flex flex-col gap-4">
      <Checkbox
        checked={checked}
        onChange={setChecked}
        label="Controlled Checkbox"
      />
      
      <Checkbox
        indeterminate={indeterminate}
        label="Indeterminate State"
      />
      
      <Checkbox
        loading={loading}
        onChange={handleLoadingClick}
        label="Loading Checkbox"
      />
      
      <Checkbox
        disabled={true}
        checked={true}
        label="Disabled Checked"
      />
    </div>
  );
}`;

  const labelExampleCode = `import { Checkbox } from "@khanhromvn/zenui";

function LabelExample() {
  return (
    <div className="flex flex-col gap-4">
      <Checkbox
        label="Right side label (default)"
      />
      
      <Checkbox
        labelPosition="left"
        label="Left side label"
      />
      
      <Checkbox
        label={
          <div>
            <span className="font-semibold">Custom label</span>
            <span className="text-text-secondary text-sm"> with additional content</span>
          </div>
        }
      />
      
      <Checkbox
        label="No label provided"
      />
    </div>
  );
}`;

  const handleLoadingDemo = () => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setChecked3(true);
    }, 2000);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Checkbox
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A versatile checkbox component with support for standard checked
            states, indeterminate states, loading indicators, and flexible label
            positioning. Perfect for forms, settings, and selection interfaces
            with smooth animations and accessibility features.
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
            Here's a simple example to get you started with the Checkbox
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <div className="flex flex-col gap-4">
              <Checkbox
                checked={checked1}
                onChange={setChecked1}
                label="Basic Checkbox"
              />

              <Checkbox checked={true} label="Checked by default" />

              <Checkbox disabled={true} label="Disabled checkbox" />
            </div>
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
              Control checkbox size using percentage scale from 50% to 200%.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex flex-col gap-4">
                <Checkbox size={80} label="Small Checkbox (80%)" />

                <Checkbox size={100} label="Default Checkbox (100%)" />

                <Checkbox size={120} label="Large Checkbox (120%)" />

                <Checkbox size={150} label="Extra Large Checkbox (150%)" />
              </div>
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

          {/* State Variants */}
          <div id="state" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              State Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Handle different states including checked, indeterminate, loading,
              and disabled.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex flex-col gap-4">
                <Checkbox
                  checked={checked2}
                  onChange={setChecked2}
                  label="Controlled Checkbox"
                />

                <Checkbox
                  indeterminate={indeterminate}
                  label="Indeterminate State"
                />

                <Checkbox
                  loading={loading}
                  checked={checked3}
                  onChange={handleLoadingDemo}
                  label="Loading Checkbox"
                />

                <Checkbox
                  disabled={true}
                  checked={true}
                  label="Disabled Checked"
                />
              </div>
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

          {/* Label Positions */}
          <div id="label" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Label Positions
            </h3>
            <p className="text-text-secondary mb-4">
              Customize label position and content with flexible options.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex flex-col gap-4">
                <Checkbox label="Right side label (default)" />

                <Checkbox labelPosition="left" label="Left side label" />

                <Checkbox
                  label={
                    <div>
                      <span className="font-semibold">Custom label</span>
                      <span className="text-text-secondary text-sm">
                        {" "}
                        with additional content
                      </span>
                    </div>
                  }
                />

                <Checkbox />
              </div>
            </div>

            <CodeBlock
              code={labelExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/LabelExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Checkbox Group Example */}
          <div id="group" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Checkbox Group
            </h3>
            <p className="text-text-secondary mb-4">
              Create checkbox groups for multiple selection scenarios.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="space-y-3">
                <h4 className="font-semibold text-text-primary mb-3">
                  Select your interests:
                </h4>
                <Checkbox label="Technology" />
                <Checkbox label="Design" />
                <Checkbox label="Business" />
                <Checkbox label="Art" />
                <Checkbox label="Science" />
              </div>
            </div>

            <CodeBlock
              code={`import { Checkbox } from "@khanhromvn/zenui";

function CheckboxGroupExample() {
  return (
    <div className="space-y-3">
      <h4 className="font-semibold text-text-primary mb-3">Select your interests:</h4>
      <Checkbox label="Technology" />
      <Checkbox label="Design" />
      <Checkbox label="Business" />
      <Checkbox label="Art" />
      <Checkbox label="Science" />
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CheckboxGroupExample.tsx"
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
            Complete list of props available for the Checkbox component.
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
                      Checkbox size (percentage scale: 50-200)
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      checked
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
                    <span className="text-text-secondary">Checked state</span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      indeterminate
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
                    <span className="text-text-secondary">
                      Indeterminate state
                    </span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      label
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      string | ReactNode
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">Checkbox label</span>
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-primary">
                      labelPosition
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      "left" | "right"
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">"right"</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">Label position</span>
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
                      onChange
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="font-mono text-xs text-text-secondary">
                      (checked: boolean) =&gt; void
                    </span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">-</span>
                  </TableCell>
                  <TableCell showVerticalDivider>
                    <span className="text-text-secondary">
                      Change event handler
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

export default CheckboxSection;
