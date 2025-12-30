import { createContext, useContext } from "react";
import {
  DiagramActionContextType,
  DiagramItemContextType,
  DiagramRenderContextType,
} from "./Diagram.types";

export const DiagramActionContext = createContext<DiagramActionContextType>({
  registerItem: () => {},
  unregisterItem: () => {},
  updateItemPosition: () => {},
  setActiveId: () => {},
  setViewport: () => {},
  setIsDragging: () => {},
});

export const DiagramItemContext = createContext<DiagramItemContextType>({
  activeId: null,
  activeNodeIds: new Set(),
  layoutPositions: {},
  isDragging: false,
});

export const DiagramRenderContext = createContext<DiagramRenderContextType>({
  items: {},
  version: 0,
  viewport: { x: 0, y: 0, zoom: 1 },
});

export const useDiagramActions = () => useContext(DiagramActionContext);
export const useDiagramItems = () => useContext(DiagramItemContext);
export const useDiagramRender = () => useContext(DiagramRenderContext);

// Unified hook for components that need everything (rarely used now)
export const useDiagram = () => {
  const actions = useContext(DiagramActionContext);
  const items = useContext(DiagramItemContext);
  const render = useContext(DiagramRenderContext);
  return { ...actions, ...items, ...render };
};
