import { useState } from "react";
import { Modal } from "../../../../components/package/components/modal";
import { Button } from "../../../../components/package/components/button";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { FileCode, Plus, Settings, AlertTriangle } from "lucide-react";
import RightPanel from "../RightPanel";

const ModalSection = () => {
  // State for different modal examples
  const [basicModalOpen, setBasicModalOpen] = useState(false);
  const [sizesModalOpen, setSizesModalOpen] = useState(false);
  const [animatedModalOpen, setAnimatedModalOpen] = useState(false);
  const [customModalOpen, setCustomModalOpen] = useState(false);
  const [fullModalOpen, setFullModalOpen] = useState(false);

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
        { id: "animation", label: "Animations" },
        { id: "custom", label: "Custom Styling" },
        { id: "fullscreen", label: "Full Screen" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Modal, Button } from "@khanhromvn/zenui";
import { useState } from "react";

function BasicModalExample() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsOpen(true)}>
        Open Modal
      </Button>

      <Modal
        open={isOpen}
        onClose={() => setIsOpen(false)}
        title="Basic Modal"
        footer={
          <div className="flex gap-2 justify-end">
            <Button
              onClick={() => setIsOpen(false)}
              className="bg-gray-500 hover:bg-gray-600 text-white"
            >
              Cancel
            </Button>
            <Button
              onClick={() => setIsOpen(false)}
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              Confirm
            </Button>
          </div>
        }
      >
        <p className="text-text-secondary">
          This is a basic modal example with title, content, and footer.
        </p>
      </Modal>
    </div>
  );
}`;

  const sizesExampleCode = `import { Modal, Button } from "@khanhromvn/zenui";

function SizeExamples() {
  const [size, setSize] = useState("md");

  return (
    <div className="flex gap-2 flex-wrap">
      <Button onClick={() => setSize("sm")}>Small</Button>
      <Button onClick={() => setSize("md")}>Medium</Button>
      <Button onClick={() => setSize("lg")}>Large</Button>
      <Button onClick={() => setSize("xl")}>Extra Large</Button>

      <Modal
        open={true}
        onClose={() => setSize(null)}
        title={\`\${size.toUpperCase()} Modal\`}
        size={size}
      >
        <p>This is a {size} sized modal.</p>
      </Modal>
    </div>
  );
}`;

  const animationExampleCode = `import { Modal, Button } from "@khanhromvn/zenui";

function AnimationExamples() {
  const [animation, setAnimation] = useState("fade");

  return (
    <div className="flex gap-2 flex-wrap">
      <Button onClick={() => setAnimation("fade")}>Fade</Button>
      <Button onClick={() => setAnimation("slide")}>Slide</Button>
      <Button onClick={() => setAnimation("scale")}>Scale</Button>

      <Modal
        open={true}
        onClose={() => setAnimation(null)}
        title="Animated Modal"
        animation={animation}
      >
        <p>This modal uses {animation} animation.</p>
      </Modal>
    </div>
  );
}`;

  const customExampleCode = `import { Modal, Button } from "@khanhromvn/zenui";
import { AlertTriangle } from "lucide-react";

function CustomModalExample() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsOpen(true)}>
        Open Custom Modal
      </Button>

      <Modal
        open={isOpen}
        onClose={() => setIsOpen(false)}
        closeOnOverlayClick={false}
        closeOnEsc={true}
        showCloseButton={true}
        position="top"
        overlayClassName="bg-black/70"
        contentClassName="border-2 border-yellow-400"
        overlayStyle={{ backdropFilter: "blur(4px)" }}
      >
        <div className="text-center p-6">
          <AlertTriangle 
            size={48} 
            className="text-yellow-500 mx-auto mb-4" 
          />
          <h3 className="text-lg font-semibold text-text-primary mb-2">
            Custom Styled Modal
          </h3>
          <p className="text-text-secondary">
            This modal has custom styling and is positioned at the top.
          </p>
        </div>
      </Modal>
    </div>
  );
}`;

  const fullScreenExampleCode = `import { Modal, Button } from "@khanhromvn/zenui";

function FullScreenModalExample() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsOpen(true)}>
        Open Full Screen Modal
      </Button>

      <Modal
        open={isOpen}
        onClose={() => setIsOpen(false)}
        size="full"
        title="Full Screen Modal"
        footer={
          <Button onClick={() => setIsOpen(false)}>
            Close
          </Button>
        }
      >
        <div className="p-4">
          <h3 className="text-xl font-bold mb-4">
            Full Screen Content
          </h3>
          <p className="text-text-secondary mb-4">
            This modal takes up the entire screen and is perfect for complex forms,
            detailed views, or immersive experiences.
          </p>
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 border border-border-default rounded-lg">
              <h4 className="font-semibold mb-2">Feature 1</h4>
              <p className="text-sm text-text-secondary">
                Detailed information about feature one.
              </p>
            </div>
            <div className="p-4 border border-border-default rounded-lg">
              <h4 className="font-semibold mb-2">Feature 2</h4>
              <p className="text-sm text-text-secondary">
                Detailed information about feature two.
              </p>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Modal</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible and accessible modal dialog component with support for
            various sizes, animations, positions, and extensive customization
            options. Perfect for displaying important information, forms,
            confirmations, and immersive experiences.
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
            Here's a simple example to get you started with the Modal component.
          </p>
          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Button
              onClick={() => setBasicModalOpen(true)}
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              Open Basic Modal
            </Button>

            <Modal
              open={basicModalOpen}
              onClose={() => setBasicModalOpen(false)}
              title="Basic Modal Example"
              footer={
                <div className="flex gap-2 justify-end">
                  <Button
                    onClick={() => setBasicModalOpen(false)}
                    className="bg-gray-500 hover:bg-gray-600 text-white"
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={() => setBasicModalOpen(false)}
                    className="bg-blue-600 hover:bg-blue-700 text-white"
                  >
                    Confirm
                  </Button>
                </div>
              }
            >
              <div className="space-y-4">
                <p className="text-text-secondary">
                  This is a basic modal example with title, content, and footer
                  actions. You can close this modal by clicking the overlay,
                  pressing ESC, or clicking the close button.
                </p>
                <div className="p-3 bg-gray-100 rounded-lg">
                  <p className="text-sm text-text-secondary">
                    Try interacting with the modal in different ways:
                  </p>
                  <ul className="text-sm text-text-secondary list-disc list-inside mt-2">
                    <li>Click outside the modal to close</li>
                    <li>Press ESC key to close</li>
                    <li>Click the X button in the header</li>
                  </ul>
                </div>
              </div>
            </Modal>
          </div>
          {/* Code Example */}re
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
              Choose from different modal sizes to fit your content needs.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 flex-wrap">
              <Button onClick={() => setSizesModalOpen(true)}>
                Open Size Examples
              </Button>
            </div>

            <Modal
              open={sizesModalOpen}
              onClose={() => setSizesModalOpen(false)}
              title="Modal Size Examples"
              size="lg"
            >
              <div className="space-y-6">
                <p className="text-text-secondary">
                  This modal demonstrates different size options. Try changing
                  the size prop:
                </p>

                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div className="p-3 border border-border-default rounded-lg">
                    <strong>sm</strong> - 400px width
                  </div>
                  <div className="p-3 border border-border-default rounded-lg">
                    <strong>md</strong> - 600px width
                  </div>
                  <div className="p-3 border border-border-default rounded-lg">
                    <strong>lg</strong> - 800px width
                  </div>
                  <div className="p-3 border border-border-default rounded-lg">
                    <strong>xl</strong> - 1000px width
                  </div>
                  <div className="p-3 border border-border-default rounded-lg col-span-2">
                    <strong>full</strong> - Full screen
                  </div>
                </div>
              </div>
            </Modal>

            <CodeBlock
              code={sizesExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SizeExamples.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Animation Variants */}
          <div id="animation" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Animation Effects
            </h3>
            <p className="text-text-secondary mb-4">
              Add smooth animations to your modals for better user experience.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 flex-wrap">
              <Button
                onClick={() => setAnimatedModalOpen(true)}
                className="bg-purple-600 hover:bg-purple-700 text-white"
              >
                Open Animated Modal
              </Button>
            </div>

            <Modal
              open={animatedModalOpen}
              onClose={() => setAnimatedModalOpen(false)}
              title="Animated Modal"
              animation="scale"
              footer={
                <Button onClick={() => setAnimatedModalOpen(false)}>
                  Close
                </Button>
              }
            >
              <div className="text-center p-6">
                <Plus size={48} className="text-purple-500 mx-auto mb-4" />
                <p className="text-text-secondary">
                  This modal uses scale animation. Try different animation
                  types:
                </p>
                <ul className="text-sm text-text-secondary list-disc list-inside mt-2 text-left">
                  <li>
                    <strong>fade</strong> - Simple fade in/out
                  </li>
                  <li>
                    <strong>slide</strong> - Slide from top
                  </li>
                  <li>
                    <strong>scale</strong> - Scale from center
                  </li>
                  <li>
                    <strong>none</strong> - No animation
                  </li>
                </ul>
              </div>
            </Modal>

            <CodeBlock
              code={animationExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/AnimationExamples.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Custom Styling */}
          <div id="custom" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Custom Styling
            </h3>
            <p className="text-text-secondary mb-4">
              Fully customize the appearance and behavior of your modals.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 flex-wrap">
              <Button
                onClick={() => setCustomModalOpen(true)}
                className="bg-yellow-600 hover:bg-yellow-700 text-white"
              >
                Open Custom Modal
              </Button>
            </div>

            <Modal
              open={customModalOpen}
              onClose={() => setCustomModalOpen(false)}
              closeOnOverlayClick={false}
              closeOnEsc={true}
              showCloseButton={true}
              position="top"
              overlayClassName="bg-black/70"
              contentClassName="border-2 border-yellow-400 shadow-2xl"
              overlayStyle={{ backdropFilter: "blur(4px)" }}
            >
              <div className="text-center p-6">
                <AlertTriangle
                  size={48}
                  className="text-yellow-500 mx-auto mb-4"
                />
                <h3 className="text-lg font-semibold text-text-primary mb-2">
                  Custom Styled Modal
                </h3>
                <p className="text-text-secondary mb-4">
                  This modal has custom styling with:
                </p>
                <ul className="text-sm text-text-secondary list-disc list-inside text-left space-y-1">
                  <li>Custom overlay with blur effect</li>
                  <li>Yellow border and shadow</li>
                  <li>Top position</li>
                  <li>Disabled overlay click (use ESC or close button)</li>
                </ul>
              </div>
            </Modal>

            <CodeBlock
              code={customExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CustomExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Full Screen Modal */}
          <div id="fullscreen" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Full Screen Modal
            </h3>
            <p className="text-text-secondary mb-4">
              Use full-screen modals for complex forms or detailed views.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 flex gap-4 flex-wrap">
              <Button
                onClick={() => setFullModalOpen(true)}
                className="bg-green-600 hover:bg-green-700 text-white"
              >
                Open Full Screen Modal
              </Button>
            </div>

            <Modal
              open={fullModalOpen}
              onClose={() => setFullModalOpen(false)}
              size="full"
              title="Full Screen Modal"
              footer={
                <div className="flex gap-2">
                  <Button
                    onClick={() => setFullModalOpen(false)}
                    className="bg-gray-500 hover:bg-gray-600 text-white"
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={() => setFullModalOpen(false)}
                    className="bg-green-600 hover:bg-green-700 text-white"
                  >
                    Save Changes
                  </Button>
                </div>
              }
            >
              <div className="p-6 space-y-6">
                <h3 className="text-2xl font-bold text-text-primary">
                  Full Screen Experience
                </h3>
                <p className="text-text-secondary text-lg">
                  This modal takes up the entire screen and is perfect for:
                </p>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <div className="p-4 border border-border-default rounded-lg bg-card-background">
                    <h4 className="font-semibold text-text-primary mb-2">
                      Complex Forms
                    </h4>
                    <p className="text-sm text-text-secondary">
                      Multi-step forms with lots of input fields and validation.
                    </p>
                  </div>
                  <div className="p-4 border border-border-default rounded-lg bg-card-background">
                    <h4 className="font-semibold text-text-primary mb-2">
                      Detailed Views
                    </h4>
                    <p className="text-sm text-text-secondary">
                      Product details, user profiles, or data visualization.
                    </p>
                  </div>
                  <div className="p-4 border border-border-default rounded-lg bg-card-background">
                    <h4 className="font-semibold text-text-primary mb-2">
                      Immersive Content
                    </h4>
                    <p className="text-sm text-text-secondary">
                      Image galleries, video players, or interactive tutorials.
                    </p>
                  </div>
                </div>

                <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <p className="text-blue-800 text-sm">
                    <strong>Tip:</strong> Full-screen modals work best when you
                    need to focus the user's attention completely on the content
                    without distractions from the background.
                  </p>
                </div>
              </div>
            </Modal>

            <CodeBlock
              code={fullScreenExampleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/FullScreenExample.tsx"
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
            Complete list of props available for the Modal component.
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
                  <span className="font-mono text-xs">open*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Hiển thị modal
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">onClose*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">() = void</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Callback khi đóng modal
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">title</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Tiêu đề modal
                </TableCell>
              </TableRow>
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
                  Nội dung modal
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">footer</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">ReactNode</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Footer content
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
                  <span className="font-mono text-xs">
                    "sm" | "md" | "lg" | "xl" | "full"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Kích thước modal
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">position</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "center" | "top" | "bottom"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Vị trí modal
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
                  <span className="font-mono text-xs">overlayClassName</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom overlay class
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">contentClassName</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom content class
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">closeOnOverlayClick</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Đóng modal khi click overlay
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">showCloseButton</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Hiện nút close
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">closeOnEsc</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Đóng modal bằng ESC
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">animation</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "fade" | "slide" | "scale" | "none"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Animation type
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">style</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">CSSProperties</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom styles
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">overlayStyle</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">CSSProperties</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom overlay styles
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">contentStyle</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">CSSProperties</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Custom content styles
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

export default ModalSection;
