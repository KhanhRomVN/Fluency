import { ReactNode } from "react";

export interface KanbanItem {
  id: string;
  content: ReactNode;
  data?: any;
}

export interface KanbanColumn {
  id: string;
  title: string;
  items: KanbanItem[];
}

export interface KanbanDragEndEvent {
  sourceColumnId: string;
  destinationColumnId: string;
  itemId: string;
  sourceIndex: number;
  destinationIndex: number;
  updatedColumns: KanbanColumn[];
}

export interface KanbanProps {
  columns: KanbanColumn[];
  onDragEnd?: (event: KanbanDragEndEvent) => void;
  renderItem?: (item: KanbanItem) => ReactNode;
  renderColumnHeader?: (column: KanbanColumn) => ReactNode;
  className?: string;
  itemClassName?: string;
  columnClassName?: string;
  droppableId?: string;
  draggableId?: string;
}
