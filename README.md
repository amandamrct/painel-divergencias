# painel-divergencias

Uma tela que mostra os pedidos que estão diferentes entre o ERP e o painel de vendas.

---

## Guia de suporte: o que fazer quando um pedido não aparece no painel

**Regra de ouro:** o ERP é o sistema oficial. O painel de vendas é uma cópia, atualizada automaticamente **uma vez por hora, logo depois da hora cheia** (9h, 10h, 11h…). Se o pedido está no ERP, ele existe e é válido, mesmo que o painel ainda não mostre.

### Passo a passo

1. **Peça o número do pedido** (o número do ERP) e procure no ERP.
   Se ele não existe no ERP, o problema não é o painel: oriente quem pediu a falar com o vendedor ou com quem lança os pedidos.
2. **Veja a hora em que o pedido foi incluído no ERP.**
   Se foi há menos de uma hora, ele provavelmente só não foi copiado ainda. Explique isso e confira de novo depois da próxima hora cheia.
3. **Abra a tela de divergências** e digite o número do pedido no campo de busca.
   Confira no topo a data de “Dados gerados em”. Se ela for anterior à inclusão do pedido, a tela ainda não sabe dele: peça à TI para atualizar.
4. **Veja o tipo do problema** e siga a tabela abaixo.

### O que cada tipo significa e o que fazer

| Tipo na tela | O que quer dizer | O que fazer |
|---|---|---|
| **Falta no painel** | O pedido está no ERP, mas não foi copiado para o painel. A coluna “O que aconteceu” mostra o provável motivo. | **“Sem CNPJ no ERP”**: pedidos de consumidor final (pessoa física) não entram no painel hoje. O pedido é válido; informe isso a quem pediu e encaminhe à TI. **“Depois da última importação”**: aguarde a próxima hora cheia; se continuar faltando, encaminhe à TI. **Outro motivo**: encaminhe à TI. |
| **Duplicado** | O pedido aparece mais de uma vez no painel. Os totais do painel ficam somados em dobro. | Considere o pedido uma vez só. Não cancele nem altere nada no ERP. Encaminhe à TI para remover a cópia. |
| **Status diferente** | O painel mostra um status antigo (por exemplo, “ABERTO” quando o ERP já está “FATURADO”). | Informe o status que está no ERP, que é o correto. Encaminhe à TI. |
| **Sem itens** | O pedido aparece no painel, mas sem nenhum produto. | Consulte os produtos no ERP e passe a informação a quem pediu. Encaminhe à TI. |

### O pedido não está na tela de divergências?

Então o ERP e o painel estavam iguais na hora em que os dados foram gerados. Confira:

- se o número foi digitado certo;
- se o painel de vendas tem algum filtro ligado (data, vendedor, status) escondendo o pedido;
- se a data de “Dados gerados em” é anterior à inclusão do pedido.

Se mesmo assim o pedido não aparece, encaminhe à TI.

### Ao encaminhar para a TI, envie

- o número do pedido no ERP;
- o tipo mostrado na tela e o texto da coluna “O que aconteceu”;
- quem reclamou e quando;
- um print da tela de divergências e do painel.

### Não faça

- **Não lance o pedido de novo no ERP** para “forçar” a ida ao painel. Isso cria um pedido duplicado de verdade.
- **Não preencha um CNPJ inventado** em pedido de consumidor final.
- Não prometa prazo de correção: quem define é a TI.

---

## Para a equipe técnica

### Arquivos

| Arquivo | Para que serve |
|---|---|
| `divergencias.sql` | Consulta única que lista os pedidos com problema e o tipo |
| `scripts/exportar.sh` | Roda a consulta e grava `public/divergencias.json` |
| `public/divergencias.json` | Resultado atual (gerado a partir do banco de exemplo) |
| `src/` | Página React (Vite) com contador, filtro por tipo e busca |
| `banco/exemplo.sql` | Banco de exemplo para testar localmente |

### Comandos

```bash
npm install
npm run dev                                         # abre a página em modo desenvolvimento
DATABASE_URL=postgres://... npm run exportar        # atualiza public/divergencias.json (precisa de psql)
npm run build                                       # gera dist/ para publicar em qualquer servidor estático
```

Para testar do zero: `psql "$DATABASE_URL" -f banco/exemplo.sql` e depois `npm run exportar`.

O JSON é uma foto do momento em que foi gerado. Para a tela ficar atual, agende o `exportar` (por exemplo, a cada hora, alguns minutos depois da integração) e copie o novo JSON para o servidor. Basta trocar o arquivo; não precisa gerar a página de novo.

### O que os dados de exemplo mostram sobre a integração

Estas conclusões vêm dos horários em `sincronizado_em` e devem ser confirmadas no log da integração:

- Ela roda de hora em hora, perto do minuto 00. O guia acima assume isso.
- Às 10:00 rodou duas vezes (10:00:03 e 10:00:35) e duplicou o 10047: a integração não verifica se o pedido já existe.
- Ela não atualiza pedidos já importados: o 10049 foi faturado às 13:20 e continuou “ABERTO” depois da execução das 14:00.
- `pedidos.cnpj` é `NOT NULL`, e o ERP aceita pedido sem CNPJ (consumidor final). Por isso o 10045 não entrou.
- O 10051 foi gravado sem itens às 14:00:03; o comentário do dump indica que a explicação está no log.
- Não há importação depois das 14:00 no dump. O 10052 (17:42) falta porque a execução das 18:00 não aconteceu ou porque o dump foi tirado antes dela.
