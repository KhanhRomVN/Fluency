import {
  FlexResponsiveProps,
  FlexProps,
  FlexItemProps,
  ResponsiveValue,
  Breakpoint,
  FlexDirection,
  FlexWrap,
  JustifyContent,
  AlignItems,
  AlignContent,
  FlexGrow,
  FlexShrink,
} from "./Flex.types";

/**
 * Check if a value is a responsive object
 */
const isResponsiveValue = <T>(
  value: ResponsiveValue<T> | undefined
): value is Partial<Record<Breakpoint, T>> => {
  return typeof value === "object" && value !== null && !Array.isArray(value);
};

/**
 * Get the base value from a responsive value (xs breakpoint or direct value)
 */
const getBaseValue = <T>(
  value: ResponsiveValue<T> | undefined
): T | undefined => {
  if (value === undefined) return undefined;
  if (isResponsiveValue(value)) {
    return value.xs;
  }
  return value as T;
};

/**
 * Generate CSS class for flex container
 */
export const generateFlexClasses = (props: FlexProps): string => {
  const classes: string[] = [];

  // Flex display
  classes.push(props.inline ? "inline-flex" : "flex");

  // Direction - handle responsive values
  const baseDirection = getBaseValue(props.direction);
  if (baseDirection) {
    classes.push(`flex-${baseDirection}`);
  }

  // Wrap - handle responsive values
  const baseWrap = getBaseValue(props.wrap);
  if (baseWrap) {
    classes.push(`flex-${baseWrap}`);
  }

  // Justify content - handle responsive values
  const baseJustify = getBaseValue(props.justify);
  if (baseJustify) {
    const justifyMap: Record<string, string> = {
      "flex-start": "justify-start",
      "flex-end": "justify-end",
      center: "justify-center",
      "space-between": "justify-between",
      "space-around": "justify-around",
      "space-evenly": "justify-evenly",
    };
    classes.push(justifyMap[baseJustify]);
  }

  // Align items - handle responsive values
  const baseAlign = getBaseValue(props.align);
  if (baseAlign) {
    const alignMap: Record<string, string> = {
      stretch: "items-stretch",
      "flex-start": "items-start",
      "flex-end": "items-end",
      center: "items-center",
      baseline: "items-baseline",
    };
    classes.push(alignMap[baseAlign]);
  }

  // Align content - handle responsive values
  const baseAlignContent = getBaseValue(props.alignContent);
  if (baseAlignContent) {
    const alignContentMap: Record<string, string> = {
      "flex-start": "content-start",
      "flex-end": "content-end",
      center: "content-center",
      "space-between": "content-between",
      "space-around": "content-around",
      stretch: "content-stretch",
    };
    classes.push(alignContentMap[baseAlignContent]);
  }

  return classes.filter(Boolean).join(" ");
};

/**
 * Generate CSS class for flex item
 */
export const generateFlexItemClasses = (props: FlexItemProps): string => {
  const classes: string[] = [];

  // Grow - handle responsive values
  const baseGrow = getBaseValue(props.grow);
  if (baseGrow !== undefined) {
    if (baseGrow === "initial" || baseGrow === "inherit") {
      classes.push(`grow-${baseGrow}`);
    } else if (typeof baseGrow === "number") {
      classes.push(`grow-${baseGrow}`);
    }
  }

  // Shrink - handle responsive values
  const baseShrink = getBaseValue(props.shrink);
  if (baseShrink !== undefined) {
    if (baseShrink === "initial" || baseShrink === "inherit") {
      classes.push(`shrink-${baseShrink}`);
    } else if (typeof baseShrink === "number") {
      classes.push(`shrink-${baseShrink}`);
    }
  }

  // Order
  if (props.order !== undefined) {
    classes.push(`order-${props.order}`);
  }

  // Align self
  if (props.alignSelf) {
    const alignSelfMap: Record<string, string> = {
      auto: "self-auto",
      "flex-start": "self-start",
      "flex-end": "self-end",
      center: "self-center",
      baseline: "self-baseline",
      stretch: "self-stretch",
    };
    classes.push(alignSelfMap[props.alignSelf]);
  }

  return classes.filter(Boolean).join(" ");
};

/**
 * Generate inline styles for flex container
 */
export const generateFlexStyles = (
  props: Partial<FlexProps>
): React.CSSProperties => {
  const styles: React.CSSProperties = {};

  // Gap - handle responsive values
  const baseGap = getBaseValue(props.gap);
  if (baseGap !== undefined) {
    if (typeof baseGap === "number") {
      styles.gap = `${baseGap}px`;
    } else {
      styles.gap = baseGap;
    }
  }

  return styles;
};

/**
 * Generate inline styles for flex item
 */
export const generateFlexItemStyles = (
  props: FlexItemProps
): React.CSSProperties => {
  const styles: React.CSSProperties = {};

  // Grow - handle responsive values
  const baseGrow = getBaseValue(props.grow);
  if (typeof baseGrow === "number") {
    styles.flexGrow = baseGrow;
  }

  // Shrink - handle responsive values
  const baseShrink = getBaseValue(props.shrink);
  if (typeof baseShrink === "number") {
    styles.flexShrink = baseShrink;
  }

  // Basis - handle responsive values
  const baseBasis = getBaseValue(props.basis);
  if (baseBasis !== undefined) {
    styles.flexBasis =
      typeof baseBasis === "number" ? `${baseBasis}px` : baseBasis;
  }

  return styles;
};

/**
 * Generate responsive classes from direct responsive prop values
 */
const generateDirectResponsiveClasses = (
  props: FlexProps | FlexItemProps,
  type: "container" | "item"
): string => {
  const classes: string[] = [];
  const breakpoints: Breakpoint[] = ["xs", "sm", "md", "lg", "xl", "xxl"];

  if (type === "container") {
    const containerProps = props as FlexProps;

    // Direction
    if (isResponsiveValue(containerProps.direction)) {
      const responsiveDirection = containerProps.direction as Partial<
        Record<Breakpoint, FlexDirection>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveDirection[bp];
        if (value && bp !== "xs") {
          classes.push(`${bp}:flex-${value}`);
        }
      });
    }

    // Wrap
    if (isResponsiveValue(containerProps.wrap)) {
      const responsiveWrap = containerProps.wrap as Partial<
        Record<Breakpoint, FlexWrap>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveWrap[bp];
        if (value && bp !== "xs") {
          classes.push(`${bp}:flex-${value}`);
        }
      });
    }

    // Justify
    if (isResponsiveValue(containerProps.justify)) {
      const justifyMap: Record<string, string> = {
        "flex-start": "justify-start",
        "flex-end": "justify-end",
        center: "justify-center",
        "space-between": "justify-between",
        "space-around": "justify-around",
        "space-evenly": "justify-evenly",
      };
      const responsiveJustify = containerProps.justify as Partial<
        Record<Breakpoint, JustifyContent>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveJustify[bp];
        if (value && bp !== "xs") {
          classes.push(`${bp}:${justifyMap[value]}`);
        }
      });
    }

    // Align
    if (isResponsiveValue(containerProps.align)) {
      const alignMap: Record<string, string> = {
        stretch: "items-stretch",
        "flex-start": "items-start",
        "flex-end": "items-end",
        center: "items-center",
        baseline: "items-baseline",
      };
      const responsiveAlign = containerProps.align as Partial<
        Record<Breakpoint, AlignItems>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveAlign[bp];
        if (value && bp !== "xs") {
          classes.push(`${bp}:${alignMap[value]}`);
        }
      });
    }

    // Align Content
    if (isResponsiveValue(containerProps.alignContent)) {
      const alignContentMap: Record<string, string> = {
        "flex-start": "content-start",
        "flex-end": "content-end",
        center: "content-center",
        "space-between": "content-between",
        "space-around": "content-around",
        stretch: "content-stretch",
      };
      const responsiveAlignContent = containerProps.alignContent as Partial<
        Record<Breakpoint, AlignContent>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveAlignContent[bp];
        if (value && bp !== "xs") {
          classes.push(`${bp}:${alignContentMap[value]}`);
        }
      });
    }
  } else {
    const itemProps = props as FlexItemProps;

    // Grow
    if (isResponsiveValue(itemProps.grow)) {
      const responsiveGrow = itemProps.grow as Partial<
        Record<Breakpoint, FlexGrow>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveGrow[bp];
        if (value !== undefined && bp !== "xs" && typeof value === "number") {
          classes.push(`${bp}:grow-${value}`);
        }
      });
    }

    // Shrink
    if (isResponsiveValue(itemProps.shrink)) {
      const responsiveShrink = itemProps.shrink as Partial<
        Record<Breakpoint, FlexShrink>
      >;
      breakpoints.forEach((bp) => {
        const value = responsiveShrink[bp];
        if (value !== undefined && bp !== "xs" && typeof value === "number") {
          classes.push(`${bp}:shrink-${value}`);
        }
      });
    }
  }

  return classes.join(" ");
};

/**
 * Generate responsive classes from legacy responsive prop
 */
const generateLegacyResponsiveClasses = (
  props: FlexProps | FlexItemProps,
  type: "container" | "item"
): string => {
  const classes: string[] = [];

  if ("responsive" in props && props.responsive) {
    const responsive = props.responsive;

    Object.entries(responsive).forEach(([breakpoint, breakpointProps]) => {
      if (!breakpointProps) return;
      const prefix = breakpoint === "xs" ? "" : `${breakpoint}:`;

      if (type === "container") {
        // Container responsive classes
        const containerProps = breakpointProps as Partial<{
          direction: FlexDirection;
          justify: JustifyContent;
          align: AlignItems;
          alignContent: AlignContent;
          wrap: FlexWrap;
          gap: number | string;
        }>;

        if (containerProps.direction) {
          classes.push(`${prefix}flex-${containerProps.direction}`);
        }

        if (containerProps.justify) {
          const justifyMap: Record<string, string> = {
            "flex-start": "justify-start",
            "flex-end": "justify-end",
            center: "justify-center",
            "space-between": "justify-between",
            "space-around": "justify-around",
            "space-evenly": "justify-evenly",
          };
          classes.push(`${prefix}${justifyMap[containerProps.justify]}`);
        }

        if (containerProps.align) {
          const alignMap: Record<string, string> = {
            stretch: "items-stretch",
            "flex-start": "items-start",
            "flex-end": "items-end",
            center: "items-center",
            baseline: "items-baseline",
          };
          classes.push(`${prefix}${alignMap[containerProps.align]}`);
        }
      } else {
        // Item responsive classes
        const itemProps = breakpointProps as Partial<{
          grow: FlexGrow;
          shrink: FlexShrink;
          basis: number | string;
          order: number;
          alignSelf: string;
        }>;

        if (typeof itemProps.grow === "number") {
          classes.push(`${prefix}grow-${itemProps.grow}`);
        }

        if (typeof itemProps.order === "number") {
          classes.push(`${prefix}order-${itemProps.order}`);
        }
      }
    });
  }

  return classes.join(" ");
};

/**
 * Generate responsive classes (supports both direct responsive values and legacy responsive prop)
 */
export const generateResponsiveClasses = (
  props: FlexProps | FlexItemProps,
  type: "container" | "item"
): string => {
  const directClasses = generateDirectResponsiveClasses(props, type);
  const legacyClasses = generateLegacyResponsiveClasses(props, type);
  return [directClasses, legacyClasses].filter(Boolean).join(" ");
};
