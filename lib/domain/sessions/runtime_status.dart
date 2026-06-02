class RuntimeStatus {
  const RuntimeStatus({
    required this.usage,
    required this.updatedAt,
    this.model,
    this.thinkingLevel,
    this.context,
  });

  final RuntimeModelStatus? model;
  final String? thinkingLevel;
  final RuntimeUsageStatus usage;
  final RuntimeContextStatus? context;
  final DateTime updatedAt;

  factory RuntimeStatus.fromJson(Map<String, Object?> json) {
    final modelJson = json['model'];
    final thinkingLevel = json['thinkingLevel'];
    final usageJson = json['usage'];
    final contextJson = json['context'];
    final updatedAtJson = json['updatedAt'];

    if (modelJson != null && modelJson is! Map<String, Object?> ||
        thinkingLevel != null && thinkingLevel is! String ||
        usageJson is! Map<String, Object?> ||
        contextJson != null && contextJson is! Map<String, Object?> ||
        updatedAtJson is! String) {
      throw const FormatException('Runtime status JSON is invalid.');
    }

    final updatedAt = DateTime.tryParse(updatedAtJson);
    if (updatedAt == null) {
      throw const FormatException('Runtime status JSON has invalid updatedAt.');
    }

    return RuntimeStatus(
      model: modelJson == null
          ? null
          : RuntimeModelStatus.fromJson(modelJson as Map<String, Object?>),
      thinkingLevel: thinkingLevel as String?,
      usage: RuntimeUsageStatus.fromJson(usageJson),
      context: contextJson == null
          ? null
          : RuntimeContextStatus.fromJson(contextJson as Map<String, Object?>),
      updatedAt: updatedAt,
    );
  }
}

class RuntimeModelStatus {
  const RuntimeModelStatus({
    required this.provider,
    required this.id,
    this.name,
    this.contextWindow,
    this.maxTokens,
    this.reasoning,
  });

  final String provider;
  final String id;
  final String? name;
  final int? contextWindow;
  final int? maxTokens;
  final bool? reasoning;

  String get displayName => name ?? id;

  factory RuntimeModelStatus.fromJson(Map<String, Object?> json) {
    final provider = json['provider'];
    final id = json['id'];
    final name = json['name'];
    final contextWindow = json['contextWindow'];
    final maxTokens = json['maxTokens'];
    final reasoning = json['reasoning'];

    if (provider is! String ||
        id is! String ||
        name != null && name is! String ||
        contextWindow != null && contextWindow is! int ||
        maxTokens != null && maxTokens is! int ||
        reasoning != null && reasoning is! bool) {
      throw const FormatException('Runtime model status JSON is invalid.');
    }

    return RuntimeModelStatus(
      provider: provider,
      id: id,
      name: name as String?,
      contextWindow: contextWindow as int?,
      maxTokens: maxTokens as int?,
      reasoning: reasoning as bool?,
    );
  }
}

class RuntimeUsageStatus {
  const RuntimeUsageStatus({
    required this.input,
    required this.output,
    required this.cacheRead,
    required this.cacheWrite,
    required this.cost,
  });

  final int input;
  final int output;
  final int cacheRead;
  final int cacheWrite;
  final RuntimeCostStatus cost;

  factory RuntimeUsageStatus.fromJson(Map<String, Object?> json) {
    final cost = json['cost'];
    if (cost is! Map<String, Object?>) {
      throw const FormatException('Runtime usage status JSON is invalid.');
    }

    return RuntimeUsageStatus(
      input: _requiredInt(json['input'], 'input'),
      output: _requiredInt(json['output'], 'output'),
      cacheRead: _requiredInt(json['cacheRead'], 'cacheRead'),
      cacheWrite: _requiredInt(json['cacheWrite'], 'cacheWrite'),
      cost: RuntimeCostStatus.fromJson(cost),
    );
  }
}

class RuntimeCostStatus {
  const RuntimeCostStatus({
    required this.input,
    required this.output,
    required this.cacheRead,
    required this.cacheWrite,
    required this.total,
  });

  final double input;
  final double output;
  final double cacheRead;
  final double cacheWrite;
  final double total;

  factory RuntimeCostStatus.fromJson(Map<String, Object?> json) {
    return RuntimeCostStatus(
      input: _requiredDouble(json['input'], 'input'),
      output: _requiredDouble(json['output'], 'output'),
      cacheRead: _requiredDouble(json['cacheRead'], 'cacheRead'),
      cacheWrite: _requiredDouble(json['cacheWrite'], 'cacheWrite'),
      total: _requiredDouble(json['total'], 'total'),
    );
  }
}

class RuntimeContextStatus {
  const RuntimeContextStatus({
    required this.contextWindow,
    this.tokens,
    this.percent,
  });

  final int? tokens;
  final int contextWindow;
  final double? percent;

  factory RuntimeContextStatus.fromJson(Map<String, Object?> json) {
    final tokens = json['tokens'];
    final percent = json['percent'];
    if (tokens != null && tokens is! int ||
        percent != null && percent is! num) {
      throw const FormatException('Runtime context status JSON is invalid.');
    }

    return RuntimeContextStatus(
      tokens: tokens as int?,
      contextWindow: _requiredInt(json['contextWindow'], 'contextWindow'),
      percent: (percent as num?)?.toDouble(),
    );
  }
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('Runtime status field $field is not an int.');
}

double _requiredDouble(Object? value, String field) {
  if (value is num) return value.toDouble();
  throw FormatException('Runtime status field $field is not a number.');
}
