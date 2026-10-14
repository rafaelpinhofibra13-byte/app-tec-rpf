# APP TEC RPF

Repositorio publico de distribuicao e atualizacao do APP TEC RPF.

## Download e atualizacoes

O site publico sera publicado em:

`https://rafaelpinhofibra13-byte.github.io/app-tec-rpf/`

As APKs ficam em GitHub Releases. O aplicativo consulta `update.json` ao abrir
e oferece o download quando encontra um `versionCode` maior que o instalado. O
Android ainda pede confirmacao do usuario para instalar cada atualizacao.

## Publicar uma atualizacao

1. Atualize `source.html` e gere a APK com `build-release.ps1`.
2. Incremente `VersionCode` e `VersionName`; o codigo deve ser maior que o da
   versao anterior.
3. Crie uma GitHub Release com a tag `v<VersionName>` e anexe o APK gerado como
   `SuperAppTecnico-<VersionName>.apk`.
4. Edite `update.json` na raiz: atualize `versionCode`, `versionName`,
   `apkUrl` para o asset da Release e `releaseNotes`.
5. Faca commit da alteracao em `update.json`. O GitHub Pages publica o site a
   partir da branch `main`; ao abrir o app, os usuarios serao avisados.

As APKs futuras precisam da mesma chave de assinatura da instalada. O APK
original usa a chave debug local do Android Studio. Preserve essa chave neste
PC, nao a publique e nao a substitua; sem ela os usuarios precisariam
desinstalar o app antes de instalar uma nova versao.
