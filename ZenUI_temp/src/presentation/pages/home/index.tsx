import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../../components/package/components/button";
import { CodeBlock } from "../../components/package/components/codeblock";
import { Card } from "../../components/package/components/card";
import { Badge } from "../../components/package/components/badge";
import { Avatar } from "../../components/package/components/avatar";
import { Input } from "../../components/package/components/input";
import { Checkbox } from "../../components/package/components/checkbox";
import { Tab, TabItem } from "../../components/package/components/tab";
import {
  ArrowRight,
  Code2,
  Palette,
  Zap,
  Package,
  Home,
  User,
  Settings,
  Search,
  Mail,
  Bell,
} from "lucide-react";
import { PRESET_THEMES, PresetThemeType } from "../../constants/theme-loader";
import { useTheme } from "../../providers/theme-provider";

const HomePage = () => {
  const navigate = useNavigate();
  const { applyPresetTheme } = useTheme();
  const [currentThemeIndex, setCurrentThemeIndex] = useState(0);

  // Lấy tất cả themes từ PRESET_THEMES
  const allThemes: PresetThemeType[] = [
    ...PRESET_THEMES.dark,
    ...PRESET_THEMES.light,
  ];

  // Tự động chuyển theme mỗi 4 giây
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentThemeIndex((prevIndex) => {
        const nextIndex = (prevIndex + 1) % allThemes.length;
        applyPresetTheme(allThemes[nextIndex]);
        return nextIndex;
      });
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  const npmInstallCode = `npm install @khanhromvn/zenui`;

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative overflow-hidden py-20 px-6">
        <div className="max-w-6xl mx-auto text-center">
          {/* Main Slogan */}
          <h1 className="text-6xl md:text-7xl font-bold text-text-primary mb-6 leading-tight">
            Build Beautiful UI
            <br />
            <span className="bg-gradient-to-r from-primary to-blue-600 bg-clip-text text-transparent">
              Effortlessly
            </span>
          </h1>

          {/* Sub Slogan */}
          <p className="text-xl md:text-2xl text-text-secondary max-w-3xl mx-auto mb-10 leading-relaxed">
            A modern, flexible and customizable UI component library for React.
            Built with TypeScript, Tailwind CSS, and Framer Motion for seamless
            integration and beautiful animations.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button
              size={120}
              icon={<ArrowRight size={20} />}
              iconPosition="right"
              onClick={() => navigate("/components")}
              className="bg-primary hover:bg-blue-600 text-white border-0 shadow-lg hover:shadow-xl transition-all"
            >
              Get Started
            </Button>
            <Button
              size={120}
              icon={<Code2 size={20} />}
              onClick={() => navigate("/components")}
              className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-border-default"
            >
              View Components
            </Button>
          </div>

          {/* Theme Indicator */}
          <div className="mt-8 mb-8 flex items-center justify-center gap-2">
            <Palette size={16} className="text-text-secondary" />
            <span className="text-sm text-text-secondary">
              Auto-switching theme: {allThemes[currentThemeIndex].name}
            </span>
          </div>

          {/* Component Mixed Showcase */}
          <Card className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Left Column */}
              <div className="space-y-4">
                {/* Avatars Group */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Team Members
                  </h4>
                  <div className="flex items-center gap-3">
                    <Avatar name="John Doe" size={44} />
                    <Avatar
                      name="Jane Smith"
                      size={44}
                      dotIcon={<Bell size={8} color="#fff" />}
                      dotBgColor="#10B981"
                    />
                    <Avatar icon={<User size={18} color="#fff" />} size={44} />
                    <Badge variant="primary">+5</Badge>
                  </div>
                </div>

                {/* Buttons Group */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Actions
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    <Button
                      icon={<Mail size={16} />}
                      className="bg-primary hover:bg-blue-600 text-white border-0"
                    >
                      Send
                    </Button>
                    <Button
                      icon={<Settings size={16} />}
                      className="bg-button-secondBg hover:bg-button-secondBgHover text-text-primary border border-border-default"
                    >
                      Settings
                    </Button>
                  </div>
                </div>

                {/* Badges */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Status
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="success" dot>
                      Active
                    </Badge>
                    <Badge variant="warning">Pending</Badge>
                    <Badge variant="error" dot>
                      Error
                    </Badge>
                  </div>
                </div>

                {/* Checkbox */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Preferences
                  </h4>
                  <div className="space-y-2">
                    <Checkbox label="Enable notifications" />
                    <Checkbox label="Auto-save changes" />
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div className="space-y-4">
                {/* Input Fields */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Search & Filter
                  </h4>
                  <div className="space-y-2">
                    <Input
                      leftIcon={<Search size={16} />}
                      placeholder="Search components..."
                      className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                    />
                    <Input
                      leftIcon={<Mail size={16} />}
                      placeholder="your@email.com"
                      className="bg-input-background border border-input-border hover:border-input-borderHover focus:border-input-borderFocus"
                    />
                  </div>
                </div>

                {/* Tabs */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Navigation
                  </h4>
                  <Tab
                    width="full"
                    className="bg-tab-background border-b border-tab-border"
                  >
                    <TabItem
                      id="overview"
                      icon={<Home size={16} />}
                      className="border-b-2 border-tab-item-border"
                      hoverClassName="hover:bg-tab-item-hoverBg"
                      activeClassName="border-tab-item-focusBorder text-primary"
                    >
                      Overview
                    </TabItem>
                    <TabItem
                      id="details"
                      icon={<Package size={16} />}
                      className="border-b-2 border-tab-item-border"
                      hoverClassName="hover:bg-tab-item-hoverBg"
                      activeClassName="border-tab-item-focusBorder text-primary"
                    >
                      Details
                    </TabItem>
                  </Tab>
                </div>

                {/* Code Block */}
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary mb-2">
                    Installation
                  </h4>
                  <CodeBlock code={npmInstallCode} language="bash" />
                </div>
              </div>
            </div>
          </Card>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
