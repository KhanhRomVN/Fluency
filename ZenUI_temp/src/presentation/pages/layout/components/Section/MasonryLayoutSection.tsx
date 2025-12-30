import { useState } from "react";
import { Masonry } from "../../../../components/package/layouts/masonry";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Image, Camera, Heart, Share2, Bookmark } from "lucide-react";
import RightPanel from "../RightPanel";

const MasonryLayoutSection = () => {
  const [items] = useState([
    {
      id: "1",
      content: (
        <div>
          <div className="w-full h-48 bg-gradient-to-br from-blue-400 to-cyan-300 rounded-t-lg"></div>
          <div className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-blue-600 dark:text-blue-400">
                PHOTOGRAPHY
              </span>
              <div className="flex items-center gap-1">
                <Heart size={14} className="text-gray-400" />
                <span className="text-xs text-gray-500">42</span>
              </div>
            </div>
            <h3 className="font-bold text-lg text-gray-900 dark:text-gray-100 mb-2">
              Mountain Landscape at Sunset
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Captured during a hike in the Swiss Alps. The golden hour light
              creates a magical atmosphere.
            </p>
            <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-100 dark:border-gray-700">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-full bg-gradient-to-r from-blue-500 to-purple-500"></div>
                <span className="text-sm text-gray-700 dark:text-gray-300">
                  Alex Morgan
                </span>
              </div>
              <span className="text-xs text-gray-500">2 days ago</span>
            </div>
          </div>
        </div>
      ),
    },
    {
      id: "2",
      height: 280,
      content: (
        <div>
          <div className="w-full h-32 bg-gradient-to-br from-green-400 to-emerald-300 rounded-t-lg"></div>
          <div className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-green-600 dark:text-green-400">
                NATURE
              </span>
              <div className="flex items-center gap-1">
                <Bookmark size={14} className="text-gray-400" />
                <span className="text-xs text-gray-500">18</span>
              </div>
            </div>
            <h3 className="font-bold text-lg text-gray-900 dark:text-gray-100 mb-2">
              Forest Path in Autumn
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              A peaceful walk through the forest during autumn. The colorful
              leaves create a beautiful carpet on the ground.
            </p>
            <div className="flex items-center gap-2">
              <Camera size={14} className="text-gray-400" />
              <span className="text-xs text-gray-500">Canon EOS R5</span>
            </div>
          </div>
        </div>
      ),
    },
    {
      id: "3",
      height: 320,
      content: (
        <div>
          <div className="w-full h-64 bg-gradient-to-br from-red-400 to-pink-300 rounded-t-lg"></div>
          <div className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-red-600 dark:text-red-400">
                URBAN
              </span>
              <div className="flex items-center gap-2">
                <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded">
                  <Share2 size={14} className="text-gray-400" />
                </button>
                <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded">
                  <Heart size={14} className="text-gray-400" />
                </button>
              </div>
            </div>
            <h3 className="font-bold text-lg text-gray-900 dark:text-gray-100 mb-2">
              City Skyline at Night
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              Skyscrapers glowing under the night sky. Long exposure shot from
              the observation deck.
            </p>
            <div className="flex flex-wrap gap-2">
              <span className="px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full">
                #nightphotography
              </span>
              <span className="px-2 py-1 text-xs bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 rounded-full">
                #cityscape
              </span>
            </div>
          </div>
        </div>
      ),
    },
    {
      id: "4",
      height: 240,
      content: (
        <div>
          <div className="w-full h-40 bg-gradient-to-br from-yellow-400 to-orange-300 rounded-t-lg"></div>
          <div className="p-4">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-8 h-8 rounded-full bg-gradient-to-r from-yellow-500 to-orange-500 flex items-center justify-center">
                <Image size={16} className="text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 dark:text-gray-100">
                  Desert Adventures
                </h3>
                <p className="text-xs text-gray-500">Travel Photography</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Golden sand dunes stretching to the horizon. The vast emptiness of
              the desert creates a sense of peace and wonder.
            </p>
          </div>
        </div>
      ),
    },
    {
      id: "5",
      height: 360,
      content: (
        <div>
          <div className="w-full h-56 bg-gradient-to-br from-purple-400 to-indigo-300 rounded-t-lg"></div>
          <div className="p-4">
            <h3 className="font-bold text-lg text-gray-900 dark:text-gray-100 mb-3">
              Aurora Borealis in Norway
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              Northern lights dancing in the Arctic sky. This natural phenomenon
              creates breathtaking displays of color and light.
            </p>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Location</span>
                <span className="text-gray-700 dark:text-gray-300">
                  Tromsø, Norway
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Temperature</span>
                <span className="text-gray-700 dark:text-gray-300">-15°C</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Best Time</span>
                <span className="text-gray-700 dark:text-gray-300">
                  September - March
                </span>
              </div>
            </div>
          </div>
        </div>
      ),
    },
    {
      id: "6",
      height: 260,
      content: (
        <div>
          <div className="w-full h-48 bg-gradient-to-br from-gray-400 to-slate-300 rounded-t-lg"></div>
          <div className="p-4">
            <h3 className="font-bold text-lg text-gray-900 dark:text-gray-100 mb-3">
              Winter Wonderland
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              Snow-covered trees and frozen lakes create a magical winter
              landscape perfect for photography.
            </p>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="flex -space-x-2">
                  <div className="w-6 h-6 rounded-full bg-blue-500 border-2 border-white dark:border-gray-800"></div>
                  <div className="w-6 h-6 rounded-full bg-green-500 border-2 border-white dark:border-gray-800"></div>
                  <div className="w-6 h-6 rounded-full bg-purple-500 border-2 border-white dark:border-gray-800"></div>
                </div>
                <span className="text-xs text-gray-500">+3 more</span>
              </div>
              <span className="text-xs text-gray-500">4 hours ago</span>
            </div>
          </div>
        </div>
      ),
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

  const basicUsageCode = `import { Masonry } from "@khanhromvn/zenui";

function MyComponent() {
  const items = [
    {
      id: "1",
      content: (
        <div className="p-4">
          <div className="w-full h-48 bg-blue-200 rounded-lg mb-3"></div>
          <h3 className="font-bold">Card Title</h3>
          <p className="text-gray-600">Card description goes here...</p>
        </div>
      ),
    },
    // ... more items
  ];

  return (
    <Masonry
      items={items}
      columns={3}
      gap={16}
    />
  );
}`;

  const responsiveUsageCode = `import { Masonry } from "@khanhromvn/zenui";

function ResponsiveMasonry() {
  const items = [/* your items */];

  return (
    <Masonry
      items={items}
      columns={4}
      gap={20}
      columnWidth={280}
      breakpoints={{
        xs: 1,  // 1 column on extra small screens
        sm: 2,  // 2 columns on small screens
        md: 3,  // 3 columns on medium screens
        lg: 4,  // 4 columns on large screens
        xl: 5,  // 5 columns on extra large screens
        xxl: 6, // 6 columns on 2xl screens
      }}
    />
  );
}`;

  const customRenderCode = `import { Masonry } from "@khanhromvn/zenui";
import { Heart, Share2 } from "lucide-react";

function CustomMasonry() {
  const items = [/* your items */];

  const renderItem = (item) => (
    <div className="group relative overflow-hidden rounded-xl bg-gradient-to-br from-gray-900 to-black text-white">
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
      <div className="p-6">
        <div className="flex justify-between items-start mb-4">
          <span className="text-xs font-medium text-cyan-400">FEATURED</span>
          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-white/10 rounded-full transition-colors">
              <Heart size={18} />
            </button>
            <button className="p-2 hover:bg-white/10 rounded-full transition-colors">
              <Share2 size={18} />
            </button>
          </div>
        </div>
        <h3 className="text-xl font-bold mb-3">{item.content.title}</h3>
        <p className="text-gray-300 text-sm leading-relaxed">
          {item.content.description}
        </p>
      </div>
    </div>
  );

  return (
    <Masonry
      items={items}
      columns={3}
      gap={24}
      renderItem={renderItem}
      itemClassName="transform transition-transform duration-300 hover:scale-[1.02]"
    />
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Masonry Layout
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A responsive masonry layout component that automatically arranges
            items into optimal columns. Perfect for galleries, card layouts, and
            content with varying heights. Features automatic column calculation
            and responsive breakpoints.
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
            Here's a simple example to get you started with the Masonry
            component.
          </p>

          {/* Live Demo */}
          <div className="bg-card-background border border-border-default rounded-lg p-4 mb-6">
            <Masonry items={items} columns={3} gap={16} />
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

        {/* EXAMPLES SECTION */}
        <section id="examples" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Responsive Example
          </h2>
          <p className="text-text-secondary mb-6">
            The Masonry component automatically adjusts column count based on
            screen size. Resize your browser to see it in action.
          </p>

          {/* Responsive Demo */}
          <div className="bg-card-background border border-border-default rounded-lg p-4 mb-6">
            <Masonry
              items={items}
              columns={4}
              gap={20}
              breakpoints={{
                xs: 1,
                sm: 2,
                md: 3,
                lg: 4,
              }}
            />
          </div>

          {/* Responsive Code Example */}
          <CodeBlock
            code={responsiveUsageCode}
            language="typescript"
            theme="vs-dark"
            readOnly={true}
            headerMode="path"
            headerIcon={<FileCode size={16} />}
            filePath="src/components/ResponsiveMasonry.tsx"
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
            Complete list of props available for the Masonry component.
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
                      items*
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      MasonryItem[]
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Array of items to display in masonry layout
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      columns
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">3</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Number of columns to display (responsive)
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      gap
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">16</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Gap between items in pixels
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      columnWidth
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      number
                    </td>
                    <td className="px-6 py-4 text-text-secondary">300</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Minimum width for each column
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      breakpoints
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      MasonryBreakpoints
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Responsive breakpoints for different screen sizes
                    </td>
                  </tr>
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-text-primary font-mono text-xs">
                      renderItem
                    </td>
                    <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                      (item: MasonryItem) =&gt; ReactNode
                    </td>
                    <td className="px-6 py-4 text-text-secondary">-</td>
                    <td className="px-6 py-4 text-text-secondary">
                      Custom render function for items
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
                      Custom CSS classes for individual items
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

export default MasonryLayoutSection;
