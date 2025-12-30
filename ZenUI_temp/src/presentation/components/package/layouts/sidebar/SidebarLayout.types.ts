import { ReactNode, CSSProperties } from "react";
import { LucideIcon } from "lucide-react";

export type SidebarLayoutVariant =
  | "default"
  | "minimal"
  | "floating"
  | "compact"
  | "gradient"
  | "glass";

export type SidebarLayoutSize = "sm" | "md" | "lg" | "xl";

export type SidebarLayoutCollapseMode =
  | "icon-only"
  | "label-only"
  | "both"
  | "auto";

export type SidebarLayoutPosition = "left" | "right";

export type SidebarLayoutBreakpoint = "xs" | "sm" | "md" | "lg" | "xl" | "xxl";

export interface SidebarLayoutItem {
  id: string;
  label: string;
  icon?: LucideIcon | React.ComponentType<any>;
  badge?: string | number;
  notification?: boolean;
  disabled?: boolean;
  href?: string;
  onClick?: () => void;
  children?: SidebarLayoutItem[];
}

export interface SidebarLayoutSection {
  id: string;
  title?: string;
  items: SidebarLayoutItem[];
  collapsed?: boolean;
  collapsible?: boolean;
}

export interface SidebarLayoutUser {
  id: string;
  name: string;
  email?: string;
  avatar?: string;
  role?: string;
}

export interface SidebarLayoutProps {
  // Core props
  children: ReactNode;
  className?: string;
  style?: CSSProperties;

  // Layout configuration
  variant?: SidebarLayoutVariant;
  size?: SidebarLayoutSize;
  collapsed?: boolean;
  onCollapse?: (collapsed: boolean) => void;
  defaultCollapsed?: boolean;
  collapsible?: boolean;
  collapseMode?: SidebarLayoutCollapseMode;

  // Responsive
  responsive?: boolean;
  breakpoint?: SidebarLayoutBreakpoint;
  mobileBreakpoint?: SidebarLayoutBreakpoint;
  hideOnMobile?: boolean;
  mobileOverlay?: boolean;
  closeOnClickOutside?: boolean;

  // Dimensions
  width?: string | number;
  collapsedWidth?: string | number;
  position?: SidebarLayoutPosition;

  // Styling
  overlay?: boolean;
  overlayOpacity?: number;
  enableBlur?: boolean;
  showCollapseButton?: boolean;
  collapseButtonPosition?:
    | "top-right"
    | "top-left"
    | "bottom-right"
    | "bottom-left"
    | "center";
  shadow?: boolean;
  border?: boolean;
  zIndex?: number;

  // Content
  sections?: SidebarLayoutSection[];
  activeSection?: string;
  onSectionClick?: (sectionId: string) => void;
  activeItem?: string;
  onItemClick?: (itemId: string) => void;

  // Branding
  logo?: ReactNode;
  logoCollapsed?: ReactNode;
  showLogo?: boolean;

  // Header
  header?: ReactNode;
  customHeader?: ReactNode;
  headerClassName?: string;

  // Footer
  footer?: ReactNode;
  customFooter?: ReactNode;
  footerClassName?: string;

  // Features
  showSearch?: boolean;
  searchPlaceholder?: string;
  onSearch?: (query: string) => void;

  theme?: "light" | "dark" | "auto";
  showThemeToggle?: boolean;
  onThemeToggle?: () => void;

  showNotifications?: boolean;
  notificationCount?: number;
  onNotificationsClick?: () => void;

  user?: SidebarLayoutUser;
  onUserClick?: (user: SidebarLayoutUser) => void;

  // Customization
  customSections?: ReactNode;
  sidebarClassName?: string;
  contentClassName?: string;

  // Advanced
  enableSticky?: boolean;
  stickyOffset?: number;
  animationDuration?: number;
  animationType?: "slide" | "fade" | "scale";
}
