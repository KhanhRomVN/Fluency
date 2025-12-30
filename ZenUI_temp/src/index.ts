// ==================== COMPONENTS ====================

// Accordion
export {
  default as Accordion,
  AccordionContext,
} from "./presentation/components/package/components/accordion/Accordion";
export { default as AccordionList } from "./presentation/components/package/components/accordion/AccordionList";
export { default as AccordionItem } from "./presentation/components/package/components/accordion/AccordionItem";
export { default as AccordionTrigger } from "./presentation/components/package/components/accordion/AccordionTrigger";
export { default as AccordionContent } from "./presentation/components/package/components/accordion/AccordionContent";
export type {
  AccordionProps,
  AccordionListProps,
  AccordionItemProps,
  AccordionTriggerProps,
  AccordionContentProps,
  AccordionType,
  AccordionContextValue,
} from "./presentation/components/package/components/accordion/Accordion.types";
export {
  isValidValue,
  getItemValue,
} from "./presentation/components/package/components/accordion/Accordion.utils";

// Avatar
export { default as Avatar } from "./presentation/components/package/components/avatar/Avatar";
export type {
  AvatarProps,
  AvatarSize,
  AvatarShape,
  AvatarIcon,
  AvatarFallbackType,
  AvatarSizeConfig,
  AvatarIconDotConfig,
} from "./presentation/components/package/components/avatar/Avatar.types";
export {
  getAvatarSizeStyles,
  getDotSize,
  getDotPosition,
  getDotIconSize,
  getInitials,
  getFallbackBackground,
  getDefaultDotBgColor,
  validateAvatarProps,
  mergeStyles as mergeAvatarStyles,
} from "./presentation/components/package/components/avatar/Avatar.utils";

// Badge
export { default as Badge } from "./presentation/components/package/components/badge/Badge";
export type {
  BadgeProps,
  BadgeSize,
  BadgeVariant,
  BadgeSizeConfig,
  BadgeVariantStyles,
} from "./presentation/components/package/components/badge/Badge.types";
export {
  getBadgeSizeStyles,
  getBadgeVariantStyles,
  shouldShowDot,
  validateBadgeProps,
  mergeStyles as mergeBadgeStyles,
} from "./presentation/components/package/components/badge/Badge.utils";

// Breadcrumb
export { default as Breadcrumb } from "./presentation/components/package/components/breadcumb/Breadcrumb";
export { default as BreadcrumbItem } from "./presentation/components/package/components/breadcumb/BreadcrumbItem";
export type {
  BreadcrumbProps,
  BreadcrumbItemProps,
} from "./presentation/components/package/components/breadcumb/Breadcrumb.types";

// Button
export { default as Button } from "./presentation/components/package/components/button/Button";
export type {
  ButtonProps,
  ButtonSize,
  ButtonWidth,
  ButtonAlign,
  ButtonIconPosition,
  ButtonIcon,
  ButtonSizeConfig,
  ButtonStyleState,
} from "./presentation/components/package/components/button/Button.types";
export {
  getButtonSizeStyles,
  getIconSize,
  getLoadingSpinner,
  shouldShowIcon,
  getContentAlignment,
  parseClassName,
  validateButtonProps,
  mergeStyles as mergeButtonStyles,
} from "./presentation/components/package/components/button/Button.utils";

// Card
export { default as Card } from "./presentation/components/package/components/card/Card";
export { default as CardHeader } from "./presentation/components/package/components/card/CardHeader";
export { default as CardBody } from "./presentation/components/package/components/card/CardBody";
export { default as CardFooter } from "./presentation/components/package/components/card/CardFooter";
export type {
  CardProps,
  CardHeaderProps,
  CardBodyProps,
  CardFooterProps,
} from "./presentation/components/package/components/card/Card.types";

// Carousel
export {
  default as Carousel,
  CarouselContext,
} from "./presentation/components/package/components/carousel/Carousel";
export { default as CarouselItem } from "./presentation/components/package/components/carousel/CarouselItem";
export type {
  CarouselProps,
  CarouselItemProps,
  CarouselContextValue,
} from "./presentation/components/package/components/carousel/Carousel.types";

// Checkbox
export { default as Checkbox } from "./presentation/components/package/components/checkbox/Checkbox";
export type { CheckboxProps } from "./presentation/components/package/components/checkbox/Checkbox.types";

// CodeBlock
export { default as CodeBlock } from "./presentation/components/package/components/codeblock/CodeBlock";
export type { CodeBlockThemeData } from "./presentation/components/package/components/codeblock/CodeBlock.types";
export { CodeBlockThemeLoader } from "./presentation/components/package/components/codeblock/CodeBlock.themeLoader";

// ColorPicker
export { default as ColorPicker } from "./presentation/components/package/components/colorpicker/ColorPicker";
export type { ColorPickerProps } from "./presentation/components/package/components/colorpicker/ColorPicker.types";
export { DEFAULT_COLORS } from "./presentation/components/package/components/colorpicker/ColorPicker.utils";

// Combobox
export { default as Combobox } from "./presentation/components/package/components/combobox/Combobox";
export { default as ComboboxItem } from "./presentation/components/package/components/combobox/ComboboxItem";
export type {
  ComboboxProps,
  ComboboxItemProps,
} from "./presentation/components/package/components/combobox/Combobox.types";

// DateTimePicker
export { default as DateTimePicker } from "./presentation/components/package/components/datetimepicker/DateTimePicker";
export type { DateTimePickerProps } from "./presentation/components/package/components/datetimepicker/DateTimePicker.types";

// Divider
export { default as Divider } from "./presentation/components/package/components/divider/Divider";
export type { DividerProps } from "./presentation/components/package/components/divider/Divider.types";

// DndZone
export { default as DndZone } from "./presentation/components/package/components/dndzone/DndZone";
export type {
  DndZoneProps,
  FileWithPreview,
} from "./presentation/components/package/components/dndzone/DndZone.types";

// Drawer
export { default as Drawer } from "./presentation/components/package/components/drawer/Drawer";
export type {
  DrawerProps,
  DrawerDirection,
  DrawerAnimationType,
  DrawerSize,
  DrawerVariants,
} from "./presentation/components/package/components/drawer/Drawer.types";
export {
  parseSize,
  getDrawerVariants,
  overlayVariants,
} from "./presentation/components/package/components/drawer/Drawer.utils";

// Dropdown
export {
  default as Dropdown,
  DropdownContext,
} from "./presentation/components/package/components/dropdown/Dropdown";
export { default as DropdownTrigger } from "./presentation/components/package/components/dropdown/DropdownTrigger";
export { default as DropdownContent } from "./presentation/components/package/components/dropdown/DropdownContent";
export { default as DropdownItem } from "./presentation/components/package/components/dropdown/DropdownItem";
export type {
  DropdownProps,
  DropdownTriggerProps,
  DropdownContentProps,
  DropdownItemProps,
  DropdownContextValue,
} from "./presentation/components/package/components/dropdown/Dropdown.types";

// Input
export { default as Input } from "./presentation/components/package/components/input/Input";
export type { InputProps } from "./presentation/components/package/components/input/Input.types";

// InputOTP
export { default as InputOTP } from "./presentation/components/package/components/input-otp/InputOTP";
export type { InputOTPProps } from "./presentation/components/package/components/input-otp/InputOTP.types";

// Modal
export { default as Modal } from "./presentation/components/package/components/modal/Modal";
export type { ModalProps } from "./presentation/components/package/components/modal/Modal.types";

// Pagination
export { default as Pagination } from "./presentation/components/package/components/pagination/Pagination";
export type { PaginationProps } from "./presentation/components/package/components/pagination/Pagination.types";

// Tab
export {
  default as Tab,
  TabContext,
} from "./presentation/components/package/components/tab/Tab";
export { default as TabItem } from "./presentation/components/package/components/tab/TabItem";
export type {
  TabProps,
  TabItemProps,
  TabContextValue,
} from "./presentation/components/package/components/tab/Tab.types";

// Table
export { default as Table } from "./presentation/components/package/components/table/Table";
export { default as TableHeader } from "./presentation/components/package/components/table/TableHeader";
export { default as TableBody } from "./presentation/components/package/components/table/TableBody";
export { default as TableFooter } from "./presentation/components/package/components/table/TableFooter";
export { default as TableRow } from "./presentation/components/package/components/table/TableRow";
export { default as TableCell } from "./presentation/components/package/components/table/TableCell";
export { default as HeaderCell } from "./presentation/components/package/components/table/HeaderCell";
export type {
  TableProps,
  TableHeaderProps,
  TableBodyProps,
  TableFooterProps,
  TableRowProps,
  TableCellProps,
  HeaderCellProps,
} from "./presentation/components/package/components/table/Table.types";

// Textarea
export { default as Textarea } from "./presentation/components/package/components/textarea/Textarea";
export type { TextareaProps } from "./presentation/components/package/components/textarea/Textarea.types";

// Tree
export { default as Tree } from "./presentation/components/package/components/tree/Tree";
export type {
  TreeProps,
  TreeNode,
} from "./presentation/components/package/components/tree/Tree.types";

// ==================== LAYOUTS ====================

// Flex
// Grid
export { default as Grid } from "./presentation/components/package/layouts/grid/Grid";
export { default as GridItem } from "./presentation/components/package/layouts/grid/GridItem";
export type {
  GridProps,
  GridItemProps,
} from "./presentation/components/package/layouts/grid/Grid.types";

// Kanban
export { default as Kanban } from "./presentation/components/package/layouts/kanban/Kanban";
export type { KanbanProps } from "./presentation/components/package/layouts/kanban/Kanban.types";

// Masonry
export { default as Masonry } from "./presentation/components/package/layouts/masonry/Masonry";
export type { MasonryProps } from "./presentation/components/package/layouts/masonry/Masonry.types";

// Sidebar
export { default as SidebarLayout } from "./presentation/components/package/layouts/sidebar/SidebarLayout";
export type { SidebarLayoutProps } from "./presentation/components/package/layouts/sidebar/SidebarLayout.types";

// Split
export { default as SplitLayout } from "./presentation/components/package/layouts/split/SplitLayout";
export { default as SplitLayoutItem } from "./presentation/components/package/layouts/split/SplitLayoutItem";
export type {
  SplitLayoutProps,
  SplitLayoutItemProps,
} from "./presentation/components/package/layouts/split/SplitLayout.types";
