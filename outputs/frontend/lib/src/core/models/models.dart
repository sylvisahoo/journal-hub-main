import 'package:flutter/foundation.dart';

@immutable
class User {
  final String userId;
  final String fullName;
  final String email;
  final String accountStatus;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.accountStatus,
  });

  User copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? accountStatus,
  }) {
    return User(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}

@immutable
class Category {
  final String categoryId;
  final String name;

  const Category({
    required this.categoryId,
    required this.name,
  });
}

@immutable
class Tag {
  final String tagId;
  final String name;

  const Tag({
    required this.tagId,
    required this.name,
  });
}

@immutable
class JournalEntry {
  final String journalId;
  final String userId;
  final String? categoryId;
  final String title;
  final String content;
  final DateTime entryDate;
  final List<String> tagIds;
  final int wordCount;
  final bool isPrivate;
  final int versionNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.journalId,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.content,
    required this.entryDate,
    required this.tagIds,
    required this.wordCount,
    required this.isPrivate,
    required this.versionNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  JournalEntry copyWith({
    String? journalId,
    String? userId,
    String? categoryId,
    String? title,
    String? content,
    DateTime? entryDate,
    List<String>? tagIds,
    int? wordCount,
    bool? isPrivate,
    int? versionNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      journalId: journalId ?? this.journalId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      tagIds: tagIds ?? this.tagIds,
      wordCount: wordCount ?? this.wordCount,
      isPrivate: isPrivate ?? this.isPrivate,
      versionNumber: versionNumber ?? this.versionNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class AnalyticsData {
  final int writingStreak;
  final int totalEntries;
  final int totalWords;
  final Map<DateTime, int> heatmapData;
  final Map<String, int> categoryDistribution;
  final List<int> monthlyWords;

  const AnalyticsData({
    required this.writingStreak,
    required this.totalEntries,
    required this.totalWords,
    required this.heatmapData,
    required this.categoryDistribution,
    required this.monthlyWords,
  });
}

@immutable
class ExportJob {
  final String exportId;
  final String format;
  final String status; // Pending, Processing, Completed, Failed
  final DateTime requestedAt;
  final String? downloadUrl;

  const ExportJob({
    required this.exportId,
    required this.format,
    required this.status,
    required this.requestedAt,
    this.downloadUrl,
  });

  ExportJob copyWith({
    String? exportId,
    String? format,
    String? status,
    DateTime? requestedAt,
    String? downloadUrl,
  }) {
    return ExportJob(
      exportId: exportId ?? this.exportId,
      format: format ?? this.format,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
