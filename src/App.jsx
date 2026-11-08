import { useEffect, useMemo, useState } from 'react'
import { TIPOS, NOME_DO_TIPO } from './tipos.js'

const TODOS = 'TODOS'

const moeda = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })

function dataHora(iso) {
  if (!iso) return '—'
  const [data, hora] = iso.split('T')
  const [a, m, d] = data.split('-')
  return `${d}/${m}/${a} ${hora.slice(0, 5)}`
}

export default function App() {
  const [dados, setDados] = useState(null)
  const [erro, setErro] = useState(null)
  const [tipo, setTipo] = useState(TODOS)
  const [busca, setBusca] = useState('')

  useEffect(() => {
    fetch(`${import.meta.env.BASE_URL}divergencias.json`, { cache: 'no-store' })
      .then((r) => {
        if (!r.ok) throw new Error(`O arquivo divergencias.json não foi encontrado (erro ${r.status}).`)
        return r.json()
      })
      .then(setDados)
      .catch((e) => setErro(e.message))
  }, [])

  const linhas = dados?.divergencias ?? []

  const contagem = useMemo(() => {
    const c = Object.fromEntries(TIPOS.map((t) => [t.codigo, 0]))
    for (const l of linhas) c[l.tipo] = (c[l.tipo] ?? 0) + 1
    return c
  }, [linhas])

  const visiveis = useMemo(() => {
    const termo = busca.trim().toLowerCase()
    return linhas.filter(
      (l) =>
        (tipo === TODOS || l.tipo === tipo) &&
        (!termo ||
          String(l.numero_erp).includes(termo) ||
          (l.cliente ?? '').toLowerCase().includes(termo))
    )
  }, [linhas, tipo, busca])

  if (erro) {
    return (
      <main>
        <h1>Divergências entre ERP e painel</h1>
        <p className="aviso">{erro} Peça à TI para gerar os dados de novo.</p>
      </main>
    )
  }

  if (!dados) {
    return (
      <main>
        <p>Carregando…</p>
      </main>
    )
  }

  return (
    <main>
      <h1>Divergências entre ERP e painel</h1>
      <p className="sub">Dados gerados em {dataHora(dados.gerado_em)}. O ERP é sempre o correto.</p>

      <div className="contadores" role="group" aria-label="Filtrar por tipo">
        <button aria-pressed={tipo === TODOS} onClick={() => setTipo(TODOS)}>
          <strong>{linhas.length}</strong> Todos
        </button>
        {TIPOS.map((t) => (
          <button
            key={t.codigo}
            aria-pressed={tipo === t.codigo}
            onClick={() => setTipo(t.codigo)}
            title={t.explicacao}
          >
            <strong>{contagem[t.codigo]}</strong> {t.nome}
          </button>
        ))}
      </div>

      <label className="busca">
        Procurar pedido ou cliente
        <input
          type="search"
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
          placeholder="Ex.: 10052 ou Frio Norte"
        />
      </label>

      {visiveis.length === 0 ? (
        <p className="vazio">
          {linhas.length === 0
            ? 'Nenhuma divergência nos dados atuais.'
            : 'Nenhum pedido com esse filtro. Se o pedido não está aqui, o ERP e o painel estavam iguais na hora em que os dados foram gerados.'}
        </p>
      ) : (
        <div className="rolagem">
          <table>
            <thead>
              <tr>
                <th>Tipo</th>
                <th>Pedido</th>
                <th>Cliente</th>
                <th>Status no ERP</th>
                <th>Status no painel</th>
                <th className="num">Valor</th>
                <th>Incluído em</th>
                <th>O que aconteceu</th>
              </tr>
            </thead>
            <tbody>
              {visiveis.map((l) => (
                <tr key={`${l.tipo}-${l.numero_erp}`}>
                  <td>
                    <span className={`etiqueta ${l.tipo}`}>{NOME_DO_TIPO[l.tipo] ?? l.tipo}</span>
                  </td>
                  <td>{l.numero_erp}</td>
                  <td>
                    {l.cliente}
                    <div className="cnpj">{l.cnpj ?? 'sem CNPJ'}</div>
                  </td>
                  <td>{l.status_erp ?? '—'}</td>
                  <td>{l.status_painel ?? '—'}</td>
                  <td className="num">{l.valor_total == null ? '—' : moeda.format(l.valor_total)}</td>
                  <td>{dataHora(l.incluido_em)}</td>
                  <td>{l.detalhe}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </main>
  )
}
