import React, { useState, useEffect, useRef, useCallback } from "react";
import {
  SplitLayoutProps,
  SplitLayoutDragEvent,
  SplitLayoutItemConfig,
} from "./SplitLayout.types";
import {
  getSplitLayoutClasses,
  getGutterStyles,
  parseSplitSize,
  calculateItemSizes,
  validateSplitConfig,
  generateResponsiveSplitClasses,
  getCurrentBreakpoint,
} from "./SplitLayout.utils";
import { cn } from "../../../../../shared/utils/cn";
import {
  GripVertical,
  GripHorizontal,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
} from "lucide-react";

const SplitLayout: React.FC<SplitLayoutProps> = ({
  children,
  direction = "horizontal",
  gutter = "md",
  resizeMode = "simple",
  sizes = [],
  minSizes = [],
  maxSizes = [],
  showDragHandles = true,
  dragHandleSize = 8,
  snapGridSize = 10,
  onSizeChange,
  onDragStart,
  onDragEnd,
  className = "",
  style = {},
  responsive,
  resizable = true,
  animationDuration = 200,
  showResizePreview = true,
  fillRemaining = true,
  equalSizes = false,
  reverse = false,
  wrap = false,
  gap,
  collapsible = false,
  collapsedSize = 50,
  expandOnHover = false,
  initialCollapsed = [],
  onCollapse,
  customDragHandle,
  customResizeIndicator,
  disabled = false,
  persistSizes = false,
  storageKey = "split-layout-sizes",
  zIndex = 10,
  ...props
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [internalSizes, setInternalSizes] =
    useState<(number | string)[]>(sizes);
  const [isDragging, setIsDragging] = useState(false);
  const [draggingItemId, setDraggingItemId] = useState<string | null>(null);
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });
  const [startSize, setStartSize] = useState(0);
  const [collapsedItems, setCollapsedItems] =
    useState<string[]>(initialCollapsed);
  const [containerSize, setContainerSize] = useState(0);
  const [currentBreakpoint, setCurrentBreakpoint] = useState<
    "xs" | "sm" | "md" | "lg" | "xl" | "xxl"
  >("md");

  // Get children as array
  const childrenArray = React.Children.toArray(children);

  // Extract item configurations from children
  const itemConfigs: SplitLayoutItemConfig[] = childrenArray.map(
    (child, index) => {
      if (React.isValidElement(child)) {
        return {
          id: child.props.id || `item-${index}`,
          size:
            child.props.size || sizes[index] || (equalSizes ? "1fr" : "auto"),
          minSize: child.props.minSize || minSizes[index],
          maxSize: child.props.maxSize || maxSizes[index],
          collapsible:
            child.props.collapsible !== undefined
              ? child.props.collapsible
              : collapsible,
          resizable:
            child.props.resizable !== undefined
              ? child.props.resizable
              : resizable,
          visible:
            child.props.visible !== undefined ? child.props.visible : true,
          priority: child.props.priority || 0,
          className: child.props.className,
          style: child.props.style,
        };
      }
      return {
        id: `item-${index}`,
        size: sizes[index] || (equalSizes ? "1fr" : "auto"),
        minSize: minSizes[index],
        maxSize: maxSizes[index],
        collapsible,
        resizable,
        visible: true,
        priority: 0,
      };
    }
  );

  // Load persisted sizes
  useEffect(() => {
    if (persistSizes && typeof window !== "undefined") {
      try {
        const saved = localStorage.getItem(storageKey);
        if (saved) {
          const parsed = JSON.parse(saved);
          setInternalSizes(parsed);
        }
      } catch (error) {
        console.warn("Failed to load persisted split layout sizes", error);
      }
    }
  }, [persistSizes, storageKey]);

  // Save sizes to localStorage
  const saveSizes = useCallback(
    (newSizes: (number | string)[]) => {
      if (persistSizes && typeof window !== "undefined") {
        try {
          localStorage.setItem(storageKey, JSON.stringify(newSizes));
        } catch (error) {
          console.warn("Failed to persist split layout sizes", error);
        }
      }
    },
    [persistSizes, storageKey]
  );

  // Handle resize observer for container
  useEffect(() => {
    if (!containerRef.current) return;

    const updateContainerSize = () => {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        const size = direction === "horizontal" ? rect.width : rect.height;
        setContainerSize(size);

        // Update breakpoint
        const width = window.innerWidth;
        setCurrentBreakpoint(getCurrentBreakpoint(width));
      }
    };

    updateContainerSize();

    const observer = new ResizeObserver(updateContainerSize);
    observer.observe(containerRef.current);

    window.addEventListener("resize", updateContainerSize);

    return () => {
      observer.disconnect();
      window.removeEventListener("resize", updateContainerSize);
    };
  }, [direction]);

  // Validate configuration
  useEffect(() => {
    if (containerSize > 0 && !validateSplitConfig(itemConfigs, containerSize)) {
      console.warn("SplitLayout: Total item sizes exceed container size");
    }
  }, [itemConfigs, containerSize]);

  // Calculate item sizes and styles
  const { sizes: calculatedSizes, styles: itemStyles } = calculateItemSizes(
    itemConfigs,
    containerSize,
    direction
  );

  const handleDragStart = useCallback(
    (itemId: string, clientX: number, clientY: number, currentSize: number) => {
      if (disabled || !resizable) return;

      setIsDragging(true);
      setDraggingItemId(itemId);
      setStartPos({ x: clientX, y: clientY });
      setStartSize(currentSize);

      onDragStart?.(itemId);
    },
    [disabled, resizable, onDragStart]
  );

  const handleDrag = useCallback(
    (clientX: number, clientY: number) => {
      if (!isDragging || !draggingItemId || !containerRef.current) return;

      const delta =
        direction === "horizontal"
          ? clientX - startPos.x
          : clientY - startPos.y;

      let newSize = startSize + delta;

      // Apply snap to grid
      if (snapGridSize > 0) {
        newSize = Math.round(newSize / snapGridSize) * snapGridSize;
      }

      // Find the item index
      const itemIndex = itemConfigs.findIndex(
        (item) => item.id === draggingItemId
      );
      if (itemIndex === -1) return;

      // Apply min/max constraints
      const config = itemConfigs[itemIndex];
      let minSize = 0;
      let maxSize = containerSize;

      if (config.minSize) {
        minSize =
          typeof config.minSize === "number"
            ? config.minSize
            : parseFloat(config.minSize);
      }

      if (config.maxSize) {
        maxSize =
          typeof config.maxSize === "number"
            ? config.maxSize
            : parseFloat(config.maxSize);
      }

      newSize = Math.max(minSize, Math.min(maxSize, newSize));

      // Update sizes
      const newSizes = [...internalSizes];
      newSizes[itemIndex] = newSize;

      setInternalSizes(newSizes);
      onSizeChange?.(newSizes, draggingItemId);

      if (showResizePreview) {
        // Visual feedback during drag
        const itemElement = containerRef.current.querySelector(
          `[data-split-item-id="${draggingItemId}"]`
        );
        if (itemElement) {
          (itemElement as HTMLElement).style[
            direction === "horizontal" ? "width" : "height"
          ] = `${newSize}px`;
        }
      }
    },
    [
      isDragging,
      draggingItemId,
      startPos,
      startSize,
      direction,
      snapGridSize,
      itemConfigs,
      containerSize,
      internalSizes,
      onSizeChange,
      showResizePreview,
    ]
  );

  const handleDragEnd = useCallback(() => {
    if (!isDragging || !draggingItemId) return;

    const itemIndex = itemConfigs.findIndex(
      (item) => item.id === draggingItemId
    );
    if (itemIndex === -1) return;

    const event: SplitLayoutDragEvent = {
      itemId: draggingItemId,
      newSize: internalSizes[itemIndex] || calculatedSizes[itemIndex],
      oldSize: startSize,
      direction,
    };

    setIsDragging(false);
    setDraggingItemId(null);

    onDragEnd?.(event);
    saveSizes(internalSizes);
  }, [
    isDragging,
    draggingItemId,
    itemConfigs,
    internalSizes,
    calculatedSizes,
    startSize,
    direction,
    onDragEnd,
    saveSizes,
  ]);

  // Mouse event handlers
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging) return;
      handleDrag(e.clientX, e.clientY);
    };

    const handleMouseUp = () => {
      handleDragEnd();
    };

    if (isDragging) {
      document.addEventListener("mousemove", handleMouseMove);
      document.addEventListener("mouseup", handleMouseUp);
      document.body.style.cursor =
        direction === "horizontal" ? "col-resize" : "row-resize";
      document.body.style.userSelect = "none";
    }

    return () => {
      document.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseup", handleMouseUp);
      document.body.style.cursor = "";
      document.body.style.userSelect = "";
    };
  }, [isDragging, handleDrag, handleDragEnd, direction]);

  // Handle collapse
  const handleCollapse = useCallback(
    (itemId: string) => {
      const isCollapsed = collapsedItems.includes(itemId);
      const newCollapsedItems = isCollapsed
        ? collapsedItems.filter((id) => id !== itemId)
        : [...collapsedItems, itemId];

      setCollapsedItems(newCollapsedItems);
      onCollapse?.(itemId, !isCollapsed);
    },
    [collapsedItems, onCollapse]
  );

  // Get layout classes
  const layoutClasses = getSplitLayoutClasses({
    direction,
    gutter,
    resizeMode,
    showDragHandles,
    resizable,
    fillRemaining,
    equalSizes,
    reverse,
    wrap,
    gap,
  });

  // Get responsive classes
  const responsiveClasses = generateResponsiveSplitClasses(
    responsive,
    currentBreakpoint
  );

  // Get gutter styles
  const gutterStyles = getGutterStyles(gutter, gap);

  // Combine all styles
  const containerStyles: React.CSSProperties = {
    ...style,
    ...gutterStyles,
    position: "relative",
    transition: `gap ${animationDuration}ms ease`,
  };

  // Render drag handle
  const renderDragHandle = (itemId: string, index: number) => {
    if (!showDragHandles || !resizable || disabled) return null;

    const isItemCollapsed = collapsedItems.includes(itemId);
    if (isItemCollapsed) return null;

    const handleStyle: React.CSSProperties = {
      position: "absolute",
      zIndex,
      transition: "background-color 0.2s ease",
      cursor: direction === "horizontal" ? "col-resize" : "row-resize",
    };

    if (direction === "horizontal") {
      handleStyle.width = `${dragHandleSize}px`;
      handleStyle.height = "100%";
      handleStyle.left = "50%";
      handleStyle.transform = "translateX(-50%)";
      handleStyle.top = "0";
    } else {
      handleStyle.height = `${dragHandleSize}px`;
      handleStyle.width = "100%";
      handleStyle.top = "50%";
      handleStyle.transform = "translateY(-50%)";
      handleStyle.left = "0";
    }

    const GripIcon = direction === "horizontal" ? GripVertical : GripHorizontal;

    return (
      <div
        key={`handle-${itemId}`}
        className="split-layout-drag-handle"
        style={handleStyle}
        onMouseDown={(e) => {
          e.preventDefault();
          e.stopPropagation();
          const itemElement = containerRef.current?.querySelector(
            `[data-split-item-id="${itemId}"]`
          );
          if (itemElement) {
            const rect = itemElement.getBoundingClientRect();
            const currentSize =
              direction === "horizontal" ? rect.width : rect.height;
            handleDragStart(itemId, e.clientX, e.clientY, currentSize);
          }
        }}
        title={
          direction === "horizontal"
            ? "Drag to resize width"
            : "Drag to resize height"
        }
      >
        {customDragHandle || (
          <div className="flex items-center justify-center h-full w-full">
            <GripIcon
              size={Math.max(12, dragHandleSize - 4)}
              className=" opacity-60"
            />
          </div>
        )}
      </div>
    );
  };

  // Render collapse button
  const renderCollapseButton = (itemId: string, index: number) => {
    const config = itemConfigs[index];
    if (!config.collapsible) return null;

    const isCollapsed = collapsedItems.includes(itemId);
    const CollapseIcon =
      direction === "horizontal"
        ? isCollapsed
          ? ChevronRight
          : ChevronLeft
        : isCollapsed
        ? ChevronDown
        : ChevronUp;

    return (
      <button
        className="split-layout-collapse-button"
        onClick={(e) => {
          e.stopPropagation();
          handleCollapse(itemId);
        }}
        style={{
          position: "absolute",
          zIndex: zIndex + 1,
          [direction === "horizontal" ? "right" : "bottom"]: "0",
          transform:
            direction === "horizontal"
              ? `translateX(${isCollapsed ? "100%" : "50%"})`
              : `translateY(${isCollapsed ? "100%" : "50%"})`,
        }}
        title={isCollapsed ? "Expand" : "Collapse"}
      >
        {config.customCollapseButton || <CollapseIcon size={16} className="" />}
      </button>
    );
  };

  // Clone children with additional props
  const enhancedChildren = React.Children.map(children, (child, index) => {
    if (!React.isValidElement(child)) return child;

    const config = itemConfigs[index];
    const isCollapsed = collapsedItems.includes(config.id!);

    const itemSize = isCollapsed
      ? `${collapsedSize}px`
      : internalSizes[index] || calculatedSizes[index];

    const enhancedStyle = {
      ...itemStyles[index],
      ...config.style,
      ...child.props.style,
      [direction === "horizontal" ? "width" : "height"]: isCollapsed
        ? `${collapsedSize}px`
        : internalSizes[index] || calculatedSizes[index],
      transition: isCollapsed
        ? `all ${animationDuration}ms ease`
        : `width ${animationDuration}ms ease, height ${animationDuration}ms ease`,
      overflow: isCollapsed ? "hidden" : "auto",
      flex: isCollapsed ? "0 0 auto" : itemStyles[index]?.flex,
    };

    return React.cloneElement(child as React.ReactElement, {
      "data-split-item-id": config.id,
      className: cn(
        child.props.className,
        config.className,
        isCollapsed && "split-layout-item-collapsed",
        isDragging &&
          draggingItemId === config.id &&
          "split-layout-item-dragging"
      ),
      style: enhancedStyle,
      isDragging: isDragging && draggingItemId === config.id,
      isResizing: isDragging,
      onResizeStart: () => onDragStart?.(config.id!),
      onResizeEnd: (newSize: number | string) => {
        const event: SplitLayoutDragEvent = {
          itemId: config.id!,
          newSize,
          oldSize: startSize,
          direction,
        };
        onDragEnd?.(event);
      },
      onCollapse: (collapsed: boolean) => handleCollapse(config.id!),
    });
  });

  return (
    <div
      ref={containerRef}
      className={cn(layoutClasses, responsiveClasses, className, "flex", {
        "flex-row": direction === "horizontal",
        "flex-col": direction === "vertical",
        "flex-row-reverse": direction === "horizontal" && reverse,
        "flex-col-reverse": direction === "vertical" && reverse,
        "flex-wrap": wrap,
        "split-layout-disabled": disabled,
      })}
      style={containerStyles}
      {...props}
    >
      {enhancedChildren}

      {/* Render drag handles between items */}
      {itemConfigs.map((config, index) => {
        if (index === 0) return null;
        const prevConfig = itemConfigs[index - 1];
        const isPrevCollapsed = collapsedItems.includes(prevConfig.id!);
        const isCurrentCollapsed = collapsedItems.includes(config.id!);

        if (isPrevCollapsed || isCurrentCollapsed) return null;

        return renderDragHandle(config.id!, index);
      })}

      {/* Render collapse buttons */}
      {itemConfigs.map((config, index) =>
        renderCollapseButton(config.id!, index)
      )}

      {/* Resize indicator */}
      {isDragging && showResizePreview && customResizeIndicator && (
        <div className="split-layout-resize-indicator">
          {customResizeIndicator}
        </div>
      )}
    </div>
  );
};

export default SplitLayout;
