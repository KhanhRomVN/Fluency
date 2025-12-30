import { Image, CornerDownRight } from "lucide-react";
import { useState } from "react";
import { Textarea } from "../../../../components/package/components/textarea";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode } from "lucide-react";
import RightPanel from "../RightPanel";
import { Button } from "../../../../components/package/components/button";

const TextareaSection = () => {
  const [text1, setText1] = useState("");
  const [text2, setText2] = useState("");
  const [text3, setText3] = useState("");
  const [text4, setText4] = useState("");

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

  const basicUsageCode = `import { Textarea } from "@khanhromvn/zenui";
import { Button } from "@khanhromvn/zenui";
import { Image, Send } from "lucide-react";
import { useState } from "react";

function MyComponent() {
  const [text, setText] = useState("");

  return (
    <Textarea
      value={text}
      onChange={setText}
      placeholder="Enter your description..."
      minRows={2}
      maxRows={10}
      className="border border-input-border-default bg-input-background hover:border-input-border-hover rounded-t-md border-b-0"
      bottomWrapper={
        <div className="flex items-center justify-between px-3 py-2 border border-input-border-default border-t-0 rounded-b-md bg-input-background">
          <button className="flex items-center gap-2 text-text-secondary hover:text-text-primary transition-colors">
            <Image size={16} />
            <span className="text-sm">Upload image</span>
          </button>
          <Button
            icon={<Send size={16} />}
            className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover"
            size={80}
          />
        </div>
      }
    />
  );
}`;

  const autoResizeCode = `import { Textarea } from "@khanhromvn/zenui";
import { useState } from "react";

function AutoResizeExample() {
  const [text, setText] = useState("");

  return (
    <Textarea
      value={text}
      onChange={setText}
      label="Auto-resize Textarea"
      placeholder="Type to see auto-resize in action..."
      autoResize={true}
      minRows={2}
      maxRows={10}
    />
  );
}`;

  const characterCountCode = `import { Textarea } from "@khanhromvn/zenui";
import { useState } from "react";

function CharacterCountExample() {
  const [text, setText] = useState("");

  return (
    <Textarea
      value={text}
      onChange={setText}
      label="Tweet"
      placeholder="What's happening?"
      maxLength={280}
      showCount={true}
      helperText="Share your thoughts"
    />
  );
}`;

  const validationCode = `import { Textarea } from "@khanhromvn/zenui";
import { useState } from "react";

function ValidationExample() {
  const [text, setText] = useState("");
  const [error, setError] = useState("");

  const handleChange = (value: string) => {
    setText(value);
    if (value.length < 10) {
      setError("Description must be at least 10 characters");
    } else {
      setError("");
    }
  };

  return (
    <Textarea
      value={text}
      onChange={handleChange}
      label="Description"
      placeholder="Enter description..."
      error={error}
      required={true}
    />
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">
            Textarea
          </h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A versatile textarea component with auto-resize, character counting,
            validation, and rich styling options. Perfect for forms, comments,
            descriptions, and any multi-line text input needs.
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
            Here's a simple example to get you started with the Textarea
            component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6">
            <Textarea
              value={text1}
              onChange={setText1}
              placeholder="Enter your description..."
              minRows={2}
              maxRows={10}
              className="border border-input-border-default bg-input-background hover:border-input-border-hover rounded-md"
              bottomWrapper={
                <div className="flex items-center justify-between">
                  <button className="flex items-center gap-2 text-text-secondary hover:text-text-primary transition-colors">
                    <Image size={14} />
                    <span className="text-xs">Upload image</span>
                  </button>
                  <Button
                    icon={<CornerDownRight size={14} />}
                    className="bg-button-bg hover:bg-button-bgHover text-button-bgText border border-button-border hover:border-button-borderHover"
                    size={70}
                  />
                </div>
              }
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
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default TextareaSection;
