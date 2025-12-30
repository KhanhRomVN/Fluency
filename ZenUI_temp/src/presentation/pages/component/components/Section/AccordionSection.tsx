import { useState } from "react";
import {
  Accordion,
  AccordionList,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "../../../../components/package/components/accordion";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { Button } from "../../../../components/package/components/button";
import { Badge } from "../../../../components/package/components/badge";
import { Input } from "../../../../components/package/components/input";
import { Tab, TabItem } from "../../../../components/package/components/tab";
import {
  HeaderCell,
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../../../../components/package/components/table";
import {
  FileCode,
  Plus,
  AlertCircle,
  CheckCircle,
  Settings,
  User,
  Mail,
  Lock,
  Bell,
  Shield,
  CreditCard,
  FileText,
  Download,
  Upload,
  Trash2,
  Edit,
  Star,
  Zap,
  Search,
  Calendar,
  X,
  Filter,
  RefreshCw,
  MessageSquare,
  Info,
  Play,
  Pause,
  Volume2,
  List,
  Grid,
  Layout,
  Sparkles,
  Rocket,
  Home,
  Smartphone,
  Key,
  Monitor,
} from "lucide-react";
import RightPanel from "../RightPanel";

const AccordionSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "advanced", label: "Advanced Form" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import {
  Accordion,
  AccordionList,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <Accordion type="single" collapsible>
      <AccordionList 
        className="bg-card-background border border-border-default rounded-lg"
        dividerColor="border-divider"
      >
        <AccordionItem value="item-1">
          <AccordionTrigger>
            Getting Started
          </AccordionTrigger>
          <AccordionContent>
            <p>Welcome to the accordion component!</p>
          </AccordionContent>
        </AccordionItem>
      </AccordionList>
    </Accordion>
  );
}`;

  // State cho các ví dụ interactive
  const [activeTab, setActiveTab] = useState("tab1");
  const [searchValue, setSearchValue] = useState("");
  const [emailValue, setEmailValue] = useState("");
  const [passwordValue, setPasswordValue] = useState("");
  const [isPlaying, setIsPlaying] = useState(false);

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Accordion
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible and accessible accordion component that allows users to
            show and hide content sections. Perfect for FAQs, settings panels,
            and content organization with support for single or multiple open
            items, custom icons, and extensive styling options.
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
          />
        </section>

        {/* USAGE SECTION */}
        <section id="basic" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the Accordion
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Accordion type="single" collapsible>
              <AccordionList
                className="bg-card-background border border-border-default rounded-lg"
                dividerColor="border-divider"
              >
                <AccordionItem value="item-1">
                  <AccordionTrigger>Getting Started</AccordionTrigger>
                  <AccordionContent>
                    <p className="mb-2">
                      Welcome to the accordion component! This is a basic
                      example showing how to use the accordion.
                    </p>
                    <p>
                      The content area can contain any React components, text,
                      or HTML elements.
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="item-2">
                  <AccordionTrigger>Installation Guide</AccordionTrigger>
                  <AccordionContent>
                    <p className="mb-2">
                      Install the package using npm or yarn:
                    </p>
                    <code className="block bg-gray-800 text-gray-100 px-3 py-2 rounded text-sm mb-2">
                      npm install @khanhromvn/zenui
                    </code>
                    <code className="block bg-gray-800 text-gray-100 px-3 py-2 rounded text-sm">
                      yarn add @khanhromvn/zenui
                    </code>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="item-3">
                  <AccordionTrigger>API Reference</AccordionTrigger>
                  <AccordionContent>
                    <p>
                      Check the props section for complete API documentation and
                      all available options.
                    </p>
                  </AccordionContent>
                </AccordionItem>
              </AccordionList>
            </Accordion>
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
        <section id="advanced" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Advanced Examples
          </h2>

          {/* Combined Accordion Example */}
          <div className="mb-10">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Advanced Accordion with Form & Badges
            </h3>
            <p className="text-text-secondary mb-4">
              Tích hợp form settings và badge components trong một Accordion duy
              nhất.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <Accordion type="multiple">
                <AccordionList className="bg-card-background border border-border-default rounded-lg">
                  <AccordionItem value="form-settings">
                    <AccordionTrigger className="hover:bg-dropdown-itemHover text-text-primary font-semibold">
                      <div className="flex items-center gap-3">
                        <Settings size={18} className="text-primary" />
                        Form Settings
                      </div>
                    </AccordionTrigger>
                    <AccordionContent>
                      <div className="p-4">
                        <div className="space-y-4">
                          <div>
                            <label className="block text-sm font-medium text-text-primary mb-1">
                              Email
                            </label>
                            <input
                              type="email"
                              placeholder="Enter your email"
                              value={emailValue}
                              onChange={(e) => setEmailValue(e.target.value)}
                              className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
                            />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-text-primary mb-1">
                              Password
                            </label>
                            <input
                              type="password"
                              placeholder="Enter your password"
                              value={passwordValue}
                              onChange={(e) => setPasswordValue(e.target.value)}
                              className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
                            />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-text-primary mb-1">
                              Search
                            </label>
                            <input
                              type="text"
                              placeholder="Search settings..."
                              value={searchValue}
                              onChange={(e) => setSearchValue(e.target.value)}
                              className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
                            />
                          </div>
                        </div>
                        <div className="flex gap-3 mt-6">
                          <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors w-full">
                            Save Changes
                          </button>
                          <button className="px-4 py-2 bg-button-secondBg hover:bg-button-secondBgHover text-text-primary rounded-lg transition-colors w-full">
                            Cancel
                          </button>
                        </div>
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                </AccordionList>
              </Accordion>
            </div>
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for Accordion components.
          </p>

          {/* Accordion Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Accordion Props
            </h3>
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
                        type
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        "single" | "multiple"
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">"single"</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Allow single or multiple items open
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        collapsible
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        boolean
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">true</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Allow items to be closed
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
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* AccordionItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              AccordionItem Props
            </h3>
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
                        value
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
                        Unique identifier for the item
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
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* AccordionTrigger Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              AccordionTrigger Props
            </h3>
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
                        icon
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        ReactNode
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">ChevronDown</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom icon component
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
                      <span className="text-text-secondary">"right"</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Position of the icon
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
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* AccordionContent Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              AccordionContent Props
            </h3>
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
                        className
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
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

// Thêm các icon components còn thiếu
const StopCircle = ({ size }: { size: number }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="12" r="10" />
    <rect x="8" y="8" width="8" height="8" />
  </svg>
);

const History = ({ size }: { size: number }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
    <path d="M3 3v5h5" />
    <path d="M12 7v5l4 2" />
  </svg>
);

const LogOut = ({ size }: { size: number }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <polyline points="16 17 21 12 16 7" />
    <line x1="21" y1="12" x2="9" y2="12" />
  </svg>
);

const Tag = ({ size }: { size: number }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M12 2H2v10l9.29 9.29c.94.94 2.48.94 3.42 0l6.58-6.58c.94-.94.94-2.48 0-3.42L12 2Z" />
    <path d="M7 7h.01" />
  </svg>
);

export default AccordionSection;
