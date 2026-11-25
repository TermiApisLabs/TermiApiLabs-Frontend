class AuthUser {
  final String id;
  final String nome;
  final String email;
  final String? fotoUrl;
  final String? resumo;
  final List<String> links;
  final String? pais;
  final String? organizacao;
  final String? emailContato;
  final bool emailVerificado;
  final String provedorAuth;
  final String dataCriacaoConta;

  const AuthUser({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.resumo,
    this.links = const [],
    this.pais,
    this.organizacao,
    this.emailContato,
    required this.emailVerificado,
    required this.provedorAuth,
    required this.dataCriacaoConta,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        nome: json['nome']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fotoUrl: json['fotoUrl']?.toString(),
        resumo: json['resumo']?.toString(),
        links: (json['links'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        pais: json['pais']?.toString(),
        organizacao: json['organizacao']?.toString(),
        emailContato: json['emailContato']?.toString(),
        emailVerificado: json['emailVerificado'] == true,
        provedorAuth: json['provedorAuth']?.toString() ?? 'LOCAL',
        dataCriacaoConta: json['dataCriacaoConta']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'fotoUrl': fotoUrl,
        'resumo': resumo,
        'links': links,
        'pais': pais,
        'organizacao': organizacao,
        'emailContato': emailContato,
        'emailVerificado': emailVerificado,
        'provedorAuth': provedorAuth,
        'dataCriacaoConta': dataCriacaoConta,
      };
}
