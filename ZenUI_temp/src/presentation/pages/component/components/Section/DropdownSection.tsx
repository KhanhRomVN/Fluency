import { useState } from "react";
import {
  Dropdown,
  DropdownTrigger,
  DropdownContent,
  DropdownItem,
} from "../../../../components/package/components/dropdown";
import { Button } from "../../../../components/package/components/button";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  FileCode,
  ChevronDown,
  User,
  Settings,
  LogOut,
  Copy,
  Trash,
  Edit,
  Share,
  Download,
  Mail,
  MessageSquare,
  Phone,
  Calendar,
  File,
  Folder,
} from "lucide-react";
import RightPanel from "../RightPanel";

const DropdownSection = () => {
  const [selectedOption, setSelectedOption] = useState("Option 1");

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "position", label: "Positioning" },
        { id: "icons", label: "With Icons" },
        { id: "custom", label: "Custom Content" },
        { id: "size", label: "Size Variants" },
        { id: "controlled", label: "Controlled" },
        { id: "disabled", label: "Disabled State" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { 
  Dropdown, 
  DropdownTrigger, 
  DropdownContent, 
  DropdownItem 
} from "@khanhromvn/zenui";
import { Button } from "@khanhromvn/zenui";
import { ChevronDown, User, Settings, LogOut } from "lucide-react";

function MyComponent() {
  return (
    <Dropdown>
      <DropdownTrigger>
        <Button 
          icon={<ChevronDown size={16} />}
          iconPosition="right"
          className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
        >
          Menu
        </Button>
      </DropdownTrigger>
      
      <DropdownContent>
        <DropdownItem leftIcon={<User size={16} />}
>
          Profile
        </DropdownItem>
        <DropdownItem leftIcon={<Settings size={16} />}
>
          Settings
        </DropdownItem>
        <DropdownItem leftIcon={<LogOut size={16} />}
>
          Logout
        </DropdownItem>
      </DropdownContent>
    </Dropdown>
  );
}`;

  const positionExampleCode = `import { 
  Dropdown, 
  DropdownTrigger, 
  DropdownContent, 
  DropdownItem 
} from "@khanhromvn/zenui";
import { Button } from "@khanhromvn/zenui";

function PositionExample() {
  return (
    <div className="grid grid-cols-3 gap-4">
      {/* Top positions */}
      <Dropdown position="top-left">
        <DropdownTrigger>
          <Button>Top Left</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>

      <Dropdown position="top-center">
        <DropdownTrigger>
          <Button>Top Center</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>

      <Dropdown position="top-right">
        <DropdownTrigger>
          <Button>Top Right</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>

      {/* Bottom positions */}
      <Dropdown position="bottom-left">
        <DropdownTrigger>
          <Button>Bottom Left</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>

      <Dropdown position="bottom-center">
        <DropdownTrigger>
          <Button>Bottom Center</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>

      <Dropdown position="bottom-right">
        <DropdownTrigger>
          <Button>Bottom Right</Button>
        </DropdownTrigger>
        <DropdownContent>
          <DropdownItem>Item 1</DropdownItem>
          <DropdownItem>Item 2</DropdownItem>
        </DropdownContent>
      </Dropdown>
    </div>
  );
}`;

  const customContentCode = `import { 
  Dropdown, 
  DropdownTrigger, 
  DropdownContent, 
  DropdownItem 
} from "@khanhromvn/zenui";
import { Button } from "@khanhromvn/zenui";

function CustomContentExample() {
  return (
    <Dropdown>
      <DropdownTrigger>
        <Button>Custom Content</Button>
      </DropdownTrigger>
      
      <DropdownContent>
        {/* Custom header */}
        <div className="px-3 py-2 border-b border-border-default">
          <p className="font-semibold text-sm">Account</p>
          <p className="text-xs text-text-secondary">user@example.com</p>
        </div>

        {/* Regular items */}
        <DropdownItem leftIcon={<User size={16} />}
>
          Profile
        </DropdownItem>
        <DropdownItem leftIcon={<Settings size={16} />}
>
          Settings
        </DropdownItem>

        {/* Divider */}
        <div className="border-t border-border-default my-1"></div>

        {/* Custom footer */}
        <div className="px-3 py-2">
          <Button width="full" size={90}>
            Sign Out
          </Button>
        </div>
      </DropdownContent>
    </Dropdown>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Dropdown
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible and customizable dropdown component with support for
            multiple positioning options, custom content, icons, and extensive
            styling. Perfect for menus, action lists, and contextual options
            across your application.
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
            Here's a simple example to get you started with the Dropdown
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex items-center justify-center">
            <Dropdown>
              <DropdownTrigger>
                <Button
                  icon={<ChevronDown size={16} />}
                  iconPosition="right"
                  className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
                >
                  Menu
                </Button>
              </DropdownTrigger>

              <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                <DropdownItem
                  leftIcon={<User size={16} />}
                  className="hover:bg-dropdown-itemHover"
                >
                  Profile
                </DropdownItem>
                <DropdownItem
                  leftIcon={<Settings size={16} />}
                  className="hover:bg-dropdown-itemHover"
                >
                  Settings
                </DropdownItem>
                <DropdownItem
                  leftIcon={<LogOut size={16} />}
                  className="hover:bg-dropdown-itemHover"
                >
                  Logout
                </DropdownItem>
              </DropdownContent>
            </Dropdown>
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

          {/* Position Examples */}
          <div id="position" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Positioning Options
            </h3>
            <p className="text-text-secondary mb-4">
              Dropdown supports 12 positioning options: top-left, top-center,
              top-right, bottom-left, bottom-center, bottom-right, left-top,
              left-center, left-bottom, right-top, right-center, right-bottom.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
              <div className="grid grid-cols-3 gap-4 mb-6">
                <Dropdown position="top-left">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-purple-600 hover:bg-purple-700 text-white border border-purple-700"
                    >
                      Top Left
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>

                <Dropdown position="top-center">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-purple-600 hover:bg-purple-700 text-white border border-purple-700"
                    >
                      Top Center
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>

                <Dropdown position="top-right">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-purple-600 hover:bg-purple-700 text-white border border-purple-700"
                    >
                      Top Right
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <Dropdown position="bottom-left">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
                    >
                      Bottom Left
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>

                <Dropdown position="bottom-center">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
                    >
                      Bottom Center
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>

                <Dropdown position="bottom-right">
                  <DropdownTrigger>
                    <Button
                      width="full"
                      className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
                    >
                      Bottom Right
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      leftIcon={<Copy size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Copy
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Edit size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Edit
                    </DropdownItem>
                    <DropdownItem
                      leftIcon={<Trash size={16} />}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Delete
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>
              </div>
            </div>

            <CodeBlock
              code={positionExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/PositionExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* With Icons */}
          <div id="icons" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              With Icons
            </h3>
            <p className="text-text-secondary mb-4">
              Add icons to dropdown items for better visual hierarchy and
              recognition.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-4 items-center justify-center flex-wrap">
              <Dropdown>
                <DropdownTrigger>
                  <Button
                    icon={<Share size={16} />}
                    iconPosition="right"
                    className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
                  >
                    Share
                  </Button>
                </DropdownTrigger>

                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<Mail size={16} />}
                    rightIcon={
                      <span className="text-xs text-text-secondary">⌘E</span>
                    }
                    className="hover:bg-dropdown-itemHover"
                  >
                    Email
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<MessageSquare size={16} />}
                    rightIcon={
                      <span className="text-xs text-text-secondary">⌘M</span>
                    }
                    className="hover:bg-dropdown-itemHover"
                  >
                    Message
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Copy size={16} />}
                    rightIcon={
                      <span className="text-xs text-text-secondary">⌘C</span>
                    }
                    className="hover:bg-dropdown-itemHover"
                  >
                    Copy Link
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>

              <Dropdown>
                <DropdownTrigger>
                  <Button
                    icon={<Download size={16} />}
                    iconPosition="right"
                    className="bg-green-600 hover:bg-green-700 text-white border border-green-700"
                  >
                    Export
                  </Button>
                </DropdownTrigger>

                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<File size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Export as PDF
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<File size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Export as CSV
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<File size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Export as JSON
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>
            </div>
          </div>

          {/* Custom Content */}
          <div id="custom" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Custom Content
            </h3>
            <p className="text-text-secondary mb-4">
              Create complex dropdowns with custom headers, footers, dividers,
              and any React content.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-4 items-center justify-center flex-wrap">
              <Dropdown>
                <DropdownTrigger>
                  <Button
                    icon={<User size={16} />}
                    className="bg-gray-600 hover:bg-gray-700 text-white border border-gray-700"
                  />
                </DropdownTrigger>

                <DropdownContent
                  minWidth="250px"
                  className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover"
                >
                  {/* Custom header */}
                  <div className="px-3 py-2 border-b border-border-default">
                    <p className="font-semibold text-sm">John Doe</p>
                    <p className="text-xs text-text-secondary">
                      john@example.com
                    </p>
                  </div>

                  {/* Regular items */}
                  <DropdownItem
                    leftIcon={<User size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Profile
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Settings size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Settings
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Calendar size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Schedule
                  </DropdownItem>

                  {/* Divider */}
                  <div className="border-t border-border-default my-1"></div>

                  {/* Custom footer */}
                  <div className="px-3 py-2">
                    <Button
                      width="full"
                      size={90}
                      className="bg-red-600 hover:bg-red-700 text-white border border-red-700"
                    >
                      Sign Out
                    </Button>
                  </div>
                </DropdownContent>
              </Dropdown>

              <Dropdown>
                <DropdownTrigger>
                  <Button
                    icon={<Folder size={16} />}
                    iconPosition="right"
                    className="bg-orange-600 hover:bg-orange-700 text-white border border-orange-700"
                  >
                    Actions
                  </Button>
                </DropdownTrigger>

                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <div className="px-3 py-2">
                    <p className="text-xs font-semibold text-text-secondary uppercase">
                      File Actions
                    </p>
                  </div>
                  <DropdownItem
                    leftIcon={<Copy size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Duplicate
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Edit size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Rename
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Download size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Download
                  </DropdownItem>

                  <div className="border-t border-border-default my-1"></div>

                  <div className="px-3 py-2">
                    <p className="text-xs font-semibold text-text-secondary uppercase">
                      Danger Zone
                    </p>
                  </div>
                  <DropdownItem
                    leftIcon={<Trash size={16} />}
                    className="text-red-600 hover:bg-red-50"
                  >
                    Delete
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>
            </div>

            <CodeBlock
              code={customContentCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CustomContentExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Size Variants */}
          <div id="size" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control dropdown size with sm, md, and lg variants.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-4 items-center justify-center flex-wrap">
              <Dropdown size="sm">
                <DropdownTrigger>
                  <Button
                    size={80}
                    className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
                  >
                    Small
                  </Button>
                </DropdownTrigger>
                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<User size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Profile
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Settings size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Settings
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<LogOut size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Logout
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>

              <Dropdown size="md">
                <DropdownTrigger>
                  <Button className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700">
                    Medium
                  </Button>
                </DropdownTrigger>
                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<User size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Profile
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Settings size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Settings
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<LogOut size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Logout
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>

              <Dropdown size="lg">
                <DropdownTrigger>
                  <Button
                    size={120}
                    className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
                  >
                    Large
                  </Button>
                </DropdownTrigger>
                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<User size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Profile
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Settings size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Settings
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<LogOut size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Logout
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>
            </div>
          </div>

          {/* Controlled Dropdown */}
          <div id="controlled" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Controlled Dropdown
            </h3>
            <p className="text-text-secondary mb-4">
              Control dropdown open state externally with the open and
              onOpenChange props.
            </p>

            <div className="bg-card-background border border-border-default rounded-md p-8 mb-6">
              <div className="flex gap-4 items-center">
                <Dropdown
                  open={selectedOption === "Option 1"}
                  onOpenChange={(open) => {
                    if (!open) setSelectedOption("");
                  }}
                >
                  <DropdownTrigger>
                    <Button
                      onClick={() =>
                        setSelectedOption(
                          selectedOption === "Option 1" ? "" : "Option 1"
                        )
                      }
                      className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
                    >
                      {selectedOption === "Option 1" ? "✓ " : ""}Option 1
                    </Button>
                  </DropdownTrigger>
                  <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                    <DropdownItem
                      onClick={() => setSelectedOption("Option 1")}
                      className="hover:bg-dropdown-itemHover"
                    >
                      Select Option 1
                    </DropdownItem>
                  </DropdownContent>
                </Dropdown>

                <p className="text-sm text-text-secondary">
                  Selected: {selectedOption || "None"}
                </p>
              </div>
            </div>
          </div>

          {/* Disabled State */}
          <div id="disabled" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Disabled State
            </h3>
            <p className="text-text-secondary mb-4">
              Disable the entire dropdown or individual items.
            </p>

            <div className="bg-card-background border border-border-default rounded-md p-8 mb-6 flex gap-4 items-center justify-center flex-wrap">
              <Dropdown disabled>
                <DropdownTrigger>
                  <Button className="bg-gray-400 text-gray-700 border border-gray-500">
                    Disabled Dropdown
                  </Button>
                </DropdownTrigger>
                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem className="hover:bg-dropdown-itemHover">
                    Item 1
                  </DropdownItem>
                  <DropdownItem className="hover:bg-dropdown-itemHover">
                    Item 2
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>

              <Dropdown>
                <DropdownTrigger>
                  <Button className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700">
                    Disabled Items
                  </Button>
                </DropdownTrigger>
                <DropdownContent className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover">
                  <DropdownItem
                    leftIcon={<Copy size={16} />}
                    className="hover:bg-dropdown-itemHover"
                  >
                    Copy (Enabled)
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Edit size={16} />}
                    disabled
                    className="hover:bg-dropdown-itemHover"
                  >
                    Edit (Disabled)
                  </DropdownItem>
                  <DropdownItem
                    leftIcon={<Trash size={16} />}
                    disabled
                    className="hover:bg-dropdown-itemHover"
                  >
                    Delete (Disabled)
                  </DropdownItem>
                </DropdownContent>
              </Dropdown>
            </div>
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for Dropdown components.
          </p>

          {/* Dropdown Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Dropdown Props
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
                        position
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        DropdownPosition
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        "bottom-left"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        Position of dropdown content
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        size
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        "sm" | "md" | "lg"
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"md"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Size variant
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        closeOnSelect
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">true</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Close when item selected
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
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        open
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Controlled open state
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onOpenChange
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        (open: boolean) =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Open state change callback
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        defaultOpen
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        boolean
                      </td>
                      <td className="px-6 py-4 text-text-secondary">false</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Default open state (uncontrolled)
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* DropdownItem Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              DropdownItem Props
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
                        children
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        ReactNode
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Item content
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        leftIcon
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        ReactNode
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Icon on the left
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        rightIcon
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        ReactNode
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Icon on the right
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
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        onClick
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        () =&gt; void
                      </td>
                      <td className="px-6 py-4 text-text-secondary">-</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Click handler
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* DropdownContent Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              DropdownContent Props
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
                        maxHeight
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"320px"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Maximum height
                      </td>
                    </tr>
                    <tr className="hover:bg-table-rowHoverBg">
                      <td className="px-6 py-4 text-text-primary font-mono text-xs">
                        minWidth
                      </td>
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        string
                      </td>
                      <td className="px-6 py-4 text-text-secondary">"200px"</td>
                      <td className="px-6 py-4 text-text-secondary">
                        Minimum width
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

export default DropdownSection;
