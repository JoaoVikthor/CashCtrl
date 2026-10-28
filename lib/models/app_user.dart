class AppUser {
  final String uid;
  final String nome;
  final String email;
  final String? empresa;
  final String? cnpj;
  final String? segmento;
  final String? telefone;
  final String? endereco;
  final String? photoUrl;
  final bool notifOrcamento;
  final bool notifRecorrentes;
  final bool notifMargem;

  const AppUser({
    required this.uid,
    required this.nome,
    required this.email,
    this.empresa,
    this.cnpj,
    this.segmento,
    this.telefone,
    this.endereco,
    this.photoUrl,
    this.notifOrcamento = true,
    this.notifRecorrentes = true,
    this.notifMargem = true,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        nome: (map['nome'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        empresa: map['empresa'] as String?,
        cnpj: map['cnpj'] as String?,
        segmento: map['segmento'] as String?,
        telefone: map['telefone'] as String?,
        endereco: map['endereco'] as String?,
        photoUrl: map['photoUrl'] as String?,
        notifOrcamento: (map['notifOrcamento'] ?? true) as bool,
        notifRecorrentes: (map['notifRecorrentes'] ?? true) as bool,
        notifMargem: (map['notifMargem'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'email': email,
        'empresa': empresa,
        'cnpj': cnpj,
        'segmento': segmento,
        'telefone': telefone,
        'endereco': endereco,
        'photoUrl': photoUrl,
        'notifOrcamento': notifOrcamento,
        'notifRecorrentes': notifRecorrentes,
        'notifMargem': notifMargem,
      };

  AppUser copyWith({
    String? nome,
    String? email,
    String? empresa,
    String? cnpj,
    String? segmento,
    String? telefone,
    String? endereco,
    String? photoUrl,
    bool? notifOrcamento,
    bool? notifRecorrentes,
    bool? notifMargem,
  }) =>
      AppUser(
        uid: uid,
        nome: nome ?? this.nome,
        email: email ?? this.email,
        empresa: empresa ?? this.empresa,
        cnpj: cnpj ?? this.cnpj,
        segmento: segmento ?? this.segmento,
        telefone: telefone ?? this.telefone,
        endereco: endereco ?? this.endereco,
        photoUrl: photoUrl ?? this.photoUrl,
        notifOrcamento: notifOrcamento ?? this.notifOrcamento,
        notifRecorrentes: notifRecorrentes ?? this.notifRecorrentes,
        notifMargem: notifMargem ?? this.notifMargem,
      );
}