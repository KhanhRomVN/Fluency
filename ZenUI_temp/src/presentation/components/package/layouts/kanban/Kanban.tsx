import React from "react";
import {
  DndContext,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
  PointerSensor,
  useSensor,
  useSensors,
  closestCorners,
} from "@dnd-kit/core";
import {
  SortableContext,
  verticalListSortingStrategy,
  arrayMove,
} from "@dnd-kit/sortable";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { KanbanProps, KanbanColumn, KanbanItem } from "./Kanban.types";
import { MoreVertical, Plus } from "lucide-react";
import { cn } from "../../../../../shared/utils/cn";

// Sortable Item Component
const SortableItem: React.FC<{
  item: KanbanItem;
  renderItem?: (item: KanbanItem) => React.ReactNode;
  itemClassName?: string;
}> = ({ item, renderItem, itemClassName }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: item.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.3 : 1,
    cursor: isDragging ? "grabbing" : "grab",
  };

  const defaultRenderItem = (item: KanbanItem) => (
    <div
      className={`p-4 mb-3 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-md transition-all ${
        isDragging ? "ring-2 ring-primary/30" : ""
      } ${itemClassName}`}
    >
      {item.content}
    </div>
  );

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className={isDragging ? "z-50" : ""}
    >
      {renderItem ? renderItem(item) : defaultRenderItem(item)}
    </div>
  );
};

// Droppable Column Component
const DroppableColumn: React.FC<{
  column: KanbanColumn;
  renderItem?: (item: KanbanItem) => React.ReactNode;
  renderColumnHeader?: (column: KanbanColumn) => React.ReactNode;
  itemClassName?: string;
  columnClassName?: string;
}> = ({
  column,
  renderItem,
  renderColumnHeader,
  itemClassName,
  columnClassName,
}) => {
  const { isOver, setNodeRef } = useSortable({
    id: column.id,
    data: { type: "column" },
  });

  const defaultRenderColumnHeader = (column: KanbanColumn) => (
    <div className="flex items-center justify-between p-3">
      <div className="flex items-center gap-2">
        <div className="w-3 h-3 rounded-full bg-primary opacity-60"></div>
        <h3 className="font-semibold">{column.title}</h3>
        <span className="px-2 py-0.5 text-xs bg-gray-100 dark:bg-gray-700 rounded-full ">
          {column.items.length}
        </span>
      </div>
      <div className="flex items-center gap-1">
        <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors">
          <Plus size={16} className="" />
        </button>
        <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors">
          <MoreVertical size={16} className="" />
        </button>
      </div>
    </div>
  );

  return (
    <div
      ref={setNodeRef}
      className={`flex-shrink-0 w-80 bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 ${columnClassName} rounded-lg border transition-all ${
        isOver ? "ring-2 ring-primary/20 bg-primary/5" : ""
      }`}
    >
      {renderColumnHeader
        ? renderColumnHeader(column)
        : defaultRenderColumnHeader(column)}
      <div className="p-3">
        <SortableContext
          items={column.items.map((item) => item.id)}
          strategy={verticalListSortingStrategy}
        >
          {column.items.map((item) => (
            <SortableItem
              key={item.id}
              item={item}
              renderItem={renderItem}
              itemClassName={itemClassName}
            />
          ))}
        </SortableContext>
      </div>
    </div>
  );
};

const Kanban: React.FC<KanbanProps> = ({
  columns,
  onDragEnd,
  renderItem,
  renderColumnHeader,
  className = "",
  itemClassName = "",
  columnClassName = "",
}) => {
  const [activeId, setActiveId] = React.useState<string | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);

    if (!over) return;

    const activeId = active.id as string;
    const overId = over.id as string;

    // Find source column and item
    const sourceColumn = columns.find((col) =>
      col.items.some((item) => item.id === activeId)
    );

    if (!sourceColumn) return;

    const sourceItem = sourceColumn.items.find((item) => item.id === activeId);
    if (!sourceItem) return;

    // Find destination column
    let destColumn = columns.find((col) => col.id === overId);
    if (!destColumn) {
      destColumn = columns.find((col) =>
        col.items.some((item) => item.id === overId)
      );
    }

    if (!destColumn) return;

    const sourceIndex = sourceColumn.items.findIndex(
      (item) => item.id === activeId
    );

    // Moving within same column
    if (sourceColumn.id === destColumn.id) {
      const destIndex = destColumn.items.findIndex(
        (item) => item.id === overId
      );
      if (destIndex === -1) return;

      const newItems = arrayMove(sourceColumn.items, sourceIndex, destIndex);
      const newColumns = columns.map((col) =>
        col.id === sourceColumn.id ? { ...col, items: newItems } : col
      );

      if (onDragEnd) {
        onDragEnd({
          sourceColumnId: sourceColumn.id,
          destinationColumnId: destColumn.id,
          itemId: activeId,
          sourceIndex,
          destinationIndex: destIndex,
          updatedColumns: newColumns,
        });
      }
    } else {
      // Moving to different column
      const newSourceItems = sourceColumn.items.filter(
        (item) => item.id !== activeId
      );

      let destIndex = destColumn.items.findIndex((item) => item.id === overId);
      if (destIndex === -1) {
        destIndex = destColumn.items.length;
      }

      const newDestItems = [...destColumn.items];
      newDestItems.splice(destIndex, 0, sourceItem);

      const newColumns = columns.map((col) => {
        if (col.id === sourceColumn.id) {
          return { ...col, items: newSourceItems };
        }
        if (col.id === destColumn.id) {
          return { ...col, items: newDestItems };
        }
        return col;
      });

      if (onDragEnd) {
        onDragEnd({
          sourceColumnId: sourceColumn.id,
          destinationColumnId: destColumn.id,
          itemId: activeId,
          sourceIndex,
          destinationIndex: destIndex,
          updatedColumns: newColumns,
        });
      }
    }
  };

  const handleDragCancel = () => {
    setActiveId(null);
  };

  const activeItem = activeId
    ? columns.flatMap((col) => col.items).find((item) => item.id === activeId)
    : null;

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragCancel={handleDragCancel}
    >
      <div className={`flex gap-4 overflow-x-auto p-4 ${className}`}>
        <SortableContext
          items={columns.map((col) => col.id)}
          strategy={verticalListSortingStrategy}
        >
          {columns.map((column) => (
            <DroppableColumn
              key={column.id}
              column={column}
              renderItem={renderItem}
              renderColumnHeader={renderColumnHeader}
              itemClassName={itemClassName}
              columnClassName={columnClassName}
            />
          ))}
        </SortableContext>
      </div>
      <DragOverlay>
        {activeItem ? (
          <div className="opacity-90 rotate-2 shadow-2xl cursor-grabbing">
            {renderItem ? (
              renderItem(activeItem)
            ) : (
              <div
                className={`p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 ${itemClassName}`}
              >
                {activeItem.content}
              </div>
            )}
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
};

export default Kanban;
