import React from "react";
import { GridProps } from "./Grid.types";
import { cn } from "../../../../../shared/utils/cn";
import {
  generateGridClasses,
  generateGridStyles,
  generateResponsiveClasses,
} from "./Grid.utils";

const Grid: React.FC<GridProps> = ({
  children,
  className = "",
  style = {},
  columns,
  rows,
  autoFlow,
  autoColumns,
  autoRows,
  gap,
  columnGap,
  rowGap,
  justifyItems,
  alignItems,
  justifyContent,
  alignContent,
  inline = false,
  responsive,
  as: Component = "div",
  ...props
}) => {
  // Generate base classes
  const baseClasses = generateGridClasses({
    autoFlow,
    justifyItems,
    alignItems,
    justifyContent,
    alignContent,
    inline,
  } as GridProps);

  // Generate responsive classes
  const responsiveClasses = generateResponsiveClasses(
    {
      autoFlow,
      justifyItems,
      alignItems,
      justifyContent,
      alignContent,
      responsive,
    } as GridProps,
    "container"
  );

  // Generate inline styles
  const inlineStyles = {
    ...generateGridStyles({
      columns,
      rows,
      autoColumns,
      autoRows,
      gap,
      columnGap,
      rowGap,
    } as GridProps),
    ...style,
  };

  // Combine all classes
  const combinedClassName = cn(baseClasses, responsiveClasses, className);

  return (
    <Component className={combinedClassName} style={inlineStyles} {...props}>
      {children}
    </Component>
  );
};

export default Grid;
