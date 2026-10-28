# Erros a Evitar (NÃO COMETER)

Lista de erros que NÃO devem ser cometidos neste projeto. Consultar sempre que houver dúvida antes de editar código, configurar o ambiente ou enviar alterações ao repositório.

---

## 1. Segurança e Segredos

### 1.1 NUNCA subir segredos para o git
- **Proibido** enviar o arquivo `.env` (contém chaves reais).
- **Proibido** enviar `android/app/google-services.json` (contém API key).
- **Proibido** enviar keystores (`*.jks`, `*.keystore`) ou `android/key.properties`.
- **Proibido** enviar `android/local.properties` (caminhos locais do SDK).
- Sempre que criar uma nova chave/token, ela deve ir para `.env` e o `.gitignore` deve ignorá-la.
- Se precisar versionar configuração de exemplo, use `.env.example` com valores vazios.

### 1.2 NUNCA deixar chaves embutidas no código Dart
- As chaves do Firebase vivem em `.env`, lidas via `flutter_dotenv` (`lib/firebase_options.dart`).
- Não voltar a colocar `apiKey: '...'` hardcoded em `lib/firebase_options.dart`, `main.dart` ou qualquer outra tela.
- Não esconder chaves em comentários, strings de testes ou Assets.

### 1.3 Atenção ao.Firebase web
- Em builds web, variáveis de ambiente ficam embutidas no bundle JS (não ficam escondidas no cliente). Para segredos de back-end, use tokens do servidor, nunca do app Flutter.
- A API key do Firebase é "restrita" (identifica o projeto); a segurança real vem das **Firebase Security Rules**, não da chave.

### 1.4 Login social
- App IDs do Facebook/Google devem vir de `.env` quando couber. Configurações nativas (AndroidManifest.xml) que não aceitem env devem ser documentadas como obrigatórias localmente.

---

## 2. Repositório e Git

### 2.1 Origin
- Remote origin: `https://github.com/JoaoVikthor/ctrlcash.git`
- Só inicializar `git`, configurar origin e fazer push quando o usuário **pedir explicitamente**.
- Nunca fazer `push --force` sem permissão.
- Nunca commitar sem antes confirmar que nenhum arquivo sensível está na staging area (verificar `git status`).

### 2.2 Commits
- Não commitar arquivos listados no `.gitignore` (mesmo via `git add -f`).
- Mensagens de commit em estilo curto e descritivo.
- Não usar `git commit --amend` em commits já enviados sem permissão.

---

## 3. Código Flutter/Dart

### 3.1 Estilo
- **NÃO adicionar comentários** no código a menos que o usuário peça (projeto não usa comentários além dos já existentes).
- Seguir a paleta de cores já definida (`colorBackground`, `colorGreenPrimary`, `colorGold`, `colorCard` em `lib/login_screen.dart`).
- Manter `lib/firebase_options.dart` lendo de `.env` (via `flutter_dotenv`); não regenerar pelo FlutterFire CLI sem depois reaplicar a leitura via env.
- Depois de qualquer alteração em código Dart, correr `flutter pub get` e `flutter analyze` (e testes se existirem) antes de reportar conclusão.

### 3.2 Antes de alterar
- Ler o(s) arquivo(s) e os arquivos vizinhos para entender convenções.
- Não assumir que uma biblioteca está disponível; verificar `pubspec.yaml`.
- Não adicionar dependências sem necessidade; quando adicionar, declarar no `pubspec.yaml` e correr `flutter pub get`.

---

## 4. Fluxo de trabalho

- Confirmar ações destrutivas (`git rm`, `flutter clean`, apagar arquivos) antes de executar.
- Não correr comandos longos de build sem necessidade; rodar `flutter analyze` como verificação mínima.
- Manter esta lista atualizada se surgirem novos erros recorrentes.