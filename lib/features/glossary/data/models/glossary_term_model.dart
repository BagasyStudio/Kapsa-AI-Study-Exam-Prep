class GlossaryTermModel {
  final String id;
  final String courseId;
  final String userId;
  final String term;
  final String definition;
  final List<String> relatedTerms;
  final String? sourceMaterialId;
  final DateTime? createdAt;

  const GlossaryTermModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.term,
    required this.definition,
    this.relatedTerms = const [],
    this.sourceMaterialId,
    this.createdAt,
  });

  factory GlossaryTermModel.fromJson(Map<String, dynamic> json) {
    final rawRelated = json['related_terms'];
    List<String> related = [];
    if (rawRelated is List) {
      related = rawRelated.map((e) => e.toString()).toList();
    }

    return GlossaryTermModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      term: json['term'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      relatedTerms: related,
      sourceMaterialId: json['source_material_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
