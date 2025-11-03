import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:csv/csv.dart';

class DynamicTranslations extends Translations {
  final Map<String, Map<String, String>> _keys = {};

  DynamicTranslations() {
    // Load translations from JSON at initialization
    _loadTranslationsFromJson();
  }

  @override
  Map<String, Map<String, String>> get keys => _keys;

  // Load translations from JSON file
  Future<void> _loadTranslationsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/lang/translations.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      jsonMap.forEach((lang, translations) {
        _keys[lang] = Map<String, String>.from(translations);
      });
    } catch (e) {
      print('Error loading translations from JSON: $e');
    }
  }

  // Add translations from external sources (e.g., CSV or manual additions)
  void addTranslations(Map<String, Map<String, String>> map) {
    map.forEach((lang, translations) {
      if (_keys.containsKey(lang)) {
        _keys[lang]?.addAll(translations); // Merge with existing translations
      } else {
        _keys[lang] = translations; // Add new language
      }
    });
  }

  // Add translations from CSV content for a specific language
  void addCsvTranslations(String langCode, String csvContent) {
    final parsedMap = _parseCsvToMap(csvContent);
    if (_keys.containsKey(langCode)) {
      _keys[langCode]?.addAll(parsedMap); // Merge with existing translations
    } else {
      _keys[langCode] = parsedMap; // Add new language
    }
  }

  // Parse translations from CSV content
  Map<String, String> _parseCsvToMap(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    final map = <String, String>{};

    for (var row in rows) {
      if (row.length >= 2) {
        map[row[0].toString()] = row[1].toString();
      }
    }
    return map;
  }
}