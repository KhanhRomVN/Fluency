import React, { useState, useCallback, useMemo, useEffect } from "react";
import {
  DiagramLayoutProps,
  DiagramEdgeOptions,
  LayoutNode,
} from "./Diagram.types";
import {
  DiagramActionContext,
  DiagramItemContext,
  DiagramRenderContext,
} from "./DiagramContext";
import { cn } from "../../../../../shared/utils/cn";
import { calculateLayout } from "./DiagramLayoutAlgorithms";

const DiagramLayout: React.FC<DiagramLayoutProps> = ({
  children,
  className = "",
  style = {},
  edges = [],
  autoLayout = false,
  layoutOptions = {},
  ...props
}) => {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [scale, setScale] = useState(1);
  const [hasFittedView, setHasFittedView] = useState(false);
  const containerRef = React.useRef<HTMLDivElement>(null);

  // Context State
  const [items, setItems] = useState<Record<string, HTMLElement>>({});
  const [activeId, setActiveId] = useState<string | null>(null);
  const [version, setVersion] = useState(0);
  const [layoutPositions, setLayoutPositions] = useState<
    Record<string, { x: number; y: number }>
  >({});

  const registerItem = useCallback((id: string, element: HTMLElement) => {
    setItems((prev) => ({ ...prev, [id]: element }));
  }, []);

  const unregisterItem = useCallback((id: string) => {
    setItems((prev) => {
      const next = { ...prev };
      delete next[id];
      return next;
    });
  }, []);

  const updateItemPosition = useCallback(() => {
    setVersion((v) => v + 1);
  }, []);

  const [isDragging, setIsDragging] = useState(false);
  const [layoutVersion, setLayoutVersion] = useState(0);
  const [itemsVersion, setItemsVersion] = useState(0);

  // Force layout update when items are added/removed (via itemsVersion change)
  useEffect(() => {
    setLayoutVersion((v) => v + 1);
  }, [itemsVersion]);

  // ResizeObserver to handle content loading
  useEffect(() => {
    if (!autoLayout) return;
    const ro = new ResizeObserver(() => setLayoutVersion((v) => v + 1));
    Object.values(items).forEach((el) => {
      // Exclude items explicitly marked to ignore layout (e.g. auto-fitting wrappers)
      if (el.getAttribute("data-layout-ignore") !== "true") {
        ro.observe(el);
      }
    });
    return () => ro.disconnect();
  }, [items, autoLayout]);

  // Auto Layout Calculation
  useEffect(() => {
    if (!autoLayout) {
      setLayoutPositions({});
      return;
    }

    if (isDragging) {
      console.log("[DiagramLayout] Skipping auto layout while dragging");
      return;
    }

    const nodeIds = Object.keys(items).filter((id) => {
      const el = items[id];
      // Exclude items explicitly marked to ignore layout (e.g. auto-fitting wrappers)
      return el && el.getAttribute("data-layout-ignore") !== "true";
    });
    if (nodeIds.length === 0) return;

    // ... existing logic ...

    console.log("[DiagramLayout] Running auto layout for nodes:", nodeIds);

    // Wait for all nodes to be measured
    const layoutNodes: LayoutNode[] = nodeIds.map((id) => {
      const el = items[id];
      // Use offsetWidth/Height for stable logical size, independent of parent transform/scale
      const width = el.offsetWidth;
      const height = el.offsetHeight;

      return {
        id,
        width: width || 200,
        height: height || 150,
        file: el.getAttribute("data-filename") || undefined,
        groupId:
          el.closest("[data-wrapper-id]")?.getAttribute("data-wrapper-id") ||
          undefined,
      };
    });

    // Run layout algorithm
    const result = calculateLayout(layoutNodes, edges, layoutOptions);

    console.log("[DiagramLayout] Layout result applied");
    setLayoutPositions(result.positions);

    // Auto-fit view to content (ONLY ONCE)
    if (!hasFittedView && Object.keys(result.positions).length > 0) {
      let minX = Infinity;
      let minY = Infinity;
      let maxX = -Infinity;
      let maxY = -Infinity;

      // Calculate bounds including node sizes
      nodeIds.forEach((id) => {
        const pos = result.positions[id];
        const node = layoutNodes.find((n) => n.id === id);
        const w = node?.width || 200;
        const h = node?.height || 150;

        if (pos) {
          minX = Math.min(minX, pos.x);
          minY = Math.min(minY, pos.y);
          maxX = Math.max(maxX, pos.x + w);
          maxY = Math.max(maxY, pos.y + h);
        }
      });

      if (minX !== Infinity && containerRef.current) {
        const padding = 100;
        const contentWidth = maxX - minX + padding * 2;
        const contentHeight = maxY - minY + padding * 2;

        const containerRect = containerRef.current.getBoundingClientRect();
        const containerW = containerRect.width;
        const containerH = containerRect.height;

        // Calculate fit scale
        const scaleX = containerW / contentWidth;
        const scaleY = containerH / contentHeight;
        let newScale = Math.min(scaleX, scaleY, 1); // Max scale 1 to avoid zooming in too much on small content
        newScale = Math.max(newScale, 0.1); // Min scale constraint

        // Center content
        // Formula: center of viewport - (center of content * scale)
        const contentCenterX = (minX + maxX) / 2;
        const contentCenterY = (minY + maxY) / 2;

        const viewportCenterX = containerW / 2;
        const viewportCenterY = containerH / 2;

        const newX = viewportCenterX - contentCenterX * newScale;
        const newY = viewportCenterY - contentCenterY * newScale;

        // console.log("[DiagramLayout] Auto-fitting view:", { ... });

        setPosition({ x: newX, y: newY });
        setScale(newScale);
        setHasFittedView(true);
      }
    }
  }, [autoLayout, edges, layoutVersion, hasFittedView]); // Depend on layoutVersion

  // Highlight Logic Helper
  const getActiveConnections = useCallback(
    (id: string | null, edges: DiagramEdgeOptions[]) => {
      if (!id)
        return { edgeIds: new Set<string>(), nodeIds: new Set<string>() };

      const edgeIds = new Set<string>();
      const nodeIds = new Set<string>();

      edges.forEach((edge) => {
        if (edge.from === id) {
          edgeIds.add(edge.id);
          nodeIds.add(edge.to);
        } else if (edge.to === id) {
          edgeIds.add(edge.id);
          nodeIds.add(edge.from);
        }
      });

      return { edgeIds, nodeIds };
    },
    []
  );

  const { edgeIds: activeEdgeIds, nodeIds: activeNodeIds } = useMemo(
    () => getActiveConnections(activeId, edges),
    [activeId, edges, getActiveConnections]
  );

  const isPanning = React.useRef(false);
  const startPanPos = React.useRef({ x: 0, y: 0 });
  const startPanOffset = React.useRef({ x: 0, y: 0 });
  const isHovering = React.useRef(false);

  // Wheel Handler (Zoom & Pan)
  React.useEffect(() => {
    const handleWheel = (e: WheelEvent) => {
      if (!isHovering.current) return;
      e.preventDefault();

      if (e.ctrlKey) {
        // Zoom
        const zoomSensitivity = 0.001;
        const delta = -e.deltaY * zoomSensitivity;
        const newScale = Math.min(Math.max(0.1, scale + delta), 5);

        // Zoom towards cursor
        const rect = containerRef.current?.getBoundingClientRect();
        if (rect) {
          const mouseX = e.clientX - rect.left;
          const mouseY = e.clientY - rect.top;

          setPosition((pos) => ({
            x: mouseX - ((mouseX - pos.x) / scale) * newScale,
            y: mouseY - ((mouseY - pos.y) / scale) * newScale,
          }));
        }

        setScale(newScale);
      } else {
        // Pan
        setPosition((pos) => ({
          x: pos.x - e.deltaX,
          y: pos.y - e.deltaY,
        }));
      }
    };

    const container = containerRef.current;
    if (container) {
      container.addEventListener("wheel", handleWheel, { passive: false });
    }

    return () => {
      if (container) {
        container.removeEventListener("wheel", handleWheel);
      }
    };
  }, [scale]);

  const handleMouseMove = (e: MouseEvent) => {
    if (!isPanning.current) return;
    const deltaX = e.clientX - startPanPos.current.x;
    const deltaY = e.clientY - startPanPos.current.y;

    setPosition({
      x: startPanOffset.current.x + deltaX,
      y: startPanOffset.current.y + deltaY,
    });
  };

  const handleMouseUp = () => {
    isPanning.current = false;
    document.removeEventListener("mousemove", handleMouseMove);
    document.removeEventListener("mouseup", handleMouseUp);
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement;

    console.log("[DiagramLayout] handleMouseDown", {
      targetTagName: target.tagName,
      targetId: target.id,
      targetClassName: target.className,
      isCurrentTarget: e.target === e.currentTarget,
      isDiagramContent: target.id === "diagram-content",
      hasZIndex: target.className.includes("z-10"),
      clientX: e.clientX,
      clientY: e.clientY,
    });

    // Clear activeId on background click
    // Check cho Items Layer hoặc Diagram Content
    const isItemsLayer = target.getAttribute("data-diagram-layer") === "items";

    if (
      e.target === e.currentTarget ||
      target.id === "diagram-content" ||
      isItemsLayer
    ) {
      console.log(
        "[DiagramLayout] Click vào background/items layer -> clear selection"
      );
      setActiveId(null);
    } else {
      console.log("[DiagramLayout] Click vào element con -> không clear");
    }

    // Middle click (1) or Right click (2)
    if (e.button === 2 || e.button === 1) {
      e.preventDefault();
      // Only start pan if clicking directly on the container or if the target bubbles up and isn't stopped
      isPanning.current = true;
      startPanPos.current = { x: e.clientX, y: e.clientY };
      startPanOffset.current = { ...position };

      document.addEventListener("mousemove", handleMouseMove);
      document.addEventListener("mouseup", handleMouseUp);
    }
  };

  const setViewport = useCallback(
    (v: { x: number; y: number; zoom: number }) => {
      setPosition({ x: v.x, y: v.y });
      setScale(v.zoom);
    },
    []
  );

  const actionValue = useMemo(
    () => ({
      registerItem,
      unregisterItem,
      updateItemPosition,
      setActiveId,
      setViewport,
      setIsDragging,
    }),
    [registerItem, unregisterItem, updateItemPosition, setActiveId, setViewport]
  );

  const itemValue = useMemo(
    () => ({
      activeId,
      activeNodeIds,
      layoutPositions,
      isDragging,
    }),
    [activeId, activeNodeIds, layoutPositions, isDragging]
  );

  const renderValue = useMemo(
    () => ({
      items,
      version,
      viewport: { x: position.x, y: position.y, zoom: scale },
    }),
    [items, version, position, scale]
  );

  return (
    <DiagramActionContext.Provider value={actionValue}>
      <DiagramItemContext.Provider value={itemValue}>
        <DiagramRenderContext.Provider value={renderValue}>
          <div
            ref={containerRef}
            className={cn(
              "relative w-full h-full overflow-hidden cursor-grab active:cursor-grabbing",
              className
            )}
            onMouseEnter={() => (isHovering.current = true)}
            onMouseLeave={() => (isHovering.current = false)}
            onMouseDown={handleMouseDown}
            onContextMenu={handleContextMenu}
            style={style}
            {...props}
          >
            <div
              id="diagram-content"
              className="absolute top-0 left-0 w-full h-full origin-top-left transition-transform duration-75 ease-out"
              style={{
                transform: `translate(${position.x}px, ${position.y}px) scale(${scale})`,
              }}
            >
              {/* Edges Layer */}
              <svg className="absolute top-0 left-0 w-full h-full overflow-visible pointer-events-none z-0">
                <DiagramEdges
                  edges={edges}
                  items={items}
                  version={version}
                  activeEdgeIds={activeEdgeIds}
                  activeId={activeId}
                />
              </svg>

              {/* Items Layer */}
              <div
                className="z-10 relative w-full h-full"
                data-diagram-layer="items"
              >
                {children}
              </div>
            </div>
          </div>
        </DiagramRenderContext.Provider>
      </DiagramItemContext.Provider>
    </DiagramActionContext.Provider>
  );
};

const DiagramEdges = ({
  edges,
  items,
  version,
  activeEdgeIds,
  activeId,
}: {
  edges: DiagramEdgeOptions[];
  items: Record<string, HTMLElement>;
  version: number;
  activeEdgeIds: Set<string>;
  activeId: string | null;
}) => {
  // Helper to calculate positions
  const getPos = (
    id: string,
    dot: "top" | "right" | "bottom" | "left" | "auto" = "auto",
    targetId?: string
  ) => {
    const el = items[id];
    if (!el) return null;

    const contentDiv = el.closest("#diagram-content");
    if (!contentDiv) return null;

    const contentRect = contentDiv.getBoundingClientRect();
    const elRect = el.getBoundingClientRect();

    const mat = new DOMMatrix(getComputedStyle(contentDiv).transform);
    const scale = mat.a;

    let x = (elRect.left - contentRect.left) / scale;
    let y = (elRect.top - contentRect.top) / scale;
    const w = elRect.width / scale;
    const h = elRect.height / scale;

    // Resolve 'auto' dot if needed
    let finalDot = dot;
    if (dot === "auto" && targetId && items[targetId]) {
      const targetEl = items[targetId];
      const targetRect = targetEl.getBoundingClientRect();

      // Calculate relative position based on centers (screen coords is fine)
      const center1 = {
        x: elRect.left + elRect.width / 2,
        y: elRect.top + elRect.height / 2,
      };
      const center2 = {
        x: targetRect.left + targetRect.width / 2,
        y: targetRect.top + targetRect.height / 2,
      };

      const dx = center2.x - center1.x;
      const dy = center2.y - center1.y;

      if (Math.abs(dx) > Math.abs(dy)) {
        // Horizontal dominant
        finalDot = dx > 0 ? "right" : "left";
      } else {
        // Vertical dominant
        finalDot = dy > 0 ? "bottom" : "top";
      }
    } else if (dot === "auto") {
      // Fallback default
      finalDot = "right";
    }

    let dir = { x: 0, y: 0 };
    switch (finalDot) {
      case "top":
        dir = { x: 0, y: -1 };
        return { x: x + w / 2, y: y, dir };
      case "bottom":
        dir = { x: 0, y: 1 };
        return { x: x + w / 2, y: y + h, dir };
      case "left":
        dir = { x: -1, y: 0 };
        return { x: x, y: y + h / 2, dir };
      case "right":
        dir = { x: 1, y: 0 };
        return { x: x + w, y: y + h / 2, dir };
    }
    return { x: x + w, y: y + h / 2, dir: { x: 1, y: 0 } };
  };

  // ============== SMART PATH ALGORITHM ==============

  /**
   * Phân tích edge và quyết định kiểu đường tối ưu
   */
  const analyzeEdgeComplexity = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } }
  ): { type: "simple" | "polyline" | "bezier"; complexity: number } => {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    // Vector giữa 2 điểm
    const directionX = dx / dist;
    const directionY = dy / dist;

    // Độ lệch hướng (dot product)
    const startDot = start.dir.x * directionX + start.dir.y * directionY;
    const endDot = end.dir.x * -directionX + end.dir.y * -directionY;

    // Tính góc lệch (0 = cùng hướng, 1 = vuông góc, 2 = ngược hướng)
    const angleDeviation = (2 - startDot - endDot) / 2;

    // Case 1: Simple Path (thẳng/gần thẳng)
    if (dist < 150 && angleDeviation < 0.3) {
      return { type: "simple", complexity: 0 };
    }

    // Case 2: Polyline (1 cong, đổi hướng đơn giản)
    if (dist < 400 && angleDeviation < 0.8) {
      return { type: "polyline", complexity: 1 };
    }

    // Case 3: Bézier (2+ cong, phức tạp)
    return { type: "bezier", complexity: angleDeviation };
  };

  /**
   * Simple Path - Đường thẳng hoặc góc vuông đơn giản
   */
  const getSimplePath = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } }
  ) => {
    const dx = end.x - start.x;
    const dy = end.y - start.y;

    // Nếu gần như thẳng hàng
    if (Math.abs(dx) < 50 || Math.abs(dy) < 50) {
      return `M ${start.x} ${start.y} L ${end.x} ${end.y}`;
    }

    // Góc vuông đơn giản
    const midX = start.x + dx * 0.5;
    return `M ${start.x} ${start.y} L ${midX} ${start.y} L ${midX} ${end.y} L ${end.x} ${end.y}`;
  };

  /**
   * Polyline Curve - 1 đoạn cong mượt (Quadratic Bézier)
   */
  const getPolylinePath = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } }
  ) => {
    const dist = Math.sqrt(
      Math.pow(end.x - start.x, 2) + Math.pow(end.y - start.y, 2)
    );

    // Đoạn thẳng ban đầu
    const straight = Math.min(dist * 0.2, 60);
    const p1 = {
      x: start.x + straight * start.dir.x,
      y: start.y + straight * start.dir.y,
    };
    const p2 = {
      x: end.x + straight * end.dir.x,
      y: end.y + straight * end.dir.y,
    };

    // Control point ở giữa để tạo 1 cong
    const midX = (p1.x + p2.x) / 2;
    const midY = (p1.y + p2.y) / 2;

    // Offset control point để tạo độ cong tự nhiên
    const offsetDist = Math.min(dist * 0.25, 80);
    const perpX = -(p2.y - p1.y) / dist;
    const perpY = (p2.x - p1.x) / dist;

    const cp = {
      x: midX + perpX * offsetDist * 0.3,
      y: midY + perpY * offsetDist * 0.3,
    };

    return `M ${start.x} ${start.y} L ${p1.x} ${p1.y} Q ${cp.x} ${cp.y}, ${p2.x} ${p2.y} L ${end.x} ${end.y}`;
  };

  /**
   * Smooth Bézier - Đường cong S tự nhiên (Cubic Bézier với 2+ điểm uốn)
   */
  const getSmoothBezierPath = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } },
    complexity: number
  ) => {
    const dist = Math.sqrt(
      Math.pow(end.x - start.x, 2) + Math.pow(end.y - start.y, 2)
    );

    // Đoạn thẳng ban đầu (ngắn hơn cho đường cong mượt hơn)
    const straight = Math.min(dist * 0.12, 40);
    const p1 = {
      x: start.x + straight * start.dir.x,
      y: start.y + straight * start.dir.y,
    };
    const p2 = {
      x: end.x + straight * end.dir.x,
      y: end.y + straight * end.dir.y,
    };

    // Control points với độ cong động dựa trên complexity
    const curveFactor = Math.min(dist * (0.35 + complexity * 0.15), 200);

    const cp1 = {
      x: p1.x + curveFactor * start.dir.x,
      y: p1.y + curveFactor * start.dir.y,
    };
    const cp2 = {
      x: p2.x + curveFactor * end.dir.x,
      y: p2.y + curveFactor * end.dir.y,
    };

    // Thêm điểm giữa với offset nhỏ để tạo độ uốn tự nhiên
    const midX = (p1.x + p2.x) / 2;
    const midY = (p1.y + p2.y) / 2;
    const perpX = -(p2.y - p1.y) / dist;
    const perpY = (p2.x - p1.x) / dist;
    const naturalOffset = Math.sin(complexity * Math.PI) * 20;

    const midControl = {
      x: midX + perpX * naturalOffset,
      y: midY + perpY * naturalOffset,
    };

    // Cubic Bézier với điểm giữa để tạo đường S
    return `M ${start.x} ${start.y} L ${p1.x} ${p1.y} C ${cp1.x} ${cp1.y}, ${midControl.x} ${midControl.y}, ${midX} ${midY} C ${midControl.x} ${midControl.y}, ${cp2.x} ${cp2.y}, ${p2.x} ${p2.y} L ${end.x} ${end.y}`;
  };

  /**
   * Step Path - Giữ nguyên cho edge type="step"
   */
  const getStepPath = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } }
  ) => {
    const margin = 20;
    const p1 = {
      x: start.x + margin * start.dir.x,
      y: start.y + margin * start.dir.y,
    };
    const p2 = {
      x: end.x + margin * end.dir.x,
      y: end.y + margin * end.dir.y,
    };

    let midPath = "";

    if (Math.abs(start.dir.x) > 0) {
      if (Math.abs(end.dir.x) > 0) {
        const midX = (p1.x + p2.x) / 2;
        midPath = `L ${midX} ${p1.y} L ${midX} ${p2.y}`;
      } else {
        midPath = `L ${p2.x} ${p1.y}`;
      }
    } else {
      if (Math.abs(end.dir.y) > 0) {
        const midY = (p1.y + p2.y) / 2;
        midPath = `L ${p1.x} ${midY} L ${p2.x} ${midY}`;
      } else {
        midPath = `L ${p1.x} ${p2.y}`;
      }
    }

    return `M ${start.x} ${start.y} L ${p1.x} ${p1.y} ${midPath} L ${p2.x} ${p2.y} L ${end.x} ${end.y}`;
  };

  /**
   * Smart Path Router - Chọn kiểu đường tối ưu
   */
  const getSmartPath = (
    start: { x: number; y: number; dir: { x: number; y: number } },
    end: { x: number; y: number; dir: { x: number; y: number } },
    edgeType?: string
  ): string => {
    // Ưu tiên edge type từ config
    if (edgeType === "step") {
      return getStepPath(start, end);
    }
    if (edgeType === "straight") {
      return `M ${start.x} ${start.y} L ${end.x} ${end.y}`;
    }

    // Phân tích và chọn tự động
    const analysis = analyzeEdgeComplexity(start, end);

    switch (analysis.type) {
      case "simple":
        return getSimplePath(start, end);
      case "polyline":
        return getPolylinePath(start, end);
      case "bezier":
      default:
        return getSmoothBezierPath(start, end, analysis.complexity);
    }
  };

  return (
    <>
      {edges.map((edge) => {
        const fromPos = getPos(edge.from, edge.fromDot || "auto", edge.to);
        const toPos = getPos(edge.to, edge.toDot || "auto", edge.from);

        if (!fromPos || !toPos) return null;

        // Smart path routing - tự động chọn kiểu đường tối ưu
        const path = getSmartPath(fromPos, toPos, edge.type);

        // Highlight Logic
        const isActive = activeId ? activeEdgeIds.has(edge.id) : true;
        const isDimmed = activeId && !isActive;
        const baseColor = edge.color || "#9ca3af";
        const finalColor = isActive ? baseColor : "#e5e7eb"; // Gray-200 if dimmed
        const strokeWidth = isActive ? edge.width || 2 : 1;
        const style = isActive && activeId ? "dashed" : edge.style; // Force dashed if highlighted

        return (
          <g
            key={edge.id}
            style={{ opacity: isDimmed ? 0.3 : 1, transition: "opacity 0.2s" }}
          >
            <path
              d={path}
              stroke={finalColor}
              strokeWidth={strokeWidth}
              fill="none"
              strokeDasharray={
                style === "dashed"
                  ? "5,5"
                  : style === "dotted"
                  ? "2,2"
                  : undefined
              }
            />
            {edge.label && (
              <text
                x={(fromPos.x + toPos.x) / 2}
                y={(fromPos.y + toPos.y) / 2 - 10}
                fill={finalColor}
                textAnchor="middle"
                fontSize={12}
                className="bg-white px-1 font-medium text-xs rounded"
              >
                {edge.label}
              </text>
            )}
          </g>
        );
      })}
    </>
  );
};

export default DiagramLayout;
