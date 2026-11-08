-- divergencias.sql
-- Lista cada pedido com problema entre o ERP (erp_pedidos, fonte da verdade)
-- e o painel de vendas (pedidos + itens_pedido). Uma linha por pedido e tipo;
-- um pedido com dois problemas aparece duas vezes, uma para cada tipo.
--
--   FALTA_NO_PAINEL    existe no ERP e não existe no painel
--   DUPLICADO          aparece mais de uma vez no painel
--   STATUS_DIVERGENTE  status no painel diferente do status no ERP
--   SEM_ITENS          está no painel, mas sem nenhum item
--
-- Não termine com nada depois do ponto e vírgula final: scripts/exportar.sh
-- usa este arquivo como subconsulta.

WITH itens AS (
    SELECT pedido_id, count(*) AS qtd_itens
    FROM itens_pedido
    GROUP BY pedido_id
),
painel AS (
    -- Um registro por número do ERP, mesmo que o painel tenha cópias.
    SELECT p.numero_erp,
           min(p.cliente)                                   AS cliente,
           min(p.cnpj)                                      AS cnpj,
           count(*)                                         AS registros,
           string_agg(p.id::text, ', ' ORDER BY p.id)       AS ids_painel,
           string_agg(DISTINCT p.status, ' / ')             AS status_painel,
           string_agg(p.id::text, ', ' ORDER BY p.id)
               FILTER (WHERE i.pedido_id IS NULL)           AS ids_sem_itens
    FROM pedidos p
    LEFT JOIN itens i ON i.pedido_id = p.id
    GROUP BY p.numero_erp
),
base AS (
    SELECT coalesce(e.nunota, pa.numero_erp)   AS numero_erp,
           coalesce(e.cliente, pa.cliente)     AS cliente,
           coalesce(e.cnpj, pa.cnpj)           AS cnpj,
           e.status                            AS status_erp,
           pa.status_painel,
           e.valor_total,
           e.dh_inclusao,
           e.dh_alteracao,
           pa.registros,
           pa.ids_painel,
           pa.ids_sem_itens,
           (SELECT max(sincronizado_em) FROM pedidos) AS ultima_sinc
    FROM erp_pedidos e
    FULL JOIN painel pa ON pa.numero_erp = e.nunota
)
SELECT tipo, numero_erp, cliente, cnpj, status_erp, status_painel,
       valor_total, dh_inclusao AS incluido_em, ids_painel, detalhe
FROM (
    -- 1. Está no ERP e não chegou ao painel
    SELECT 'FALTA_NO_PAINEL' AS tipo, b.*,
           CASE
               WHEN b.cnpj IS NULL THEN
                   'Sem CNPJ no ERP. O painel exige CNPJ (provável motivo de não ter sido importado).'
               WHEN b.dh_inclusao > b.ultima_sinc THEN
                   'Incluído em ' || to_char(b.dh_inclusao, 'DD/MM HH24:MI')
                   || ', depois da última importação registrada no painel ('
                   || to_char(b.ultima_sinc, 'DD/MM HH24:MI') || ').'
               ELSE
                   'Incluído em ' || to_char(b.dh_inclusao, 'DD/MM HH24:MI')
                   || ' e não importado pela integração.'
           END AS detalhe
    FROM base b
    WHERE b.status_erp IS NOT NULL AND b.registros IS NULL

    UNION ALL

    -- 2. Mais de um registro no painel para o mesmo pedido
    SELECT 'DUPLICADO', b.*,
           b.registros || ' registros no painel para o mesmo pedido (ids ' || b.ids_painel || ').'
    FROM base b
    WHERE b.registros > 1

    UNION ALL

    -- 3. Status do painel diferente do ERP
    SELECT 'STATUS_DIVERGENTE', b.*,
           'ERP: ' || b.status_erp || ' (alterado em ' || to_char(b.dh_alteracao, 'DD/MM HH24:MI')
           || '). Painel: ' || b.status_painel || '.'
    FROM base b
    WHERE b.status_erp IS NOT NULL
      AND b.registros IS NOT NULL
      AND b.status_painel IS DISTINCT FROM b.status_erp

    UNION ALL

    -- 4. No painel, mas sem itens
    SELECT 'SEM_ITENS', b.*,
           'Pedido no painel sem nenhum item (id ' || b.ids_sem_itens || ').'
    FROM base b
    WHERE b.ids_sem_itens IS NOT NULL
) d
ORDER BY CASE tipo
             WHEN 'FALTA_NO_PAINEL'   THEN 1
             WHEN 'DUPLICADO'         THEN 2
             WHEN 'STATUS_DIVERGENTE' THEN 3
             WHEN 'SEM_ITENS'         THEN 4
         END,
         numero_erp;
