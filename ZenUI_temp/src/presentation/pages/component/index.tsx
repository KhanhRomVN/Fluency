import { useLocation } from "react-router-dom";
import ComponentSidebar from "./components/ComponentSidebar";
import AvatarSection from "./components/Section/AvatarSection";
import BadgeSection from "./components/Section/BadgeSection";
import BreadcrumbSection from "./components/Section/BreadcrumbSection";
import ButtonSection from "./components/Section/ButtonSection";
import CardSection from "./components/Section/CardSection";
import CheckboxSection from "./components/Section/CheckboxSection";
import CodeBlockSection from "./components/Section/CodeBlockSection";
import ColorPickerSection from "./components/Section/ColorPickerSection";
import DividerSection from "./components/Section/DividerSection";
import DndZoneSection from "./components/Section/DndZoneSection";
import DrawerSection from "./components/Section/DrawerSection";
import DropdownSection from "./components/Section/DropdownSection";
import InputSection from "./components/Section/InputSection";
import InputOTPSection from "./components/Section/InputOTPSection";
import ModalSection from "./components/Section/ModalSection";
import PaginationSection from "./components/Section/PaginationSection";
import TableSection from "./components/Section/TableSection";
import TabSection from "./components/Section/TabSection";
import AccordionSection from "./components/Section/AccordionSection";
import CarouselSection from "./components/Section/CarouselSection";
import TreeSection from "./components/Section/TreeSection";
import TextareaSection from "./components/Section/TextareaSection";

const ComponentsPage = () => {
  const location = useLocation();
  const section =
    new URLSearchParams(location.search).get("section") || "drawer";

  const renderSection = () => {
    switch (section) {
      case "avatar":
        return <AvatarSection />;
      case "accordion":
        return <AccordionSection />;
      case "badge":
        return <BadgeSection />;
      case "breadcrumb":
        return <BreadcrumbSection />;
      case "button":
        return <ButtonSection />;
      case "card":
        return <CardSection />;
      case "carousel":
        return <CarouselSection />;
      case "checkbox":
        return <CheckboxSection />;
      case "codeblock":
        return <CodeBlockSection />;
      case "colorpicker":
        return <ColorPickerSection />;
      case "divider":
        return <DividerSection />;
      case "dndzone":
        return <DndZoneSection />;
      case "drawer":
        return <DrawerSection />;
      case "dropdown":
        return <DropdownSection />;
      case "input":
        return <InputSection />;
      case "input-otp":
        return <InputOTPSection />;
      case "modal":
        return <ModalSection />;
      case "pagination":
        return <PaginationSection />;
      case "table":
        return <TableSection />;
      case "tab":
        return <TabSection />;
      case "textarea":
        return <TextareaSection />;
      case "tree":
        return <TreeSection />;
      default:
        return <DrawerSection />;
    }
  };

  return (
    <div className="flex h-full relative">
      <ComponentSidebar />
      <main className="flex-1 overflow-y-auto p-8 pr-64" id="main-content">
        {renderSection()}
      </main>
    </div>
  );
};

export default ComponentsPage;
