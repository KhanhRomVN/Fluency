import { useState } from "react";
import { Pagination } from "../../../../components/package/components/pagination";
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

const PaginationSection = () => {
  // State for pagination examples
  const [classicPage, setClassicPage] = useState(5);
  const [minimalDotsPage, setMinimalDotsPage] = useState(5);
  const [pillPage, setPillPage] = useState(5);
  const [cardPage, setCardPage] = useState(5);
  const [compactPage, setCompactPage] = useState(5);
  const [dropdownPage, setDropdownPage] = useState(5);
  const [progressPage, setProgressPage] = useState(5);
  const [sliderPage, setSliderPage] = useState(5);

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "variants",
      label: "Variants",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "classic", label: "Classic" },
        { id: "minimal", label: "Minimal Dots" },
        { id: "pill", label: "Pill Group" },
        { id: "card", label: "Card Style" },
        { id: "compact", label: "Compact" },
        { id: "dropdown", label: "Dropdown" },
        { id: "progress", label: "Progress Bar" },
        { id: "slider", label: "Slider" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function BasicPaginationExample() {
  const [currentPage, setCurrentPage] = useState(1);
  const totalItems = 100;
  const itemsPerPage = 10;

  return (
    <Pagination
      totalItems={totalItems}
      itemsPerPage={itemsPerPage}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="classic"
    />
  );
}`;

  const classicCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function ClassicExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="classic"
    />
  );
}`;

  const minimalDotsCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function MinimalDotsExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="minimal-dots"
    />
  );
}`;

  const pillCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function PillExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="pill"
    />
  );
}`;

  const cardCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function CardExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="card"
    />
  );
}`;

  const compactCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function CompactExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="compact"
    />
  );
}`;

  const dropdownCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function DropdownExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="dropdown"
    />
  );
}`;

  const progressCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function ProgressExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="progress"
    />
  );
}`;

  const sliderCode = `import { Pagination } from "@khanhromvn/zenui";
import { useState } from "react";

function SliderExample() {
  const [currentPage, setCurrentPage] = useState(5);

  return (
    <Pagination
      totalItems={100}
      itemsPerPage={10}
      currentPage={currentPage}
      onPageChange={setCurrentPage}
      variant="slider"
    />
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Pagination
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A comprehensive pagination component with 8 distinct UI variants to
            match any design style. From classic outlined buttons to modern
            progress bars and interactive sliders, choose the perfect pagination
            style for your application. Each variant is fully responsive and
            theme-aware.
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
            Here's a simple example to get you started with the Pagination
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Pagination
              totalItems={100}
              itemsPerPage={10}
              currentPage={classicPage}
              onPageChange={setClassicPage}
              variant="classic"
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

        {/* VARIANTS SECTION */}
        <section id="variants" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Pagination Variants
          </h2>
          <p className="text-text-secondary mb-8">
            8 kiểu thiết kế Pagination khác nhau về cấu trúc UI. Mỗi variant có
            phong cách riêng phù hợp với các ngữ cảnh thiết kế khác nhau.
          </p>

          {/* Variant 1: Classic */}
          <div id="classic" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              1. Classic Outlined
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Kiểu cổ điển với border, mỗi số là một button riêng biệt
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 overflow-x-auto">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={classicPage}
                  onPageChange={setClassicPage}
                  variant="classic"
                />
              </div>
            </div>
            <CodeBlock
              code={classicCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ClassicExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 2: Minimal Dots */}
          <div id="minimal" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              2. Minimal Dots
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Thiết kế tối giản với dots, trang active mở rộng thành circle lớn
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={minimalDotsPage}
                  onPageChange={setMinimalDotsPage}
                  variant="minimal-dots"
                />
              </div>
            </div>
            <CodeBlock
              code={minimalDotsCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/MinimalDotsExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 3: Pill Group */}
          <div id="pill" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              3. Pill Group
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Các button được nhóm trong một container hình viên thuốc
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 overflow-x-auto">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={pillPage}
                  onPageChange={setPillPage}
                  variant="pill"
                />
              </div>
            </div>
            <CodeBlock
              code={pillCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/PillExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 4: Card Style */}
          <div id="card" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              4. Card Style
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Dạng thẻ với shadow, mỗi số như một card nhỏ
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4 overflow-x-auto">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={cardPage}
                  onPageChange={setCardPage}
                  variant="card"
                />
              </div>
            </div>
            <CodeBlock
              code={cardCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CardExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 5: Compact Ellipsis */}
          <div id="compact" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              5. Compact with Ellipsis
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Hiển thị rút gọn với dấu "..." khi có nhiều trang, tất cả trong
              một border container
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={compactPage}
                  onPageChange={setCompactPage}
                  variant="compact"
                />
              </div>
            </div>
            <CodeBlock
              code={compactCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CompactExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 6: Dropdown */}
          <div id="dropdown" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              6. Dropdown Style
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Sử dụng dropdown select để chọn trang, kết hợp với nút Trước/Sau
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={dropdownPage}
                  onPageChange={setDropdownPage}
                  variant="dropdown"
                />
              </div>
            </div>
            <CodeBlock
              code={dropdownCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/DropdownExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 7: Progress Bar */}
          <div id="progress" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              7. Progress Bar Style
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Dạng thanh tiến trình hiển thị vị trí hiện tại
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={progressPage}
                  onPageChange={setProgressPage}
                  variant="progress"
                />
              </div>
            </div>
            <CodeBlock
              code={progressCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/ProgressExample.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Variant 8: Slider */}
          <div id="slider" className="mb-12">
            <h3 className="text-xl font-semibold text-text-primary mb-2">
              8. Slider Style
            </h3>
            <p className="text-sm text-text-secondary mb-6">
              Sử dụng range slider để di chuyển giữa các trang
            </p>
            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <div className="flex justify-center">
                <Pagination
                  totalItems={100}
                  itemsPerPage={10}
                  currentPage={sliderPage}
                  onPageChange={setSliderPage}
                  variant="slider"
                />
              </div>
            </div>
            <CodeBlock
              code={sliderCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SliderExample.tsx"
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
            Complete list of props available for the Pagination component.
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
                  <span className="font-mono text-xs">totalItems*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Total number of items to paginate
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">itemsPerPage*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Number of items per page
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">currentPage*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Current active page
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">onPageChange*</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    (page: number) =&gt; void
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  -
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Callback when page changes
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
                    "classic" | "minimal-dots" | "pill" | "card" | "compact" |
                    "dropdown" | "progress" | "slider"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  "classic"
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Pagination variant style
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
                  <span className="font-mono text-xs">"sm" | "md" | "lg"</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  "md"
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Size of pagination elements
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">align</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">
                    "left" | "center" | "right"
                  </span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  "center"
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Horizontal alignment
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">showNavigation</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">boolean</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  true
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Show previous/next buttons
                </TableCell>
              </TableRow>
              <TableRow
                showHorizontalDivider
                className="hover:bg-table-hoverItemBodyBg"
              >
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">maxVisiblePages</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  <span className="font-mono text-xs">number</span>
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  7
                </TableCell>
                <TableCell showVerticalDivider className="bg-table-bodyBg">
                  Maximum visible page numbers (compact variant)
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

export default PaginationSection;
