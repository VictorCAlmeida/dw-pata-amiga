-- Seleciona o banco de dados principal do Data Warehouse da Pata Amiga
USE dw_pata_amiga;

-- =====================================================================================
-- 1 Onde está o gargalo da entrega?
-- =====================================================================================
-- Calcula a média em dias de cada um dos quatro marcos do processo logístico e o tempo total até a entrega,
-- permitindo identificar qual etapa do fluxo (Integração, Separação, Nota Fiscal ou Despacho) consome mais tempo.
SELECT  
    ROUND(AVG(dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(dias_separacao_nota), 2) AS media_separacao_nota,
    ROUND(AVG(dias_nota_despacho), 2) AS media_nota_despacho,
    ROUND(AVG(dias_despacho_entrega), 2) AS media_despacho_entrega,
    ROUND(AVG(dias_total_ate_entrega), 2) AS media_total_ate_entrega
FROM fato_pedido;

-- =====================================================================================
-- 2 Qual categoria concentra o faturamento?
-- =====================================================================================

-- (Trecho comentado anteriormente deixado intacto no script)
-- SELECT  
  -- c.nome_categoria,
  --  SUM(f.vl_liquido) AS faturamento_total,
   -- ROUND((SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido)) * 100, 2) AS percentual_total
-- FROM fato_pedido f
-- JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
-- GROUP BY c.nome_categoria
-- ORDER BY faturamento_total DESC;

-- Cruza a tabela fato com a dim_categoria padronizada para agrupar o faturamento líquido total por categoria,
-- calculando também o peso percentual de cada categoria sobre o faturamento global da rede.
SELECT  
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total,
    ROUND((SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido)) * 100, 2) AS percentual_total
FROM fato_pedido f
JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento_total DESC;

-- =====================================================================================
-- 3 O desconto funciona igual em todo canal?
-- =====================================================================================

-- Agrupa os pedidos por canal de venda e status de desconto para comparar a quantidade de pedidos
-- e o ticket médio gerado (com vs. sem desconto) em cada canal específico (App, Site, Loja Física, etc.).
SELECT  
    canal_pedido,
    houve_desconto,
    COUNT(numero_pedido) AS qtd_pedidos,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio
FROM fato_pedido
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;

-- =====================================================================================
-- 4 Qual praça de atendimento concentra o faturamento?
-- =====================================================================================

-- (Trecho comentado anteriormente deixado intacto no script)
-- SELECT  
   -- p.nome_praca,
   -- ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
  --  p.domicilios_com_pet
-- FROM fato_pedido f
-- JOIN bridge_loja_praca b ON f.sk_loja = b.cod_loja
-- JOIN dim_praca p ON b.sk_praca = p.sk_praca
-- GROUP BY p.cod_praca, p.nome_praca, p.domicilios_com_pet
-- ORDER BY faturamento_rateado DESC;

-- Realiza o rateio do faturamento das lojas para as praças de atendimento através da tabela ponte (bridge),
-- multiplicando o valor líquido pelo fator público e cruzando com o número de domicílios com pet de cada praça.
SELECT  
    p.nome_praca,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
    p.domicilios_com_pet
FROM fato_pedido f
JOIN stg_pedido sp ON sp.NumeroPedido = f.numero_pedido
JOIN bridge_loja_praca b ON b.cod_loja = sp.`Cod Loja`
JOIN dim_praca p ON b.sk_praca = p.sk_praca
GROUP BY p.sk_praca, p.nome_praca, p.domicilios_com_pet
ORDER BY faturamento_rateado DESC;

-- =====================================================================================
-- 5 Onde abrir a próxima loja (itens por mil habitantes)?
-- =====================================================================================

-- Ranqueia as lojas e cidades calculando a densidade de vendas relativa (total de itens vendidos por mil habitantes)
-- e cruzando com o tempo médio de entrega para subsidiar a decisão de expansão da rede.
SELECT  
    l.cidade,
    l.nome_loja,
    SUM(f.qtd_itens) AS total_itens_vendidos,
    l.populacao_cidade,
    ROUND((SUM(f.qtd_itens) / l.populacao_cidade) * 1000, 2) AS itens_por_mil_habitantes,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS media_dias_entrega
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
GROUP BY l.cidade, l.nome_loja, l.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;