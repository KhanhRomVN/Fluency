import React from "react";
import { DiagramNodeProps } from "./Diagram.types";
import { cn } from "../../../../../shared/utils/cn";

import { useDiagramActions, useDiagramItems } from "./DiagramContext";

const DiagramNode: React.FC<DiagramNodeProps & { filename?: string }> = ({
  children,
  className = "",
  style = {},
  fit = true,
  minWidth,
  minHeight,
  maxWidth,
  maxHeight,
  showDots = false,
  dotClassName,
  filename,
  ...props
}) => {
  const { layoutPositions, activeId, activeNodeIds } = useDiagramItems();
  const {
    registerItem,
    unregisterItem,
    updateItemPosition,
    setActiveId,
    setIsDragging,
  } = useDiagramActions();

  const autoPos = props.id ? layoutPositions[props.id] : undefined;

  const containerStyles: React.CSSProperties = {
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    minWidth: minWidth,
    minHeight: minHeight,
    width: fit ? "fit-content" : undefined,
    height: fit ? "fit-content" : undefined,
    ...style,
    // Apply auto layout position if available
    ...(autoPos && {
      position: "absolute",
      left: autoPos.x,
      top: autoPos.y,
    }),
  };

  // Performance Optimization: Use Ref for drag offset to avoid re-renders on every mouse move
  const dragOffsetRef = React.useRef({ x: 0, y: 0 });
  const isDragging = React.useRef(false);
  const startPos = React.useRef({ x: 0, y: 0 });
  const startOffset = React.useRef({ x: 0, y: 0 });
  const rafRef = React.useRef<number | null>(null);

  const itemRef = React.useRef<HTMLDivElement>(null);

  React.useLayoutEffect(() => {
    if (props.id && itemRef.current) {
      registerItem(props.id, itemRef.current);

      // Resize Observer to auto-update connections when content size changes
      const observer = new ResizeObserver(() => {
        updateItemPosition(props.id!);
      });
      observer.observe(itemRef.current);

      return () => {
        observer.disconnect();
        unregisterItem(props.id!);
        if (rafRef.current) {
          cancelAnimationFrame(rafRef.current);
        }
      };
    }
  }, [props.id, registerItem, unregisterItem, updateItemPosition]);

  const handleMouseDown = (e: React.MouseEvent) => {
    // Left click to select
    if (e.button === 0) {
      if (props.id) {
        const target = e.target as HTMLElement;
        const containsTarget = itemRef.current?.contains(target);

        console.log("[DiagramNode] handleMouseDown", {
          nodeId: props.id,
          targetTagName: target.tagName,
          targetId: target.id,
          targetClassName: target.className,
          containsTarget,
          isItemRef: target === itemRef.current,
          clientX: e.clientX,
          clientY: e.clientY,
        });

        // Chỉ stop propagation nếu click vào chính node hoặc children của nó
        // Không stop nếu click vào vùng margin/padding ngoài
        if (containsTarget) {
          console.log(
            "[DiagramNode] Contains target -> stop propagation & set active"
          );
          e.stopPropagation();
          setActiveId(props.id);
        } else {
          console.log("[DiagramNode] NOT contains target -> bubble lên");
        }
      }
    }

    if (e.button === 2) {
      // Right click
      e.preventDefault();
      e.stopPropagation();
      isDragging.current = true;
      setIsDragging(true); // Notify context
      startPos.current = { x: e.clientX, y: e.clientY };
      startOffset.current = { ...dragOffsetRef.current };

      document.addEventListener("mousemove", handleMouseMove);
      document.addEventListener("mouseup", handleMouseUp);
    }
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging.current || !itemRef.current) return;

    if (rafRef.current) return; // Drop frame if already scheduled

    rafRef.current = requestAnimationFrame(() => {
      if (!isDragging.current || !itemRef.current) return;

      const deltaX = e.clientX - startPos.current.x;
      const deltaY = e.clientY - startPos.current.y;

      // Update ref directly
      dragOffsetRef.current = {
        x: startOffset.current.x + deltaX,
        y: startOffset.current.y + deltaY,
      };

      // Direct DOM manipulation for performance
      itemRef.current.style.transform = `translate(${dragOffsetRef.current.x}px, ${dragOffsetRef.current.y}px)`;

      // Notify context to update edges (still needed for edges to follow)
      // This might still cause some overhead but much less than full component re-render
      if (props.id) {
        updateItemPosition(props.id);
      }

      rafRef.current = null;
    });
  };

  const handleMouseUp = () => {
    isDragging.current = false;
    setIsDragging(false); // Notify context
    if (rafRef.current) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
    document.removeEventListener("mousemove", handleMouseMove);
    document.removeEventListener("mouseup", handleMouseUp);
  };

  // Also update position after mount to ensure initial edges are correct
  React.useEffect(() => {
    if (props.id) updateItemPosition(props.id);
  }, []);

  // Prevent context menu on the item itself if we want consistency,
  // currently only preventing on mousedown for the drag, but actual contextmenu event fires on mouseup often.
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
  };

  const isActive = activeId === props.id;
  const isRelated = props.id ? activeNodeIds?.has(props.id) : false;

  // Merge drag transform with valid style
  const finalStyle = {
    ...containerStyles,
    transform: `${containerStyles.transform || ""} translate(${
      dragOffsetRef.current.x
    }px, ${dragOffsetRef.current.y}px)`,
    // Visual feedback for selection
    borderColor: isActive ? "#3b82f6" : isRelated ? "#3b82f6" : undefined,
    borderStyle: isRelated ? "dashed" : containerStyles.borderStyle,
    borderWidth: isActive || isRelated ? 2 : containerStyles.borderWidth,
    zIndex: isActive || isDragging.current ? 50 : undefined,
    opacity: activeId && !isActive && !isRelated ? 0.3 : 1, // Dim others
    transition: "all 0.2s",
  };

  const dotClass = cn(
    "absolute w-2 h-2 bg-blue-500 rounded-full transition-all cursor-pointer z-10",
    !showDots && "opacity-0 group-hover:opacity-100",
    dotClassName
  );

  return (
    <div
      ref={itemRef}
      className={cn("relative group", className)}
      style={finalStyle}
      onMouseDown={handleMouseDown}
      onContextMenu={handleContextMenu}
      id={props.id}
      data-filename={filename}
      {...props}
    >
      {/* Top Dot */}
      <div
        className={cn(
          dotClass,
          "top-0 left-1/2 -translate-x-1/2 -translate-y-1/2"
        )}
      />

      {/* Right Dot */}
      <div
        className={cn(
          dotClass,
          "top-1/2 right-0 translate-x-1/2 -translate-y-1/2"
        )}
      />

      {/* Bottom Dot */}
      <div
        className={cn(
          dotClass,
          "bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2"
        )}
      />

      {/* Left Dot */}
      <div
        className={cn(
          dotClass,
          "top-1/2 left-0 -translate-x-1/2 -translate-y-1/2"
        )}
      />

      {children}
    </div>
  );
};

export default DiagramNode;
