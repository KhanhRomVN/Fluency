import 'package:fluency/shared/uikit/accordion/accordion.dart';
import 'package:fluency/shared/uikit/avatar/avatar.dart';
import 'package:fluency/shared/uikit/badge/badge.dart';
import 'package:fluency/shared/uikit/breadcrumb/breadcrumb.dart';
import 'package:fluency/shared/uikit/button/button.dart';
import 'package:fluency/shared/uikit/card/card.dart';
import 'package:fluency/shared/uikit/carousel/carousel.dart';
import 'package:fluency/shared/uikit/checkbox/checkbox.dart';
import 'package:fluency/shared/uikit/divider/divider.dart';
import 'package:fluency/shared/uikit/drawer/drawer.dart';
import 'package:fluency/shared/uikit/dropdown/dropdown.dart';
import 'package:fluency/shared/uikit/input/input.dart';
import 'package:fluency/shared/uikit/modal/modal.dart';
import 'package:fluency/shared/uikit/pagination/pagination.dart';
import 'package:fluency/shared/uikit/tab/tab.dart';
import 'package:fluency/shared/uikit/table/table.dart';
import 'package:fluency/shared/uikit/textarea/textarea.dart';
import 'package:flutter/material.dart' hide Badge;

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  // Checkbox State
  bool _checkboxValue = false;

  // Pagination State
  int _currentPage = 1;

  // Dropdown
  String _dropdownValue = 'Option 1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Component Gallery")),
      drawer: AppDrawer(
        child: Column(
          children: [
            const AppDrawerHeader(child: Center(child: Text("Drawer Header"))),
            ListTile(title: const Text("Item 1"), onTap: () {}),
            ListTile(title: const Text("Item 2"), onTap: () {}),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Buttons"),
            Wrap(spacing: 8, children: [
              Button(
                  label: "Primary",
                  onPressed: () {},
                  backgroundColor: Colors.blue),
              Button(
                  label: "Secondary",
                  onPressed: () {},
                  backgroundColor: Colors.grey),
              const Button(label: "Loading", loading: true),
              const Button(label: "Disabled", disabled: true),
              const Button(icon: Icon(Icons.add), size: 100), // Icon only
            ]),
            _section("Accordion"),
            const Accordion(
              children: [
                AccordionItem(value: "1", children: [
                  AccordionTrigger(child: Text("Item 1")),
                  AccordionContent(child: Text("Content 1"))
                ]),
                AccordionItem(value: "2", children: [
                  AccordionTrigger(child: Text("Item 2")),
                  AccordionContent(child: Text("Content 2"))
                ]),
              ],
            ),
            _section("Avatar"),
            const Row(children: [
              Avatar(name: "John Doe"),
              SizedBox(width: 8),
              Avatar(name: "Jane Smith", status: AvatarStatus.online),
              SizedBox(width: 8),
              Avatar(
                  src: "https://i.pravatar.cc/150", status: AvatarStatus.busy),
            ]),
            _section("Badge"),
            const Wrap(spacing: 8, children: [
              Badge(text: "Primary", variant: BadgeVariant.primary),
              Badge(text: "Secondary", variant: BadgeVariant.secondary),
              Badge(text: "Outline", variant: BadgeVariant.outline),
              Badge(text: "Destructive", variant: BadgeVariant.destructive),
              Badge(text: "Dot", dot: true, variant: BadgeVariant.primary),
            ]),
            _section("Breadcrumb"),
            Breadcrumb(items: [
              BreadcrumbItem(text: "Home", href: "/"),
              BreadcrumbItem(text: "Components", href: "/components"),
              const BreadcrumbItem(text: "Breadcrumb", active: true),
            ]),
            _section("Card"),
            const AppCard(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCardHeader(child: Text("Card Title")),
                  AppCardBody(child: Text("This is the card body content.")),
                  AppCardFooter(child: Text("Footer Info")),
                ],
              ),
            ),
            _section("Carousel"),
            Carousel(
              height: 150,
              items: [
                Container(
                    color: Colors.red,
                    child: const Center(
                        child: Text("Slide 1",
                            style: TextStyle(color: Colors.white)))),
                Container(
                    color: Colors.green,
                    child: const Center(
                        child: Text("Slide 2",
                            style: TextStyle(color: Colors.white)))),
                Container(
                    color: Colors.blue,
                    child: const Center(
                        child: Text("Slide 3",
                            style: TextStyle(color: Colors.white)))),
              ],
            ),
            _section("Checkbox"),
            AppCheckbox(
              checked: _checkboxValue,
              label: "Accept Terms",
              onChanged: (v) => setState(() => _checkboxValue = v),
            ),
            _section("Divider"),
            const AppDivider(),
            _section("Dropdown"),
            AppDropdown<String>(
              items: [
                const DropdownItem(value: "Option 1", label: "Option 1"),
                const DropdownItem(value: "Option 2", label: "Option 2"),
              ],
              onSelected: (v) => setState(() => _dropdownValue = v),
              child: Button(
                  label: _dropdownValue,
                  icon: const Icon(Icons.arrow_drop_down)),
            ),
            _section("Input"),
            const AppInput(label: "Username", placeholder: "Enter username"),
            const SizedBox(height: 8),
            const AppInput(
                label: "Password",
                obscureText: true,
                placeholder: "Enter password"),
            _section("Modal"),
            Button(
                label: "Open Modal",
                onPressed: () {
                  AppModal.show(
                      context: context,
                      builder: (ctx) => AppModal(
                            title: "Example Modal",
                            children: const [Text("This is a modal content.")],
                            footer: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Button(
                                      label: "Close",
                                      onPressed: () => Navigator.pop(ctx)),
                                ]),
                          ));
                }),
            _section("Pagination"),
            AppPagination(
              currentPage: _currentPage,
              totalPages: 10,
              onPageChange: (page) => setState(() => _currentPage = page),
            ),
            _section("Tab"),
            const SizedBox(
              height: 200,
              child: AppTabs(
                tabs: [
                  AppTabItem(
                      label: "Tab 1",
                      content: Center(child: Text("Content 1"))),
                  AppTabItem(
                      label: "Tab 2",
                      content: Center(child: Text("Content 2"))),
                ],
              ),
            ),
            _section("Table"),
            AppTable(
              columns: const [
                AppTableColumn(label: "ID"),
                AppTableColumn(label: "Name"),
              ],
              rows: const [
                DataRow(cells: [DataCell(Text("1")), DataCell(Text("Alice"))]),
                DataRow(cells: [DataCell(Text("2")), DataCell(Text("Bob"))]),
              ],
            ),
            _section("Textarea"),
            const AppTextarea(
                label: "Comments", placeholder: "Enter your comments here..."),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
        ],
      ),
    );
  }
}
