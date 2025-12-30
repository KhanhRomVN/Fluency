import { ReactNode } from "react";

export interface MasonryItem {
  id: string;
  content: ReactNode;
  height?: number; // Optional height for manual control
  width?: number; // Optional width for manual control
  data?: any;
}

export interface MasonryColumn {
  id: string;
  items: MasonryItem[];
}

export interface MasonryBreakpoints {
  xs?: number;
  sm?: number;
  md?: number;
  lg?: number;
  xl?: number;
  xxl?: number;
}

export interface MasonryProps {
  items: MasonryItem[];
  columns?: number;
  gap?: number;
  columnWidth?: number;
  breakpoints?: MasonryBreakpoints;
  renderItem?: (item: MasonryItem) => ReactNode;
  className?: string;
  itemClassName?: string;
  columnClassName?: string;
}
