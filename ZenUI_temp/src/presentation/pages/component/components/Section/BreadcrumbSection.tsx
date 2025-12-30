import { useState } from "react";
import {
  Breadcrumb,
  BreadcrumbItem,
} from "../../../../components/package/components/breadcumb";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { FileCode, Folder, FileText, Settings, Home } from "lucide-react";
import RightPanel from "../RightPanel";

const BreadcrumbSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "separator", label: "Separator Types" },
        { id: "size", label: "Size Variants" },
        { id: "real-world", label: "Real-world Usage" },
        { id: "click-handler", label: "Click Handler" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Breadcrumb, BreadcrumbItem } from "@khanhromvn/zenui";
import { Home, Folder, FileText } from "lucide-react";

function MyComponent() {
  return (
    <Breadcrumb>
      <BreadcrumbItem icon={Home} text="Home" href="/" />
      <BreadcrumbItem icon={Folder} text="Documents" href="/documents" />
      <BreadcrumbItem icon={Folder} text="Projects" href="/documents/projects" />
      <BreadcrumbItem icon={FileText} text="zenui.pdf" />
    </Breadcrumb>
  );
}`;

  const separatorExampleCode = `import { Breadcrumb, BreadcrumbItem } from "@khanhromvn/zenui";
import { Home, Folder, FileText } from "lucide-react";

function SeparatorExample() {
  return (
    <div className="flex flex-col gap-4">
      {/* With Icons */}
      <Breadcrumb>
        <BreadcrumbItem icon={Home} text="Home" href="/" />
        <BreadcrumbItem icon={Folder} text="Documents" href="/documents" />
        <BreadcrumbItem icon={Folder} text="Projects" href="/documents/projects" />
        <BreadcrumbItem icon={FileText} text="zenui.pdf" />
      </Breadcrumb>

      {/* Without Icons */}
      <Breadcrumb>
        <BreadcrumbItem text="Home" href="/" />
        <BreadcrumbItem text="Documents" href="/documents" />
        <BreadcrumbItem text="Projects" href="/documents/projects" />
        <BreadcrumbItem text="zenui.pdf" />
      </Breadcrumb>

      {/* Custom Separator */}
      <Breadcrumb>
        <BreadcrumbItem text="Home" href="/" />
        <BreadcrumbItem text="Documents" href="/documents" />
        <BreadcrumbItem text="Projects" />
      </Breadcrumb>
    </div>
  );
}`;

  const sizeExampleCode = `import { Breadcrumb, BreadcrumbItem } from "@khanhromvn/zenui";
import { Home, Folder, FileText } from "lucide-react";

function SizeExample() {
  return (
    <div className="flex flex-col gap-4">
      <Breadcrumb size={80}>
        <BreadcrumbItem icon={Home} text="Home" href="/" />
        <BreadcrumbItem icon={Folder} text="Components" href="/components" />
        <BreadcrumbItem icon={FileText} text="Breadcrumb" />
      </Breadcrumb>

      <Breadcrumb size={100}>
        <BreadcrumbItem icon={Home} text="Home" href="/" />
        <BreadcrumbItem icon={Folder} text="Components" href="/components" />
        <BreadcrumbItem icon={FileText} text="Breadcrumb" />
      </Breadcrumb>

      <Breadcrumb size={120}>
        <BreadcrumbItem icon={Home} text="Home" href="/" />
        <BreadcrumbItem icon={Folder} text="Components" href="/components" />
        <BreadcrumbItem icon={FileText} text="Breadcrumb" />
      </Breadcrumb>

      <Breadcrumb size={150}>
        <BreadcrumbItem icon={Home} text="Home" href="/" />
        <BreadcrumbItem icon={Folder} text="Components" href="/components" />
        <BreadcrumbItem icon={FileText} text="Breadcrumb" />
      </Breadcrumb>
    </div>
  );
}`;

  const clickHandlerExampleCode = `import { Breadcrumb, BreadcrumbItem } from "@khanhromvn/zenui";
import { Home, Folder, FileText } from "lucide-react";

function ClickHandlerExample() {
  const handleItemClick = (label: string, index: number) => {
    console.log('Clicked:', label, 'at index:', index);
  };

  return (
    <Breadcrumb>
      <BreadcrumbItem
        icon={Home}
        text="Home"
        href="/"
        onClick={() => handleItemClick("Home", 0)}
      />
      <BreadcrumbItem
        icon={Folder}
        text="Products"
        href="/products"
        onClick={() => handleItemClick("Products", 1)}
      />
      <BreadcrumbItem
        icon={Folder}
        text="Electronics"
        href="/products/electronics"
        onClick={() => handleItemClick("Electronics", 2)}
      />
      <BreadcrumbItem
        icon={FileText}
        text="Smartphones"
      />
    </Breadcrumb>
  );
}`;

  // Example breadcrumb items
  const basicItems = [
    { id: "home", label: "Home", href: "/" },
    { id: "documents", label: "Documents", href: "/documents" },
    { id: "projects", label: "Projects", href: "/documents/projects" },
    { id: "zenui", label: "zenui.pdf" },
  ];

  const ecommerceItems = [
    { id: "home", label: "Home", href: "/" },
    { id: "shop", label: "Shop", href: "/shop" },
    { id: "electronics", label: "Electronics", href: "/shop/electronics" },
    { id: "phones", label: "Smartphones", href: "/shop/electronics/phones" },
    { id: "iphone", label: "iPhone 15 Pro" },
  ];

  const settingsItems = [
    { id: "home", label: "Home", href: "/" },
    { id: "settings", label: "Settings", href: "/settings" },
    { id: "account", label: "Account", href: "/settings/account" },
    { id: "security", label: "Security", href: "/settings/account/security" },
    { id: "2fa", label: "Two-Factor Authentication" },
  ];

  const [clickLog, setClickLog] = useState<string[]>([]);

  const handleItemClick = (item: any, index: number) => {
    const log = `Clicked: "${item.label}" at index ${index}`;
    setClickLog((prev) => [log, ...prev.slice(0, 4)]);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Breadcrumb
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A navigation component that shows the current page's location within
            a hierarchy. Perfect for websites with deep navigation structures,
            helping users understand their current context and navigate back to
            parent sections easily.
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
            Here's a simple example to get you started with the Breadcrumb
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Breadcrumb>
              <BreadcrumbItem icon={Home} text="Home" href="/" />
              <BreadcrumbItem
                icon={Folder}
                text="Documents"
                href="/documents"
              />
              <BreadcrumbItem
                icon={Folder}
                text="Projects"
                href="/documents/projects"
              />
              <BreadcrumbItem icon={FileText} text="zenui.pdf" />
            </Breadcrumb>
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

          {/* Separator Types */}
          <div id="separator" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Separator Types
            </h3>
            <p className="text-text-secondary mb-4">
              Choose from different separator icons: chevron, slash, or arrow.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-4">
              <Breadcrumb>
                <BreadcrumbItem icon={Home} text="Home" href="/" />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                />
                <BreadcrumbItem
                  icon={Folder}
                  text="Projects"
                  href="/documents/projects"
                />
                <BreadcrumbItem icon={FileText} text="zenui.pdf" />
              </Breadcrumb>

              <Breadcrumb>
                <BreadcrumbItem text="Home" href="/" />
                <BreadcrumbItem text="Documents" href="/documents" />
                <BreadcrumbItem text="Projects" href="/documents/projects" />
                <BreadcrumbItem text="zenui.pdf" />
              </Breadcrumb>

              <Breadcrumb>
                <BreadcrumbItem text="Home" href="/" />
                <BreadcrumbItem text="Documents" href="/documents" />
                <BreadcrumbItem text="Projects" />
              </Breadcrumb>
            </div>

            <CodeBlock
              code={separatorExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SeparatorExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Size Variants */}
          <div id="size" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control breadcrumb size using percentage scale from 50% to 200%.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-4">
              <Breadcrumb size={80}>
                <BreadcrumbItem icon={Home} text="Home" href="/" />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                />
                <BreadcrumbItem icon={FileText} text="Breadcrumb" />
              </Breadcrumb>

              <Breadcrumb size={100}>
                <BreadcrumbItem icon={Home} text="Home" href="/" />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                />
                <BreadcrumbItem icon={FileText} text="Breadcrumb" />
              </Breadcrumb>

              <Breadcrumb size={120}>
                <BreadcrumbItem icon={Home} text="Home" href="/" />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                />
                <BreadcrumbItem icon={FileText} text="Breadcrumb" />
              </Breadcrumb>

              <Breadcrumb size={150}>
                <BreadcrumbItem icon={Home} text="Home" href="/" />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                />
                <BreadcrumbItem icon={FileText} text="Breadcrumb" />
              </Breadcrumb>
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

          {/* Real-world Examples */}
          <div id="real-world" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Real-world Usage
            </h3>
            <p className="text-text-secondary mb-4">
              Common use cases for breadcrumbs in different applications.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex flex-col gap-6">
              {/* E-commerce Example */}
              <div>
                <h4 className="text-sm font-medium text-text-secondary mb-2">
                  E-commerce Website
                </h4>
                <Breadcrumb>
                  <BreadcrumbItem icon={Home} text="Home" href="/" />
                  <BreadcrumbItem icon={Folder} text="Shop" href="/shop" />
                  <BreadcrumbItem
                    icon={Folder}
                    text="Electronics"
                    href="/shop/electronics"
                  />
                  <BreadcrumbItem
                    icon={Folder}
                    text="Smartphones"
                    href="/shop/electronics/phones"
                  />
                  <BreadcrumbItem icon={FileText} text="iPhone 15 Pro" />
                </Breadcrumb>
              </div>

              {/* Settings Example */}
              <div>
                <h4 className="text-sm font-medium text-text-secondary mb-2">
                  Settings Navigation
                </h4>
                <Breadcrumb>
                  <BreadcrumbItem icon={Home} text="Home" href="/" />
                  <BreadcrumbItem
                    icon={Settings}
                    text="Settings"
                    href="/settings"
                  />
                  <BreadcrumbItem
                    icon={Settings}
                    text="Account"
                    href="/settings/account"
                  />
                  <BreadcrumbItem
                    icon={Settings}
                    text="Security"
                    href="/settings/account/security"
                  />
                  <BreadcrumbItem text="Two-Factor Authentication" />
                </Breadcrumb>
              </div>

              {/* Without Home Icon */}
              <div>
                <h4 className="text-sm font-medium text-text-secondary mb-2">
                  Without Home Icon
                </h4>
                <Breadcrumb>
                  <BreadcrumbItem text="Documents" href="/documents" />
                  <BreadcrumbItem text="Projects" href="/documents/projects" />
                  <BreadcrumbItem text="zenui.pdf" />
                </Breadcrumb>
              </div>
            </div>

            <CodeBlock
              code={`import { Breadcrumb, BreadcrumbItem } from "@khanhromvn/zenui";
import { Home, Folder, FileText, Settings } from "lucide-react";

function RealWorldExample() {
  return (
    <div className="flex flex-col gap-6">
      {/* E-commerce Example */}
      <div>
        <h4 className="text-sm font-medium text-text-secondary mb-2">
          E-commerce Website
        </h4>
        <Breadcrumb>
          <BreadcrumbItem icon={Home} text="Home" href="/" />
          <BreadcrumbItem icon={Folder} text="Shop" href="/shop" />
          <BreadcrumbItem icon={Folder} text="Electronics" href="/shop/electronics" />
          <BreadcrumbItem icon={Folder} text="Smartphones" href="/shop/electronics/phones" />
          <BreadcrumbItem icon={FileText} text="iPhone 15 Pro" />
        </Breadcrumb>
      </div>

      {/* Settings Example */}
      <div>
        <h4 className="text-sm font-medium text-text-secondary mb-2">
          Settings Navigation
        </h4>
        <Breadcrumb>
          <BreadcrumbItem icon={Home} text="Home" href="/" />
          <BreadcrumbItem icon={Settings} text="Settings" href="/settings" />
          <BreadcrumbItem icon={Settings} text="Account" href="/settings/account" />
          <BreadcrumbItem icon={Settings} text="Security" href="/settings/account/security" />
          <BreadcrumbItem text="Two-Factor Authentication" />
        </Breadcrumb>
      </div>

      {/* Without Home Icon */}
      <div>
        <h4 className="text-sm font-medium text-text-secondary mb-2">
          Without Home Icon
        </h4>
        <Breadcrumb>
          <BreadcrumbItem text="Documents" href="/documents" />
          <BreadcrumbItem text="Projects" href="/documents/projects" />
          <BreadcrumbItem text="zenui.pdf" />
        </Breadcrumb>
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

          {/* Click Handler */}
          <div id="click-handler" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Click Handler
            </h3>
            <p className="text-text-secondary mb-4">
              Handle click events on breadcrumb items for custom navigation.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <Breadcrumb>
                <BreadcrumbItem
                  icon={Home}
                  text="Home"
                  href="/"
                  onClick={() => handleItemClick({ label: "Home" }, 0)}
                />
                <BreadcrumbItem
                  icon={Folder}
                  text="Documents"
                  href="/documents"
                  onClick={() => handleItemClick({ label: "Documents" }, 1)}
                />
                <BreadcrumbItem
                  icon={Folder}
                  text="Projects"
                  href="/documents/projects"
                  onClick={() => handleItemClick({ label: "Projects" }, 2)}
                />
                <BreadcrumbItem icon={FileText} text="zenui.pdf" />
              </Breadcrumb>

              {/* Click Log */}
              {clickLog.length > 0 && (
                <div className="mt-4 p-3 bg-input-background rounded border border-border-default">
                  <h5 className="text-sm font-medium text-text-primary mb-2">
                    Click Log:
                  </h5>
                  <div className="space-y-1">
                    {clickLog.map((log, index) => (
                      <div
                        key={index}
                        className="text-xs text-text-secondary font-mono"
                      >
                        {log}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <CodeBlock
              code={clickHandlerExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ClickHandlerExample.tsx"
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
            Complete list of props available for the Breadcrumb component.
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
                  <span className="font-mono text-xs">children*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Children (BreadcrumbItem components)
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">separator</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">LucideIcon</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Icon ngăn cách giữa các item - chỉ LucideIcon
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
                  Kích thước breadcrumb (percentage scale)
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
            </TableBody>
          </Table>

          {/* BreadcrumbItem Type */}
          <div className="mt-8">
            <h3 className="text-xl font-semibold text-text-primary mb-4">
              BreadcrumbItem Props
            </h3>
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
                    <span className="font-mono text-xs">icon</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">LucideIcon</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    -
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    Icon của item - chỉ LucideIcon
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">text*</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">string</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    -
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    Text hiển thị
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">href</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">string</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    -
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    URL (optional)
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">onClick</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    <span className="font-mono text-xs">() =&gt; void</span>
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    -
                  </TableCell>
                  <TableCell showVerticalDivider className="bg-table-bodyBg">
                    Click handler (optional)
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

export default BreadcrumbSection;
