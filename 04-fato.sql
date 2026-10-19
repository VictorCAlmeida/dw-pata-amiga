-- =====================================================================================
--  ARQUIVO 4:  A TABELA FATO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode por último, depois de garantir a carga das dimensões (Arquivos 2 e 3).
-- =====================================================================================

-- Seleciona o banco de dados principal do Data Warehouse da Pata Amiga
USE dw_pata_amiga;

-- Esvazia a tabela fato de pedidos para garantir uma carga limpa e sem duplicidades
TRUNCATE TABLE fato_pedido;

-- Insere os dados transformados e consolidados da staging diretamente na tabela fato (grão: 1 linha por pedido)
INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    qtd_itens,
    qtd_unidades_devolvidas,
    nr_itens_cancelados,
    peso_total_kg,
    vl_bruto,
    vl_desconto,
    vl_liquido,
    houve_desconto,
    canal_pedido,
    vl_frete,
    transportadora,
    situacao_pedido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT 
    p.`NumeroPedido` AS numero_pedido,
    
    -- SK Tempo Pedido (converte a data americana 'MM/DD/YYYY HH:MM PM' para o formato numérico YYYYMMDD)
    COALESCE(t1.sk_tempo, -1) AS sk_tempo_pedido,
    
    -- SK Tempo Entrega (converte 'YYYY-MM-DD' para o formato numérico YYYYMMDD; se vazio, assume a linha -1)
    COALESCE(t2.sk_tempo, -1) AS sk_tempo_entrega,
    
    -- SK Loja (busca na dimensão por nome padronizado; se não encontrar ou for vazio, aplica o fallback -1)
    COALESCE(l.sk_loja, -1) AS sk_loja,
    
    -- SK Categoria (busca na dimensão através da grafia crua; com fallback para -1 se ausente)
    COALESCE(c.sk_categoria, -1) AS sk_categoria,
    
    -- Métricas e Quantidades (conversão de texto para inteiro)
    CAST(p.`QTD.Itens` AS SIGNED) AS qtd_itens,
    CAST(p.`Qtd Unidades Devolvidas` AS SIGNED) AS qtd_unidades_devolvidas,
    CAST(p.`NrItensCancelados` AS SIGNED) AS nr_itens_cancelados,
    CAST(REPLACE(REPLACE(p.`Peso Total (kg)`, 'R$', ''), ',', '.') AS DECIMAL(10,2)) AS peso_total_kg,
    
    -- Valores Financeiros (aplicação da regra de números: trata vazios/traços como NULL e ajusta pontos/vírgulas)
    CASE 
        WHEN TRIM(REPLACE(p.`ValorBrutoPedido(R$)`,'R$','')) IN ('','-') THEN NULL
        WHEN p.`ValorBrutoPedido(R$)` LIKE '%,%' THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(p.`ValorBrutoPedido(R$)`,'R$',''),' ',''),'.',''),',','.') AS DECIMAL(15,2))
        ELSE CAST(REPLACE(REPLACE(p.`ValorBrutoPedido(R$)`,'R$',''),' ','') AS DECIMAL(15,2))
    END AS vl_bruto,

    CASE 
        WHEN TRIM(REPLACE(p.`Valor Desconto (R$)`,'R$','')) IN ('','-') THEN NULL
        WHEN p.`Valor Desconto (R$)` LIKE '%,%' THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(p.`Valor Desconto (R$)`,'R$',''),' ',''),'.',''),',','.') AS DECIMAL(15,2))
        ELSE CAST(REPLACE(REPLACE(p.`Valor Desconto (R$)`,'R$',''),' ','') AS DECIMAL(15,2))
    END AS vl_desconto,

    CASE 
        WHEN TRIM(REPLACE(p.`ValorLiquidoPedido(R$)`,'R$','')) IN ('','-') THEN NULL
        WHEN p.`ValorLiquidoPedido(R$)` LIKE '%,%' THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`,'R$',''),' ',''),'.',''),',','.') AS DECIMAL(15,2))
        ELSE CAST(REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`,'R$',''),' ','') AS DECIMAL(15,2))
    END AS vl_liquido,

    p.`HouveDesconto` AS houve_desconto,
    p.`CanalPedido` AS canal_pedido,

    CASE 
        WHEN TRIM(REPLACE(p.`Valor Frete (R$)`,'R$','')) IN ('','-') THEN NULL
        WHEN p.`Valor Frete (R$)` LIKE '%,%' THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(p.`Valor Frete (R$)`,'R$',''),' ',''),'.',''),',','.') AS DECIMAL(15,2))
        ELSE CAST(REPLACE(REPLACE(p.`Valor Frete (R$)`,'R$',''),' ','') AS DECIMAL(15,2))
    END AS vl_frete,

    p.`TransportadoraResponsavel` AS transportadora,
    p.`SituacaoPedido` AS situacao_pedido,

    -- Cálculo sequencial dos 4 intervalos logísticos em dias e do tempo total até a entrega via DATEDIFF
    DATEDIFF(STR_TO_DATE(p.`Dt Separacao Estoque`, '%Y-%m-%d'), STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p')) AS dias_integracao_separacao,
    DATEDIFF(STR_TO_DATE(p.`DtNotaFiscal`, '%Y-%m-%d'), STR_TO_DATE(p.`Dt Separacao Estoque`, '%Y-%m-%d')) AS dias_separacao_nota,
    DATEDIFF(STR_TO_DATE(p.`Dt_Despacho_Transportadora`, '%Y-%m-%d'), STR_TO_DATE(p.`DtNotaFiscal`, '%Y-%m-%d')) AS dias_nota_despacho,
    DATEDIFF(STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d'), STR_TO_DATE(p.`Dt_Despacho_Transportadora`, '%Y-%m-%d')) AS dias_despacho_entrega,
    DATEDIFF(STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d'), STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p')) AS dias_total_ate_entrega

FROM stg_pedido p

-- Lookup para Dimensão Loja (aplicando as 3 regras de exceção de grafia e removendo o sufixo '/SC')
LEFT JOIN dim_loja l ON l.chave_loja = 
    CASE 
        WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA BLUMENAL CENTRO' THEN 'PATA AMIGA BLUMENAU CENTRO'
        WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA FLORIPA NORTE' THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
        WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA JGUA DO SUL' THEN 'PATA AMIGA JARAGUA DO SUL'
        ELSE TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))
    END

-- Lookup para Dimensão Categoria (relacionando diretamente pela grafia crua da staging)
LEFT JOIN dim_categoria c ON c.categoria_origem = p.`CategoriaProduto`

-- Lookup para Dimensão Tempo (Data do Pedido em papel de Role-Playing)
LEFT JOIN dim_tempo t1 ON t1.sk_tempo = CAST(DATE_FORMAT(STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p'), '%Y%m%d') AS SIGNED)

-- Lookup para Dimensão Tempo (Data da Entrega em papel de Role-Playing)
LEFT JOIN dim_tempo t2 ON t2.sk_tempo = CAST(DATE_FORMAT(STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d'), '%Y%m%d') AS SIGNED);