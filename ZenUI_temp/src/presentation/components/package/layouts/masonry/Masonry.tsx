import React, { useEffect, useRef, useState, useCallback } from "react";
import { MasonryProps, MasonryItem, MasonryColumn } from "./Masonry.types";
import {
  calculateColumns,
  distributeItems,
  getResponsiveColumns,
  debounce,
} from "./Masonry.utils";
import { cn } from "../../../../../shared/utils/cn";

const Masonry: React.FC<MasonryProps> = ({
  items,
  columns: propColumns = 3,
  gap = 16,
  columnWidth = 300,
  breakpoints,
  renderItem,
  className = "",
  itemClassName = "",
  columnClassName = "",
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [columns, setColumns] = useState<MasonryColumn[]>([]);
  const [actualColumns, setActualColumns] = useState(propColumns);

  const updateLayout = useCallback(() => {
    if (!containerRef.current) return;

    const containerWidth = containerRef.current.clientWidth;

    // Calculate responsive columns
    let calculatedColumns = propColumns;
    if (breakpoints) {
      calculatedColumns = getResponsiveColumns(
        containerWidth,
        breakpoints,
        propColumns
      );
    } else {
      calculatedColumns = calculateColumns(
        containerWidth,
        columnWidth,
        gap,
        1,
        6
      );
    }

    setActualColumns(calculatedColumns);

    // Distribute items to columns
    const newColumns = distributeItems(items, calculatedColumns);
    setColumns(newColumns);
  }, [items, propColumns, columnWidth, gap, breakpoints]);

  useEffect(() => {
    updateLayout();

    const handleResize = debounce(updateLayout, 100);
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, [updateLayout]);

  useEffect(() => {
    // Update when items change
    if (columns.length > 0) {
      const newColumns = distributeItems(items, actualColumns, columns);
      setColumns(newColumns);
    }
  }, [items]);

  const defaultRenderItem = (item: MasonryItem) => (
    <div
      className={`mb-${gap} ${itemClassName}`}
      style={{
        marginBottom: `${gap}px`,
        breakInside: "avoid",
      }}
    >
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden hover:shadow-md transition-shadow duration-200">
        {item.content}
      </div>
    </div>
  );

  const columnStyle = {
    display: "flex",
    flexDirection: "column" as const,
    width: `calc((100% - ${gap * (actualColumns - 1)}px) / ${actualColumns})`,
    gap: `${gap}px`,
  };

  return (
    <div ref={containerRef} className={`masonry-container ${className}`}>
      {columns.length > 0 ? (
        <div
          className="flex w-full"
          style={{
            gap: `${gap}px`,
          }}
        >
          {columns.map((column) => (
            <div
              key={column.id}
              className={`masonry-column ${columnClassName}`}
              style={columnStyle}
            >
              {column.items.map((item) => (
                <React.Fragment key={item.id}>
                  {renderItem ? renderItem(item) : defaultRenderItem(item)}
                </React.Fragment>
              ))}
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-8 ">No items to display</div>
      )}
    </div>
  );
};

export default Masonry;
