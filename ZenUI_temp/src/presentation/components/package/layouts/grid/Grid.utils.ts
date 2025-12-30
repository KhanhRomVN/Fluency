import { GridProps, GridItemProps } from "./Grid.types";

/**
 * Generate CSS classes for grid container
 */
export const generateGridClasses = (props: GridProps): string => {
  const classes: string[] = [];

  // Grid display
  classes.push(props.inline ? "inline-grid" : "grid");

  // Auto flow
  if (props.autoFlow) {
    const flowMap: Record<string, string> = {
      row: "grid-flow-row",
      column: "grid-flow-col",
      dense: "grid-flow-dense",
      "row dense": "grid-flow-row-dense",
      "column dense": "grid-flow-col-dense",
    };
    classes.push(flowMap[props.autoFlow]);
  }

  // Justify items
  if (props.justifyItems) {
    const justifyItemsMap: Record<string, string> = {
      start: "justify-items-start",
      end: "justify-items-end",
      center: "justify-items-center",
      stretch: "justify-items-stretch",
    };
    classes.push(justifyItemsMap[props.justifyItems]);
  }

  // Align items
  if (props.alignItems) {
    const alignItemsMap: Record<string, string> = {
      start: "items-start",
      end: "items-end",
      center: "items-center",
      stretch: "items-stretch",
      baseline: "items-baseline",
    };
    classes.push(alignItemsMap[props.alignItems]);
  }

  // Justify content
  if (props.justifyContent) {
    const justifyContentMap: Record<string, string> = {
      start: "justify-start",
      end: "justify-end",
      center: "justify-center",
      stretch: "justify-stretch",
      "space-between": "justify-between",
      "space-around": "justify-around",
      "space-evenly": "justify-evenly",
    };
    classes.push(justifyContentMap[props.justifyContent]);
  }

  // Align content
  if (props.alignContent) {
    const alignContentMap: Record<string, string> = {
      start: "content-start",
      end: "content-end",
      center: "content-center",
      stretch: "content-stretch",
      "space-between": "content-between",
      "space-around": "content-around",
      "space-evenly": "content-evenly",
    };
    classes.push(alignContentMap[props.alignContent]);
  }

  return classes.filter(Boolean).join(" ");
};

/**
 * Generate CSS classes for grid item
 */
export const generateGridItemClasses = (props: GridItemProps): string => {
  const classes: string[] = [];

  // Column span
  if (props.colSpan !== undefined) {
    if (props.colSpan === "auto") {
      classes.push("col-auto");
    } else if (props.colSpan === "full") {
      classes.push("col-span-full");
    } else if (typeof props.colSpan === "number") {
      classes.push(`col-span-${props.colSpan}`);
    }
  }

  // Row span
  if (props.rowSpan !== undefined) {
    if (props.rowSpan === "auto") {
      classes.push("row-auto");
    } else if (props.rowSpan === "full") {
      classes.push("row-span-full");
    } else if (typeof props.rowSpan === "number") {
      classes.push(`row-span-${props.rowSpan}`);
    }
  }

  // Column start
  if (props.colStart !== undefined) {
    if (props.colStart === "auto") {
      classes.push("col-start-auto");
    } else if (typeof props.colStart === "number") {
      classes.push(`col-start-${props.colStart}`);
    }
  }

  // Column end
  if (props.colEnd !== undefined) {
    if (props.colEnd === "auto") {
      classes.push("col-end-auto");
    } else if (typeof props.colEnd === "number") {
      classes.push(`col-end-${props.colEnd}`);
    }
  }

  // Row start
  if (props.rowStart !== undefined) {
    if (props.rowStart === "auto") {
      classes.push("row-start-auto");
    } else if (typeof props.rowStart === "number") {
      classes.push(`row-start-${props.rowStart}`);
    }
  }

  // Row end
  if (props.rowEnd !== undefined) {
    if (props.rowEnd === "auto") {
      classes.push("row-end-auto");
    } else if (typeof props.rowEnd === "number") {
      classes.push(`row-end-${props.rowEnd}`);
    }
  }

  // Justify self
  if (props.justifySelf) {
    const justifySelfMap: Record<string, string> = {
      auto: "justify-self-auto",
      start: "justify-self-start",
      end: "justify-self-end",
      center: "justify-self-center",
      stretch: "justify-self-stretch",
    };
    classes.push(justifySelfMap[props.justifySelf]);
  }

  // Align self
  if (props.alignSelf) {
    const alignSelfMap: Record<string, string> = {
      auto: "self-auto",
      start: "self-start",
      end: "self-end",
      center: "self-center",
      stretch: "self-stretch",
      baseline: "self-baseline",
    };
    classes.push(alignSelfMap[props.alignSelf]);
  }

  // Order
  if (props.order !== undefined) {
    classes.push(`order-${props.order}`);
  }

  return classes.filter(Boolean).join(" ");
};

/**
 * Generate inline styles for grid container
 */
export const generateGridStyles = (props: GridProps): React.CSSProperties => {
  const styles: React.CSSProperties = {};

  // Grid template columns
  if (props.columns !== undefined) {
    if (typeof props.columns === "number") {
      styles.gridTemplateColumns = `repeat(${props.columns}, minmax(0, 1fr))`;
    } else {
      styles.gridTemplateColumns = props.columns;
    }
  }

  // Grid template rows
  if (props.rows !== undefined) {
    if (typeof props.rows === "number") {
      styles.gridTemplateRows = `repeat(${props.rows}, minmax(0, 1fr))`;
    } else {
      styles.gridTemplateRows = props.rows;
    }
  }

  // Auto columns
  if (props.autoColumns !== undefined) {
    styles.gridAutoColumns = props.autoColumns;
  }

  // Auto rows
  if (props.autoRows !== undefined) {
    styles.gridAutoRows = props.autoRows;
  }

  // Gap
  if (props.gap !== undefined) {
    if (typeof props.gap === "number") {
      styles.gap = `${props.gap}px`;
    } else {
      styles.gap = props.gap;
    }
  }

  // Column gap
  if (props.columnGap !== undefined) {
    if (typeof props.columnGap === "number") {
      styles.columnGap = `${props.columnGap}px`;
    } else {
      styles.columnGap = props.columnGap;
    }
  }

  // Row gap
  if (props.rowGap !== undefined) {
    if (typeof props.rowGap === "number") {
      styles.rowGap = `${props.rowGap}px`;
    } else {
      styles.rowGap = props.rowGap;
    }
  }

  return styles;
};

/**
 * Generate inline styles for grid item
 */
export const generateGridItemStyles = (
  props: GridItemProps
): React.CSSProperties => {
  const styles: React.CSSProperties = {};

  // Note: Most grid item properties are handled via classes
  // This function is here for consistency and future extensibility

  return styles;
};

/**
 * Generate responsive classes for grid container
 */
export const generateResponsiveClasses = (
  props: GridProps | GridItemProps,
  type: "container" | "item"
): string => {
  const classes: string[] = [];

  if ("responsive" in props && props.responsive) {
    const responsive = props.responsive;

    Object.entries(responsive).forEach(([breakpoint, breakpointProps]) => {
      const prefix = breakpoint === "xs" ? "" : `${breakpoint}:`;

      if (type === "container") {
        const containerProps = breakpointProps as GridProps;

        // Auto flow
        if (containerProps.autoFlow) {
          const flowMap: Record<string, string> = {
            row: "grid-flow-row",
            column: "grid-flow-col",
            dense: "grid-flow-dense",
            "row dense": "grid-flow-row-dense",
            "column dense": "grid-flow-col-dense",
          };
          classes.push(`${prefix}${flowMap[containerProps.autoFlow]}`);
        }

        // Justify items
        if (containerProps.justifyItems) {
          const justifyItemsMap: Record<string, string> = {
            start: "justify-items-start",
            end: "justify-items-end",
            center: "justify-items-center",
            stretch: "justify-items-stretch",
          };
          classes.push(
            `${prefix}${justifyItemsMap[containerProps.justifyItems]}`
          );
        }

        // Align items
        if (containerProps.alignItems) {
          const alignItemsMap: Record<string, string> = {
            start: "items-start",
            end: "items-end",
            center: "items-center",
            stretch: "items-stretch",
            baseline: "items-baseline",
          };
          classes.push(`${prefix}${alignItemsMap[containerProps.alignItems]}`);
        }
      } else {
        const itemProps = breakpointProps as GridItemProps;

        // Column span
        if (itemProps.colSpan !== undefined) {
          if (itemProps.colSpan === "auto") {
            classes.push(`${prefix}col-auto`);
          } else if (itemProps.colSpan === "full") {
            classes.push(`${prefix}col-span-full`);
          } else if (typeof itemProps.colSpan === "number") {
            classes.push(`${prefix}col-span-${itemProps.colSpan}`);
          }
        }

        // Row span
        if (itemProps.rowSpan !== undefined) {
          if (itemProps.rowSpan === "auto") {
            classes.push(`${prefix}row-auto`);
          } else if (itemProps.rowSpan === "full") {
            classes.push(`${prefix}row-span-full`);
          } else if (typeof itemProps.rowSpan === "number") {
            classes.push(`${prefix}row-span-${itemProps.rowSpan}`);
          }
        }

        // Order
        if (itemProps.order !== undefined) {
          classes.push(`${prefix}order-${itemProps.order}`);
        }
      }
    });
  }

  return classes.join(" ");
};
