import React from "react";
import { GridItemProps } from "./Grid.types";
import { cn } from "../../../../../shared/utils/cn";
import {
  generateGridItemClasses,
  generateGridItemStyles,
  generateResponsiveClasses,
} from "./Grid.utils";

const GridItem: React.FC<GridItemProps> = ({
  children,
  className = "",
  style = {},
  colSpan,
  rowSpan,
  colStart,
  colEnd,
  rowStart,
  rowEnd,
  justifySelf,
  alignSelf,
  order,
  responsive,
  as: Component = "div",
  ...props
}) => {
  // Generate base classes
  const baseClasses = generateGridItemClasses({
    colSpan,
    rowSpan,
    colStart,
    colEnd,
    rowStart,
    rowEnd,
    justifySelf,
    alignSelf,
    order,
  } as GridItemProps);

  // Generate responsive classes
  const responsiveClasses = generateResponsiveClasses(
    {
      colSpan,
      rowSpan,
      colStart,
      colEnd,
      rowStart,
      rowEnd,
      justifySelf,
      alignSelf,
      order,
      responsive,
    } as GridItemProps,
    "item"
  );

  // Generate inline styles
  const inlineStyles = {
    ...generateGridItemStyles({} as GridItemProps),
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

export default GridItem;
