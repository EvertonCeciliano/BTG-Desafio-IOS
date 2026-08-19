# BTG Desafio iOS

App de conversão de moedas desenvolvido como resposta ao desafio técnico do BTG Pactual.

---

## Sobre

Permite ao usuário selecionar uma moeda de origem e uma de destino, inserir um valor e visualizar o resultado da conversão em tempo real. As taxas são obtidas via API e ficam disponíveis offline graças à persistência local.

## Telas

| Conversão | Lista de Moedas |
|---|---|
| Seleção de moedas, campo de valor e resultado | Busca por nome/código e ordenação |

## Arquitetura

**MVVM** com separação clara de responsabilidades:

```
btg/
├── Models/          # Currency, LiveRates, respostas da API
├── Services/        # NetworkService, Repository, PersistenceService
├── ViewModels/      # ConversionViewModel, CurrencyListViewModel
└── Views/           # ConversionViewController, CurrencyListViewController
```

- **UI:** UIKit programático (sem Storyboard)
- **Reatividade:** Combine (`@Published` + `sink`)
- **Async:** Swift Concurrency (`async/await`)
- **Cache:** UserDefaults para uso offline

## Features

### Obrigatórias
- [x] Taxas obtidas da API `/list` e `/live`
- [x] Conversão entre quaisquer duas moedas via dólar como moeda base
- [x] Tratamento de erros, loading e busca vazia

### Opcionais
- [x] Busca por nome ou código da moeda
- [x] Ordenação por nome ou código
- [x] Persistência local com fallback offline
- [x] Testes unitários (ViewModels + Repository)
- [x] Arquitetura MVVM
- [x] Pipeline de CI com GitHub Actions

## Testes

Cobertura de 20 testes unitários:

- `ConversionViewModelTests` — conversão, cross rate, swap, erros
- `CurrencyListViewModelTests` — filtro, ordenação, combinações
- `CurrencyRepositoryTests` — cache, fallback offline, persistência

Para rodar: adicione um **Unit Testing Bundle** target no Xcode com nome `btgTests` e inclua os arquivos da pasta `btgTests/`.

## CI

GitHub Actions roda build e testes em cada push e pull request para `main`.

```
.github/workflows/ci.yml
```

## Requisitos

- iOS 16+
- Xcode 16+
- Swift 5.9+
- Sem dependências externas

## Autor

**Everton Ceciliano** — primeiro projeto Swift, desenvolvido durante estudos de desenvolvimento iOS.
