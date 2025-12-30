import { useState } from "react";
import { Tree, TreeNode } from "../../../../components/package/components/tree";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Folder, File, Settings, User, Database } from "lucide-react";
import RightPanel from "../RightPanel";

const TreeSection = () => {
  const [selectedNode, setSelectedNode] = useState<TreeNode | null>(null);

  // Basic tree data
  const basicData: TreeNode[] = [
    {
      id: "1",
      label: "Root",
      children: [
        {
          id: "1-1",
          label: "Child 1",
          children: [{ id: "1-1-1", label: "Child 1-1" }],
        },
        {
          id: "1-2",
          label: "Child 2",
        },
      ],
    },
  ];

  // File system tree data
  const fileSystemData: TreeNode[] = [
    {
      id: "root",
      label: "Project",
      icon: <Folder size={16} color="var(--text-secondary)" />,
      children: [
        {
          id: "src",
          label: "src",
          icon: <Folder size={16} color="var(--text-secondary)" />,
          children: [
            {
              id: "components",
              label: "components",
              icon: <Folder size={16} color="var(--text-secondary)" />,
              children: [
                {
                  id: "button-tsx",
                  label: "Button.tsx",
                  icon: <File size={16} color="#3b82f6" />,
                },
                {
                  id: "input-tsx",
                  label: "Input.tsx",
                  icon: <File size={16} color="#3b82f6" />,
                },
              ],
            },
            {
              id: "utils",
              label: "utils",
              icon: <Folder size={16} color="var(--text-secondary)" />,
              children: [
                {
                  id: "helpers-ts",
                  label: "helpers.ts",
                  icon: <File size={16} color="#eab308" />,
                },
              ],
            },
          ],
        },
        {
          id: "public",
          label: "public",
          icon: <Folder size={16} color="var(--text-secondary)" />,
          children: [
            {
              id: "index-html",
              label: "index.html",
              icon: <File size={16} color="#f97316" />,
            },
          ],
        },
        {
          id: "package-json",
          label: "package.json",
          icon: <File size={16} color="#22c55e" />,
        },
      ],
    },
  ];

  // Settings tree data
  const settingsData: TreeNode[] = [
    {
      id: "settings",
      label: "Settings",
      icon: <Settings size={16} color="var(--text-secondary)" />,
      children: [
        {
          id: "account",
          label: "Account",
          icon: <User size={16} color="var(--text-secondary)" />,
          children: [
            { id: "profile", label: "Profile" },
            { id: "security", label: "Security" },
          ],
        },
        {
          id: "database",
          label: "Database",
          icon: <Database size={16} color="var(--text-secondary)" />,
          children: [
            { id: "connections", label: "Connections" },
            { id: "backups", label: "Backups" },
          ],
        },
      ],
    },
  ];

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    { id: "examples", label: "Examples" },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Tree, TreeNode } from "@khanhromvn/zenui";

const data: TreeNode[] = [
  {
    id: '1',
    label: 'Root',
    children: [
      {
        id: '1-1',
        label: 'Child 1',
        children: [
          { id: '1-1-1', label: 'Child 1-1' }
        ]
      },
      {
        id: '1-2',
        label: 'Child 2'
      }
    ]
  }
];

function MyComponent() {
  return (
    <Tree
      data={data}
      onNodeClick={(node) => console.log('Clicked:', node)}
    />
  );
}`;

  const fileSystemCode = `import { Tree, TreeNode } from "@khanhromvn/zenui";
import { Folder, File } from "lucide-react";

const fileSystemData: TreeNode[] = [
  {
    id: "root",
    label: "Project",
    icon: <Folder size={16} />,
    children: [
      {
        id: "src",
        label: "src",
        icon: <Folder size={16} />,
        children: [
          {
            id: "components",
            label: "components",
            icon: <Folder size={16} />,
            children: [
              {
                id: "button-tsx",
                label: "Button.tsx",
                icon: <File size={16} color="#3b82f6" />,
              }
            ]
          }
        ]
      }
    ]
  }
];

function FileSystemTree() {
  return (
    <Tree
      data={fileSystemData}
      defaultExpandAll={true}
      onNodeClick={(node) => console.log('Selected file:', node)}
    />
  );
}`;

  const customStyleCode = `import { Tree, TreeNode } from "@khanhromvn/zenui";

const data: TreeNode[] = [
  {
    id: '1',
    label: 'Important Item',
    className: 'font-bold text-primary',
    children: [
      {
        id: '1-1',
        label: 'Regular Item',
      }
    ]
  }
];

function CustomStyledTree() {
  return (
    <Tree
      data={data}
      indentSize={32}
      showLines={true}
      selectable={true}
    />
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Tree</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A hierarchical tree view component for displaying nested data
            structures. Perfect for file systems, organizational charts,
            navigation menus, and any hierarchical data visualization with
            expand/collapse functionality.
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
        <section id="usage" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Basic Usage
          </h2>
          <p className="text-text-secondary mb-6">
            Here's a simple example to get you started with the Tree component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Tree
              data={basicData}
              onNodeClick={(node) => setSelectedNode(node)}
            />
            {selectedNode && (
              <div className="mt-4 p-3 bg-input-background rounded-md">
                <p className="text-sm text-text-secondary">
                  Selected:{" "}
                  <span className="text-text-primary font-medium">
                    {selectedNode.label}
                  </span>
                </p>
              </div>
            )}
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

          {/* File System Tree */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              File System Tree
            </h3>
            <p className="text-text-secondary mb-4">
              Display a file system structure with custom icons for folders and
              files.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <Tree
                data={fileSystemData}
                defaultExpandAll={true}
                onNodeClick={(node) =>
                  console.log("Selected file:", node.label)
                }
              />
            </div>

            <CodeBlock
              code={fileSystemCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/FileSystemTree.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Settings Tree */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Settings Navigation
            </h3>
            <p className="text-text-secondary mb-4">
              Use tree view for hierarchical navigation menus.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <Tree
                data={settingsData}
                defaultExpandedIds={["settings", "account"]}
                onNodeClick={(node) => console.log("Navigate to:", node.label)}
              />
            </div>

            <CodeBlock
              code={`import { Tree, TreeNode } from "@khanhromvn/zenui";
import { Settings, User, Database } from "lucide-react";

const settingsData: TreeNode[] = [
  {
    id: "settings",
    label: "Settings",
    icon: <Settings size={16} />,
    children: [
      {
        id: "account",
        label: "Account",
        icon: <User size={16} />,
        children: [
          { id: "profile", label: "Profile" },
          { id: "security", label: "Security" }
        ]
      }
    ]
  }
];

function SettingsTree() {
  return (
    <Tree
      data={settingsData}
      defaultExpandedIds={["settings", "account"]}
      onNodeClick={(node) => console.log('Navigate to:', node)}
    />
  );
}`}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/SettingsTree.tsx"
              showLineNumbers={true}
            />
          </div>

          {/* Custom Styling */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Custom Styling
            </h3>
            <p className="text-text-secondary mb-4">
              Apply custom className to individual nodes for custom styling.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-4">
              <Tree
                data={[
                  {
                    id: "1",
                    label: "Important Item",
                    className: "font-bold",
                    children: [
                      {
                        id: "1-1",
                        label: "Regular Item",
                      },
                      {
                        id: "1-2",
                        label: "Disabled Item",
                        disabled: true,
                      },
                    ],
                  },
                ]}
                indentSize={32}
              />
            </div>

            <CodeBlock
              code={customStyleCode}
              language="typescript"
              theme="vs-dark"
              readOnly={true}
              filename="src/components/CustomStyledTree.tsx"
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
            Complete list of props available for the Tree component.
          </p>

          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden mb-8">
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
                      data
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      TreeNode[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">required</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Tree data structure
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      onNodeClick
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (node: TreeNode) =&gt; void
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Callback when a node is clicked
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      onNodeToggle
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (id: string, expanded: boolean) =&gt; void
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Callback when a node is expanded/collapsed
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      defaultExpandedIds
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">[]</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Initially expanded node IDs
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      defaultExpandAll
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">false</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Expand all nodes by default
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      showLines
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">true</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Show lines connecting nodes
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      showIcons
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">true</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Show icons for nodes
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
                      Custom CSS class
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      indentSize
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">24</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Indent size in pixels
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      selectable
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">true</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Allow selecting nodes
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      selectedId
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Controlled selected node ID
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <h3 className="text-lg font-semibold text-text-primary mb-3">
            TreeNode Interface
          </h3>
          <p className="text-text-secondary mb-4">
            Structure of each node in the tree data.
          </p>

          <div className="bg-card-background border border-border-default rounded-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-input-background">
                  <tr>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Property
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Type
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Required
                    </th>
                    <th className="px-6 py-4 text-left text-text-primary font-semibold">
                      Description
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-default">
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      id
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">Yes</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Unique identifier for the node
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      label
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string | ReactNode
                    </td>
                    <td className="px-6 py-4 text-text-secondary">Yes</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Label to display for the node
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      children
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      TreeNode[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">No</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Children nodes
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      className
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      string
                    </td>
                    <td className="px-6 py-4 text-text-secondary">No</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom CSS class for this node
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      icon
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      ReactNode
                    </td>
                    <td className="px-6 py-4 text-text-secondary">No</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom icon for this node
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      disabled
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      boolean
                    </td>
                    <td className="px-6 py-4 text-text-secondary">No</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Whether this node is disabled
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      data
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      any
                    </td>
                    <td className="px-6 py-4 text-text-secondary">No</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Additional data attached to the node
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

export default TreeSection;
