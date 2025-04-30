// import 'dart:convert';

class Plant {
  final String id;
  final String name;
  final String image;
  final String userId;
  final PlantHealth? plantHealth;
  final Classification? classification;
  final String status;
  final bool slaCompliantClient;
  final bool slaCompliantSystem;
  final int createdDatetime;
  final int finishedDatetime;
  final double? temperature;
  final double? soilHumidity;

  Plant({
    required this.id,
    required this.name,
    required this.image,
    required this.userId,
    required this.plantHealth,
    required this.classification,
    required this.status,
    required this.slaCompliantClient,
    required this.slaCompliantSystem,
    required this.createdDatetime,
    required this.finishedDatetime,
    this.temperature,
    this.soilHumidity,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      userId: json['userId'] ?? '',
      plantHealth: json['plantHealth'] != null
          ? PlantHealth.fromJson(json['plantHealth'])
          : null,
      classification: json['classification'] != null
          ? Classification.fromJson(json['classification'])
          : null,
      status: json['status'] ?? '',
      slaCompliantClient: json['sla_compliant_client'] ?? false,
      slaCompliantSystem: json['sla_compliant_system'] ?? false,
      createdDatetime: json['created_datetime'] ?? 0,
      finishedDatetime: json['finished_datetime'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Plant(name: $name, id: $id)';
  }
}

class PlantHealth {
  final HealthStatus? isHealthy;
  final Disease? disease;

  PlantHealth({required this.isHealthy, required this.disease});

  factory PlantHealth.fromJson(Map<String, dynamic> json) {
    return PlantHealth(
      isHealthy: json['is_healthy'] != null
          ? HealthStatus.fromJson(json['is_healthy'])
          : null,
      disease:
          json['disease'] != null ? Disease.fromJson(json['disease']) : null,
    );
  }
}

class HealthStatus {
  final double probability;
  final bool binary;

  HealthStatus({required this.probability, required this.binary});

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      probability: json['probability']?.toDouble() ?? 0.0,
      binary: json['binary'] ?? false,
    );
  }
}

class Disease {
  final List<DiseaseSuggestion> suggestions;

  Disease({required this.suggestions});

  factory Disease.fromJson(Map<String, dynamic> json) {
    var list = json['suggestions'] as List? ?? [];
    return Disease(
      suggestions:
          list.map((item) => DiseaseSuggestion.fromJson(item)).toList(),
    );
  }
}

class DiseaseSuggestion {
  final String name;
  final double probability;
  final DiseaseDetails? details;

  DiseaseSuggestion({
    required this.name,
    required this.probability,
    required this.details,
  });

  factory DiseaseSuggestion.fromJson(Map<String, dynamic> json) {
    return DiseaseSuggestion(
      name: json['name'] ?? '',
      probability: json['probability']?.toDouble() ?? 0.0,
      details: json['details'] != null
          ? DiseaseDetails.fromJson(json['details'])
          : null,
    );
  }
}

class DiseaseDetails {
  final String description;
  final dynamic treatment;
  final String cause;
  final String url;

  DiseaseDetails({
    required this.description,
    required this.treatment,
    required this.cause,
    required this.url,
  });

  factory DiseaseDetails.fromJson(Map<String, dynamic> json) {
    return DiseaseDetails(
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
      cause: json['cause'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class Classification {
  final List<Suggestion> suggestions;

  Classification({required this.suggestions});

  factory Classification.fromJson(Map<String, dynamic> json) {
    var list = json['suggestions'] as List? ?? [];
    return Classification(
      suggestions: list.map((item) => Suggestion.fromJson(item)).toList(),
    );
  }
}

class Suggestion {
  final String id;
  final String name;
  final double probability;
  final List<SimilarImage> similarImages;
  final SuggestionDetails? details;

  Suggestion({
    required this.id,
    required this.name,
    required this.probability,
    required this.similarImages,
    required this.details,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    var list = json['similar_images'] as List? ?? [];
    return Suggestion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      probability: json['probability']?.toDouble() ?? 0.0,
      similarImages: list.map((item) => SimilarImage.fromJson(item)).toList(),
      details: json['details'] != null
          ? SuggestionDetails.fromJson(json['details'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Suggestion(name: $name, probability: $probability)';
  }
}

class SimilarImage {
  final String id;
  final String url;
  final String licenseName;
  final String licenseUrl;
  final String citation;
  final double similarity;
  final String urlSmall;

  SimilarImage({
    required this.id,
    required this.url,
    required this.licenseName,
    required this.licenseUrl,
    required this.citation,
    required this.similarity,
    required this.urlSmall,
  });

  factory SimilarImage.fromJson(Map<String, dynamic> json) {
    return SimilarImage(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      licenseName: json['license_name'] ?? '',
      licenseUrl: json['license_url'] ?? '',
      citation: json['citation'] ?? '',
      similarity: json['similarity']?.toDouble() ?? 0.0,
      urlSmall: json['url_small'] ?? '',
    );
  }
}

class SuggestionDetails {
  final String language;
  final String entityId;
  final List<String> commonNames;
  final Description? description;
  final String commonUses;
  final String bestLightCondition;
  final String bestWatering;
  final String bestSoilType;
  final String toxicity;

  SuggestionDetails({
    required this.language,
    required this.entityId,
    required this.commonNames,
    required this.description,
    required this.commonUses,
    required this.bestLightCondition,
    required this.bestWatering,
    required this.bestSoilType,
    required this.toxicity,
  });

  factory SuggestionDetails.fromJson(Map<String, dynamic> json) {
    var list = json['common_names'] as List? ?? [];
    return SuggestionDetails(
      language: json['language'] ?? '',
      entityId: json['entity_id'] ?? '',
      commonNames: list.map((item) => item.toString()).toList(),
      description: json['description'] != null
          ? Description.fromJson(json['description'])
          : null,
      commonUses: json['common_uses'] ?? '',
      bestLightCondition: json['best_light_condition'] ?? '',
      bestWatering: json['best_watering'] ?? '',
      bestSoilType: json['best_soil_type'] ?? '',
      toxicity: json['toxicity'] ?? '',
    );
  }
  @override
  String toString() {
    return 'SuggestionDetails(language: $language, entityId: $entityId, commonNames: $commonNames, '
        'description: ${description?.value}, commonUses: $commonUses, bestLightCondition: $bestLightCondition, '
        'bestWatering: $bestWatering, bestSoilType: $bestSoilType, toxicity: $toxicity)';
  }
}

class Description {
  final String value;
  final String citation;
  final String licenseName;
  final String licenseUrl;

  Description({
    required this.value,
    required this.citation,
    required this.licenseName,
    required this.licenseUrl,
  });

  factory Description.fromJson(Map<String, dynamic> json) {
    return Description(
      value: json['value'] ?? '',
      citation: json['citation'] ?? '',
      licenseName: json['license_name'] ?? '',
      licenseUrl: json['license_url'] ?? '',
    );
  }
}
