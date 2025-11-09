// Modelos para o sistema de Rifa Digital
import 'package:equatable/equatable.dart';

/// Modelo para participação na rifa
class RifaParticipacao extends Equatable {
  final String id;
  final String userId;
  final String videoId;
  final List<int> numerosGerados;
  final DateTime dataParticipacao;
  final bool ativo;

  const RifaParticipacao({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.numerosGerados,
    required this.dataParticipacao,
    this.ativo = true,
  });

  factory RifaParticipacao.fromJson(Map<String, dynamic> json) {
    return RifaParticipacao(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      numerosGerados: List<int>.from(json['numeros_gerados'] as List),
      dataParticipacao: DateTime.parse(json['data_participacao'] as String),
      ativo: true, // Valor padrão já que a coluna não existe no banco
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'numeros_gerados': numerosGerados,
      'data_participacao': dataParticipacao.toIso8601String(),
      'ativo': ativo,
    };
  }

  @override
  List<Object?> get props => [id, userId, videoId, numerosGerados, dataParticipacao, ativo];
}

/// Modelo para números da rifa
class RifaNumero extends Equatable {
  final String id;
  final int numero;
  final String participacaoId;
  final bool sorteado;
  final DateTime? dataSorteio;
  final String? sorteioId;

  const RifaNumero({
    required this.id,
    required this.numero,
    required this.participacaoId,
    this.sorteado = false,
    this.dataSorteio,
    this.sorteioId,
  });

  factory RifaNumero.fromJson(Map<String, dynamic> json) {
    return RifaNumero(
      id: json['id'] as String,
      numero: json['numero'] as int,
      participacaoId: json['participacao_id'] as String,
      sorteado: json['sorteado'] as bool? ?? false,
      dataSorteio: json['data_sorteio'] != null 
          ? DateTime.parse(json['data_sorteio'] as String)
          : null,
      sorteioId: json['sorteio_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'participacao_id': participacaoId,
      'sorteado': sorteado,
      'data_sorteio': dataSorteio?.toIso8601String(),
      'sorteio_id': sorteioId,
    };
  }

  @override
  List<Object?> get props => [id, numero, participacaoId, sorteado, dataSorteio, sorteioId];
}

/// Modelo para sorteios
class Sorteio extends Equatable {
  final String id;
  final String nome;
  final String descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final List<int> numerosSorteados;
  final String status;
  final String? premioDescricao;
  final double? premioValor;
  final DateTime? dataRealizacao;

  const Sorteio({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.numerosSorteados,
    required this.status,
    this.premioDescricao,
    this.premioValor,
    this.dataRealizacao,
  });

  factory Sorteio.fromJson(Map<String, dynamic> json) {
    return Sorteio(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String,
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      dataFim: DateTime.parse(json['data_fim'] as String),
      numerosSorteados: List<int>.from(json['numeros_sorteados'] as List),
      status: json['status'] as String,
      premioDescricao: json['premio_descricao'] as String?,
      premioValor: json['premio_valor']?.toDouble(),
      dataRealizacao: json['data_realizacao'] != null
          ? DateTime.parse(json['data_realizacao'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'numeros_sorteados': numerosSorteados,
      'status': status,
      'premio_descricao': premioDescricao,
      'premio_valor': premioValor,
      'data_realizacao': dataRealizacao?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, nome, descricao, dataInicio, dataFim, 
    numerosSorteados, status, premioDescricao, premioValor, dataRealizacao
  ];
}

/// Modelo para tentativas da Teimozinha
class TeimozinhaTentativa extends Equatable {
  final String id;
  final String userId;
  final int numeroEscolhido;
  final int numeroSorteado;
  final bool ganhou;
  final DateTime dataTentativa;
  final String? premioDescricao;
  final double? premioValor;

  const TeimozinhaTentativa({
    required this.id,
    required this.userId,
    required this.numeroEscolhido,
    required this.numeroSorteado,
    required this.ganhou,
    required this.dataTentativa,
    this.premioDescricao,
    this.premioValor,
  });

  factory TeimozinhaTentativa.fromJson(Map<String, dynamic> json) {
    return TeimozinhaTentativa(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      numeroEscolhido: json['numero_escolhido'] as int,
      numeroSorteado: json['numero_sorteado'] as int,
      ganhou: json['ganhou'] as bool,
      dataTentativa: DateTime.parse(json['data_tentativa'] as String),
      premioDescricao: json['premio_descricao'] as String?,
      premioValor: json['premio_valor']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'numero_escolhido': numeroEscolhido,
      'numero_sorteado': numeroSorteado,
      'ganhou': ganhou,
      'data_tentativa': dataTentativa.toIso8601String(),
      'premio_descricao': premioDescricao,
      'premio_valor': premioValor,
    };
  }

  @override
  List<Object?> get props => [
    id, userId, numeroEscolhido, numeroSorteado, 
    ganhou, dataTentativa, premioDescricao, premioValor
  ];
}

/// Modelo para vídeos premiados
class VideoPremiado extends Equatable {
  final String id;
  final String titulo;
  final String url;
  final String tipo;
  final bool ativo;
  final int ordem;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  const VideoPremiado({
    required this.id,
    required this.titulo,
    required this.url,
    required this.tipo,
    this.ativo = true,
    this.ordem = 0,
    this.dataInicio,
    this.dataFim,
  });

  factory VideoPremiado.fromJson(Map<String, dynamic> json) {
    return VideoPremiado(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      url: json['url'] as String,
      tipo: json['tipo'] as String,
      ativo: json['ativo'] as bool? ?? true,
      ordem: json['ordem'] as int? ?? 0,
      dataInicio: json['data_inicio'] != null
          ? DateTime.parse(json['data_inicio'] as String)
          : null,
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'url': url,
      'tipo': tipo,
      'ativo': ativo,
      'ordem': ordem,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, titulo, url, tipo, ativo, ordem, dataInicio, dataFim];
}

/// Modelo para configurações do sistema
class ConfiguracaoSistema extends Equatable {
  final String chave;
  final String valor;
  final String? descricao;
  final String tipo;

  const ConfiguracaoSistema({
    required this.chave,
    required this.valor,
    this.descricao,
    required this.tipo,
  });

  factory ConfiguracaoSistema.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoSistema(
      chave: json['chave'] as String,
      valor: json['valor'] as String,
      descricao: json['descricao'] as String?,
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chave': chave,
      'valor': valor,
      'descricao': descricao,
      'tipo': tipo,
    };
  }

  @override
  List<Object?> get props => [chave, valor, descricao, tipo];
}