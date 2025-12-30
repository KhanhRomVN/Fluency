import { useState } from "react";
import {
  Table,
  TableHeader,
  TableBody,
  TableFooter,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Edit, Trash2, ChevronUp, ChevronDown } from "lucide-react";
import RightPanel from "../RightPanel";
import { Button } from "../../../../components/package/components/button";
import { Modal } from "../../../../components/package/components/modal";
import { Avatar } from "../../../../components/package/components/avatar";
import { Pagination } from "../../../../components/package/components/pagination";

const TableSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [{ id: "basic", label: "Basic Usage" }],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  // Sample data - 20 fake users
  const sampleData = [
    {
      id: 1,
      name: "John Doe",
      email: "john.doe@example.com",
      age: 28,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=1",
      role: "Senior Developer",
    },
    {
      id: 2,
      name: "Jane Smith",
      email: "jane.smith@example.com",
      age: 32,
      department: "Marketing",
      avatarUrl: "https://i.pravatar.cc/150?img=2",
      role: "Marketing Manager",
    },
    {
      id: 3,
      name: "Bob Johnson",
      email: "bob.johnson@example.com",
      age: 45,
      department: "Sales",
      avatarUrl: "https://i.pravatar.cc/150?img=3",
      role: "Sales Director",
    },
    {
      id: 4,
      name: "Alice Brown",
      email: "alice.brown@example.com",
      age: 29,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=4",
      role: "Frontend Developer",
    },
    {
      id: 5,
      name: "Charlie Wilson",
      email: "charlie.wilson@example.com",
      age: 38,
      department: "HR",
      avatarUrl: "https://i.pravatar.cc/150?img=5",
      role: "HR Specialist",
    },
    {
      id: 6,
      name: "Diana Martinez",
      email: "diana.martinez@example.com",
      age: 26,
      department: "Design",
      avatarUrl: "https://i.pravatar.cc/150?img=6",
      role: "UI/UX Designer",
    },
    {
      id: 7,
      name: "Edward Lee",
      email: "edward.lee@example.com",
      age: 41,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=7",
      role: "DevOps Engineer",
    },
    {
      id: 8,
      name: "Fiona Garcia",
      email: "fiona.garcia@example.com",
      age: 33,
      department: "Marketing",
      avatarUrl: "https://i.pravatar.cc/150?img=8",
      role: "Content Strategist",
    },
    {
      id: 9,
      name: "George Taylor",
      email: "george.taylor@example.com",
      age: 50,
      department: "Sales",
      avatarUrl: "https://i.pravatar.cc/150?img=9",
      role: "Account Executive",
    },
    {
      id: 10,
      name: "Hannah Anderson",
      email: "hannah.anderson@example.com",
      age: 27,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=10",
      role: "Backend Developer",
    },
    {
      id: 11,
      name: "Ian Thomas",
      email: "ian.thomas@example.com",
      age: 35,
      department: "Product",
      avatarUrl: "https://i.pravatar.cc/150?img=11",
      role: "Product Manager",
    },
    {
      id: 12,
      name: "Julia White",
      email: "julia.white@example.com",
      age: 30,
      department: "Design",
      avatarUrl: "https://i.pravatar.cc/150?img=12",
      role: "Graphic Designer",
    },
    {
      id: 13,
      name: "Kevin Harris",
      email: "kevin.harris@example.com",
      age: 42,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=13",
      role: "Tech Lead",
    },
    {
      id: 14,
      name: "Laura Martin",
      email: "laura.martin@example.com",
      age: 31,
      department: "HR",
      avatarUrl: "https://i.pravatar.cc/150?img=14",
      role: "Recruiter",
    },
    {
      id: 15,
      name: "Michael Clark",
      email: "michael.clark@example.com",
      age: 39,
      department: "Sales",
      avatarUrl: "https://i.pravatar.cc/150?img=15",
      role: "Sales Manager",
    },
    {
      id: 16,
      name: "Nancy Rodriguez",
      email: "nancy.rodriguez@example.com",
      age: 28,
      department: "Marketing",
      avatarUrl: "https://i.pravatar.cc/150?img=16",
      role: "Social Media Manager",
    },
    {
      id: 17,
      name: "Oliver Lewis",
      email: "oliver.lewis@example.com",
      age: 36,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=17",
      role: "Full Stack Developer",
    },
    {
      id: 18,
      name: "Patricia Walker",
      email: "patricia.walker@example.com",
      age: 44,
      department: "Product",
      avatarUrl: "https://i.pravatar.cc/150?img=18",
      role: "Product Owner",
    },
    {
      id: 19,
      name: "Quinn Hall",
      email: "quinn.hall@example.com",
      age: 25,
      department: "Design",
      avatarUrl: "https://i.pravatar.cc/150?img=19",
      role: "Motion Designer",
    },
    {
      id: 20,
      name: "Rachel Allen",
      email: "rachel.allen@example.com",
      age: 37,
      department: "Engineering",
      avatarUrl: "https://i.pravatar.cc/150?img=20",
      role: "QA Engineer",
    },
  ];

  // State for pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  // State for sorting
  const [ageSortDirection, setAgeSortDirection] = useState<
    "asc" | "desc" | null
  >(null);
  const [sortedData, setSortedData] = useState(sampleData);

  // State for modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<any>(null);

  // Handle age sort
  const handleAgeSort = () => {
    let newDirection: "asc" | "desc" | null = null;

    if (ageSortDirection === null) {
      newDirection = "asc";
    } else if (ageSortDirection === "asc") {
      newDirection = "desc";
    } else {
      newDirection = null;
    }

    setAgeSortDirection(newDirection);

    if (newDirection === null) {
      setSortedData(sampleData);
    } else {
      const sorted = [...sampleData].sort((a, b) => {
        if (newDirection === "asc") {
          return a.age - b.age;
        } else {
          return b.age - a.age;
        }
      });
      setSortedData(sorted);
    }
  };

  const basicUsageCode = `import { 
  Table, 
  TableHeader, 
  TableBody, 
  TableRow, 
  TableCell,
  HeaderCell
} from "@khanhromvn/zenui";
import { useState } from "react";

function BasicTable() {
  const sampleData = [
    { id: 1, name: "John Doe", email: "john@example.com", age: 28, department: "Engineering" },
    { id: 2, name: "Jane Smith", email: "jane@example.com", age: 32, department: "Marketing" },
    { id: 3, name: "Bob Johnson", email: "bob@example.com", age: 45, department: "Sales" },
  ];

  const [ageSortDirection, setAgeSortDirection] = useState(null);
  const [sortedData, setSortedData] = useState(sampleData);

  const handleAgeSort = () => {
    let newDirection = null;
    
    if (ageSortDirection === null) {
      newDirection = "asc";
    } else if (ageSortDirection === "asc") {
      newDirection = "desc";
    } else {
      newDirection = null;
    }
    
    setAgeSortDirection(newDirection);
    
    if (newDirection === null) {
      setSortedData(sampleData);
    } else {
      const sorted = [...sampleData].sort((a, b) => {
        return newDirection === "asc" ? a.age - b.age : b.age - a.age;
      });
      setSortedData(sorted);
    }
  };

  const handleRowClick = (record, index) => {
    console.log("Clicked:", record, "Index:", index);
  };

  return (
    <div className="border border-table-border rounded-lg overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow className="bg-table-headerBg">
            <HeaderCell showVerticalDivider showHorizontalDivider>Name</HeaderCell>
            <HeaderCell showVerticalDivider showHorizontalDivider>Email</HeaderCell>
            <HeaderCell 
              showVerticalDivider 
              showHorizontalDivider 
              align="center"
              sortable
              sortDirection={ageSortDirection}
              onSort={handleAgeSort}
            >
              Age
            </HeaderCell>
            <HeaderCell showVerticalDivider showHorizontalDivider>Department</HeaderCell>
          </TableRow>
        </TableHeader>
        <TableBody>
          {sortedData.map((item, index) => (
            <TableRow
              key={item.id}
              className="hover:bg-table-hoverItemBodyBg transition-colors cursor-pointer"
              onClick={() => handleRowClick(item, index)}
              showHorizontalDivider
            >
              <TableCell showVerticalDivider>{item.name}</TableCell>
              <TableCell showVerticalDivider>{item.email}</TableCell>
              <TableCell showVerticalDivider align="center">{item.age}</TableCell>
              <TableCell showVerticalDivider>{item.department}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}`;

  const paginationExampleCode = `import { Table } from "@khanhromvn/zenui";
import { useState } from "react";

function PaginatedTable() {
  const [data, setData] = useState([
    { id: 1, name: "John Doe", age: 28, department: "Engineering" },
    { id: 2, name: "Jane Smith", age: 32, department: "Marketing" },
    // ... more data
  ]);

  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 5,
    total: 50, // Total records from server
  });

  const columns = [
    { key: "name", title: "Name", sortable: true },
    { key: "age", title: "Age", sortable: true },
    { key: "department", title: "Department", sortable: true },
  ];

  const handlePageChange = (page, pageSize) => {
    // Fetch new page data from server
    fetchData(page, pageSize);
    setPagination({ ...pagination, current: page });
  };

  return (
    <Table
      data={data}
      columns={columns}
      pagination={pagination}
      onPageChange={handlePageChange}
      variant="striped"
    />
  );
}`;

  const subComponentsExampleCode = `import { 
  Table, 
  TableHeader, 
  TableBody, 
  TableFooter, 
  TableRow, 
  TableCell,
  HeaderCell
} from "@khanhromvn/zenui";

function CustomTable() {
  return (
    <div className="border border-table-border rounded-lg overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow className="bg-table-headerBg">
            <HeaderCell>ID</HeaderCell>
            <HeaderCell>Name</HeaderCell>
            <HeaderCell>Status</HeaderCell>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow className="hover:bg-table-hoverItemBodyBg">
            <TableCell>1</TableCell>
            <TableCell>John Doe</TableCell>
            <TableCell>Active</TableCell>
          </TableRow>
          <TableRow className="hover:bg-table-hoverItemBodyBg">
            <TableCell>2</TableCell>
            <TableCell>Jane Smith</TableCell>
            <TableCell>Inactive</TableCell>
          </TableRow>
        </TableBody>
        <TableFooter>
          <TableRow className="bg-table-footerBg">
            <TableCell colSpan={3} align="center">
              Total: 2 records
            </TableCell>
          </TableRow>
        </TableFooter>
      </Table>
    </div>
  );
}`;

  const columns = [
    {
      key: "name",
      title: "Name",
      sortable: true,
      sorter: (a: any, b: any) => a.name.localeCompare(b.name),
      width: "20%",
    },
    {
      key: "email",
      title: "Email",
      sortable: true,
      sorter: (a: any, b: any) => a.email.localeCompare(b.email),
      width: "25%",
    },
    {
      key: "age",
      title: "Age",
      sortable: true,
      align: "center" as const,
      sorter: (a: any, b: any) => a.age - b.age,
      width: "10%",
    },
    {
      key: "department",
      title: "Department",
      sortable: true,
      sorter: (a: any, b: any) => a.department.localeCompare(b.department),
      width: "15%",
    },
    {
      key: "status",
      title: "Status",
      sortable: true,
      align: "center" as const,
      render: (value: any) => (
        <span
          className={`px-2 py-1 rounded-full text-xs font-medium ${
            value === "Active"
              ? "bg-green-100 text-green-800"
              : "bg-red-100 text-red-800"
          }`}
        >
          {value}
        </span>
      ),
      width: "15%",
    },
    {
      key: "actions",
      title: "Actions",
      align: "center" as const,
      render: (_: any, record: any) => (
        <div className="flex gap-2">
          <Button
            size={80}
            icon={<Edit size={12} />}
            className="bg-blue-600 hover:bg-blue-700 text-white border border-blue-700"
            onClick={(e) => {
              e.stopPropagation();
              console.log("Edit:", record);
            }}
          />
          <Button
            size={80}
            icon={<Trash2 size={12} />}
            className="bg-red-600 hover:bg-red-700 text-white border border-red-700"
            onClick={(e) => {
              e.stopPropagation();
              console.log("Delete:", record);
            }}
          />
        </div>
      ),
      width: "15%",
    },
  ];

  const handlePageChange = (page: number) => {
    console.log("Page changed:", page);
    setCurrentPage(page);
  };

  const handleSort = (sort: any) => {
    console.log("Sort changed:", sort);
  };

  const handleRowClick = (record: any, index: number) => {
    console.log("Row clicked:", record, "Index:", index);
    setSelectedRow(record);
    setIsModalOpen(true);
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Table</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A powerful and flexible table component with built-in sorting,
            pagination, and extensive customization options. Perfect for
            displaying tabular data with rich interactions, customizable
            styling, and responsive design.
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
            Here's a simple example to get you started with the Table component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-4 mb-6">
            <div className="border border-table-border rounded-lg overflow-hidden">
              <div className="max-h-[500px] overflow-y-auto">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-table-headerBg">
                      <HeaderCell showVerticalDivider showHorizontalDivider>
                        Name
                      </HeaderCell>
                      <HeaderCell showVerticalDivider showHorizontalDivider>
                        Email
                      </HeaderCell>
                      <HeaderCell
                        showVerticalDivider
                        showHorizontalDivider
                        align="center"
                        sortable
                        sortDirection={ageSortDirection}
                        onSort={handleAgeSort}
                      >
                        Age
                      </HeaderCell>
                      <HeaderCell showVerticalDivider showHorizontalDivider>
                        Department
                      </HeaderCell>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {sortedData
                      .slice(
                        (currentPage - 1) * itemsPerPage,
                        currentPage * itemsPerPage
                      )
                      .map((item, index) => (
                        <TableRow
                          key={item.id}
                          className="hover:bg-table-hoverItemBodyBg transition-colors cursor-pointer"
                          onClick={() => handleRowClick(item, index)}
                          showHorizontalDivider
                        >
                          <TableCell showVerticalDivider>
                            <div className="flex items-center gap-3">
                              <Avatar
                                src={item.avatarUrl}
                                alt={item.name}
                                size={40}
                                shape="circle"
                              />
                              <div className="flex flex-col">
                                <span className="font-medium text-text-primary">
                                  {item.name}
                                </span>
                                <span className="text-sm text-text-secondary">
                                  {item.role}
                                </span>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell showVerticalDivider>
                            {item.email}
                          </TableCell>
                          <TableCell showVerticalDivider align="center">
                            {item.age}
                          </TableCell>
                          <TableCell showVerticalDivider>
                            {item.department}
                          </TableCell>
                        </TableRow>
                      ))}
                  </TableBody>
                  <TableFooter>
                    <TableRow className="bg-table-footerBg">
                      <TableCell colSpan={4} className="py-2">
                        <Pagination
                          totalItems={sortedData.length}
                          itemsPerPage={itemsPerPage}
                          currentPage={currentPage}
                          onPageChange={handlePageChange}
                          variant="classic"
                          align="left"
                          showNavigation={true}
                          showPageNumbers={true}
                          maxVisiblePages={5}
                          size="sm"
                        />
                      </TableCell>
                    </TableRow>
                  </TableFooter>
                </Table>
              </div>
            </div>
          </div>

          {/* Modal for row details */}
          <Modal
            open={isModalOpen}
            onClose={() => setIsModalOpen(false)}
            title="User Details"
            size="md"
          >
            {selectedRow && (
              <div className="space-y-4">
                <div className="flex items-center gap-4 pb-4 border-b border-border-default">
                  <Avatar
                    src={selectedRow.avatarUrl}
                    alt={selectedRow.name}
                    size={80}
                    shape="circle"
                  />
                  <div>
                    <h3 className="text-xl font-semibold text-text-primary">
                      {selectedRow.name}
                    </h3>
                    <p className="text-text-secondary">{selectedRow.role}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-text-secondary">Email</p>
                    <p className="font-medium text-text-primary">
                      {selectedRow.email}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-text-secondary">Age</p>
                    <p className="font-medium text-text-primary">
                      {selectedRow.age}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-text-secondary">Department</p>
                    <p className="font-medium text-text-primary">
                      {selectedRow.department}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-text-secondary">ID</p>
                    <p className="font-medium text-text-primary">
                      #{selectedRow.id}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </Modal>

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

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for the Table component.
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
                  <TableCell showVerticalDivider>data*</TableCell>
                  <TableCell showVerticalDivider>T[]</TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>
                    Array of data objects
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>columns*</TableCell>
                  <TableCell showVerticalDivider>
                    TableColumn&lt;T&gt;[]
                  </TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>Column definitions</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>size</TableCell>
                  <TableCell showVerticalDivider>"sm" | "md" | "lg"</TableCell>
                  <TableCell showVerticalDivider>"md"</TableCell>
                  <TableCell showVerticalDivider>Table size variant</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>variant</TableCell>
                  <TableCell showVerticalDivider>
                    "default" | "bordered" | "striped"
                  </TableCell>
                  <TableCell showVerticalDivider>"default"</TableCell>
                  <TableCell showVerticalDivider>Table style variant</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>pagination</TableCell>
                  <TableCell showVerticalDivider>TablePagination</TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>
                    Pagination configuration
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>loading</TableCell>
                  <TableCell showVerticalDivider>boolean</TableCell>
                  <TableCell showVerticalDivider>false</TableCell>
                  <TableCell showVerticalDivider>Loading state</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>emptyMessage</TableCell>
                  <TableCell showVerticalDivider>string</TableCell>
                  <TableCell showVerticalDivider>"No data available"</TableCell>
                  <TableCell showVerticalDivider>
                    Message when data is empty
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>onRowClick</TableCell>
                  <TableCell showVerticalDivider>
                    (record: T, index: number) =&gt; void
                  </TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>Row click handler</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>onSort</TableCell>
                  <TableCell showVerticalDivider>
                    (sort: TableSort | null) =&gt; void
                  </TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>Sort change handler</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>onPageChange</TableCell>
                  <TableCell showVerticalDivider>
                    (page: number, pageSize: number) =&gt; void
                  </TableCell>
                  <TableCell showVerticalDivider>-</TableCell>
                  <TableCell showVerticalDivider>Page change handler</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>rowKey</TableCell>
                  <TableCell showVerticalDivider>
                    string | (record: T) =&gt; string
                  </TableCell>
                  <TableCell showVerticalDivider>"id"</TableCell>
                  <TableCell showVerticalDivider>
                    Unique key for each row
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>showHeader</TableCell>
                  <TableCell showVerticalDivider>boolean</TableCell>
                  <TableCell showVerticalDivider>true</TableCell>
                  <TableCell showVerticalDivider>
                    Show/hide table header
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>showFooter</TableCell>
                  <TableCell showVerticalDivider>boolean</TableCell>
                  <TableCell showVerticalDivider>true</TableCell>
                  <TableCell showVerticalDivider>
                    Show/hide table footer
                  </TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>stickyHeader</TableCell>
                  <TableCell showVerticalDivider>boolean</TableCell>
                  <TableCell showVerticalDivider>false</TableCell>
                  <TableCell showVerticalDivider>Make header sticky</TableCell>
                </TableRow>
                <TableRow
                  showHorizontalDivider
                  className="hover:bg-table-hoverItemBodyBg"
                >
                  <TableCell showVerticalDivider>className</TableCell>
                  <TableCell showVerticalDivider>string</TableCell>
                  <TableCell showVerticalDivider>""</TableCell>
                  <TableCell showVerticalDivider>
                    Additional CSS classes
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

export default TableSection;
