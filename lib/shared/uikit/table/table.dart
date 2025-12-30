import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppTableColumn {
  final String label;
  final bool numeric;
  final Function(int columnIndex, bool ascending)? onSort;

  const AppTableColumn({
    required this.label,
    this.numeric = false,
    this.onSort,
  });
}

class AppTable extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  final List<AppTableColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
              appColors?.background ?? Colors.grey[200]),
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: columns.map((col) {
            return DataColumn(
              label: Text(
                col.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: col.numeric,
              onSort: col.onSort,
            );
          }).toList(),
          rows: rows,
        ),
      ),
    );
  }
}
