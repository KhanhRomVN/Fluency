import { useState } from "react";
import { Avatar } from "../../../../components/package/components/avatar";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import {
  FileCode,
  User,
  Settings,
  Check,
  Clock,
  X,
  Phone,
  Mail,
} from "lucide-react";
import RightPanel from "../RightPanel";

const AvatarSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "size-variants", label: "Size Variants" },
        { id: "icon-dot", label: "Icon Dot" },
        { id: "shape-variants", label: "Shape Variants" },
        { id: "fallback", label: "Fallback Options" },
        { id: "icon-avatar", label: "Icon Avatar" },
        { id: "interactive", label: "Interactive" },
        { id: "group", label: "Avatar Group" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Avatar } from "@khanhromvn/zenui";
import { Check, Mail } from "lucide-react";

function MyComponent() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Avatar 
        src="src/presentation/components/package/components/avatar/avatar.jpeg"
        size={40}
      />
      <Avatar 
        name="Jane Smith"
        size={48}
        dotIcon={<Check size={8} color="#fff" />}
        dotBgColor="#10B981"
      />
      <Avatar name="Alice Johnson" fallbackType="initials" size={32} />
      <Avatar icon={<Mail size={20} color="#fff" />} size={40} />
    </div>
  );
}`;

  const sizeExampleCode = `import { Avatar } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Avatar name="Small" size={24} />
      <Avatar name="Default" size={32} />
      <Avatar name="Medium" size={48} />
      <Avatar name="Large" size={64} />
      <Avatar name="XLarge" size={96} />
    </div>
  );
}`;

  const iconExampleCode = `import { Avatar } from "@khanhromvn/zenui";
import { Check, X, Clock, Phone } from "lucide-react";

function IconExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Avatar 
        name="Online User" 
        dotIcon={<Check size={8} color="#fff" />}
        dotBgColor="#10B981"
      />
      <Avatar 
        name="Offline User" 
        dotIcon={<X size={8} color="#fff" />}
        dotBgColor="#6B7280"
      />
      <Avatar 
        name="Away User" 
        dotIcon={<Clock size={8} color="#fff" />}
        dotBgColor="#F59E0B"
      />
      <Avatar 
        name="Busy User" 
        dotIcon={<Phone size={8} color="#fff" />}
        dotBgColor="#EF4444"
      />
      <Avatar name="No Icon" />
    </div>
  );
}`;

  const shapeExampleCode = `import { Avatar } from "@khanhromvn/zenui";

function ShapeExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Avatar name="Circle" shape="circle" />
      <Avatar name="Square" shape="square" />
      <Avatar name="Rounded" shape="rounded" />
    </div>
  );
}`;

  const fallbackExampleCode = `import { Avatar } from "@khanhromvn/zenui";

function FallbackExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      {/* Icon Fallback */}
      <Avatar fallbackType="icon" />
      
      {/* Initials Fallback */}
      <Avatar name="John Doe" fallbackType="initials" />
      <Avatar name="Alice Bob Johnson" fallbackType="initials" />
      <Avatar name="Single" fallbackType="initials" />
      
      {/* Image with error handling */}
      <Avatar 
        src="/invalid-path.jpg"
        name="Error Handler"
        fallbackType="initials"
      />
    </div>
  );
}`;

  const iconAvatarExampleCode = `import { Avatar } from "@khanhromvn/zenui";
import { Mail, Phone, User, Settings } from "lucide-react";

function IconAvatarExample() {
  return (
    <div className="flex gap-4 items-center justify-center flex-wrap">
      <Avatar 
        icon={<Mail size={20} color="#fff" />}
        size={40}
      />
      <Avatar 
        icon={<Phone size={24} color="#fff" />}
        size={48}
        dotIcon={<Check size={8} color="#fff" />}
        dotBgColor="#10B981"
      />
      <Avatar 
        icon={<User size={28} color="#fff" />}
        size={56}
      />
      <Avatar 
        icon={<Settings size={32} color="#fff" />}
        size={64}
      />
    </div>
  );
}`;

  const interactiveExampleCode = `import { Avatar } from "@khanhromvn/zenui";
import { Check } from "lucide-react";

function InteractiveExample() {
  return (
    <div className="flex gap-6 items-center justify-center flex-wrap">
      <Avatar 
        name="Click Me"
        size={64}
        onClick={() => alert("Avatar clicked!")}
        className="cursor-pointer transition-transform hover:scale-110"
      />
      <Avatar
        name="Hover Me"
        dotIcon={<Check size={8} color="#fff" />}
        dotBgColor="#10B981"
        onClick={() => console.log("Avatar clicked")}
        className="cursor-pointer transition-all hover:shadow-lg hover:border-2 hover:border-blue-500"
      />
    </div>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Avatar</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A versatile avatar component for displaying user profiles, with
            support for images, fallback initials, status indicators, and
            multiple shapes. Perfect for user interfaces, chat applications, and
            social features.
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
            Here's a simple example to get you started with the Avatar
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 flex gap-6 items-center justify-center flex-wrap">
            <Avatar
              src="src/presentation/components/package/components/avatar/avatar.jpeg"
              size={40}
            />
            <Avatar
              name="Jane Smith"
              size={48}
              dotIcon={<Check size={8} color="#fff" />}
              dotBgColor="#10B981"
            />
            <Avatar name="Alice Johnson" fallbackType="initials" size={32} />
            <Avatar icon={<Mail size={20} color="#fff" />} size={40} />
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
          <div id="size-variants" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Size Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Control avatar size from 16px to 200px with consistent scaling.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              <Avatar name="Small" size={24} />
              <Avatar name="Default" size={32} />
              <Avatar name="Medium" size={48} />
              <Avatar name="Large" size={64} />
              <Avatar name="XLarge" size={96} />
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

          {/* Icon Dot */}
          <div id="icon-dot" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Icon Dot
            </h3>
            <p className="text-text-secondary mb-4">
              Add custom icons to avatar with customizable background colors.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              <Avatar
                name="Online User"
                dotIcon={<Check size={8} color="#fff" />}
                dotBgColor="#10B981"
              />
              <Avatar
                name="Offline User"
                dotIcon={<X size={8} color="#fff" />}
                dotBgColor="#6B7280"
              />
              <Avatar
                name="Away User"
                dotIcon={<Clock size={8} color="#fff" />}
                dotBgColor="#F59E0B"
              />
              <Avatar
                name="Busy User"
                dotIcon={<Phone size={8} color="#fff" />}
                dotBgColor="#EF4444"
              />
              <Avatar name="No Icon" />
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

          {/* Shape Variants */}
          <div id="shape-variants" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Shape Variants
            </h3>
            <p className="text-text-secondary mb-4">
              Choose from circle, square, or rounded shapes.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              <Avatar name="Circle" shape="circle" />
              <Avatar name="Square" shape="square" />
              <Avatar name="Rounded" shape="rounded" />
            </div>

            <CodeBlock
              code={shapeExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ShapeExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Fallback Types */}
          <div id="fallback" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Fallback Options
            </h3>
            <p className="text-text-secondary mb-4">
              Graceful fallbacks when images fail to load or aren't provided.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              {/* Icon Fallback */}
              <Avatar fallbackType="icon" />

              {/* Initials Fallback */}
              <Avatar name="John Doe" fallbackType="initials" />
              <Avatar name="Alice Bob Johnson" fallbackType="initials" />
              <Avatar name="Single" fallbackType="initials" />

              {/* Image with error handling */}
              <Avatar
                src="/invalid-path.jpg"
                name="Error Handler"
                fallbackType="initials"
              />
            </div>

            <CodeBlock
              code={fallbackExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/FallbackExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Icon Avatar */}
          <div id="icon-avatar" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Icon Avatar
            </h3>
            <p className="text-text-secondary mb-4">
              Use icons directly as avatar content instead of images or
              initials.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              <Avatar icon={<Mail size={20} color="#fff" />} size={40} />
              <Avatar
                icon={<Phone size={24} color="#fff" />}
                size={48}
                dotIcon={<Check size={8} color="#fff" />}
                dotBgColor="#10B981"
              />
              <Avatar icon={<User size={28} color="#fff" />} size={56} />
              <Avatar icon={<Settings size={32} color="#fff" />} size={64} />
            </div>

            <CodeBlock
              code={iconAvatarExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/IconAvatarExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Interactive Avatar */}
          <div id="interactive" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Interactive Avatar
            </h3>
            <p className="text-text-secondary mb-4">
              Make avatars clickable with hover effects and click handlers.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-6 items-center justify-center flex-wrap">
              <Avatar
                name="Click Me"
                size={64}
                onClick={() => alert("Avatar clicked!")}
                className="cursor-pointer transition-transform hover:scale-110"
              />
              <Avatar
                name="Hover Me"
                dotIcon={<Check size={8} color="#fff" />}
                dotBgColor="#10B981"
                onClick={() => console.log("Avatar clicked")}
                className="cursor-pointer transition-all hover:shadow-lg hover:border-2 hover:border-blue-500"
              />
            </div>

            <CodeBlock
              code={interactiveExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/InteractiveExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Group Avatars */}
          <div id="group" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Avatar Group
            </h3>
            <p className="text-text-secondary mb-4">
              Display multiple avatars together with automatic stacking.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex -space-x-3 mb-6">
                <Avatar name="User 1" size={40} />
                <Avatar name="User 2" size={40} />
                <Avatar name="User 3" size={40} />
                <Avatar name="User 4" size={40} />
                <div className="w-10 h-10 rounded-full bg-gray-300 border-2 border-white flex items-center justify-center text-xs font-medium text-gray-600">
                  +2
                </div>
              </div>

              <div className="flex -space-x-4">
                <Avatar
                  name="Team A"
                  size={56}
                  dotIcon={<Check size={10} color="#fff" />}
                  dotBgColor="#10B981"
                />
                <Avatar
                  name="Team B"
                  size={56}
                  dotIcon={<Clock size={10} color="#fff" />}
                  dotBgColor="#F59E0B"
                />
                <Avatar
                  name="Team C"
                  size={56}
                  dotIcon={<Phone size={10} color="#fff" />}
                  dotBgColor="#EF4444"
                />
              </div>
            </div>

            <CodeBlock
              code={`import { Avatar } from "@khanhromvn/zenui";

function GroupExample() {
  return (
    <div className="space-y-6">
      <div className="flex -space-x-3">
        <Avatar name="User 1" size={40} />
        <Avatar name="User 2" size={40} />
        <Avatar name="User 3" size={40} />
        <Avatar name="User 4" size={40} />
        <div className="w-10 h-10 rounded-full bg-gray-300 border-2 border-white flex items-center justify-center text-xs font-medium text-gray-600">
          +2
        </div>
      </div>

      <div className="flex -space-x-4">
        <Avatar
          name="Team A"
          size={56}
          dotIcon={<Check size={10} color="#fff" />}
          dotBgColor="#10B981"
        />
        <Avatar
          name="Team B"
          size={56}
          dotIcon={<Clock size={10} color="#fff" />}
          dotBgColor="#F59E0B"
        />
        <Avatar
          name="Team C"
          size={56}
          dotIcon={<Phone size={10} color="#fff" />}
          dotBgColor="#EF4444"
        />
      </div>
    </div>
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/GroupExample.tsx"
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
            Complete list of props available for the Avatar component.
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
                  <span className="font-mono text-xs">size</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Kích thước avatar (pixel)
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">src</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  URL ảnh
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">alt</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Alt text cho ảnh
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">name</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Tên để tạo initials
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">icon</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">React.ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Icon hiển thị chính ở Avatar (thay thế image/initials)
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">dotIcon</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">React.ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Icon hiển thị trong dot
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">dotBgColor</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Màu nền của dot chứa icon
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">shape</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "circle" | "square" | "rounded"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Hình dạng avatar
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
                  <span className="font-mono text-xs">fallbackType</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">"icon" | "initials"</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Loại fallback khi không có ảnh
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
                  <span className="font-mono text-xs">
                    (event: React.MouseEvent&lt;HTMLDivElement&gt;) =&gt; void
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Click handler
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

export default AvatarSection;
