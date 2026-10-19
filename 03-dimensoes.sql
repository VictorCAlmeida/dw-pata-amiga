-- =====================================================================================
--  ARQUIVO 3:  AS DIMENSOES QUE VOCE PREENCHE
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 01-carga-staging.sql e 02-dimensoes-prontas.sql
-- =====================================================================================

-- Seleciona o banco de dados principal do Data Warehouse da Pata Amiga
USE dw_pata_amiga;

-- -------------------------------------------------------------------------------------
-- 1. DIM_CATEGORIA
-- -------------------------------------------------------------------------------------
-- Limpa os registros anteriores da tabela dim_categoria para permitir re-execução do script
TRUNCATE TABLE dim_categoria;

-- Ajusta o modo de sessão para permitir a inserção explícita do valor -1 no campo AUTO_INCREMENT
SET SESSION sql_mode = '';

-- Insere a linha coringa (-1) para tratar categorias não mapeadas ou nulas
INSERT INTO dim_categoria (sk_categoria, categoria_origem, nome_categoria, grupo_categoria)
VALUES (-1, 'Nao Informado', 'Nao Informado', 'Nao Informado');

-- Extrai as grafias únicas da staging e aplica a ordem lógica do CASE WHEN para padronização
INSERT INTO dim_categoria (categoria_origem, nome_categoria, grupo_categoria)
SELECT DISTINCT 
    `CategoriaProduto` AS categoria_origem,
    CASE 
        -- Atenção: MED é testado primeiro para capturar "Ração Medicamentosa" antes da regra de Ração
        WHEN UPPER(`CategoriaProduto`) LIKE '%MED%' THEN 'Medicamento'
        WHEN UPPER(`CategoriaProduto`) LIKE '%PETISC%' THEN 'Petisco'
        WHEN UPPER(`CategoriaProduto`) LIKE '%RA%' THEN 'Racao'
        WHEN UPPER(`CategoriaProduto`) LIKE '%HIG%' THEN 'Higiene'
        WHEN UPPER(`CategoriaProduto`) LIKE '%BRINQ%' THEN 'Brinquedo'
        WHEN UPPER(`CategoriaProduto`) LIKE '%ACESS%' THEN 'Acessorio'
        WHEN UPPER(`CategoriaProduto`) LIKE '%SERV%' THEN 'Servico'
        ELSE 'Nao Informado'
    END AS nome_categoria,
    CASE 
        -- Agrupa as categorias padronizadas nos seus respectivos macro-grupos de negócio
        WHEN UPPER(`CategoriaProduto`) LIKE '%MED%' OR UPPER(`CategoriaProduto`) LIKE '%HIG%' THEN 'Saude e Higiene'
        WHEN UPPER(`CategoriaProduto`) LIKE '%PETISC%' OR UPPER(`CategoriaProduto`) LIKE '%RA%' THEN 'Alimentacao'
        WHEN UPPER(`CategoriaProduto`) LIKE '%BRINQ%' OR UPPER(`CategoriaProduto`) LIKE '%ACESS%' OR UPPER(`CategoriaProduto`) LIKE '%SERV%' THEN 'Bem-estar'
        ELSE 'Nao Informado'
    END AS grupo_categoria
FROM stg_pedido
WHERE `CategoriaProduto` IS NOT NULL AND TRIM(`CategoriaProduto`) <> '';


-- -------------------------------------------------------------------------------------
-- 2. DIM_PRACA
-- -------------------------------------------------------------------------------------
-- Esvazia a dimensão de praças antes do novo carregamento
TRUNCATE TABLE dim_praca;

-- Insere a linha coringa (-1) para a dimensão de praças
INSERT INTO dim_praca (sk_praca, cod_praca, nome_praca, regional, domicilios_com_pet)
VALUES (-1, '-1', 'Nao Informado', 'Nao Informado', 0);

-- Carrega as praças únicas a partir da staging, removendo os pontos de milhar dos domicílios
INSERT INTO dim_praca (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT DISTINCT
    `CodPraca`,
    `NomePraca`,
    `Regional`,
    CAST(REPLACE(`DomiciliosComPet`, '.', '') AS UNSIGNED)
FROM stg_loja_praca;


-- -------------------------------------------------------------------------------------
-- 3. BRIDGE_LOJA_PRACA
-- -------------------------------------------------------------------------------------
-- Limpa a tabela ponte antes de refazer a associação N:N entre lojas e praças
TRUNCATE TABLE bridge_loja_praca;

-- Popula a tabela ponte realizando o JOIN com a dim_praca e convertendo o percentual de público em fator decimal
INSERT INTO bridge_loja_praca (cod_loja, sk_praca, fator_publico)
SELECT 
    s.`CodLoja`,
    p.`sk_praca`,
    CAST(REPLACE(REPLACE(s.`PercentualPublico`, 'R$', ''), ',', '.') AS DECIMAL(6,4)) AS fator_publico
FROM stg_loja_praca s
JOIN dim_praca p ON p.cod_praca = s.`CodPraca`;