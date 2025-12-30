import React from "react";

export type DiagramWrapperProps = Omit<DiagramNodeProps, "title"> & {
  title?: React.ReactNode;
};

export interface DiagramLayoutProps
  extends React.HTMLAttributes<HTMLDivElement> {
  children?: React.ReactNode;
  edges?: DiagramEdgeOptions[];
  /**
   * Enable smart auto layout algorithm.
   * When true, nodes will be automatically positioned for optimal visualization.
   */
  /**
   * Enable smart auto layout algorithm.
   * When true, nodes will be automatically positioned for optimal visualization.
   */
  autoLayout?: boolean;
  /**
   * Options for smart layout algorithm
   */
  layoutOptions?: {
    nodeSpacing?: number; // Minimum space between nodes (default: 80)
    iterations?: number; // Number of simulation iterations (default: 100)
    edgeWeight?: number; // How much edges pull connected nodes together (default: 0.5)
    repulsionStrength?: number; // How much nodes push each other apart (default: 5000)
  };
}

export interface DiagramNodeProps extends React.HTMLAttributes<HTMLDivElement> {
  children?: React.ReactNode;
  /**
   * If true, the item will fit its content size.
   * If false, it might take 100% width/height depending on parent or default behavior.
   * Defaults to true (fit content).
   */
  fit?: boolean;
  minWidth: string | number;
  minHeight: string | number;
  maxWidth: string | number;
  maxHeight: string | number;
  /**
   * If true, dots will always be visible.
   * If false or undefined, dots will only appear on hover.
   */
  showDots?: boolean;
  /**
   * Custom class name for the connection dots.
   */
  dotClassName?: string;
  /**
   * Unique identifier for the item. Required for connecting edges.
   */
  id?: string;
}

export type DiagramEdgeType = "straight" | "step" | "bezier" | "smooth";

export interface DiagramEdgeOptions {
  id: string;
  from: string;
  to: string;
  fromDot?: "top" | "right" | "bottom" | "left" | "auto";
  toDot?: "top" | "right" | "bottom" | "left" | "auto";
  label?: string;
  color?: string;
  width?: number;
  type?: DiagramEdgeType;
  style?: "solid" | "dashed" | "dotted";
}

export interface DiagramActionContextType {
  registerItem: (id: string, element: HTMLElement) => void;
  unregisterItem: (id: string) => void;
  updateItemPosition: (id: string) => void;
  setActiveId: (id: string | null) => void;
  setViewport: (viewport: { x: number; y: number; zoom: number }) => void;
  setIsDragging: (isDragging: boolean) => void;
}

export interface DiagramItemContextType {
  activeId: string | null;
  activeNodeIds: Set<string>;
  layoutPositions: Record<string, { x: number; y: number }>;
  isDragging: boolean;
}

export interface DiagramRenderContextType {
  items: Record<string, HTMLElement>;
  version: number;
  viewport: { x: number; y: number; zoom: number };
}

export type DiagramContextType = DiagramActionContextType &
  DiagramItemContextType &
  DiagramRenderContextType;

export interface LayoutNode {
  id: string;
  width: number;
  height: number;
  file?: string;
  data?: any;
  groupId?: string; // Wrapper ID this node belongs to
  x?: number; // Internal use for simulation
  y?: number; // Internal use for simulation
}
