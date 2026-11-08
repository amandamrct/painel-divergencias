#!/usr/bin/env bash
# Roda divergencias.sql e grava o resultado em public/divergencias.json.
# Uso: DATABASE_URL=postgres://usuario:senha@host:5432/banco ./scripts/exportar.sh
# Precisa de psql e node instalados.
set -euo pipefail

cd "$(dirname "$0")/.."
: "${DATABASE_URL:?Defina DATABASE_URL apontando para o banco com erp_pedidos, pedidos e itens_pedido}"

# A consulta vira subconsulta: tira o ponto e vírgula final.
CONSULTA="$(sed -e 's/;[[:space:]]*$//' divergencias.sql)"
DESTINO="public/divergencias.json"

psql "$DATABASE_URL" -X -q -A -t -v ON_ERROR_STOP=1 -c "
SELECT json_build_object(
    'gerado_em',    to_char(now(), 'YYYY-MM-DD\"T\"HH24:MI:SS'),
    'divergencias', coalesce(json_agg(d.linha ORDER BY d.ordem), '[]'::json)
)
FROM (SELECT c AS linha, row_number() OVER () AS ordem FROM (${CONSULTA}) c) d;
" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.stringify(JSON.parse(s),null,2)+"\n"))' > "$DESTINO.tmp"

mv "$DESTINO.tmp" "$DESTINO"
echo "Gravado $DESTINO"
