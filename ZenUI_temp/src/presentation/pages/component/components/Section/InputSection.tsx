import { useState } from "react";
import { Input } from "../../../../components/package/components/input";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Search, X, ChevronDown } from "lucide-react";
import RightPanel from "../RightPanel";
import {
  Combobox,
  ComboboxItem,
} from "../../../../components/package/components/combobox";
import {
  DateTimePicker,
  formatDate,
} from "../../../../components/package/components/datetimepicker";

const InputSection = () => {
  const [searchValue, setSearchValue] = useState("");
  const [emailValue, setEmailValue] = useState("");
  const [passwordValue, setPasswordValue] = useState("");
  const [comboboxOpen, setComboboxOpen] = useState(false);
  const [calendarOpen, setCalendarOpen] = useState(false);
  const [dateTimeValue, setDateTimeValue] = useState<Date | null>(null);
  const [tagInput, setTagInput] = useState("");
  const [tags, setTags] = useState([
    { id: 1, label: "React" },
    { id: 2, label: "TypeScript" },
    { id: 3, label: "Tailwind" },
  ]);
  const [countries, setCountries] = useState([
    { value: "us", label: "United States" },
    { value: "uk", label: "United Kingdom" },
    { value: "ca", label: "Canada" },
    { value: "au", label: "Australia" },
    { value: "de", label: "Germany" },
    { value: "fr", label: "France" },
    { value: "jp", label: "Japan" },
    { value: "kr", label: "South Korea" },
    { value: "vn", label: "Vietnam" },
    { value: "th", label: "Thailand" },
  ]);

  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "combobox", label: "Combobox Input" },
        { id: "calendar", label: "Calendar Input" },
        { id: "password", label: "Password Validation" },
        { id: "multi", label: "Multi-Value Tags" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const npmInstallCode = `npm install @khanhromvn/zenui`;
  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Input } from "@khanhromvn/zenui";
import { Search, Mail } from "lucide-react";

function MyComponent() {
  const [value, setValue] = useState("");

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "400px" }}>
      <Input
        placeholder="Basic input"
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
      
      <Input
        leftIcon={<Search size={16} />}
        placeholder="Search..."
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
      
      <Input
        leftIcon={<Mail size={16} />}
        placeholder="Email address"
        type="email"
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
    </div>
  );
}`;

  const sizeExampleCode = `import { Input } from "@khanhromvn/zenui";

function SizeExample() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "400px" }}>
      <Input
        size={80}
        placeholder="Small (80%)"
      />
      
      <Input
        size={100}
        placeholder="Default (100%)"
      />
      
      <Input
        size={120}
        placeholder="Large (120%)"
      />
    </div>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Input</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A versatile and customizable input component with support for icons,
            validation states, clear buttons, password visibility toggles, and
            multiple variants. Perfect for forms, search interfaces, and data
            entry across your application.
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
            Here's a simple example to get you started with the Input component.
          </p>

          {/* Live Demo */}
          <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-4">
            <Input
              placeholder="Basic input"
              value={emailValue}
              onChange={(e) => setEmailValue(e.target.value)}
              className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
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

          {/* Combobox Type */}
          <div id="combobox" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Combobox Input
            </h3>
            <p className="text-text-secondary mb-4">
              Searchable dropdown with autocomplete functionality. Perfect for
              selecting from large lists of options.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-4">
              <Input
                type="combobox"
                placeholder="Search countries..."
                leftIcon={<Search size={16} />}
                rightIcon={[
                  searchValue && (
                    <X size={16} onClick={() => setSearchValue("")} />
                  ),
                  <ChevronDown size={16} />,
                ].filter(Boolean)}
                value={searchValue}
                popoverOpen={comboboxOpen}
                onChange={(e) => setSearchValue(e.target.value)}
                onPopoverOpenChange={setComboboxOpen}
                className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                popoverContent={
                  <Combobox
                    searchQuery={searchValue}
                    value={searchValue}
                    onChange={(value, option) => {
                      setSearchValue(option.label);
                      setComboboxOpen(false);
                      console.log("Selected:", value);
                    }}
                    onCreate={(newValue) => {
                      const newCountry = {
                        value: newValue.toLowerCase().replace(/\s+/g, "-"),
                        label: newValue,
                      };
                      setCountries([...countries, newCountry]);
                      setSearchValue(newValue);
                      setComboboxOpen(false);
                      console.log("Created:", newCountry);
                    }}
                    searchable
                    creatable
                    creatableMessage='Create country "%s"'
                    className="bg-dropdown-background border border-dropdown-border hover:border-dropdown-borderHover"
                  >
                    {countries.map((country) => (
                      <ComboboxItem
                        key={country.value}
                        value={country.value}
                        label={country.label}
                        className="hover:bg-dropdown-itemHover"
                      />
                    ))}
                  </Combobox>
                }
              />
            </div>
          </div>

          {/* Calendar Type */}
          <div id="calendar" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Calendar Input
            </h3>
            <p className="text-text-secondary mb-4">
              Date and time picker with calendar interface. Supports date-only,
              time-only, and datetime modes.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-4">
              {/* DateTime Picker */}
              <Input
                type="calendar"
                placeholder="Select date and time"
                value={
                  dateTimeValue
                    ? formatDate(dateTimeValue, "MM/dd/yyyy HH:mm")
                    : ""
                }
                popoverOpen={calendarOpen}
                onPopoverOpenChange={setCalendarOpen}
                className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                popoverContent={
                  <DateTimePicker
                    mode="datetime"
                    value={dateTimeValue}
                    onChange={(date) => {
                      setDateTimeValue(date);
                      setCalendarOpen(false);
                    }}
                    showTimePicker={true}
                    className="bg-dropdown-background border border-border-default rounded-md shadow-lg hover:border-border-hover"
                  />
                }
              />
            </div>
          </div>

          {/* Password Type with Validation */}
          <div id="password" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Password Input with Validation
            </h3>
            <p className="text-text-secondary mb-4">
              Password input with inline validation panel showing requirements
              in real-time.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-4">
              <Input
                type="password"
                placeholder="Enter your password"
                value={passwordValue}
                onChange={(e) => setPasswordValue(e.target.value)}
                className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                inlinePanel={
                  <div className="space-y-1.5">
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs ${
                          passwordValue.length >= 8
                            ? "text-green-500"
                            : "text-gray-400"
                        }`}
                      >
                        {passwordValue.length >= 8 ? "✓" : "○"} At least 8
                        characters
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs ${
                          /[A-Z]/.test(passwordValue)
                            ? "text-green-500"
                            : "text-gray-400"
                        }`}
                      >
                        {/[A-Z]/.test(passwordValue) ? "✓" : "○"} One uppercase
                        letter
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs ${
                          /[a-z]/.test(passwordValue)
                            ? "text-green-500"
                            : "text-gray-400"
                        }`}
                      >
                        {/[a-z]/.test(passwordValue) ? "✓" : "○"} One lowercase
                        letter
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs ${
                          /[0-9]/.test(passwordValue)
                            ? "text-green-500"
                            : "text-gray-400"
                        }`}
                      >
                        {/[0-9]/.test(passwordValue) ? "✓" : "○"} One number
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xs ${
                          /[!@#$%^&*]/.test(passwordValue)
                            ? "text-green-500"
                            : "text-gray-400"
                        }`}
                      >
                        {/[!@#$%^&*]/.test(passwordValue) ? "✓" : "○"} One
                        special character (!@#$%^&*)
                      </span>
                    </div>
                  </div>
                }
              />
            </div>
          </div>

          {/* Multi-Value Input */}
          <div id="multi" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Multi-Value Input with Tags
            </h3>
            <p className="text-text-secondary mb-4">
              Input that supports multiple values displayed as badges. Press
              Enter to add tags.
            </p>

            <div className="border-2 border-dashed border-border-default rounded-lg p-8 mb-6 space-y-6">
              <div>
                <label className="block text-sm font-medium text-text-primary mb-2">
                  Tags with Inline Panel
                </label>
                <Input
                  type="text"
                  placeholder="Type and press Enter..."
                  value={tagInput}
                  onChange={(e) => setTagInput(e.target.value)}
                  onKeyDown={(e: { key: string }) => {
                    if (e.key === "Enter" && tagInput.trim()) {
                      setTags([
                        ...tags,
                        { id: Date.now(), label: tagInput.trim() },
                      ]);
                      setTagInput("");
                    }
                  }}
                  multiValue={true}
                  badges={tags}
                  onBadgeRemove={(id) => {
                    setTags(tags.filter((tag) => tag.id !== id));
                  }}
                  badgeColorMode="diverse"
                  className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                  inlinePanel={
                    <div className="text-xs text-text-secondary">
                      💡 Tip: Tags are displayed above when inline panel is
                      present
                    </div>
                  }
                />
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

export default InputSection;
