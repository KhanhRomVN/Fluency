import {
  SidebarLayoutVariant,
  SidebarLayoutSize,
  SidebarLayoutPosition,
  SidebarLayoutBreakpoint,
} from "./SidebarLayout.types";

export const parseSidebarSize = (size: string | number): string => {
  if (typeof size === "number") return `${size}px`;
  if (
    size.includes("px") ||
    size.includes("%") ||
    size.includes("rem") ||
    size.includes("em")
  ) {
    return size;
  }
  return `${size}px`;
};

export const getSidebarClasses = (params: {
  variant: SidebarLayoutVariant;
  size: SidebarLayoutSize;
  collapsed: boolean;
  position: SidebarLayoutPosition;
  overlay: boolean;
  enableBlur: boolean;
  shadow: boolean;
  border: boolean;
  enableSticky: boolean;
  isMobile: boolean;
  hideOnMobile: boolean;
  mobileOverlay: boolean;
}): string => {
  const classes: string[] = [
    "sidebar-layout",
    "flex",
    "flex-col",
    "bg-sidebar-background",
    "transition-all",
    "duration-200",
  ];

  // Variant classes
  switch (params.variant) {
    case "minimal":
      classes.push("border-r");
      break;
    case "floating":
      classes.push("rounded-r-xl", "m-2", "shadow-xl");
      break;
    case "compact":
      classes.push("py-2");
      break;
    case "gradient":
      classes.push(
        "bg-gradient-to-b from-sidebar-background to-card-background"
      );
      break;
    case "glass":
      classes.push(
        "bg-sidebar-background/80",
        "backdrop-blur-lg",
        "backdrop-saturate-150"
      );
      break;
    default:
      classes.push("border-r");
  }

  // Size classes
  const sizeClasses = {
    sm: "text-sm",
    md: "text-base",
    lg: "text-lg",
    xl: "text-xl",
  };
  classes.push(sizeClasses[params.size]);

  // Position
  if (params.position === "right") {
    classes.push("border-l", "border-r-0");
  }

  // Shadow
  if (params.shadow) {
    classes.push("shadow-lg");
  }

  // Blur
  if (params.enableBlur) {
    classes.push("backdrop-blur-sm");
  }

  // Sticky
  if (params.enableSticky && !params.isMobile) {
    classes.push("sticky", "top-0", "h-screen");
  }

  // Mobile
  if (params.isMobile && params.mobileOverlay && !params.hideOnMobile) {
    classes.push("shadow-2xl");
  }

  return classes.join(" ");
};

export const getContentClasses = (params: {
  collapsed: boolean;
  position: SidebarLayoutPosition;
  sidebarWidth: string;
  collapsedWidth: string;
  enableSticky: boolean;
  stickyOffset: number;
  isMobile: boolean;
  hideOnMobile: boolean;
}): string => {
  const classes: string[] = [
    "content-area",
    "flex-1",
    "min-h-screen",
    "transition-all",
    "duration-200",
  ];

  if (params.enableSticky && !params.isMobile) {
    classes.push("relative");
  }

  if (params.isMobile && params.hideOnMobile) {
    classes.push("w-full");
  }

  return classes.join(" ");
};

export const getCollapseButtonClasses = (params: {
  collapseButtonPosition: string;
  variant: SidebarLayoutVariant;
}): string => {
  const classes: string[] = [
    "collapse-button",
    "absolute",
    "p-2",
    "rounded-full",
    "border",
    "shadow-md",
    "hover:shadow-lg",
    "transition-all",
    "duration-200",
    "z-10",
    "focus:outline-none",
    "focus:ring-2",
  ];

  // Position classes
  switch (params.collapseButtonPosition) {
    case "top-right":
      classes.push("top-4", "-right-3");
      break;
    case "top-left":
      classes.push("top-4", "-left-3");
      break;
    case "bottom-right":
      classes.push("bottom-4", "-right-3");
      break;
    case "bottom-left":
      classes.push("bottom-4", "-left-3");
      break;
    case "center":
      classes.push("top-1/2", "-right-3", "transform", "-translate-y-1/2");
      break;
  }

  // Variant specific
  if (params.variant === "glass") {
    classes.push("bg-white/20", "backdrop-blur-sm");
  }

  return classes.join(" ");
};

export const generateSectionClasses = (params: {
  variant: SidebarLayoutVariant;
  size: SidebarLayoutSize;
  collapsed: boolean;
}): string => {
  const classes: string[] = ["sidebar-section", "mb-4"];

  if (params.collapsed) {
    classes.push("px-2");
  } else {
    classes.push("px-4");
  }

  return classes.join(" ");
};

export const generateItemClasses = (params: {
  variant: SidebarLayoutVariant;
  size: SidebarLayoutSize;
  collapsed: boolean;
  active: boolean;
}): string => {
  const classes: string[] = [
    "sidebar-item",
    "w-full",
    "text-left",
    "flex",
    "items-center",
    "transition-colors",
    "duration-150",
    "focus:outline-none",
    "focus:ring-2",
  ];

  // Size based padding
  const paddingClasses = {
    sm: params.collapsed ? "p-2" : "px-3 py-2",
    md: params.collapsed ? "p-2" : "px-4 py-3",
    lg: params.collapsed ? "p-3" : "px-5 py-4",
    xl: params.collapsed ? "p-3" : "px-6 py-4",
  };
  classes.push(paddingClasses[params.size]);

  // Active state
  if (params.active) {
    classes.push(
      "border-l-2",
    );
    if (params.variant === "glass") {
      classes.push("bg-white/20");
    }
  }

  // Rounded corners
  if (!params.collapsed) {
    classes.push("rounded-lg", "mx-2");
  } else {
    classes.push("rounded-full", "justify-center");
  }

  // Disabled cursor
  classes.push("cursor-pointer");

  return classes.join(" ");
};

export const getBreakpointWidth = (
  breakpoint: SidebarLayoutBreakpoint
): number => {
  const breakpoints: Record<SidebarLayoutBreakpoint, number> = {
    xs: 0,
    sm: 640,
    md: 768,
    lg: 1024,
    xl: 1280,
    xxl: 1536,
  };
  return breakpoints[breakpoint];
};
