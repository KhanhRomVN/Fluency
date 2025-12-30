import {
  Card,
  CardHeader,
  CardBody,
  CardFooter,
} from "../../../../components/package/components/card";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableCell,
  HeaderCell,
} from "../../../../components/package/components/table";
import { CodeBlock } from "../../../../components/package/components/codeblock";
import { FileCode, Star, User } from "lucide-react";
import RightPanel from "../RightPanel";
import React from "react";

const CardSection = () => {
  // Navigation sections for right panel
  const navigationSections = [
    { id: "about", label: "About" },
    { id: "install", label: "Install" },
    {
      id: "examples",
      label: "Examples",
      subSections: [
        { id: "basic", label: "Basic Usage" },
        { id: "alignment", label: "Alignment" },

        { id: "complex", label: "Complex Examples" },
      ],
    },
    { id: "props", label: "Props" },
  ];

  const [animationKey, setAnimationKey] = React.useState(0);

  const handleReloadAnimation = () => {
    setAnimationKey((prev) => prev + 1);
  };

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  const yarnInstallCode = `yarn add @khanhromvn/zenui`;

  const basicUsageCode = `import { Card, CardHeader, CardBody, CardFooter } from "@khanhromvn/zenui";

function MyComponent() {
  return (
    <Card
      className="rounded-md"
      cardAlign={{ horizontal: "center", vertical: "center" }}
      width={0.5}
    >
      <CardHeader>
        <div>
          <h3 className="text-xl font-semibold text-text-primary">
            Basic Card
          </h3>
          <p className="text-sm text-text-secondary mt-1">
            Card with full header and footer
          </p>
        </div>
      </CardHeader>
      
      <CardBody>
        <p className="text-text-secondary">
          Footer section contains action buttons. Footer section
          contains action buttons. Footer section contains action
          buttons. Footer section contains action buttons.
        </p>
      </CardBody>
      
      <CardFooter>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
            Action
          </button>
          <button className="px-4 py-2 bg-button-secondBg hover:bg-button-secondBgHover text-text-primary rounded-lg transition-colors">
            Cancel
          </button>
        </div>
      </CardFooter>
    </Card>
  );
}`;

  const alignmentExampleCode = `import { Card, CardHeader, CardBody } from "@khanhromvn/zenui";

function AlignmentExample() {
  return (
    <div className="space-y-6">
      {/* Card Alignment in Container */}
      <div className="h-96 border-2 border-dashed border-border-default rounded-lg p-4 flex">
        <Card
          cardAlign={{ horizontal: "center", vertical: "center" }}
          width={0.5}
          className="rounded-md"
        >
          <CardBody>
            <div className="text-center">
              <h3 className="text-xl font-semibold text-text-primary mb-2">
                Centered Card
              </h3>
              <p className="text-sm text-text-secondary">
                This card is centered both horizontally and vertically in container.
              </p>
            </div>
          </CardBody>
        </Card>
      </div>
    </div>
  );
}`;

  const loginFormCode = `import { Card, CardHeader, CardBody, CardFooter } from "@khanhromvn/zenui";

function LoginFormExample() {
  return (
    <Card
      className="rounded-md"
      width={0.4}
      cardAlign={{ horizontal: "center", vertical: "center" }}
    >
      <CardHeader>
        <div>
          <h3 className="text-2xl font-semibold text-text-primary">
            Welcome Back
          </h3>
          <p className="text-sm text-text-secondary mt-1">
            Login to your account
          </p>
        </div>
      </CardHeader>
      
      <CardBody>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text-primary mb-1">
              Email
            </label>
            <input
              type="email"
              placeholder="Enter your email"
              className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-text-primary mb-1">
              Password
            </label>
            <input
              type="password"
              placeholder="Enter your password"
              className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
            />
          </div>
        </div>
      </CardBody>
      
      <CardFooter>
        <div className="space-y-3">
          <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors w-full">
            Login
          </button>
          <button className="px-4 py-2 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 rounded-lg transition-colors w-full flex items-center justify-center gap-2">
            <svg width="18" height="18" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Login with Google
          </button>
        </div>
      </CardFooter>
    </Card>
  );
}`;

  const productCardCode = `import { Card, CardBody, CardFooter } from "@khanhromvn/zenui";

function ProductCardExample() {
  return (
    <Card
      className="rounded-md overflow-hidden"
      width={0.35}
      style={{ padding: 0 }}
    >
      <img
        src="https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop"
        alt="Product"
        className="w-full h-48 object-cover"
      />
      <CardBody>
        <div className="space-y-4">
          <div>
            <h3 className="text-xl font-semibold text-text-primary">
              Premium Headphones
            </h3>
            <p className="text-sm text-text-secondary mt-1">
              High-quality wireless headphones with noise cancellation
            </p>
          </div>
          <p className="text-text-secondary">
            Experience crystal-clear audio with our premium wireless headphones featuring active noise cancellation technology.
          </p>
        </div>
      </CardBody>
      <CardFooter>
        <div className="flex justify-end gap-3 pt-2">
          <button className="px-4 py-2 bg-button-secondBg hover:bg-button-secondBgHover text-text-primary rounded-lg transition-colors">
            View Details
          </button>
          <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
            Add to Cart
          </button>
        </div>
      </CardFooter>
    </Card>
  );
}`;

  const featureCardCode = `import { Card, CardBody } from "@khanhromvn/zenui";
import { Star } from "lucide-react";

function FeatureCardExample() {
  return (
    <Card
      className="rounded-md hover:border-button-bg transition-colors"
      width={0.4}
    >
      <CardBody>
        <div className="space-y-3">
          <div className="w-12 h-12 bg-button-bg/10 rounded-lg flex items-center justify-center">
            <Star className="text-button-bg" size={24} />
          </div>
          <h3 className="text-xl font-semibold text-text-primary">
            Lightning Fast
          </h3>
          <p className="text-text-secondary">
            Optimized for performance with instant loading and smooth interactions.
          </p>
        </div>
      </CardBody>
    </Card>
  );
}`;

  const statsCardCode = `import { Card, CardBody, CardFooter } from "@khanhromvn/zenui";
import { User } from "lucide-react";

function StatsCardExample() {
  return (
    <Card
      className="rounded-md"
      width={0.4}
    >
      <CardBody>
        <div className="space-y-4">
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center">
                <User className="text-green-500" size={20} />
              </div>
              <h3 className="text-lg font-semibold text-text-primary pt-2">
                Total Revenue
              </h3>
              <p className="text-sm text-text-secondary">
                Monthly earnings overview
              </p>
            </div>
            <button className="p-2 hover:bg-input-background rounded-lg transition-colors">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" className="text-text-secondary">
                <circle cx="12" cy="12" r="1"/>
                <circle cx="12" cy="5" r="1"/>
                <circle cx="12" cy="19" r="1"/>
              </svg>
            </button>
          </div>
        </div>
      </CardBody>
      <CardFooter>
        <div className="flex items-center justify-between">
          <span className="text-2xl font-bold text-text-primary">
            $12,458
          </span>
          <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
            View Report
          </button>
        </div>
      </CardFooter>
    </Card>
  );
}`;

  return (
    <>
      <div className="max-w-4xl mx-auto">
        {/* ABOUT SECTION */}
        <section id="about" className="mb-12">
          <h1 className="text-4xl font-bold text-text-primary mb-3">Card</h1>
          <p className="text-lg text-text-secondary leading-relaxed">
            A flexible container component for displaying content and actions in
            a clear and organized manner. Perfect for dashboards, product
            displays, content sections, and data presentation with multiple
            variants and extensive customization options.
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
            Here's a simple example to get you started with the Card component.
          </p>

          {/* Live Demo */}
          <div className="mb-6">
            <div className="border-2 border-dashed border-border-default rounded-lg p-6">
              <Card
                className="rounded-md bg-card-background border-border-default"
                cardAlign={{ horizontal: "center", vertical: "center" }}
                width={0.45}
              >
                <CardHeader>
                  <div>
                    <h3 className="text-xl font-semibold text-text-primary">
                      Basic Card
                    </h3>
                    <p className="text-sm text-text-secondary mt-1">
                      Card with full header and footer
                    </p>
                  </div>
                </CardHeader>

                <CardBody>
                  <p className="text-text-secondary">
                    Footer section contains action buttons. Footer section
                    contains action buttons. Footer section contains action
                    buttons. Footer section contains action buttons.
                  </p>
                </CardBody>

                <CardFooter>
                  <div className="flex gap-3">
                    <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
                      Action
                    </button>
                    <button className="px-4 py-2 bg-button-secondBg hover:bg-button-secondBgHover text-text-primary rounded-lg transition-colors">
                      Cancel
                    </button>
                  </div>
                </CardFooter>
              </Card>
            </div>
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
          {/* Alignment */}
          <div id="alignment" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Alignment Options
            </h3>
            <p className="text-text-secondary mb-4">
              Control both card alignment in container and content alignment
              inside the card.
            </p>

            <div className="mb-4 space-y-6">
              <div>
                <h4 className="text-md font-semibold text-text-primary mb-3">
                  Card Alignment in Container
                </h4>
                <div className="h-96 border-2 border-dashed border-border-default rounded-lg p-4 flex">
                  <Card
                    cardAlign={{ horizontal: "center", vertical: "center" }}
                    width={0.5}
                    className="rounded-md bg-card-background border-border-default"
                  >
                    <CardBody>
                      <div className="text-center">
                        <h3 className="text-xl font-semibold text-text-primary mb-2">
                          Centered Card
                        </h3>
                        <p className="text-sm text-text-secondary">
                          This card is centered both horizontally and vertically
                          in container.
                        </p>
                      </div>
                    </CardBody>
                  </Card>
                </div>
              </div>

              <CodeBlock
                code={alignmentExampleCode}
                language="typescript"
                theme="vs-dark"
                readOnly={true}
                filename="src/components/AlignmentExample.tsx"
                showLineNumbers={true}
              />
            </div>
          </div>

          {/* Complex Examples */}
          <div id="complex" className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Complex Examples
            </h3>
            <p className="text-text-secondary mb-4">
              Real-world examples showing various card compositions.
            </p>

            {/* Login Form */}
            <div className="mb-6">
              <h4 className="text-md font-semibold text-text-primary mb-3">
                Login Form Card
              </h4>
              <div className="border-2 border-dashed border-border-default rounded-lg p-6 flex justify-center">
                <Card
                  className="rounded-md bg-card-background border-border-default"
                  width={0.45}
                  cardAlign={{ horizontal: "center", vertical: "center" }}
                >
                  <CardHeader>
                    <div>
                      <h3 className="text-xl font-semibold text-text-primary">
                        Login to your account
                      </h3>
                      <p className="text-sm text-text-secondary mt-1">
                        Enter your email below to login to your account
                      </p>
                    </div>
                  </CardHeader>

                  <CardBody>
                    <div className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-text-primary mb-1">
                          Email
                        </label>
                        <input
                          type="email"
                          placeholder="Enter your email"
                          className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-text-primary mb-1">
                          Password
                        </label>
                        <input
                          type="password"
                          placeholder="Enter your password"
                          className="w-full px-3 py-2 border border-border-default rounded-lg focus:outline-none focus:ring-2 focus:ring-button-bg bg-input-background text-text-primary"
                        />
                      </div>
                    </div>
                  </CardBody>

                  <CardFooter>
                    <div className="space-y-3">
                      <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors w-full">
                        Login
                      </button>
                      <button className="px-4 py-2 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 rounded-lg transition-colors w-full flex items-center justify-center gap-2">
                        <svg width="18" height="18" viewBox="0 0 24 24">
                          <path
                            fill="#4285F4"
                            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                          />
                          <path
                            fill="#34A853"
                            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                          />
                          <path
                            fill="#FBBC05"
                            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                          />
                          <path
                            fill="#EA4335"
                            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                          />
                        </svg>
                        Login with Google
                      </button>
                    </div>
                  </CardFooter>
                </Card>
              </div>

              <CodeBlock
                code={loginFormCode}
                language="typescript"
                theme="vs-dark"
                readOnly={true}
                filename="src/components/LoginFormExample.tsx"
                showLineNumbers={true}
              />
            </div>

            {/* Product Card */}
            <div className="mb-6">
              <h4 className="text-md font-semibold text-text-primary mb-3">
                Product Card
              </h4>
              <div className="border-2 border-dashed border-border-default rounded-lg p-6 flex justify-center">
                <Card
                  className="rounded-md overflow-hidden"
                  width={0.35}
                  style={{ padding: 0 }}
                  cardAlign={{ horizontal: "center", vertical: "center" }}
                >
                  <img
                    src="https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop"
                    alt="Product"
                    className="w-full h-48 object-cover"
                  />
                  <CardBody>
                    <div className="space-y-4">
                      <div>
                        <h3 className="text-xl font-semibold text-text-primary">
                          Premium Headphones
                        </h3>
                        <p className="text-sm text-text-secondary mt-1">
                          High-quality wireless headphones with noise
                          cancellation
                        </p>
                      </div>
                      <p className="text-text-secondary">
                        Experience crystal-clear audio with our premium wireless
                        headphones featuring active noise cancellation
                        technology.
                      </p>
                    </div>
                  </CardBody>
                  <CardFooter>
                    <div className="flex justify-end gap-3 pt-2">
                      <button className="px-4 py-2 bg-button-secondBg hover:bg-button-secondBgHover text-text-primary rounded-lg transition-colors">
                        View Details
                      </button>
                      <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
                        Add to Cart
                      </button>
                    </div>
                  </CardFooter>
                </Card>
              </div>

              <CodeBlock
                code={productCardCode}
                language="typescript"
                theme="vs-dark"
                readOnly={true}
                filename="src/components/ProductCardExample.tsx"
                showLineNumbers={true}
              />
            </div>

            {/* Feature Card */}
            <div className="mb-6">
              <h4 className="text-md font-semibold text-text-primary mb-3">
                Feature Card
              </h4>
              <div className="border-2 border-dashed border-border-default rounded-lg p-6 flex justify-center">
                <Card
                  className="rounded-md hover:border-button-bg transition-colors"
                  width={0.4}
                  cardAlign={{ horizontal: "center", vertical: "center" }}
                >
                  <CardBody>
                    <div className="space-y-3">
                      <div className="w-12 h-12 bg-button-bg/10 rounded-lg flex items-center justify-center">
                        <Star className="text-button-bg" size={24} />
                      </div>
                      <h3 className="text-xl font-semibold text-text-primary">
                        Lightning Fast
                      </h3>
                      <p className="text-text-secondary">
                        Optimized for performance with instant loading and
                        smooth interactions.
                      </p>
                    </div>
                  </CardBody>
                </Card>
              </div>

              <CodeBlock
                code={featureCardCode}
                language="typescript"
                theme="vs-dark"
                readOnly={true}
                filename="src/components/FeatureCardExample.tsx"
                showLineNumbers={true}
              />
            </div>

            {/* Stats Card */}
            <div className="mb-6">
              <h4 className="text-md font-semibold text-text-primary mb-3">
                Stats Card with Actions
              </h4>
              <div className="border-2 border-dashed border-border-default rounded-lg p-6 flex justify-center">
                <Card
                  className="rounded-md"
                  width={0.4}
                  cardAlign={{ horizontal: "center", vertical: "center" }}
                >
                  <CardBody>
                    <div className="space-y-4">
                      <div className="flex items-start justify-between">
                        <div className="space-y-1">
                          <div className="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center">
                            <User className="text-green-500" size={20} />
                          </div>
                          <h3 className="text-lg font-semibold text-text-primary pt-2">
                            Total Revenue
                          </h3>
                          <p className="text-sm text-text-secondary">
                            Monthly earnings overview
                          </p>
                        </div>
                        <button className="p-2 hover:bg-input-background rounded-lg transition-colors">
                          <svg
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            className="text-text-secondary"
                          >
                            <circle cx="12" cy="12" r="1" />
                            <circle cx="12" cy="5" r="1" />
                            <circle cx="12" cy="19" r="1" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </CardBody>
                  <CardFooter>
                    <div className="flex items-center justify-between">
                      <span className="text-2xl font-bold text-text-primary">
                        $12,458
                      </span>
                      <button className="px-4 py-2 bg-button-bg hover:bg-button-bgHover text-button-bgText rounded-lg transition-colors">
                        View Report
                      </button>
                    </div>
                  </CardFooter>
                </Card>
              </div>

              <CodeBlock
                code={statsCardCode}
                language="typescript"
                theme="vs-dark"
                readOnly={true}
                filename="src/components/StatsCardExample.tsx"
                showLineNumbers={true}
              />
            </div>
          </div>
        </section>

        {/* PROPS SECTION */}
        <section id="props" className="mb-12">
          <h2 className="text-2xl font-semibold text-text-primary mb-4">
            Props
          </h2>
          <p className="text-text-secondary mb-6">
            Complete list of props available for Card components.
          </p>

          {/* Card Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              Card Props
            </h3>
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
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        width
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        number
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Card width as fraction (0-1, e.g., 0.5 = 50%)
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        cardAlign
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        {`{ horizontal?: "left" | "center" | "right", vertical?: "top" | "center" | "bottom" }`}
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Card alignment in parent container
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        children
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        ReactNode
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Card body content
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        hoverable
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        boolean
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">false</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Enable hover effects
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        hoverEffectVariant
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        "lift" | "glow" | "border-glow" | "glass" | "tilt" |
                        "scale" | "shadow" | "none"
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Hover effect variant (overrides hoverEffect if set)
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        hoverEffect
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        HoverEffectConfig
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom hover effect configuration (only works when
                        hoverEffectVariant is not set)
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        className
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        string
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">""</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        onClick
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        (e: MouseEvent) =&gt; void
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Click event handler
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* CardHeader Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              CardHeader Props
            </h3>
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
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        children
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        ReactNode
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Header content
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        className
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        string
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">""</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* CardBody Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              CardBody Props
            </h3>
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
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        children
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        ReactNode
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">Body content</span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        className
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        string
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">""</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>

          {/* CardFooter Props */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-text-primary mb-3">
              CardFooter Props
            </h3>
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
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        children
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        ReactNode
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">-</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Footer content
                      </span>
                    </TableCell>
                  </TableRow>
                  <TableRow
                    showHorizontalDivider
                    className="hover:bg-table-hoverItemBodyBg"
                  >
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-primary">
                        className
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="font-mono text-xs text-text-secondary">
                        string
                      </span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">""</span>
                    </TableCell>
                    <TableCell showVerticalDivider>
                      <span className="text-text-secondary">
                        Custom CSS classes
                      </span>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </div>
        </section>
      </div>

      {/* Right Panel Navigation */}
      <RightPanel sections={navigationSections} />
    </>
  );
};

export default CardSection;
