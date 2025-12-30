import { useState } from "react";
import { Kanban } from "../../../../components/package/layouts/kanban";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, MoreVertical, Clock, User, CheckCircle } from "lucide-react";
import RightPanel from "../RightPanel";

const KanbanLayoutSection = () => {
  const [columns, setColumns] = useState([
    {
      id: "todo",
      title: "To Do",
      items: [
        {
          id: "1",
          content: (
            <div className="space-y-2">
              <div className="flex items-start justify-between">
                <h4 className="font-medium text-gray-900 dark:text-gray-100">
                  Design Homepage
                </h4>
                <MoreVertical size={16} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">
                Create wireframes and mockups
              </p>
              <div className="flex items-center gap-4 pt-2">
                <div className="flex items-center gap-1">
                  <Clock size={14} className="text-gray-400" />
                  <span className="text-xs text-gray-500">2 days</span>
                </div>
                <div className="flex items-center gap-1">
                  <User size={14} className="text-gray-400" />
                  <span className="text-xs text-gray-500">Design Team</span>
                </div>
              </div>
            </div>
          ),
        },
        {
          id: "2",
          content: (
            <div className="space-y-2">
              <div className="flex items-start justify-between">
                <h4 className="font-medium text-gray-900 dark:text-gray-100">
                  Write Documentation
                </h4>
                <MoreVertical size={16} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">API reference and guides</p>
              <div className="flex items-center gap-4 pt-2">
                <div className="flex items-center gap-1">
                  <Clock size={14} className="text-blue-500" />
                  <span className="text-xs text-blue-500">High</span>
                </div>
              </div>
            </div>
          ),
        },
      ],
    },
    {
      id: "inprogress",
      title: "In Progress",
      items: [
        {
          id: "3",
          content: (
            <div className="space-y-2">
              <div className="flex items-start justify-between">
                <h4 className="font-medium text-gray-900 dark:text-gray-100">
                  Implement Authentication
                </h4>
                <MoreVertical size={16} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">JWT tokens and OAuth</p>
              <div className="flex items-center gap-4 pt-2">
                <div className="flex items-center gap-1">
                  <Clock size={14} className="text-yellow-500" />
                  <span className="text-xs text-yellow-500">Due tomorrow</span>
                </div>
                <div className="flex items-center gap-1">
                  <User size={14} className="text-yellow-500" />
                  <span className="text-xs text-yellow-500">You</span>
                </div>
              </div>
            </div>
          ),
        },
      ],
    },
    {
      id: "review",
      title: "Review",
      items: [
        {
          id: "4",
          content: (
            <div className="space-y-2">
              <div className="flex items-start justify-between">
                <h4 className="font-medium text-gray-900 dark:text-gray-100">
                  Code Review
                </h4>
                <MoreVertical size={16} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">PR #42 - Feature branch</p>
              <div className="flex items-center gap-4 pt-2">
                <div className="flex items-center gap-1">
                  <User size={14} className="text-purple-500" />
                  <span className="text-xs text-purple-500">2 reviewers</span>
                </div>
              </div>
            </div>
          ),
        },
      ],
    },
    {
      id: "done",
      title: "Done",
      items: [
        {
          id: "5",
          content: (
            <div className="space-y-2">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2">
                  <CheckCircle size={16} className="text-green-500" />
                  <h4 className="font-medium text-gray-900 dark:text-gray-100">
                    Setup CI/CD Pipeline
                  </h4>
                </div>
                <MoreVertical size={16} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">Github Actions workflow</p>
              <div className="flex items-center gap-4 pt-2">
                <div className="flex items-center gap-1">
                  <Clock size={14} className="text-green-500" />
                  <span className="text-xs text-green-500">Completed</span>
                </div>
              </div>
            </div>
          ),
        },
      ],
    },
  ]);

  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    { id: "examples", label: "Examples" },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Kanban } from "@khanhromvn/zenui";

function MyComponent() {
  const [columns, setColumns] = useState([
    {
      id: "todo",
      title: "To Do",
      items: [
        { id: "1", content: "Task 1" },
        { id: "2", content: "Task 2" },
      ],
    },
    {
      id: "inprogress",
      title: "In Progress",
      items: [
        { id: "3", content: "Task 3" },
      ],
    },
  ]);

  const handleDragEnd = (event) => {
    console.log("Dragged item:", event);
    // Update your state here based on the drag event
  };

  return (
    <Kanban
      columns={columns}
      onDragEnd={handleDragEnd}
    />
  );
}`;

  const customRenderCode = `import { Kanban } from "@khanhromvn/zenui";
import { CheckCircle, Clock } from "lucide-react";

function CustomKanban() {
  const [columns, setColumns] = useState([...]);

  const renderItem = (item) => (
    <div className="p-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-gray-900 rounded-lg shadow border border-blue-100 dark:border-gray-700">
      <div className="flex items-start justify-between">
        <h3 className="font-semibold">{item.content.title}</h3>
        <Clock size={16} className="text-gray-400" />
      </div>
      <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
        {item.content.description}
      </p>
    </div>
  );

  const renderColumnHeader = (column) => (
    <div className="p-3 bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 border-b flex justify-between items-center">
      <div className="flex items-center gap-3">
        <div className="w-2 h-2 rounded-full bg-blue-500"></div>
        <h2 className="font-bold">{column.title}</h2>
        <span className="px-2 py-1 text-xs bg-white dark:bg-gray-900 rounded-full">
          {column.items.length}
        </span>
      </div>
      <button className="p-1 hover:bg-white dark:hover:bg-gray-800 rounded">
        <Plus size={16} />
      </button>
    </div>
  );

  return (
    <Kanban
      columns={columns}
      renderItem={renderItem}
      renderColumnHeader={renderColumnHeader}
    />
  );
}`;

  const handleDragEnd = (event: any) => {
    console.log("Dragged item:", event);
    // Update state with new columns arrangement
    if (event.updatedColumns) {
      setColumns(event.updatedColumns);
    }
  };

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Kanban Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A drag-and-drop Kanban board component for managing tasks and
            workflows. Perfect for project management, task tracking, and
            visualizing work stages with intuitive drag-and-drop interactions.
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
            headerIcon={<FileCode size={16} />}
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
        <section id="usage" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the Kanban
            component.
          </p>

          {/* Live Demo */}
          <div className="bg-card-background border border-border-default rounded-lg p-4 mb-6">
            <Kanban columns={columns} onDragEnd={handleDragEnd} />
          </div>

          {/* Code Example */}
          <CodeBlock
            code={basicUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            headerMode="path"
            headerIcon={<FileCode size={16} />}
            filePath="src/components/BasicExample.tsx"
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
            Complete list of props available for the Kanban component.
          </p>

          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-input-background">
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
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      columns*
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      KanbanColumn[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Array of column definitions
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      onDragEnd
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (event: KanbanDragEndEvent) =&gt; void
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Callback when drag ends
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      renderItem
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (item: KanbanItem) =&gt; ReactNode
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom render function for items
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      renderColumnHeader
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (column: KanbanColumn) =&gt; ReactNode
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom render function for column headers
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      className
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">""</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom CSS classes for the container
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      itemClassName
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">""</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom CSS classes for items
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      columnClassName
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">""</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom CSS classes for columns
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default KanbanLayoutSection;
