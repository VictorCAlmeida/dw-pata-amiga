-- =====================================================================================
--  ARQUIVO 2:  AS DIMENSOES PRONTAS E ESTRUTURA DO DW
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================

-- Seleciona o banco de dados principal do Data Warehouse da Pata Amiga
USE dw_pata_amiga;

-- -------------------------------------------------------------------------------------
-- DIM_TEMPO
-- -------------------------------------------------------------------------------------
-- Remove a tabela dim_tempo caso ela já exista para garantir uma execução limpa (re-executável)
DROP TABLE IF EXISTS dim_tempo;

-- Cria a estrutura da dimensão de tempo com surrogate key baseada no formato numérico AAAAMMDD
CREATE TABLE dim_tempo (
    sk_tempo INT PRIMARY KEY,
    data_completa DATE,
    ano INT,
    mes INT,
    nome_mes VARCHAR(20),
    dia INT,
    nome_dia VARCHAR(20),
    trimester INT,
    semestre INT,
    dia_util VARCHAR(3)
);

-- Insere o registro coringa / linha padrão (-1) para tratar datas nulas ou não informadas
INSERT INTO dim_tempo (sk_tempo, data_completa, ano, mes, nome_mes, dia, nome_dia, trimestre, semestre, dia_util)
VALUES (-1, '1900-01-01', 1900, 1, 'Nao Informado', 1, 'Nao Informado', 1, 1, 'Nao');

-- Insere a massa de dados inicial da dimensão de tempo abrangendo os dias do período operado pela rede
INSERT INTO dim_tempo (sk_tempo, data_completa, ano, mes, nome_mes, dia, nome_dia, trimestre, semestre, dia_util) VALUES 
(20230901, '2023-09-01', 2023, 9, 'Setembro', 1, 'Sexta-feira', 3, 2, 'Sim'),
(20230902, '2023-09-02', 2023, 9, 'Setembro', 2, 'Sabado', 3, 2, 'Nao'),
(20230903, '2023-09-03', 2023, 9, 'Setembro', 3, 'Domingo', 3, 2, 'Nao'),
(20230904, '2023-09-04', 2023, 9, 'Setembro', 4, 'Segunda-feira', 3, 2, 'Sim'),
(20230905, '2023-09-05', 2023, 9, 'Setembro', 5, 'Terca-feira', 3, 2, 'Sim'),
(20230906, '2023-09-06', 2023, 9, 'Setembro', 6, 'Quarta-feira', 3, 2, 'Sim'),
(20230907, '2023-09-07', 2023, 9, 'Setembro', 7, 'Quinta-feira', 3, 2, 'Sim'),
(20230908, '2023-09-08', 2023, 9, 'Setembro', 8, 'Sexta-feira', 3, 2, 'Sim'),
(20230909, '2023-09-09', 2023, 9, 'Setembro', 9, 'Sabado', 3, 2, 'Nao'),
(20230910, '2023-09-10', 2023, 9, 'Setembro', 10, 'Domingo', 3, 2, 'Nao'),
(20230911, '2023-09-11', 2023, 9, 'Setembro', 11, 'Segunda-feira', 3, 2, 'Sim'),
(20230912, '2023-09-12', 2023, 9, 'Setembro', 12, 'Terca-feira', 3, 2, 'Sim'),
(20230913, '2023-09-13', 2023, 9, 'Setembro', 13, 'Quarta-feira', 3, 2, 'Sim'),
(20230914, '2023-09-14', 2023, 9, 'Setembro', 14, 'Quinta-feira', 3, 2, 'Sim'),
(20230915, '2023-09-15', 2023, 9, 'Setembro', 15, 'Sexta-feira', 3, 2, 'Sim'),
(20230916, '2023-09-16', 2023, 9, 'Setembro', 16, 'Sabado', 3, 2, 'Nao'),
(20230917, '2023-09-17', 2023, 9, 'Setembro', 17, 'Domingo', 3, 2, 'Nao'),
(20230918, '2023-09-18', 2023, 9, 'Setembro', 18, 'Segunda-feira', 3, 2, 'Sim'),
(20230919, '2023-09-19', 2023, 9, 'Setembro', 19, 'Terca-feira', 3, 2, 'Sim'),
(20230920, '2023-09-20', 2023, 9, 'Setembro', 20, 'Quarta-feira', 3, 2, 'Sim');

-- -------------------------------------------------------------------------------------
-- DIM_LOJA
-- -------------------------------------------------------------------------------------
-- Remove a tabela dim_loja existente para recriação limpa
DROP TABLE IF EXISTS dim_loja;

-- Cria a estrutura da dimensão de lojas utilizando chave substituta autoincremental
CREATE TABLE dim_loja (
    sk_loja INT AUTO_INCREMENT PRIMARY KEY,
    cod_loja VARCHAR(10),
    chave_loja VARCHAR(80),
    nome_loja VARCHAR(80),
    cidade VARCHAR(50),
    uf VARCHAR(2),
    mesorregiao VARCHAR(50),
    populacao_cidade INT,
    area_venda_m2 INT,
    porte VARCHAR(20),
    faixa_franquia VARCHAR(15),
    formato_loja VARCHAR(20)
);

-- Insere a linha coringa (-1) na dim_loja para salvaguardar vendas sem correspondência de loja
INSERT INTO dim_loja (sk_loja, cod_loja, chave_loja, nome_loja, cidade, uf, mesorregiao, populacao_cidade, area_venda_m2, porte, faixa_franquia, formato_loja)
VALUES (-1, '-1', 'NAO INFORMADO', 'Nao Informado', 'Nao Informado', 'SC', 'Nao Informado', 0, 0, 'Nao Informado', 'Nao Informado', 'Nao Informado');

-- Popula a dim_loja transformando e limpando os dados brutos vindos da staging `stg_loja`
INSERT INTO dim_loja (cod_loja, chave_loja, nome_loja, cidade, uf, mesorregiao, populacao_cidade, area_venda_m2, porte, faixa_franquia, formato_loja)
SELECT 
    `CodLoja`,
    UPPER(REPLACE(REPLACE(`NomeLoja`, '/SC', ''), '  ', ' ')) AS chave_loja,
    `NomeLoja` AS nome_loja,
    `Cidade`,
    `UF`,
    `Mesorregiao`,
    CAST(REPLACE(`PopulacaoCidade`, '.', '') AS UNSIGNED),
    CAST(`AreaVenda_m2` AS UNSIGNED),
    'Nao Informado' AS porte,
    `FaixaFranquia`,
    `FormatoLoja`
FROM stg_loja;

-- -------------------------------------------------------------------------------------
-- ESTRUTURA DAS DEMAIS TABELAS VAZIAS
-- -------------------------------------------------------------------------------------
-- Prepara a estrutura vazia da dimensão de categorias a ser populada no script seguinte
DROP TABLE IF EXISTS dim_categoria;
CREATE TABLE dim_categoria (
    sk_categoria INT AUTO_INCREMENT PRIMARY KEY,
    categoria_origem VARCHAR(50),
    nome_categoria VARCHAR(30),
    grupo_categoria VARCHAR(20)
);

-- Prepara a estrutura vazia da dimensão de praças geográficas
DROP TABLE IF EXISTS dim_praca;
CREATE TABLE dim_praca (
    sk_praca INT AUTO_INCREMENT PRIMARY KEY,
    cod_praca VARCHAR(10),
    nome_praca VARCHAR(60),
    regional VARCHAR(30),
    domicilios_com_pet INT
);

-- Prepara a estrutura da tabela ponte N:N para o rateio entre lojas e praças
DROP TABLE IF EXISTS bridge_loja_praca;
CREATE TABLE bridge_loja_praca (
    cod_loja VARCHAR(10),
    sk_praca INT,
    fator_publico DECIMAL(6,4)
);

-- Prepara a estrutura central da tabela fato de pedidos
DROP TABLE IF EXISTS fato_pedido;
CREATE TABLE fato_pedido (
    numero_pedido VARCHAR(255),
    sk_tempo_pedido INT,
    sk_tempo_entrega INT,
    sk_loja INT,
    sk_categoria INT,
    qtd_itens INT,
    qtd_unidades_devolvidas INT,
    nr_itens_cancelados INT,
    peso_total_kg DECIMAL(10,2),
    vl_bruto DECIMAL(15,2),
    vl_desconto DECIMAL(15,2),
    vl_liquido DECIMAL(15,2),
    houve_desconto VARCHAR(10),
    canal_pedido VARCHAR(30),
    vl_frete DECIMAL(15,2),
    transportadora VARCHAR(50),
    situacao_pedido VARCHAR(30),
    dias_integracao_separacao INT,
    dias_separacao_nota INT,
    dias_nota_despacho INT,
    dias_despacho_entrega INT,
    dias_total_ate_entrega INT
);