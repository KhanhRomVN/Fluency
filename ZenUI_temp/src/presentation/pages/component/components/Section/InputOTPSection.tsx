import { useState } from "react";
import { InputOTP } from "../../../../components/package/components/input-otp";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { FileCode, Shield } from "lucide-react";
import RightPanel from "../RightPanel";

const InputOTPSection = () => {
  const [otpValue, setOtpValue] = useState("");
  const [completedValue, setCompletedValue] = useState("");

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "variant", label: "Variants" },
        { id: "size", label: "Size Variants" },
        { id: "features", label: "Advanced Features" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { InputOTP } from "@khanhromvn/zenui";
import { useState } from "react";

function MyComponent() {
  const [otp, setOtp] = useState("");

  const handleComplete = (value: string) => {
    console.log("OTP completed:", value);
    // Handle OTP verification here
  };

  return (
    <div className="space-y-4">
      <InputOTP
        length={6}
        value={otp}
        onChange={setOtp}
        onComplete={handleComplete}
        className="justify-center"
      />
      
      <p className="text-center text-text-secondary">
        {otp.length === 6 ? "OTP Complete!" : "Enter 6-digit code"}
      </p>
    </div>
  );
}`;

  const variantExampleCode = `import { InputOTP } from "@khanhromvn/zenui";

function VariantExample() {
  return (
    <div className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Outline Variant
        </label>
        <InputOTP
          length={4}
          variant="outline"
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Filled Variant
        </label>
        <InputOTP
          length={4}
          variant="filled"
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Underline Variant
        </label>
        <InputOTP
          length={4}
          variant="underline"
          className="justify-center"
        />
      </div>
    </div>
  );
}`;

  const sizeExampleCode = `import { InputOTP } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Small (80%)
        </label>
        <InputOTP
          length={4}
          size={80}
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Default (100%)
        </label>
        <InputOTP
          length={4}
          size={100}
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Large (120%)
        </label>
        <InputOTP
          length={4}
          size={120}
          className="justify-center"
        />
      </div>
    </div>
  );
}`;

  const featureExampleCode = `import { InputOTP } from "@khanhromvn/zenui";

function FeatureExample() {
  const handleComplete = (value: string) => {
    // Verify OTP logic here
    alert(\`Verifying OTP: \${value}\`);
  };

  return (
    <div className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          4-digit PIN
        </label>
        <InputOTP
          length={4}
          type="password"
          onComplete={handleComplete}
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          8-digit Code (Disabled)
        </label>
        <InputOTP
          length={8}
          disabled={true}
          className="justify-center"
        />
      </div>
      
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">
          Loading State
        </label>
        <InputOTP
          length={6}
          loading={true}
          className="justify-center"
        />
      </div>
    </div>
  );
}`;

  const handleComplete = (value: string) => {
    setCompletedValue(value);
    console.log("OTP completed:", value);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Input OTP
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A secure and user-friendly One-Time Password (OTP) input component
            with auto-focus, paste support, and keyboard navigation. Perfect for
            verification codes, PIN entry, and authentication flows in your
            application.
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
            Here's a simple example to get you started with the InputOTP
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-4">
            <InputOTP
              length={6}
              value={otpValue}
              onChange={setOtpValue}
              onComplete={handleComplete}
              className="justify-center"
            />

            <div className="text-center space-y-2">
              <p className="text-text-secondary">
                {otpValue.length === 6 ? "OTP Complete!" : "Enter 6-digit code"}
              </p>
              {completedValue && (
                <p className="text-green-600 font-medium">
                  Last completed: {completedValue}
                </p>
              )}
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

          {/* Variants */}
          <div id="variant" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              OTP Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Choose from different input variants to match your design system.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 space-y-6">
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Outline Variant
                </label>
                <InputOTP
                  length={4}
                  variant="outline"
                  className="justify-center"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Filled Variant
                </label>
                <InputOTP
                  length={4}
                  variant="filled"
                  className="justify-center"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Underline Variant
                </label>
                <InputOTP
                  length={4}
                  variant="underline"
                  className="justify-center"
                />
              </div>
            </div>

            <CodeBlock
              code={variantExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/VariantExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Sizes */}
          <div id="size" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control OTP input size using percentage scale from 50% to 200%.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 space-y-6">
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Small (80%)
                </label>
                <InputOTP length={4} size={80} className="justify-center" />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Default (100%)
                </label>
                <InputOTP length={4} size={100} className="justify-center" />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Large (120%)
                </label>
                <InputOTP length={4} size={120} className="justify-center" />
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

          {/* Features */}
          <div id="features" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Advanced Features
            </h3>
            <p className="text-text-secondary mb-4">
              Explore different OTP lengths, types, and states.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 space-y-6">
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  4-digit PIN (Password type)
                </label>
                <InputOTP
                  length={4}
                  type="password"
                  onComplete={handleComplete}
                  className="justify-center"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  8-digit Code (Disabled)
                </label>
                <InputOTP
                  length={8}
                  disabled={true}
                  className="justify-center"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-2">
                  Loading State
                </label>
                <InputOTP
                  length={6}
                  loading={true}
                  className="justify-center"
                />
              </div>
            </div>

            <CodeBlock
              code={featureExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/FeatureExample.tsx"
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
            Complete list of props available for the InputOTP component.
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
                  <span className="font-mono text-xs">length</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Số lượng inputs
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
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Kích thước input (percentage scale)
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
                    "outline" | "filled" | "underline"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Variant của input
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">type</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "text" | "password" | "number"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Loại input
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">disabled</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Trạng thái disabled
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">loading</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Trạng thái loading
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">autoFocus</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Tự động focus vào input đầu tiên
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
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom class name
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">onChange</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    (value: string) =&gt; void
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Change handler
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">onComplete</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    (value: string) =&gt; void
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Complete handler
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

export default InputOTPSection;
