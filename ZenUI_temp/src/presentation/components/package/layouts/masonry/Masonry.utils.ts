// Utility functions for Masonry component

import {
  MasonryBreakpoints,
  MasonryColumn,
  MasonryItem,
} from "./Masonry.types";

export const calculateColumns = (
  containerWidth: number,
  columnWidth: number,
  gap: number,
  minColumns: number = 1,
  maxColumns: number = 6
): number => {
  const availableWidth = containerWidth - gap * (maxColumns - 1);
  const calculated = Math.floor(availableWidth / (columnWidth + gap));

  return Math.max(minColumns, Math.min(maxColumns, calculated));
};

export const distributeItems = <T extends MasonryItem>(
  items: T[],
  columns: number,
  existingColumns?: MasonryColumn[]
): MasonryColumn[] => {
  // Initialize columns if not provided
  const columnsArray: MasonryColumn[] =
    existingColumns ||
    Array.from({ length: columns }, (_, i) => ({
      id: `column-${i}`,
      items: [],
    }));

  // Reset if no existing columns
  if (!existingColumns) {
    columnsArray.forEach((col) => (col.items = []));
  }

  // Calculate column heights for distribution
  const columnHeights = columnsArray.map((col) =>
    col.items.reduce((sum, item) => sum + (item.height || 200), 0)
  );

  // Distribute items to the shortest column
  items.forEach((item) => {
    const shortestColumnIndex = columnHeights.indexOf(
      Math.min(...columnHeights)
    );
    columnsArray[shortestColumnIndex].items.push(item);
    columnHeights[shortestColumnIndex] += item.height || 200;
  });

  return columnsArray;
};

export const getResponsiveColumns = (
  width: number,
  breakpoints?: MasonryBreakpoints,
  defaultColumns: number = 3
): number => {
  if (!breakpoints) return defaultColumns;

  const { xs = 1, sm = 2, md = 3, lg = 4, xl = 5, xxl = 6 } = breakpoints;

  if (width >= 1920) return xxl;
  if (width >= 1536) return xl;
  if (width >= 1280) return lg;
  if (width >= 1024) return md;
  if (width >= 640) return sm;
  return xs;
};

export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout;

  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};
