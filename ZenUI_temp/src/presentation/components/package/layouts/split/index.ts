export { default as SplitLayout } from "./SplitLayout";
export { default as SplitLayoutItem } from "./SplitLayoutItem";

export type {
  SplitLayoutProps,
  SplitLayoutItemProps,
  SplitLayoutDirection,
  SplitLayoutGutter,
  SplitLayoutResizeMode,
  SplitLayoutBreakpoint,
  SplitLayoutResponsiveConfig,
  SplitLayoutDragEvent,
} from "./SplitLayout.types";

export {
  parseSplitSize,
  getSplitLayoutClasses,
  getSplitItemClasses,
  getGutterStyles,
  getDragHandleStyles,
  calculateItemSizes,
  validateSplitConfig,
  generateResponsiveSplitClasses,
} from "./SplitLayout.utils";
