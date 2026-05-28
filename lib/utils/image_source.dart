import 'dart:io';

import 'package:flutter/material.dart';

bool isNetworkImageUrl(String value) {
  final trimmed = value.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

ImageProvider? resolveImageProvider(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (isNetworkImageUrl(trimmed)) {
    return NetworkImage(trimmed);
  }

  final file = File(trimmed);
  if (file.existsSync()) {
    return FileImage(file);
  }

  return null;
}

bool hasRenderableImage(String value) {
  return resolveImageProvider(value) != null;
}
