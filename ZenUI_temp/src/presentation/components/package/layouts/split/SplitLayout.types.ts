import { ReactNode, CSSProperties } from "react";

export type SplitLayoutDirection = "horizontal" | "vertical";
export type SplitLayoutGutter = "none" | "sm" | "md" | "lg" | "xl";
export type SplitLayoutResizeMode = "none" | "simple" | "advanced" | "sticky";
export type SplitLayoutBreakpoint = "xs" | "sm" | "md" | "lg" | "xl" | "xxl";

export interface SplitLayoutResponsiveConfig {
  direction?: SplitLayoutDirection;
  minSize?: number | string;
  maxSize?: number | string;
  defaultSize?: number | string;
  collapsible?: boolean;
  collapsedSize?: number;
}

export interface SplitLayoutDragEvent {
  itemId: string;
  newSize: number | string;
  oldSize: number | string;
  direction: SplitLayoutDirection;
}

export interface SplitLayoutItemConfig {
  customCollapseButton?: any;
  id?: string;
  size?: number | string;
  minSize?: number | string;
  maxSize?: number | string;
  defaultSize?: number | string;
  collapsible?: boolean;
  collapsedSize?: number;
  resizable?: boolean;
  visible?: boolean;
  priority?: number;
  className?: string;
  style?: CSSProperties;
}

export interface SplitLayoutProps {
  /** Children components (SplitLayoutItem) */
  children: ReactNode;

  /** Direction of split */
  direction?: SplitLayoutDirection;

  /** Gutter size between items */
  gutter?: SplitLayoutGutter;

  /** Resize mode */
  resizeMode?: SplitLayoutResizeMode;

  /** Default sizes for items (array of numbers or strings) */
  sizes?: (number | string)[];

  /** Minimum sizes for items */
  minSizes?: (number | string)[];

  /** Maximum sizes for items */
  maxSizes?: (number | string)[];

  /** Whether to show drag handles */
  showDragHandles?: boolean;

  /** Drag handle size */
  dragHandleSize?: number;

  /** Snap to grid size */
  snapGridSize?: number;

  /** On size change callback */
  onSizeChange?: (sizes: (number | string)[], itemId?: string) => void;

  /** On drag start callback */
  onDragStart?: (itemId: string) => void;

  /** On drag end callback */
  onDragEnd?: (event: SplitLayoutDragEvent) => void;

  /** Custom className */
  className?: string;

  /** Custom style */
  style?: CSSProperties;

  /** Responsive configuration */
  responsive?: Partial<
    Record<SplitLayoutBreakpoint, SplitLayoutResponsiveConfig>
  >;

  /** Whether layout is resizable */
  resizable?: boolean;

  /** Animation duration for resize */
  animationDuration?: number;

  /** Show resize preview */
  showResizePreview?: boolean;

  /** Fill remaining space */
  fillRemaining?: boolean;

  /** Equal sizes for all items */
  equalSizes?: boolean;

  /** Reverse direction */
  reverse?: boolean;

  /** Wrap items */
  wrap?: boolean;

  /** Gap between items (overrides gutter) */
  gap?: number | string;

  /** Allow collapsing items */
  collapsible?: boolean;

  /** Collapsed size */
  collapsedSize?: number;

  /** Expand collapsed item on hover */
  expandOnHover?: boolean;

  /** Initial collapsed state */
  initialCollapsed?: string[];

  /** On collapse callback */
  onCollapse?: (itemId: string, collapsed: boolean) => void;

  /** Custom drag handle component */
  customDragHandle?: ReactNode;

  /** Custom resize indicator */
  customResizeIndicator?: ReactNode;

  /** Disable drag */
  disabled?: boolean;

  /** Persist sizes in localStorage */
  persistSizes?: boolean;

  /** Storage key for persistence */
  storageKey?: string;

  /** Z-index for drag handles */
  zIndex?: number;
}

export interface SplitLayoutItemProps {
  /** Item content */
  children: ReactNode;

  /** Unique identifier */
  id?: string;

  /** Initial size */
  size?: number | string;

  /** Minimum size */
  minSize?: number | string;

  /** Maximum size */
  maxSize?: number | string;

  /** Whether item is resizable */
  resizable?: boolean;

  /** Whether item is collapsible */
  collapsible?: boolean;

  /** Whether item is visible */
  visible?: boolean;

  /** Priority for auto-sizing */
  priority?: number;

  /** Custom className */
  className?: string;

  /** Custom style */
  style?: CSSProperties;

  /** On resize start callback */
  onResizeStart?: () => void;

  /** On resize end callback */
  onResizeEnd?: (newSize: number | string) => void;

  /** On collapse callback */
  onCollapse?: (collapsed: boolean) => void;

  /** Default collapsed state */
  defaultCollapsed?: boolean;

  /** Collapsed size */
  collapsedSize?: number;

  /** Custom collapse button */
  customCollapseButton?: ReactNode;

  /** Custom resize handle */
  customResizeHandle?: ReactNode;

  /** Item is being dragged */
  isDragging?: boolean;

  /** Item is being resized */
  isResizing?: boolean;

  /** Disable item */
  disabled?: boolean;

  /** Overlay content when collapsed */
  collapsedOverlay?: ReactNode;
}
