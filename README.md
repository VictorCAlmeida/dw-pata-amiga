# Projeto Data Warehouse - Pata Amiga
Data Warehouse em Star Schema para a rede Pata Amiga (MySQL).


## 1. Visão Geral do Projeto
Este projeto consiste na implementação de um Data Warehouse (DW) utilizando modelagem dimensional em estrela (Star Schema) para a rede **Pata Amiga**[cite: 1, 2, 3]. O objetivo é consolidar dados operacionais de vendas, lojas, praças e categorias para análises estratégicas e suporte à tomada de decisão da diretoria[cite: 1, 2, 3].

---

## 2. Diagnóstico da Staging (Tarefa 1)
Antes da transformação e carga para o modelo dimensional (`dw_pata_amiga`), foi realizada uma auditoria na camada de *staging* para identificar inconsistências, valores nulos e padrões de grafia[cite: 1, 2, 3].

### Resultados da Conferência Inicial:
* **`stg_pedido`**: 4.044 linhas (Esperado: 4.044)[cite: 1, 2, 3]
* **`stg_loja`**: 32 linhas (Esperado: 32)
* **`stg_loja_praca`**: 48 linhas (Esperado: 48)[cite: 20]

### Diagnósticos e Inconsistências Identificadas:
* **Grafias distintas de categoria**: 18 variações brutas encontradas, tratadas posteriormente na padronização para 7 categorias oficiais[cite: 21].
* **Grafias distintas de nome de loja**: 50 variações de maiúsculas/minúsculas, abreviações e sufixos[cite: 21].
* **Grafias de Canal de Pedido e Desconto**: Mapeadas para 8 e 12 variações respetivamente para padronização analítica[cite: 21].
* **Pedidos sem Código de Loja**: 1.575 registros (~39%), correspondentes a vendas realizadas em canais digitais ou sem identificação de balcão[cite: 21].
* **Pedidos sem Nome de Loja**: 3 registros identificados (encaminhados para a linha padrão `-1` na dimensão)[cite: 1, 3, 21].
* **Marcos temporais em branco**: 1.953 entregas ainda não concluídas e registos sem data de separação preenchida (tratados com `-1` ou valores nulos no DW)[cite: 1, 2, 3, 21].

---

## 3. Arquitetura e Modelo Dimensional
O Data Warehouse segue o modelo estrela (*Star Schema*), estruturado em torno da tabela fato `fato_pedido` e rodeado pelas seguintes dimensões[cite: 1, 2, 3]:
* `dim_tempo` (utilizada em esquema de *role-playing* para Data do Pedido e Data de Entrega)[cite: 1, 3]
* `dim_loja` (fotografia atual das filiais)[cite: 3]
* `dim_praca` (regiões de atuação)[cite: 3]
* `bridge_loja_praca` (tabela ponte N:N responsável pelo rateio de público e faturamento entre lojas e praças)[cite: 1, 3]
* `dim_categoria` (categorias de produtos padronizadas)[cite: 1, 3]

---

## 4. Respostas às Perguntas de Negócio (Tarefa 5)
As consultas analíticas executadas no arquivo `05-perguntas.sql` permitiram extrair os seguintes insights para a diretoria[cite: 3]:

* **P1 (Desempenho por Categoria/Canal):** Identificação dos tempos médios logísticos por etapa, apontando o intervalo com maior retenção operacional no processo de entrega da rede[cite: 2, 3].
* **P2 (Análise de Prazos e Logística):** Consolidação do faturamento por categoria de produto limpa e padronizada, demonstrando o peso percentual de cada segmento face ao total faturado[cite: 2, 3].
* **P3 (Comportamento de Descontos):** Avaliação do impacto do desconto no ticket médio segmentado por canal de venda (App, Site, Loja Física, Telefone e WhatsApp), evidenciando discrepâncias nas políticas comerciais aplicadas[cite: 2, 3].
* **P4 (Desempenho por Praça):** Cruzamento do faturamento rateado através da tabela ponte com o número de domicílios com animais de estimação por praça de atendimento[cite: 2, 3].
* **P5 (Recomendação de Expansão):** 
  * *Recomendação:* Com base nos dados consolidados, sugere-se a abertura da próxima loja na praça com maior rácio de itens vendidos por mil habitantes e elevado tempo médio de entrega nas zonas periféricas[cite: 2, 3].
  * *Limitações dos dados:* O modelo atual não contempla dados demográficos externos (renda per capita da região) nem custos operacionais detalhados, sendo uma análise estritamente comportamental baseada no histórico de vendas existente[cite: 2, 3].

---

## 5. Como Executar os Scripts
A ordem correta de execução no MySQL Workbench é:
1. `01-carga-staging.sql` (Criação e carga das tabelas brutas)[cite: 2, 3]
2. `02-dimensoes-prontas.sql` (Criação das dimensões estáticas)[cite: 3]
3. `03-dimensoes.sql` (População das dimensões dinâmicas e da tabela ponte)[cite: 3]
4. `04-fato.sql` (Carga da tabela fato com conversões, modo estrito ajustado e cálculos de prazos)[cite: 1, 2, 3]
5. `05-perguntas.sql` (Execução das queries analíticas para a diretoria)[cite: 3]
