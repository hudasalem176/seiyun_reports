import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final importFile = File('lib/import.dart');

  final allDartFiles =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('import.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.endsWith('.freezed.dart'),
          )
          .toList();

  final Set<String> allExports = {};

  // Base exports
  allExports.add("export 'package:flutter/material.dart';");
  allExports.add("export 'package:provider/provider.dart';");

  for (var file in allDartFiles) {
    var relativePath = file.path.substring(4).replaceAll('\\', '/');
    allExports.add("export 'package:seiyun_reports_app/$relativePath';");
  }

  // Keep any existing external package exports in import.dart just in case
  if (importFile.existsSync()) {
    for (var line in importFile.readAsLinesSync()) {
      if (line.trim().startsWith("export 'package:") &&
          !line.contains("seiyun_reports_app") &&
          !line.contains("flutter/material") &&
          !line.contains("provider/provider")) {
        allExports.add(line.trim());
      }
    }
  }

  importFile.writeAsStringSync('${allExports.join('\n')}\n');

  for (var file in allDartFiles) {
    if (file.path == importFile.path) continue;

    List<String> lines = file.readAsLinesSync();

    // Check if it's a part file
    bool isPart = lines.any((l) => l.trim().startsWith('part of '));
    if (isPart) continue;

    List<String> newLines = [];
    bool addedImport = false;

    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        // Skip relative internal imports (don't start with package/dart)
        if (!trimmed.contains('package:') && !trimmed.contains('dart:')) {
          continue;
        }
        // Skip absolute internal imports
        if (trimmed.contains('package:seiyun_reports_app/') &&
            !trimmed.contains('package:seiyun_reports_app/import.dart')) {
          continue;
        }
        // Skip existing universal imports
        if (trimmed == "import 'package:flutter/material.dart';" ||
            trimmed == "import 'package:provider/provider.dart';") {
          continue;
        }
        // It's some external package like firebase or geolocator. Keep it!
        newLines.add(line);
      } else {
        // Add universal import right before the first non-import line / non-blank line
        if (!addedImport &&
            (trimmed.startsWith('class ') ||
                trimmed.startsWith('const ') ||
                trimmed.startsWith('final ') ||
                trimmed.startsWith('void ') ||
                trimmed.startsWith('Widget ') ||
                trimmed.startsWith('enum ') ||
                trimmed.startsWith('mixins ') ||
                trimmed.startsWith('extension ') ||
                trimmed.startsWith('part ') ||
                trimmed.startsWith('@') ||
                trimmed.isNotEmpty)) {
          newLines.add("import 'package:seiyun_reports_app/import.dart';");
          addedImport = true;
          newLines.add(line);
        } else {
          newLines.add(line);
        }
      }
    }

    if (!addedImport && newLines.isNotEmpty) {
      newLines.insert(0, "import 'package:seiyun_reports_app/import.dart';");
    }

    // Deduplicate universal import if any overlap occurred
    var deduped = <String>[];
    bool hasUniversal = false;
    for (var l in newLines) {
      if (l.trim() == "import 'package:seiyun_reports_app/import.dart';") {
        if (!hasUniversal) {
          deduped.add(l);
          hasUniversal = true;
        }
      } else {
        deduped.add(l);
      }
    }

    file.writeAsStringSync('${deduped.join('\n')}\n');
  }
  // ignore: avoid_print
  print("Refactoring complete.");
}
