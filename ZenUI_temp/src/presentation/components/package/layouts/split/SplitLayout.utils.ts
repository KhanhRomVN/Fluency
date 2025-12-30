import {
  SplitLayoutDirection,
  SplitLayoutGutter,
  SplitLayoutBreakpoint,
  SplitLayoutItemConfig,
} from "./SplitLayout.types";

export const parseSplitSize = (size: number | string): string => {
  if (typeof size === "number") {
    return `${size}px`;
  }
  if (
    size.includes("px") ||
    size.includes("%") ||
    size.includes("rem") ||
    size.includes("em") ||
    size.includes("fr")
  ) {
    return size;
  }
  // Assume it's a number without unit
  if (!isNaN(parseFloat(size))) {
    return `${size}px`;
  }
  return size;
};

export const getSplitLayoutClasses = (params: {
  direction: SplitLayoutDirection;
  gutter: SplitLayoutGutter;
  resizeMode: string;
  showDragHandles: boolean;
  resizable: boolean;
  fillRemaining: boolean;
  equalSizes: boolean;
  reverse: boolean;
  wrap: boolean;
  gap?: number | string;
}): string => {
  const classes: string[] = [
    "split-layout",
    `split-layout-${params.direction}`,
  ];

  // Gutter classes
  if (params.gutter !== "none") {
    classes.push(`split-layout-gutter-${params.gutter}`);
  }

  // Resize mode
  if (params.resizeMode !== "none") {
    classes.push(`split-layout-resize-${params.resizeMode}`);
  }

  // Drag handles
  if (params.showDragHandles && params.resizable) {
    classes.push("split-layout-with-handles");
  }

  // Fill remaining space
  if (params.fillRemaining) {
    classes.push("split-layout-fill");
  }

  // Equal sizes
  if (params.equalSizes) {
    classes.push("split-layout-equal");
  }

  // Reverse
  if (params.reverse) {
    classes.push("split-layout-reverse");
  }

  // Wrap
  if (params.wrap) {
    classes.push("split-layout-wrap");
  }

  return classes.join(" ");
};

export const getSplitItemClasses = (params: {
  direction: SplitLayoutDirection;
  resizable: boolean;
  collapsible: boolean;
  visible: boolean;
  isDragging: boolean;
  isResizing: boolean;
  disabled: boolean;
}): string => {
  const classes: string[] = ["split-layout-item"];

  // Resizable
  if (params.resizable) {
    classes.push("split-layout-item-resizable");
  }

  // Collapsible
  if (params.collapsible) {
    classes.push("split-layout-item-collapsible");
  }

  // Visible
  if (!params.visible) {
    classes.push("split-layout-item-hidden");
  }

  // States
  if (params.isDragging) {
    classes.push("split-layout-item-dragging");
  }

  if (params.isResizing) {
    classes.push("split-layout-item-resizing");
  }

  if (params.disabled) {
    classes.push("split-layout-item-disabled");
  }

  return classes.join(" ");
};

export const getGutterStyles = (
  gutter: SplitLayoutGutter,
  gap?: number | string
): React.CSSProperties => {
  const styles: React.CSSProperties = {};

  if (gap !== undefined) {
    styles.gap = parseSplitSize(gap);
    return styles;
  }

  const gutterSizes: Record<SplitLayoutGutter, string> = {
    none: "0",
    sm: "4px",
    md: "8px",
    lg: "16px",
    xl: "24px",
  };

  styles.gap = gutterSizes[gutter];
  return styles;
};

export const getDragHandleStyles = (params: {
  direction: SplitLayoutDirection;
  size: number;
  isDragging: boolean;
  isResizing: boolean;
}): React.CSSProperties => {
  const styles: React.CSSProperties = {
    position: "absolute",
    zIndex: 10,
    backgroundColor:
      params.isDragging || params.isResizing
        ? "var(--primary)"
        : "var(--border-default)",
    transition: "background-color 0.2s ease",
  };

  if (params.direction === "horizontal") {
    styles.width = `${params.size}px`;
    styles.height = "100%";
    styles.cursor = "col-resize";
    styles.top = "0";
  } else {
    styles.height = `${params.size}px`;
    styles.width = "100%";
    styles.cursor = "row-resize";
    styles.left = "0";
  }

  return styles;
};

export const calculateItemSizes = (
  items: SplitLayoutItemConfig[],
  containerSize: number,
  direction: SplitLayoutDirection
): { sizes: string[]; styles: React.CSSProperties[] } => {
  const sizes: string[] = [];
  const styles: React.CSSProperties[] = [];

  // Calculate total fixed size and flex count
  let totalFixed = 0;
  let flexCount = 0;

  items.forEach((item) => {
    if (item.size && typeof item.size === "number") {
      totalFixed += item.size;
    } else if (
      item.size &&
      typeof item.size === "string" &&
      item.size.endsWith("px")
    ) {
      totalFixed += parseFloat(item.size);
    } else if (
      item.size &&
      typeof item.size === "string" &&
      item.size.endsWith("%")
    ) {
      const percent = parseFloat(item.size);
      totalFixed += (containerSize * percent) / 100;
    } else if (item.size === "auto" || !item.size) {
      flexCount++;
    }
  });

  // Calculate remaining space for flex items
  const remainingSpace = Math.max(0, containerSize - totalFixed);
  const flexSize = flexCount > 0 ? remainingSpace / flexCount : 0;

  // Generate sizes and styles
  items.forEach((item) => {
    let sizeStyle: React.CSSProperties = {};

    if (item.size === "auto" || !item.size) {
      sizeStyle.flex = "1 1 0%";
      sizes.push("auto");
    } else if (typeof item.size === "number") {
      sizeStyle[
        direction === "horizontal" ? "width" : "height"
      ] = `${item.size}px`;
      sizeStyle.flex = "0 0 auto";
      sizes.push(`${item.size}px`);
    } else if (item.size.endsWith("%")) {
      sizeStyle[direction === "horizontal" ? "width" : "height"] = item.size;
      sizeStyle.flex = "0 0 auto";
      sizes.push(item.size);
    } else if (item.size.endsWith("fr")) {
      sizeStyle.flex = `${parseFloat(item.size)} 1 0%`;
      sizes.push(item.size);
    } else {
      sizeStyle[direction === "horizontal" ? "width" : "height"] = item.size;
      sizeStyle.flex = "0 0 auto";
      sizes.push(item.size);
    }

    // Apply min/max sizes
    if (item.minSize) {
      sizeStyle[direction === "horizontal" ? "minWidth" : "minHeight"] =
        parseSplitSize(item.minSize);
    }

    if (item.maxSize) {
      sizeStyle[direction === "horizontal" ? "maxWidth" : "maxHeight"] =
        parseSplitSize(item.maxSize);
    }

    styles.push(sizeStyle);
  });

  return { sizes, styles };
};

export const validateSplitConfig = (
  items: SplitLayoutItemConfig[],
  containerSize: number
): boolean => {
  let total = 0;

  for (const item of items) {
    if (item.size && typeof item.size === "number") {
      total += item.size;
    } else if (
      item.size &&
      typeof item.size === "string" &&
      item.size.endsWith("%")
    ) {
      const percent = parseFloat(item.size);
      total += (containerSize * percent) / 100;
    } else if (
      item.size &&
      typeof item.size === "string" &&
      item.size.endsWith("px")
    ) {
      total += parseFloat(item.size);
    }
  }

  return total <= containerSize;
};

export const generateResponsiveSplitClasses = (
  responsive: Partial<Record<SplitLayoutBreakpoint, any>> | undefined,
  currentBreakpoint: SplitLayoutBreakpoint
): string => {
  const classes: string[] = [];

  if (!responsive) return "";

  // Apply styles for current breakpoint and smaller
  const breakpointOrder: SplitLayoutBreakpoint[] = [
    "xs",
    "sm",
    "md",
    "lg",
    "xl",
    "xxl",
  ];
  const currentIndex = breakpointOrder.indexOf(currentBreakpoint);

  for (let i = 0; i <= currentIndex; i++) {
    const bp = breakpointOrder[i];
    if (responsive[bp]) {
      const config = responsive[bp];
      if (config.direction) {
        classes.push(`split-layout-${bp}-${config.direction}`);
      }
      if (config.collapsible !== undefined) {
        classes.push(`split-layout-${bp}-collapsible`);
      }
    }
  }

  return classes.join(" ");
};

export const getBreakpointValue = (
  breakpoint: SplitLayoutBreakpoint
): number => {
  const values: Record<SplitLayoutBreakpoint, number> = {
    xs: 0,
    sm: 640,
    md: 768,
    lg: 1024,
    xl: 1280,
    xxl: 1536,
  };
  return values[breakpoint];
};

export const getCurrentBreakpoint = (width: number): SplitLayoutBreakpoint => {
  if (width >= 1536) return "xxl";
  if (width >= 1280) return "xl";
  if (width >= 1024) return "lg";
  if (width >= 768) return "md";
  if (width >= 640) return "sm";
  return "xs";
};
