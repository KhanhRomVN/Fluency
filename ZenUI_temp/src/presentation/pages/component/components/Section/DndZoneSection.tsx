import { useState } from "react";
import { DndZone } from "../../../../components/package/components/dndzone";
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

const DndZoneSection = () => {
  const [files1, setFiles1] = useState<File[]>([]);
  const [files2, setFiles2] = useState<File[]>([]);
  const [files3, setFiles3] = useState<File[]>([]);

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "image", label: "Image Upload" },
        { id: "single", label: "Single File" },
        { id: "custom", label: "Custom Config" },
        { id: "disabled", label: "Disabled State" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { DndZone } from "@khanhromvn/zenui";
import { useState } from "react";

function MyComponent() {
  const [files, setFiles] = useState<File[]>([]);

  return (
    <DndZone
      onFilesChange={setFiles}
      placeholder="Drag & drop files here or click to browse"
      showPreview={true}
    />
  );
}`;

  const imageOnlyCode = `import { DndZone } from "@khanhromvn/zenui";
import { useState } from "react";

function ImageUploadExample() {
  const [files, setFiles] = useState<File[]>([]);

  return (
    <DndZone
      onFilesChange={setFiles}
      accept="image/*"
      maxSize={5 * 1024 * 1024} // 5MB
      placeholder="Drop images here (max 5MB)"
      showPreview={true}
    />
  );
}`;

  const singleFileCode = `import { DndZone } from "@khanhromvn/zenui";
import { useState } from "react";

function SingleFileExample() {
  const [files, setFiles] = useState<File[]>([]);

  return (
    <DndZone
      onFilesChange={setFiles}
      multiple={false}
      placeholder="Drop a single file here"
      height="150px"
    />
  );
}`;

  const customConfigCode = `import { DndZone } from "@khanhromvn/zenui";
import { useState } from "react";

function CustomConfigExample() {
  const [files, setFiles] = useState<File[]>([]);

  return (
    <DndZone
      onFilesChange={setFiles}
      accept=".pdf,.doc,.docx"
      maxFiles={3}
      maxSize={10 * 1024 * 1024} // 10MB
      placeholder="Drop documents here (max 3 files)"
      showFileSize={true}
      allowRemove={true}
    />
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Drag & Drop Zone
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A versatile drag-and-drop file upload component with support for
            file validation, preview generation, size limits, and multiple file
            handling. Perfect for file uploads, image galleries, and document
            management systems.
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
            Here's a simple example to get you started with the DndZone
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <DndZone
              onFilesChange={setFiles1}
              placeholder="Drag & drop files here or click to browse"
              showPreview={true}
            />
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

          {/* Image Only */}
          <div id="image" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Image Upload Only
            </h3>
            <p className="text-text-secondary mb-4">
              Restrict file types to images only with size validation and
              preview.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <DndZone
                onFilesChange={setFiles2}
                accept="image/*"
                maxSize={5 * 1024 * 1024} // 5MB
                placeholder="Drop images here (max 5MB)"
                showPreview={true}
              />
            </div>

            <CodeBlock
              code={imageOnlyCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ImageUploadExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Single File */}
          <div id="single" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Single File Upload
            </h3>
            <p className="text-text-secondary mb-4">
              Allow only one file to be uploaded at a time.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <DndZone
                onFilesChange={setFiles3}
                multiple={false}
                placeholder="Drop a single file here"
                height="150px"
              />
            </div>

            <CodeBlock
              code={singleFileCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SingleFileExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Custom Configuration */}
          <div id="custom" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Custom Configuration
            </h3>
            <p className="text-text-secondary mb-4">
              Configure file type restrictions, maximum files, and size limits.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <DndZone
                onFilesChange={(files) => console.log("Files:", files)}
                accept=".pdf,.doc,.docx"
                maxFiles={3}
                maxSize={10 * 1024 * 1024} // 10MB
                placeholder="Drop documents here (max 3 files)"
                showFileSize={true}
                allowRemove={true}
              />
            </div>

            <CodeBlock
              code={customConfigCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CustomConfigExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Disabled State */}
          <div id="disabled" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Disabled State
            </h3>
            <p className="text-text-secondary mb-4">
              Disable the drop zone to prevent file uploads.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <DndZone
                disabled={true}
                placeholder="Upload disabled"
                height="150px"
              />
            </div>

            <CodeBlock
              code={`import { DndZone } from "@khanhromvn/zenui";

function DisabledExample() {
  return (
    <DndZone
      disabled={true}
      placeholder="Upload disabled"
      height="150px"
    />
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/DisabledExample.tsx"
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
            Complete list of props available for the DndZone component.
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
                  <span className="font-mono text-xs">onFilesChange*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    (files: File[]) =&gt; void
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Callback khi files được chọn
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">accept</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Loại file chấp nhận
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">multiple</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Cho phép nhiều files
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">maxSize</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Kích thước file tối đa (bytes)
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">maxFiles</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Số lượng file tối đa
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
                  <span className="font-mono text-xs">height</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Chiều cao drop zone
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">showPreview</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Hiện preview cho ảnh
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">placeholder</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">string</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Text placeholder
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">showFileSize</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Hiện kích thước file
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">allowRemove</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Cho phép xóa file
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

export default DndZoneSection;
