// Ordem e nomes dos tipos, em linguagem de quem atende chamados.
export const TIPOS = [
  { codigo: 'FALTA_NO_PAINEL',   nome: 'Falta no painel',   explicacao: 'Está no ERP e não aparece no painel.' },
  { codigo: 'DUPLICADO',         nome: 'Duplicado',         explicacao: 'Aparece mais de uma vez no painel.' },
  { codigo: 'STATUS_DIVERGENTE', nome: 'Status diferente',  explicacao: 'O painel mostra um status diferente do ERP.' },
  { codigo: 'SEM_ITENS',         nome: 'Sem itens',         explicacao: 'Está no painel, mas sem nenhum produto.' },
]

export const NOME_DO_TIPO = Object.fromEntries(TIPOS.map((t) => [t.codigo, t.nome]))
