import React, { useState, useEffect } from "react";
import {
  SidebarLayoutProps,
  SidebarLayoutSection,
  SidebarLayoutItem,
} from "./SidebarLayout.types";
import {
  parseSidebarSize,
  getSidebarClasses,
  getContentClasses,
  getCollapseButtonClasses,
  generateSectionClasses,
  generateItemClasses,
} from "./SidebarLayout.utils";
import { cn } from "../../../../../shared/utils/cn";
import {
  ChevronLeft,
  ChevronRight,
  Menu,
  X,
  Home,
  Settings,
  User,
  FileText,
  BarChart,
  Bell,
  HelpCircle,
  LogOut,
  Search,
  Moon,
  Sun,
} from "lucide-react";

const SidebarLayout: React.FC<SidebarLayoutProps> = ({
  children,
  className = "",
  style = {},
  variant = "default",
  size = "md",
  collapsed: controlledCollapsed,
  onCollapse,
  defaultCollapsed = false,
  collapsible = true,
  collapseMode = "icon-only",
  responsive = true,
  breakpoint = "md",
  width = 256,
  collapsedWidth = 64,
  position = "left",
  overlay = false,
  overlayOpacity = 0.5,
  enableBlur = false,
  showCollapseButton = true,
  collapseButtonPosition = "top-right",
  sections = [],
  activeSection,
  onSectionClick,
  activeItem,
  onItemClick,
  logo,
  logoCollapsed,
  footer,
  header,
  sidebarClassName = "",
  contentClassName = "",
  headerClassName = "",
  footerClassName = "",
  showLogo = true,
  showSearch = false,
  searchPlaceholder = "Search...",
  onSearch,
  theme = "auto",
  showThemeToggle = false,
  onThemeToggle,
  showNotifications = false,
  notificationCount = 0,
  onNotificationsClick,
  user,
  onUserClick,
  enableSticky = false,
  stickyOffset = 0,
  animationDuration = 200,
  animationType = "slide",
  shadow = true,
  border = true,
  customSections,
  customHeader,
  customFooter,
  mobileBreakpoint = "md",
  hideOnMobile = false,
  mobileOverlay = true,
  closeOnClickOutside = true,
  zIndex = 40,
  ...props
}) => {
  const [internalCollapsed, setInternalCollapsed] = useState(defaultCollapsed);
  const [isMobile, setIsMobile] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [isOpenMobile, setIsOpenMobile] = useState(false);

  const collapsed =
    controlledCollapsed !== undefined ? controlledCollapsed : internalCollapsed;

  // Handle responsive behavior
  useEffect(() => {
    const checkMobile = () => {
      if (!responsive) return;
      const breakpoints = {
        xs: 0,
        sm: 640,
        md: 768,
        lg: 1024,
        xl: 1280,
        xxl: 1536,
      };
      const breakpointWidth = breakpoints[breakpoint];
      setIsMobile(window.innerWidth < breakpointWidth);
    };

    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, [responsive, breakpoint]);

  // Handle click outside on mobile
  useEffect(() => {
    if (!mobileOverlay || !isMobile || !isOpenMobile || !closeOnClickOutside)
      return;

    const handleClickOutside = (e: MouseEvent) => {
      const sidebar = document.querySelector(".sidebar-layout-container");
      if (sidebar && !sidebar.contains(e.target as Node)) {
        setIsOpenMobile(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isMobile, isOpenMobile, mobileOverlay, closeOnClickOutside]);

  const handleCollapse = () => {
    const newCollapsed = !collapsed;
    if (controlledCollapsed === undefined) {
      setInternalCollapsed(newCollapsed);
    }
    onCollapse?.(newCollapsed);
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchQuery(value);
    onSearch?.(value);
  };

  const handleMobileToggle = () => {
    setIsOpenMobile(!isOpenMobile);
  };

  // Parse width values
  const parsedWidth = parseSidebarSize(width);
  const parsedCollapsedWidth = parseSidebarSize(collapsedWidth);

  // Get CSS classes
  const sidebarClasses = getSidebarClasses({
    variant,
    size,
    collapsed,
    position,
    overlay,
    enableBlur,
    shadow,
    border,
    enableSticky,
    isMobile,
    hideOnMobile,
    mobileOverlay,
  });

  const contentClasses = getContentClasses({
    collapsed,
    position,
    sidebarWidth: parsedWidth,
    collapsedWidth: parsedCollapsedWidth,
    enableSticky,
    stickyOffset,
    isMobile,
    hideOnMobile,
  });

  const collapseButtonClasses = getCollapseButtonClasses({
    collapseButtonPosition,
    variant,
  });

  // Render sections and items
  const renderSection = (section: SidebarLayoutSection) => {
    const sectionClasses = generateSectionClasses({
      variant,
      size,
      collapsed,
    });

    return (
      <div key={section.id} className={sectionClasses}>
        {!collapsed && section.title && (
          <div className="px-4 py-2">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-text-secondary">
              {section.title}
            </h3>
          </div>
        )}
        {collapsed && section.title && (
          <div className="py-2 border-b border-border-default mx-3" />
        )}
        <div className="space-y-1">
          {section.items.map((item) => renderItem(item))}
        </div>
      </div>
    );
  };

  const renderItem = (item: SidebarLayoutItem) => {
    const itemClasses = generateItemClasses({
      variant,
      size,
      collapsed,
      active: activeItem === item.id,
    });

    const Icon = item.icon || Home;

    return (
      <button
        key={item.id}
        onClick={() => onItemClick?.(item.id)}
        className={itemClasses}
        title={collapsed ? item.label : undefined}
      >
        <div className="flex items-center">
          <Icon size={size === "sm" ? 16 : 20} className="flex-shrink-0" />
          {!collapsed && <span className="ml-3 truncate">{item.label}</span>}
        </div>
        {item.badge && !collapsed && (
          <span className="ml-auto px-2 py-0.5 text-xs font-medium bg-primary/10 text-primary rounded-full">
            {item.badge}
          </span>
        )}
        {item.notification && !collapsed && (
          <span className="ml-auto w-2 h-2 bg-red-500 rounded-full" />
        )}
      </button>
    );
  };

  // Default sections if none provided
  const defaultSections: SidebarLayoutSection[] =
    sections.length > 0
      ? sections
      : [
          {
            id: "main",
            title: "Main",
            items: [
              { id: "dashboard", label: "Dashboard", icon: Home },
              { id: "analytics", label: "Analytics", icon: BarChart },
              { id: "documents", label: "Documents", icon: FileText },
              { id: "users", label: "Users", icon: User },
              { id: "settings", label: "Settings", icon: Settings },
            ],
          },
          {
            id: "support",
            title: "Support",
            items: [
              { id: "help", label: "Help Center", icon: HelpCircle },
              {
                id: "notifications",
                label: "Notifications",
                icon: Bell,
                badge: "3",
              },
            ],
          },
        ];

  // Render header
  const renderHeader = () => {
    if (customHeader) return customHeader;

    return (
      <div
        className={cn("p-4 border-b border-border-default", headerClassName)}
      >
        {showLogo && (
          <div className="flex items-center">
            {logo ? (
              <div className="flex items-center space-x-3">
                <div className="flex-shrink-0">
                  {collapsed && logoCollapsed ? logoCollapsed : logo}
                </div>
                {!collapsed && <span className="text-xl font-bold">ZenUI</span>}
              </div>
            ) : (
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
                  <span className="text-white font-bold">Z</span>
                </div>
                {!collapsed && <span className="text-xl font-bold">ZenUI</span>}
              </div>
            )}
          </div>
        )}

        {showSearch && !collapsed && (
          <div className="mt-4 relative">
            <Search
              className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-secondary"
              size={16}
            />
            <input
              type="text"
              placeholder={searchPlaceholder}
              value={searchQuery}
              onChange={handleSearch}
              className="w-full pl-10 pr-4 py-2  border border-border-default rounded-lg text-sm  focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
        )}

        {isMobile && !hideOnMobile && (
          <button
            onClick={handleMobileToggle}
            className="absolute right-4 top-4 p-2 rounded-lg "
          >
            <X size={20} />
          </button>
        )}
      </div>
    );
  };

  // Render footer
  const renderFooter = () => {
    if (customFooter) return customFooter;

    return (
      <div
        className={cn("p-4 border-t border-border-default", footerClassName)}
      >
        {user && !collapsed ? (
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
              {user.avatar ? (
                <img
                  src={user.avatar}
                  alt={user.name}
                  className="w-8 h-8 rounded-full"
                />
              ) : (
                <span className="text-sm font-medium text-primary">
                  {user.name?.charAt(0) || "U"}
                </span>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium  truncate">{user.name}</p>
              <p className="text-xs text-text-secondary truncate">
                {user.email || user.role}
              </p>
            </div>
            <button
              onClick={() => onUserClick?.(user)}
              className="p-1  rounded"
            >
              <LogOut size={16} />
            </button>
          </div>
        ) : user && collapsed ? (
          <div className="flex justify-center">
            <button
              onClick={() => onUserClick?.(user)}
              className="p-2  rounded-full"
              title={user.name}
            >
              {user.avatar ? (
                <img
                  src={user.avatar}
                  alt={user.name}
                  className="w-8 h-8 rounded-full"
                />
              ) : (
                <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <span className="text-sm font-medium text-primary">
                    {user.name?.charAt(0) || "U"}
                  </span>
                </div>
              )}
            </button>
          </div>
        ) : (
          <div className="flex items-center justify-between">
            {showThemeToggle && (
              <button onClick={onThemeToggle} className="p-2 rounded-lg ">
                {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
              </button>
            )}
            {showNotifications && (
              <button
                onClick={onNotificationsClick}
                className="p-2 rounded-lg  relative"
              >
                <Bell size={18} />
                {notificationCount > 0 && (
                  <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                    {notificationCount > 9 ? "9+" : notificationCount}
                  </span>
                )}
              </button>
            )}
          </div>
        )}
      </div>
    );
  };

  // Collapse button
  const renderCollapseButton = () => {
    if (!showCollapseButton || !collapsible) return null;

    const Icon = collapsed
      ? position === "right"
        ? ChevronLeft
        : ChevronRight
      : position === "right"
      ? ChevronRight
      : ChevronLeft;

    return (
      <button
        onClick={handleCollapse}
        className={collapseButtonClasses}
        aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
      >
        <Icon size={16} />
      </button>
    );
  };

  // Mobile overlay
  const renderMobileOverlay = () => {
    if (!isMobile || !mobileOverlay || !isOpenMobile) return null;

    return (
      <div
        className="fixed inset-0 bg-black z-30"
        style={{ opacity: overlayOpacity }}
        onClick={() => setIsOpenMobile(false)}
      />
    );
  };

  // Mobile menu button (outside sidebar)
  const renderMobileMenuButton = () => {
    if (!isMobile || hideOnMobile) return null;

    return (
      <button
        onClick={handleMobileToggle}
        className="fixed top-4 left-4 z-50 p-2 rounded-lg bg-card-background border border-border-default shadow-lg"
      >
        <Menu size={20} />
      </button>
    );
  };

  // Calculate sidebar styles
  const sidebarStyles: React.CSSProperties = {
    width: collapsed ? parsedCollapsedWidth : parsedWidth,
    transition: `width ${animationDuration}ms ease-in-out`,
    zIndex,
    ...style,
  };

  // Calculate content styles
  const contentStyles: React.CSSProperties = {
    marginLeft:
      position === "left" && !isMobile
        ? collapsed
          ? parsedCollapsedWidth
          : parsedWidth
        : 0,
    marginRight:
      position === "right" && !isMobile
        ? collapsed
          ? parsedCollapsedWidth
          : parsedWidth
        : 0,
    transition: `margin ${animationDuration}ms ease-in-out`,
  };

  // Mobile sidebar classes
  const mobileSidebarClasses = cn(
    sidebarClasses,
    "fixed inset-y-0 left-0 transform transition-transform duration-300 ease-in-out z-40",
    isOpenMobile ? "translate-x-0" : "-translate-x-full"
  );

  // Desktop sidebar classes
  const desktopSidebarClasses = cn(sidebarClasses, "h-full");

  return (
    <div className={cn("sidebar-layout-container", className)} {...props}>
      {/* Mobile Menu Button */}
      {renderMobileMenuButton()}

      {/* Mobile Overlay */}
      {renderMobileOverlay()}

      {/* Sidebar */}
      <aside
        className={
          isMobile && !hideOnMobile
            ? mobileSidebarClasses
            : desktopSidebarClasses
        }
        style={sidebarStyles}
      >
        {/* Header */}
        {header || renderHeader()}

        {/* Custom Sections */}
        {customSections ? (
          customSections
        ) : (
          <div className="flex-1 overflow-y-auto py-4">
            {defaultSections.map(renderSection)}
          </div>
        )}

        {/* Footer */}
        {footer || renderFooter()}

        {/* Collapse Button */}
        {!isMobile && renderCollapseButton()}
      </aside>

      {/* Main Content */}
      <main
        className={cn(contentClasses, contentClassName)}
        style={isMobile ? undefined : contentStyles}
      >
        {children}
      </main>
    </div>
  );
};

export default SidebarLayout;
