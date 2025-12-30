import { ReactNode } from "react";

export type GridAutoFlow =
  | "row"
  | "column"
  | "dense"
  | "row dense"
  | "column dense";
export type GridTemplateColumns = string | number;
export type GridTemplateRows = string | number;
export type GridAutoColumns = string;
export type GridAutoRows = string;
export type JustifyItems = "start" | "end" | "center" | "stretch";
export type AlignItems = "start" | "end" | "center" | "stretch" | "baseline";
export type JustifyContent =
  | "start"
  | "end"
  | "center"
  | "stretch"
  | "space-between"
  | "space-around"
  | "space-evenly";
export type AlignContent =
  | "start"
  | "end"
  | "center"
  | "stretch"
  | "space-between"
  | "space-around"
  | "space-evenly";

export interface GridResponsiveProps {
  columns?: GridTemplateColumns;
  rows?: GridTemplateRows;
  autoFlow?: GridAutoFlow;
  autoColumns?: GridAutoColumns;
  autoRows?: GridAutoRows;
  gap?: string | number;
  columnGap?: string | number;
  rowGap?: string | number;
  justifyItems?: JustifyItems;
  alignItems?: AlignItems;
  justifyContent?: JustifyContent;
  alignContent?: AlignContent;
}

export interface GridProps extends GridResponsiveProps {
  children: ReactNode;
  className?: string;
  style?: React.CSSProperties;
  inline?: boolean;
  responsive?: {
    xs?: GridResponsiveProps;
    sm?: GridResponsiveProps;
    md?: GridResponsiveProps;
    lg?: GridResponsiveProps;
    xl?: GridResponsiveProps;
    xxl?: GridResponsiveProps;
  };
  as?: keyof JSX.IntrinsicElements;
  [key: string]: any;
}

export interface GridItemProps {
  children?: ReactNode;
  className?: string;
  style?: React.CSSProperties;
  colSpan?: number | "auto" | "full";
  rowSpan?: number | "auto" | "full";
  colStart?: number | "auto";
  colEnd?: number | "auto";
  rowStart?: number | "auto";
  rowEnd?: number | "auto";
  justifySelf?: "auto" | "start" | "end" | "center" | "stretch";
  alignSelf?: "auto" | "start" | "end" | "center" | "stretch" | "baseline";
  order?: number;
  responsive?: {
    xs?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
    sm?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
    md?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
    lg?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
    xl?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
    xxl?: Partial<
      Omit<GridItemProps, "children" | "className" | "style" | "responsive">
    >;
  };
  as?: keyof JSX.IntrinsicElements;
  [key: string]: any;
}
