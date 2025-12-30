import React from "react";
import { FlexProps } from "./Flex.types";
import { cn } from "../../../../../shared/utils/cn";
import {
  generateFlexClasses,
  generateFlexStyles,
  generateResponsiveClasses,
} from "./Flex.utils";

const Flex: React.FC<FlexProps> = ({
  children,
  className = "",
  style = {},
  direction = "row",
  wrap = "nowrap",
  justify = "flex-start",
  align = "stretch",
  alignContent,
  gap,
  inline = false,
  grow,
  shrink,
  basis,
  responsive,
  as: Component = "div",
  ...props
}) => {
  // Generate base classes
  const baseClasses = generateFlexClasses({
    direction,
    wrap,
    justify,
    align,
    alignContent,
    inline,
  } as FlexProps);

  // Generate responsive classes
  const responsiveClasses = generateResponsiveClasses(
    { direction, wrap, justify, align, alignContent, responsive } as FlexProps,
    "container"
  );

  // Generate inline styles
  const inlineStyles = {
    ...generateFlexStyles({ gap, grow, shrink, basis }),
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

export default Flex;
