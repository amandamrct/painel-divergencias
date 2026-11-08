-- Banco de exemplo (cópia do dump recebido) para testar a consulta localmente:
--   psql "$DATABASE_URL" -f banco/exemplo.sql
DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS erp_pedidos;

-- Espelho dos pedidos do ERP (fonte da verdade)
CREATE TABLE erp_pedidos (
    nunota        INT PRIMARY KEY,
    cliente       VARCHAR(100) NOT NULL,
    cnpj          VARCHAR(18),
    dh_inclusao   TIMESTAMP NOT NULL,
    dh_alteracao  TIMESTAMP NOT NULL,
    status        VARCHAR(20) NOT NULL,
    valor_total   NUMERIC(12,2) NOT NULL
);

-- Banco do painel de vendas (alimentado pela integração)
CREATE TABLE pedidos (
    id               SERIAL PRIMARY KEY,
    numero_erp       INT NOT NULL,
    cliente          VARCHAR(100) NOT NULL,
    cnpj             VARCHAR(18) NOT NULL,
    status           VARCHAR(20) NOT NULL,
    valor_total      NUMERIC(12,2) NOT NULL,
    sincronizado_em  TIMESTAMP NOT NULL
);

CREATE TABLE itens_pedido (
    id          SERIAL PRIMARY KEY,
    pedido_id   INT NOT NULL REFERENCES pedidos(id),
    sku         VARCHAR(30) NOT NULL,
    qtd         INT NOT NULL,
    preco_unit  NUMERIC(12,2) NOT NULL
);

INSERT INTO erp_pedidos VALUES
(10041, 'Refrigeração Alfa LTDA',         '11.111.111/0001-11', '2026-11-05 08:45', '2026-11-05 08:45', 'ABERTO',    1250.00),
(10042, 'Frio Norte Instalações',         '22.222.222/0001-22', '2026-11-05 08:50', '2026-11-05 08:50', 'ABERTO',     480.00),
(10043, 'Hotel Atlântico',                '33.333.333/0001-33', '2026-11-05 08:58', '2026-11-05 08:58', 'ABERTO',    3120.00),
(10044, 'Clima Center',                   '44.444.444/0001-44', '2026-11-05 09:20', '2026-11-05 09:20', 'ABERTO',     890.00),
(10045, 'João Batista Silva (cons. final)', NULL,               '2026-11-05 09:35', '2026-11-05 09:35', 'ABERTO',     315.00),
(10046, 'Supermercado Boa Compra',        '55.555.555/0001-55', '2026-11-05 09:40', '2026-11-05 09:52', 'FATURADO',  5600.00),
(10047, 'Offshore Serviços Marítimos',    '66.666.666/0001-66', '2026-11-05 09:55', '2026-11-05 09:55', 'ABERTO',    2740.00),
(10048, 'Gelo Bom Refrigeração',          '77.777.777/0001-77', '2026-11-05 10:30', '2026-11-05 10:30', 'ABERTO',     660.00),
(10049, 'Ar & Cia Climatização',          '88.888.888/0001-88', '2026-11-05 10:45', '2026-11-05 13:20', 'FATURADO',  1980.00),
(10050, 'Refrigeração Alfa LTDA',         '11.111.111/0001-11', '2026-11-05 13:10', '2026-11-05 13:10', 'ABERTO',     410.00),
(10051, 'Térmica Rio',                    '99.999.999/0001-99', '2026-11-05 13:40', '2026-11-05 13:40', 'ABERTO',     275.00),
(10052, 'Frio Norte Instalações',         '22.222.222/0001-22', '2026-11-05 17:42', '2026-11-05 17:42', 'ABERTO',    1150.00);

INSERT INTO pedidos (id, numero_erp, cliente, cnpj, status, valor_total, sincronizado_em) VALUES
(1,  10041, 'Refrigeração Alfa LTDA',      '11.111.111/0001-11', 'ABERTO',   1250.00, '2026-11-05 09:00:03'),
(2,  10042, 'Frio Norte Instalações',      '22.222.222/0001-22', 'ABERTO',    480.00, '2026-11-05 09:00:03'),
(3,  10043, 'Hotel Atlântico',             '33.333.333/0001-33', 'ABERTO',   3120.00, '2026-11-05 09:00:04'),
(4,  10044, 'Clima Center',                '44.444.444/0001-44', 'ABERTO',    890.00, '2026-11-05 10:00:02'),
(5,  10046, 'Supermercado Boa Compra',     '55.555.555/0001-55', 'FATURADO', 5600.00, '2026-11-05 10:00:03'),
(6,  10047, 'Offshore Serviços Marítimos', '66.666.666/0001-66', 'ABERTO',   2740.00, '2026-11-05 10:00:03'),
(7,  10047, 'Offshore Serviços Marítimos', '66.666.666/0001-66', 'ABERTO',   2740.00, '2026-11-05 10:00:35'),
(8,  10048, 'Gelo Bom Refrigeração',       '77.777.777/0001-77', 'ABERTO',    660.00, '2026-11-05 11:00:02'),
(9,  10049, 'Ar & Cia Climatização',       '88.888.888/0001-88', 'ABERTO',   1980.00, '2026-11-05 11:00:02'),
(10, 10050, 'Refrigeração Alfa LTDA',      '11.111.111/0001-11', 'ABERTO',    410.00, '2026-11-05 14:00:02'),
(11, 10051, 'Térmica Rio',                 '99.999.999/0001-99', 'ABERTO',    275.00, '2026-11-05 14:00:03');
SELECT setval('pedidos_id_seq', 11);

INSERT INTO itens_pedido (pedido_id, sku, qtd, preco_unit) VALUES
(1,  'CMP-EMB-FF8.5',   2,  450.00),
(1,  'VAL-EXP-TS2',     1,  350.00),
(2,  'GAS-R410A-11KG',  1,  480.00),
(3,  'CMP-DAN-SC15',    2, 1200.00),
(3,  'CAP-RUN-45UF',    4,  180.00),
(4,  'MOT-VENT-1/6',    2,  445.00),
(5,  'CON-UNI-5HP',     1, 5600.00),
(6,  'CMP-TEC-AE4440',  1, 1900.00),
(6,  'FIL-SEC-DML083',  6,   90.00),
(6,  'PRE-PRS-KP5',     1,  300.00),
(7,  'CMP-TEC-AE4440',  1, 1900.00),
(7,  'FIL-SEC-DML083',  6,   90.00),
(7,  'PRE-PRS-KP5',     1,  300.00),
(8,  'TER-DIG-MT512',   3,  220.00),
(9,  'EVA-INT-12K',     1, 1980.00),
(10, 'CAP-RUN-45UF',    2,  180.00),
(10, 'FIT-ISO-3M',      1,   50.00);
-- pedido 11 (10051) ficou sem itens: ver log da integração
