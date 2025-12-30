import React from "react";
import { DiagramWrapperProps } from "./Diagram.types";
import { cn } from "../../../../../shared/utils/cn";

import { useDiagramActions, useDiagramItems } from "./DiagramContext";

const DiagramWrapper: React.FC<DiagramWrapperProps> = ({
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
  title,
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

  const finalAnchorStyle: React.CSSProperties = {
    ...style,
    position: "absolute",
    width: 0,
    height: 0,
    background: "transparent",
    border: "none",
    boxShadow: "none",
    overflow: "visible",
    pointerEvents: "auto", // Cho phép bắt events
    // Apply auto layout position if available
    ...(autoPos && {
      left: autoPos.x,
      top: autoPos.y,
    }),
  };

  const dragOffsetRef = React.useRef({ x: 0, y: 0 });
  const [visualBox, setVisualBox] = React.useState({
    x: 0,
    y: 0,
    width: 0,
    height: 0,
  });

  const isDragging = React.useRef(false);
  const startPos = React.useRef({ x: 0, y: 0 });
  const startOffset = React.useRef({ x: 0, y: 0 });

  const rafDragRef = React.useRef<number | null>(null);
  const rafSizeRef = React.useRef<number | null>(null);

  const anchorRef = React.useRef<HTMLDivElement>(null);
  const visualRef = React.useRef<HTMLDivElement>(null);
  const probeRef = React.useRef<HTMLDivElement>(null); // For scale measurement

  React.useLayoutEffect(() => {
    if (props.id && visualRef.current) {
      registerItem(props.id, visualRef.current);

      const updateSize = () => {
        if (!anchorRef.current || !probeRef.current) return;

        if (rafSizeRef.current) return;

        rafSizeRef.current = requestAnimationFrame(() => {
          if (!anchorRef.current || !probeRef.current) return;

          const children = anchorRef.current.children;

          let minX = Infinity;
          let minY = Infinity;
          let maxX = -Infinity;
          let maxY = -Infinity;
          let hasChildren = false;

          const parentRect = anchorRef.current.getBoundingClientRect();

          // SCALE DETECTION with PROBE
          const probeRect = probeRef.current.getBoundingClientRect();
          // Probe is width: 100px in layout.
          // If zoom is 100%, rect.width = 100.
          // If zoom is 50%, rect.width = 50.
          // Scale factor = rendering / layout.
          // Avoid div by zero
          const scale = probeRect.width > 0 ? probeRect.width / 100 : 1;

          // Loop children
          for (let i = 0; i < children.length; i++) {
            const child = children[i] as HTMLElement;
            // Skip visual box, and probe
            if (child === visualRef.current || child === probeRef.current)
              continue;

            if (!child.id) continue; // Skip non-nodes

            if (child.tagName === "DIV" && child.id !== props.id) {
              const childRect = child.getBoundingClientRect();
              const relLeft = (childRect.left - parentRect.left) / scale;
              const relTop = (childRect.top - parentRect.top) / scale;
              const relRight = (childRect.right - parentRect.left) / scale;
              const relBottom = (childRect.bottom - parentRect.top) / scale;

              if (relLeft < minX) minX = relLeft;
              if (relTop < minY) minY = relTop;
              if (relRight > maxX) maxX = relRight;
              if (relBottom > maxY) maxY = relBottom;
              hasChildren = true;
            }
          }

          if (hasChildren && fit) {
            const padding = 20;

            const newX = minX - padding;
            const newY = minY - padding;
            const newW = maxX - minX + 2 * padding;
            const newH = maxY - minY + 2 * padding;

            setVisualBox((prev) => {
              if (
                Math.abs(prev.x - newX) < 1 &&
                Math.abs(prev.y - newY) < 1 &&
                Math.abs(prev.width - newW) < 1 &&
                Math.abs(prev.height - newH) < 1
              )
                return prev;
              return { x: newX, y: newY, width: newW, height: newH };
            });

            updateItemPosition(props.id!);
          }
          rafSizeRef.current = null;
        });
      };

      setTimeout(updateSize, 0);

      const mutationObserver = new MutationObserver(updateSize);
      mutationObserver.observe(anchorRef.current!, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["style", "class"],
      });

      const resizeObserver = new ResizeObserver(updateSize);
      resizeObserver.observe(anchorRef.current!);
      // Need to observe children too
      Array.from(anchorRef.current!.children).forEach((c) => {
        if (c !== visualRef.current && c !== probeRef.current)
          resizeObserver.observe(c);
      });

      return () => {
        mutationObserver.disconnect();
        resizeObserver.disconnect();
        unregisterItem(props.id!);
        if (rafSizeRef.current) cancelAnimationFrame(rafSizeRef.current);
        if (rafDragRef.current) cancelAnimationFrame(rafDragRef.current);
      };
    }
  }, [props.id, registerItem, unregisterItem, updateItemPosition, fit]);

  const handleMouseDown = (e: React.MouseEvent) => {
    // Check if we should start drag
    const startDrag = (e: React.MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();
      isDragging.current = true;
      setIsDragging(true); // Notify context
      startPos.current = { x: e.clientX, y: e.clientY };
      startOffset.current = { ...dragOffsetRef.current };

      document.addEventListener("mousemove", handleMouseMove);
      document.addEventListener("mouseup", handleMouseUp);
    };

    // Left click
    if (e.button === 0) {
      const target = e.target as HTMLElement;

      console.log("[DiagramWrapper] handleMouseDown", {
        wrapperId: props.id,
        targetTagName: target.tagName,
        targetId: target.id,
        targetClassName: target.className,
        isVisualBox: target === visualRef.current,
        isAnchor: target === anchorRef.current,
      });

      // Nếu click vào visual box (border hoặc background của wrapper)
      // -> Select wrapper VÀ Start Drag
      if (target === visualRef.current) {
        console.log("[DiagramWrapper] Click visual box -> Select & Drag");
        setActiveId(props.id || null);
        startDrag(e);
        return;
      }

      // Nếu click vào anchor (vùng trống xung quanh), KHÔNG stop propagation
      if (target === anchorRef.current) {
        return;
      }

      // Nếu click vào probe, bỏ qua
      if (target === probeRef.current) {
        return;
      }
    }

    if (e.button === 2) {
      // Right click to drag group
      startDrag(e);
    }
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging.current) return;

    if (rafDragRef.current) return;

    rafDragRef.current = requestAnimationFrame(() => {
      if (!isDragging.current || !anchorRef.current) return;

      const deltaX = e.clientX - startPos.current.x;
      const deltaY = e.clientY - startPos.current.y;

      dragOffsetRef.current = {
        x: startOffset.current.x + deltaX,
        y: startOffset.current.y + deltaY,
      };

      // Move the ANCHOR (logical parent)
      anchorRef.current.style.transform = `translate(${dragOffsetRef.current.x}px, ${dragOffsetRef.current.y}px)`;

      // Update Position for edges
      if (props.id) {
        updateItemPosition(props.id);
      }

      rafDragRef.current = null;
    });
  };

  const handleMouseUp = () => {
    isDragging.current = false;
    setIsDragging(false); // Notify context
    if (rafDragRef.current) {
      cancelAnimationFrame(rafDragRef.current);
      rafDragRef.current = null;
    }
    document.removeEventListener("mousemove", handleMouseMove);
    document.removeEventListener("mouseup", handleMouseUp);
  };

  React.useEffect(() => {
    if (props.id) updateItemPosition(props.id);
  }, []);

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
  };

  const isActive = activeId === props.id;
  const isRelated = props.id ? activeNodeIds?.has(props.id) : false;

  const visualStyles: React.CSSProperties = {
    position: "absolute",
    left: visualBox.x,
    top: visualBox.y,
    width: fit && visualBox.width > 0 ? visualBox.width : "auto",
    height: fit && visualBox.height > 0 ? visualBox.height : "auto",
    // KHÔNG áp dụng min/max constraints cho wrapper
  };

  const highlightStyles: React.CSSProperties = {
    borderColor: isActive ? "#3b82f6" : isRelated ? "#3b82f6" : undefined,
    borderStyle: isRelated ? "dashed" : undefined,
    borderWidth: isActive || isRelated ? 2 : undefined,
    opacity: activeId && !isActive && !isRelated ? 0.3 : 1,
    transition: "all 0.2s",
    pointerEvents: "none", // Để children xử lý pointer events
    zIndex: isActive || isDragging.current ? 40 : undefined,
  };

  const dotClass = cn(
    "absolute w-3 h-3 bg-blue-500 rounded-full transition-all cursor-pointer z-10",
    !showDots && "opacity-0 group-hover:opacity-100",
    dotClassName
  );

  return (
    <div
      ref={anchorRef}
      style={{
        ...finalAnchorStyle,
        transform: `${finalAnchorStyle.transform || ""} translate(${
          dragOffsetRef.current.x
        }px, ${dragOffsetRef.current.y}px)`,
      }}
      onMouseDown={handleMouseDown}
      onContextMenu={handleContextMenu}
      onClick={(e) => {
        // Bắt click vào anchor để không bị children chặn
        const target = e.target as HTMLElement;
        if (target === anchorRef.current || target === probeRef.current) {
          // Click vào vùng trống, không làm gì để bubble lên
          return;
        }
      }}
      data-wrapper-id={props.id}
      {...props}
    >
      {/* Scale Probe - Invisible, fixed width 100px */}
      <div
        ref={probeRef}
        style={{
          width: 100,
          height: 0,
          position: "absolute",
          visibility: "hidden",
          pointerEvents: "none",
        }}
      />

      {/* Visual Box */}
      <div
        ref={visualRef}
        data-layout-ignore={fit ? "true" : undefined}
        className={cn("relative group bg-transparent", className)}
        style={{ ...visualStyles, ...highlightStyles }}
      >
        {/* Dots - bắt pointer events */}
        <div
          className={cn(
            dotClass,
            "top-0 left-1/2 -translate-x-1/2 -translate-y-1/2"
          )}
          style={{ pointerEvents: "auto" }}
        />
        <div
          className={cn(
            dotClass,
            "top-1/2 right-0 translate-x-1/2 -translate-y-1/2"
          )}
          style={{ pointerEvents: "auto" }}
        />
        <div
          className={cn(
            dotClass,
            "bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2"
          )}
          style={{ pointerEvents: "auto" }}
        />
        <div
          className={cn(
            dotClass,
            "top-1/2 left-0 -translate-x-1/2 -translate-y-1/2"
          )}
          style={{ pointerEvents: "auto" }}
        />
      </div>

      {/* Children */}
      {children}
    </div>
  );
};

export default DiagramWrapper;
