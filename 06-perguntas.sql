-- =====================================================================================
--   ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--   Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--   Rode depois de: 04-fato.sql
--
--   Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--   aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--   P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--   Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--   de loja. AVG ignora NULL - por the etapa nao cumprida foi gravada como NULL.
--   dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

SELECT  
    -- Média de dias entre a integração no ERP e a separação no estoque
    ROUND(AVG(dias_integracao_separacao), 2) AS media_integracao_separacao,
    
    -- Média de dias entre a separação e a emissão da nota fiscal
    ROUND(AVG(dias_separacao_nota), 2) AS media_separacao_nota,
    
    -- Média de dias entre a nota fiscal e o despacho para a transportadora
    ROUND(AVG(dias_nota_despacho), 2) AS media_nota_despacho,
    
    -- Média de dias entre o despacho e a entrega efetiva na casa do cliente
    ROUND(AVG(dias_despacho_entrega), 2) AS media_despacho_entrega,
    
    -- Média do tempo total do processo completo (do ERP até a entrega final)
    ROUND(AVG(dias_total_ate_entrega), 2) AS media_total_ate_entrega
FROM fato_pedido;


-- =====================================================================================
--   P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--   Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--   PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--   subconsulta com o faturamento da rede como denominador.

SELECT  
    c.nome_categoria,
    -- Soma o faturamento líquido total por categoria de produto padronizada
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total,
    
    -- Calcula o percentual de participação de cada categoria em relação ao faturamento total da rede
    ROUND((SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido)) * 100, 2) AS percentual_total
FROM fato_pedido f
JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento_total DESC;


-- =====================================================================================
--   P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--   Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--   propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--   Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--   de WHATS.

SELECT  
    canal_pedido,
    houve_desconto,
    -- Conta a quantidade de pedidos agrupados por canal e aplicação de desconto
    COUNT(numero_pedido) AS qtd_pedidos,
    
    -- Calcula o ticket médio (média do valor líquido) para cada combinação de canal e desconto
    ROUND(AVG(vl_liquido), 2) AS ticket_medio
FROM fato_pedido
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;


-- =====================================================================================
--   P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--   Esta e a pergunta que paga a dim_praca e a ponte.
--   Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--   entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--   praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--   nao ser contado duas vezes.

SELECT  
    p.nome_praca,
    -- Multiplica o valor líquido pelo fator público da ponte para ratear corretamente o faturamento por praça
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
    p.domicilios_com_pet
FROM fato_pedido f
JOIN stg_pedido sp ON sp.NumeroPedido = f.numero_pedido
JOIN bridge_loja_praca b ON b.cod_loja = sp.`Cod Loja`
JOIN dim_praca p ON b.sk_praca = p.sk_praca
GROUP BY p.sk_praca, p.nome_praca, p.domicilios_com_pet
ORDER BY faturamento_rateado DESC;


-- =====================================================================================
--   P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--   (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--       denominador na dimensao), calculado AQUI na consulta - nunca gravado
--       pronto. Cruze com o tempo medio de entrega.
--   (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--       responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--       cadastro so tem a foto de hoje.
--   (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--       itens e valores em branco.

SELECT  
    l.cidade,
    l.nome_loja,
    -- Soma total de itens vendidos pela loja
    SUM(f.qtd_itens) AS total_itens_vendidos,
    l.populacao_cidade,
    
    -- Calcula o indicador de itens vendidos por cada mil habitantes da cidade da loja
    ROUND((SUM(f.qtd_itens) / l.populacao_cidade) * 1000, 2) AS itens_por_mil_habitantes,
    
    -- Cruza com o tempo médio de entrega da respectiva loja
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS media_dias_entrega
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
GROUP BY l.cidade, l.nome_loja, l.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;