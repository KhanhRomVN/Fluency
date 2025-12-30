import { ReactNode } from "react";

export type FlexDirection = "row" | "column" | "row-reverse" | "column-reverse";
export type FlexWrap = "nowrap" | "wrap" | "wrap-reverse";
export type JustifyContent =
  | "flex-start"
  | "flex-end"
  | "center"
  | "space-between"
  | "space-around"
  | "space-evenly";
export type AlignItems =
  | "stretch"
  | "flex-start"
  | "flex-end"
  | "center"
  | "baseline";
export type AlignContent =
  | "flex-start"
  | "flex-end"
  | "center"
  | "space-between"
  | "space-around"
  | "stretch";
export type FlexGrow = number | "initial" | "inherit";
export type FlexShrink = number | "initial" | "inherit";
export type FlexBasis = string | "auto" | "initial" | "inherit";

// Breakpoint keys
export type Breakpoint = "xs" | "sm" | "md" | "lg" | "xl" | "xxl";

// Responsive value type - allows either a direct value or an object with breakpoint keys
export type ResponsiveValue<T> = T | Partial<Record<Breakpoint, T>>;

export interface FlexResponsiveProps {
  direction?: FlexDirection;
  wrap?: FlexWrap;
  justify?: JustifyContent;
  align?: AlignItems;
  alignContent?: AlignContent;
  gap?: string | number;
  grow?: FlexGrow;
  shrink?: FlexShrink;
  basis?: FlexBasis;
}

export interface FlexProps {
  children: ReactNode;
  className?: string;
  style?: React.CSSProperties;
  inline?: boolean;
  // Support responsive values directly on props
  direction?: ResponsiveValue<FlexDirection>;
  wrap?: ResponsiveValue<FlexWrap>;
  justify?: ResponsiveValue<JustifyContent>;
  align?: ResponsiveValue<AlignItems>;
  alignContent?: ResponsiveValue<AlignContent>;
  gap?: ResponsiveValue<string | number>;
  // Keep the responsive prop for backward compatibility
  responsive?: {
    xs?: FlexResponsiveProps;
    sm?: FlexResponsiveProps;
    md?: FlexResponsiveProps;
    lg?: FlexResponsiveProps;
    xl?: FlexResponsiveProps;
    xxl?: FlexResponsiveProps;
  };
  as?: keyof JSX.IntrinsicElements;
  [key: string]: any;
}

export interface FlexItemProps {
  children?: ReactNode;
  className?: string;
  style?: React.CSSProperties;
  order?: number;
  alignSelf?:
    | "auto"
    | "flex-start"
    | "flex-end"
    | "center"
    | "baseline"
    | "stretch";
  // Support responsive values directly on props
  grow?: ResponsiveValue<FlexGrow>;
  shrink?: ResponsiveValue<FlexShrink>;
  basis?: ResponsiveValue<FlexBasis>;
  as?: keyof JSX.IntrinsicElements;
  [key: string]: any;
}
