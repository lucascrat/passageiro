# Guia de Build de Release - App Flutter Android

## Resumo
Este documento descreve o processo completo para gerar uma versão de release do app Flutter Android com todas as configurações de produção.

## Pré-requisitos
- Flutter SDK instalado
- Android SDK configurado
- Keystore de release configurado (`android/key.properties`)
- Variáveis de ambiente configuradas

## Configurações Realizadas

### 1. Variáveis de Ambiente
Arquivo `.env` criado na raiz do projeto com:
```
SUPABASE_URL=https://yubztvbrgrldfueelxfh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
USE_SUPABASE=true
BINGO_WS_URL=wss://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app/ws
BINGO_API_URL=https://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app
ADMIN_EMAIL=lrlucasrafael11@gmail.com
ADMIN_PASSWORD=01Deus02@
```

### 2. Configuração do Build Android
Arquivo `android/app/build.gradle` modificado:
- Minificação desabilitada para evitar problemas de compatibilidade
- Shrink resources desabilitado
- ProGuard comentado temporariamente

### 3. Otimizações Realizadas
- Remoção de debug prints em produção
- Configuração de signing para release
- Otimização de assets e fontes

## Comandos de Build

### Limpar Build Anterior
```bash
flutter clean
```

### Gerar APK de Release
```bash
flutter build apk --release \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://yubztvbrgrldfueelxfh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Ynp0dmJyZ3JsZGZ1ZWVseGZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MDYwNzgsImV4cCI6MjA3NTI4MjA3OH0.2TrL_0LARjlNSctImwGMht7-hYxMNNSuhnGfLJMySU4 \
  --dart-define=BINGO_WS_URL=wss://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app/ws \
  --dart-define=BINGO_API_URL=https://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app \
  --dart-define=ADMIN_EMAIL=lrlucasrafael11@gmail.com \
  --dart-define=ADMIN_PASSWORD=01Deus02@
```

### Gerar AAB de Release (Android App Bundle)
```bash
flutter build appbundle --release \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://yubztvbrgrldfueelxfh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Ynp0dmJyZ3JsZGZ1ZWVseGZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MDYwNzgsImV4cCI6MjA3NTI4MjA3OH0.2TrL_0LARjlNSctImwGMht7-hYxMNNSuhnGfLJMySU4 \
  --dart-define=BINGO_WS_URL=wss://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app/ws \
  --dart-define=BINGO_API_URL=https://bingo-admin-web-git-main-lucasrafaels-projects-b5b3b8b5.vercel.app \
  --dart-define=ADMIN_EMAIL=lrlucasrafael11@gmail.com \
  --dart-define=ADMIN_PASSWORD=01Deus02@
```

## Arquivos Gerados

### APK de Release
- **Localização**: `build/app/outputs/flutter-apk/app-release.apk`
- **Tamanho**: ~40.3MB
- **Uso**: Instalação direta em dispositivos Android

### AAB de Release
- **Localização**: `build/app/outputs/bundle/release/app-release.aab`
- **Tamanho**: ~60.6MB
- **Uso**: Upload para Google Play Store

## Funcionalidades Testadas

### Sistema Bingo
- ✅ Conexão com WebSocket de produção
- ✅ Integração com Supabase
- ✅ Login de administrador
- ✅ Funcionalidades de jogo

### Configurações de Produção
- ✅ URLs de produção configuradas
- ✅ Variáveis de ambiente aplicadas
- ✅ Build assinado com keystore de release
- ✅ Debug prints removidos

## Problemas Conhecidos

### AAB Build Warning
- O build do AAB apresenta warning sobre debug symbols
- Não impacta a funcionalidade do app
- Relacionado à configuração do Android toolchain

### Soluções Aplicadas
- Minificação desabilitada para evitar problemas de compatibilidade
- ProGuard temporariamente desabilitado
- Build APK funciona perfeitamente

## Próximos Passos

1. **Para Produção**:
   - Remover credenciais de admin das variáveis de ambiente
   - Habilitar minificação após testes extensivos
   - Configurar ProGuard rules específicas

2. **Para Deploy**:
   - Usar AAB para Google Play Store
   - Usar APK para distribuição direta

## Comandos Úteis

```bash
# Verificar dispositivos conectados
flutter devices

# Verificar configuração do Flutter
flutter doctor

# Listar emuladores disponíveis
flutter emulators

# Instalar APK em dispositivo conectado
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Notas de Segurança

⚠️ **IMPORTANTE**: As credenciais de admin estão incluídas no build atual apenas para desenvolvimento. Para produção, remover as variáveis `ADMIN_EMAIL` e `ADMIN_PASSWORD`.

## Data de Criação
08/10/2025 - Versão 1.0.0+1