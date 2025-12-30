import React from "react";
import { SplitLayoutItemProps } from "./SplitLayout.types";
import { getSplitItemClasses } from "./SplitLayout.utils";
import { cn } from "../../../../../shared/utils/cn";

const SplitLayoutItem: React.FC<SplitLayoutItemProps> = ({
  children,
  id,
  size,
  minSize,
  maxSize,
  resizable = true,
  collapsible = false,
  visible = true,
  priority = 0,
  className = "",
  style = {},
  onResizeStart,
  onResizeEnd,
  onCollapse,
  defaultCollapsed = false,
  collapsedSize = 50,
  customCollapseButton,
  customResizeHandle,
  isDragging = false,
  isResizing = false,
  disabled = false,
  collapsedOverlay,
  ...props
}) => {
  const [internalCollapsed, setInternalCollapsed] =
    React.useState(defaultCollapsed);

  const handleCollapse = () => {
    const newCollapsed = !internalCollapsed;
    setInternalCollapsed(newCollapsed);
    onCollapse?.(newCollapsed);
  };

  const itemClasses = getSplitItemClasses({
    direction: "horizontal", // This will be overridden by parent
    resizable,
    collapsible,
    visible,
    isDragging,
    isResizing,
    disabled,
  });

  const combinedClassName = cn(
    "split-layout-item",
    itemClasses,
    internalCollapsed && "split-layout-item-collapsed",
    className
  );

  const combinedStyle: React.CSSProperties = {
    ...style,
    position: "relative",
    overflow: internalCollapsed ? "hidden" : "auto",
    transition: "all 0.2s ease",
  };

  // If collapsed, apply collapsed size
  if (internalCollapsed) {
    if (typeof collapsedSize === "number") {
      combinedStyle.width = `${collapsedSize}px`;
      combinedStyle.height = `${collapsedSize}px`;
    } else {
      combinedStyle.width = collapsedSize;
      combinedStyle.height = collapsedSize;
    }
    combinedStyle.flex = "0 0 auto";
  }

  // Apply min/max sizes
  if (minSize) {
    combinedStyle.minWidth =
      typeof minSize === "number" ? `${minSize}px` : minSize;
    combinedStyle.minHeight =
      typeof minSize === "number" ? `${minSize}px` : minSize;
  }

  if (maxSize) {
    combinedStyle.maxWidth =
      typeof maxSize === "number" ? `${maxSize}px` : maxSize;
    combinedStyle.maxHeight =
      typeof maxSize === "number" ? `${maxSize}px` : maxSize;
  }

  return (
    <div
      id={id}
      className={combinedClassName}
      style={combinedStyle}
      data-split-item-id={id}
      data-priority={priority}
      data-collapsible={collapsible}
      data-collapsed={internalCollapsed}
      {...props}
    >
      {internalCollapsed && collapsedOverlay ? (
        <div className="split-layout-item-collapsed-overlay">
          {collapsedOverlay}
        </div>
      ) : (
        children
      )}

      {/* Collapse button for this item (if collapsible) */}
      {collapsible && customCollapseButton && (
        <div className="split-layout-item-collapse-button-wrapper">
          {customCollapseButton}
        </div>
      )}
    </div>
  );
};

export default SplitLayoutItem;
