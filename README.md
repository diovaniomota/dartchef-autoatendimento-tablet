# DartFood Mesa App

App Flutter para o cliente fazer o pedido direto da mesa e enviar para o `next-food`.

## Arquitetura

- `next-food`: painel interno que recebe e acompanha os pedidos de mesa
- `next-food-tablet`: backend/API pública segura para cardápio e envio do pedido
- `next-food-tablet-app`: app Flutter instalado no tablet da mesa

## Antes de usar

1. Rode a migration de pedidos de mesa:
   `next-food/database/migration_tablet_pedidos.sql`
2. Suba o backend público:
   `cd next-food-tablet && npm install && npm run dev`
3. Ajuste o `.env` do app Flutter com o IP da máquina que está rodando o backend.

Exemplo:

```env
API_BASE_URL=http://192.168.0.41:3002
DEFAULT_ORGANIZATION_ID=SEU_ID_DA_ORGANIZACAO
DEFAULT_TABLE_CODE=01
```

## Rodando

Quando o Flutter SDK estiver disponível na máquina:

```bash
cd next-food-tablet-app
flutter pub get
flutter run
```

## Fluxo

1. O tablet abre o cardápio da mesa.
2. O cliente monta o pedido e envia.
3. O app chama `next-food-tablet/api/public/orders`.
4. O pedido entra em `restaurant_orders` e aparece na tela `Pedidos Mesa` do `next-food`.
