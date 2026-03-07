# AGENTS.md

## Цель документа
Этот файл обязателен к прочтению любым ИИ-агентом перед изменениями в проекте `Kollocol`.
Задача: вносить изменения в том же архитектурном и код-стиле, не ломая текущие границы ответственности.

## Технологический контекст проекта
- Язык: Swift
- UI: UIKit, полностью кодом (без Storyboard/XIB)
- Архитектура модулей: SVIP в текущем формате проекта
- Навигация: через Coordinators
- Сеть: собственный `APIClient` + `Endpoint` + `RequestInterceptor`
- Асинхронность: `async/await`, `actor`, `@MainActor`

## Обязательный порядок секций в классах (`// MARK: -`)
Используй только нужные секции, но если секция есть, порядок строгий:
1. `// MARK: - Typealias`
2. `// MARK: - UI Components`
3. `// MARK: - Constants`
4. `// MARK: - Properties`
5. `// MARK: - Lifecycle`
6. `// MARK: - Methods`
7. `// MARK: - Private Methods`
8. `// MARK: - Actions`

Дополнительно:
- Для extension-реализаций протоколов используй отдельные блоки вида `// MARK: - UITableViewDataSource`, `// MARK: - UITextFieldDelegate` и т.д.
- Не добавляй секции «на будущее». Только те, что реально используются в файле.

## UIKit-верстка: только через свойства и `UIView+Pin`
- UI создается property-based способом: `private let ... = { ... }()`.
- Не использовать односимвольные имена (`l`, `b`, `v`, `tf`). Имена должны отражать назначение: `titleLabel`, `registerButton`, `avatarImageView`.
- Для констрейнтов использовать extension [`Kollocol/Extensions/UIView+Pin.swift`](/Users/aipotiakin/Files/Projects/Swift/Kollocol/Kollocol/Extensions/UIView+Pin.swift):
  - `pin(to:)`, `pinCenter(to:)`, `pinHorizontal(to:)`, `pinVertical(to:)`
  - `pinLeft/Right/Top/Bottom`, `pinCenterX/Y`
  - `setWidth`, `setHeight`, `pinWidth`, `pinHeight`
- Не ограничиваться только `leading/top/trailing/bottom`, использовать готовые групповые pin-методы, где это уместно.

## SVIP в этом проекте (фактическое соответствие имен)
В проекте SVIP реализован так:
- **S (Service layer)**: `Services/*`, `Networking/*`, `Token/*`
- **V (View)**: `*ViewController` (например, `StartViewController`, `MainViewController`)
- **I (Interactor)**: `*Logic` классы/акторы, реализующие `*Interactor` протоколы
- **P (Presenter/Router adapter)**: `*Router`, реализующие `*Presenter`
- **Configurator**: `*Assembly.build(...)`

### Главный принцип
Источник истины по сценарию — interactor (`*Logic`).

### Роли слоев
- `Interactor`:
  - принимает пользовательские события (через вызовы из View)
  - хранит/меняет бизнес-состояние сценария
  - принимает продуктовые решения
  - дергает сервисы и передает результат в presenter
- `Service layer`:
  - выполняет внешнюю работу (сеть, токены, хранилища)
  - не управляет сценарием экрана
  - не владеет бизнес-состоянием UI-сценария
- `View`:
  - отображение UI
  - сбор пользовательского ввода
  - проброс событий в interactor
  - без бизнес-решений и без прямых вызовов сервисов
- `Presenter/Router`:
  - адаптирует данные для отображения во View
  - триггерит навигацию
  - не хранит критичное бизнес-состояние сценария
- `Configurator (Assembly)`:
  - только сборка зависимостей и связывание модулей
  - без UI- и бизнес-логики

### Что делать
- Класть правила/переходы состояния/сценарную логику в interactor.
- Делать сервисный слой «техническим» относительно бизнеса.
- Держать View максимально пассивным.
- Собирать модуль в одном месте (`Assembly`).
- Направлять зависимости внутрь через протоколы.
- Проектировать так, чтобы бизнес-логика не зависела от UI-деталей.
- Не дублировать одно и то же состояние между слоями.

### Что не делать
- Не класть бизнес-логику во View.
- Не класть бизнес-логику в Presenter/Router.
- Не давать сервисам управлять сценарием экрана.
- Не хранить одно и то же состояние одновременно во View/Presenter/Interactor.
- Не обращаться к сервисам из UI напрямую (в обход interactor).
- Не смешивать навигацию, бизнес-решения и рендеринг в одном классе.

### Проверка правильной архитектуры
- Меняется бизнес-правило → правки в interactor.
- Меняется способ получения данных → правки в service/network слое.
- Меняется отображение → правки в View/Presenter.
- Меняется навигация → правки в coordinator/router.
- Меняется сборка зависимостей → правки в Assembly/SceneDelegate.

## Роутинг и алерты
- Навигация централизована в Coordinators:
  - [`Kollocol/Coordinators/AppCoordinator.swift`](/Users/aipotiakin/Files/Projects/Swift/Kollocol/Kollocol/Coordinators/AppCoordinator.swift)
  - [`Kollocol/Coordinators/AuthCoordinator.swift`](/Users/aipotiakin/Files/Projects/Swift/Kollocol/Kollocol/Coordinators/AuthCoordinator.swift)
  - [`Kollocol/Coordinators/MainCoordinator.swift`](/Users/aipotiakin/Files/Projects/Swift/Kollocol/Kollocol/Coordinators/MainCoordinator.swift)
- В идеале показ экранов и алертов делать через coordinator, а не напрямую из view/router.
- Для ошибок/алертов использовать `AlertPresenting`, `ErrorMessageDisplaying`, `ServiceErrorHandling`.

## Границы зависимостей и поток данных
- `ViewController` хранит `private var interactor: <Scene>Interactor`.
- `Logic` хранит `presenter` + сервисы (`UserService`, `AuthService`, `QuizService`, `SessionManager` и т.д.).
- `Router` хранит `weak var view` и `router: <RoutingProtocol>` для навигации.
- `Assembly.build(...)` связывает: `Router -> Logic -> ViewController`.

## Concurrency и Actor-правила
- Сервисы в проекте — `actor` (например, `AuthServiceImpl`, `UserServiceImpl`, `QuizServiceImpl`).
- Координаторы и роутеры, работающие с UI, помечены `@MainActor`.
- UI-обновления выполняются на main actor (`@MainActor` методы во view/router).
- Из View в async interactor обычно запуск через `Task { ... }`.

## Правила сервисного и сетевого слоя
- Внешние запросы оформляются через `Endpoint`.
- Общий клиент — `APIClient`; не дублируй HTTP-логику по сервисам.
- Ошибки сервисов маппятся через `NetworkServiceError.wrap(error)`.
- Для авторизации используется interceptor (`AuthInterceptor`) + `SessionManager`.
- DTO маппятся в Domain-модели в слое DTO/Domain (`toDomain()`), затем в ViewData (`toViewData()`) при необходимости.

## Стиль кода и соглашения проекта
- `final class` по умолчанию, где нет необходимости в наследовании.
- `@available(*, unavailable)` для `init(coder:)` в кодовых контроллерах/ячейках.
- Слабые ссылки на view в router (`weak var view`).
- Приватность по умолчанию: `private` для внутренних деталей.
- Extension-ы для протоколов и вспомогательных сущностей выносить в конец файла.
- Имена типов по роли: `StartAssembly`, `StartLogic`, `StartRouter`, `StartViewController`, `StartInteractor`, `StartPresenter`.

## Создание нового модуля (чеклист)
1. Создай `SceneNameAssembly`, `SceneNameLogic`, `SceneNameRouter`, `SceneNameViewController`, `SceneNameProtocols`, `SceneNameModels`.
2. В `Assembly` собери зависимости и свяжи `presenter.view = view`.
3. Во `ViewController` оставь только UI + проксирование событий в interactor.
4. В `Logic` помести сценарную бизнес-логику и работу с сервисами.
5. В `Router` помести навигацию и подготовку данных к отображению.
6. Для ошибок используй `ServiceErrorHandling` и user-facing сообщения.
7. Для layout используй только `UIView+Pin` + property-based UI.
8. Проверь порядок `// MARK: -` секций.

## Перед завершением задачи агент обязан проверить
1. Нет ли бизнес-логики в View/Router.
2. Нет ли прямых вызовов сервисов из UI.
3. Соблюден ли порядок `// MARK: -`.
4. Используются ли осмысленные имена переменных/свойств.
5. Констрейнты выставлены через `UIView+Pin`.
6. Навигация и алерты не размазаны по слоям и по возможности идут через coordinator.
7. Новые зависимости подключены через протоколы и сборку в `Assembly`/координаторе.
8. Если создал новый файл - в начале должно быть написано

//
//  <NAME>.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on <CURRENT_DATE>.
/
