import React from "react";
import { FlexItemProps } from "./Flex.types";
import { cn } from "../../../../../shared/utils/cn";
import {
  generateFlexItemClasses,
  generateFlexItemStyles,
  generateResponsiveClasses,
} from "./Flex.utils";

const FlexItem: React.FC<FlexItemProps> = ({
  children,
  className = "",
  style = {},
  grow,
  shrink,
  basis,
  order,
  alignSelf,
  responsive,
  as: Component = "div",
  ...props
}) => {
  // Generate base classes
  const baseClasses = generateFlexItemClasses({
    grow,
    shrink,
    order,
    alignSelf,
  } as FlexItemProps);

  // Generate responsive classes
  const responsiveClasses = generateResponsiveClasses(
    { grow, shrink, order, alignSelf, responsive } as FlexItemProps,
    "item"
  );

  // Generate inline styles
  const inlineStyles = {
    ...generateFlexItemStyles({ grow, shrink, basis } as FlexItemProps),
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

export default FlexItem;
