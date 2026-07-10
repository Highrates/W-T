# Админ-панель — спецификация вёрстки

Самодостаточный гайд: разметка + CSS. Можно копировать в любой проект без привязки к исходникам.

Шрифт: **Commissioner** (или `system-ui`). Базовая высота контролов: **28px**. Границы: **hairline 0.7px**.

---

## 1. CSS-переменные (положить в `:root`)

```css
:root {
  --color-ink-black: #051826;
  --color-black: #000000;
  --color-white: #ffffff;
  --color-gray: #9d9d9d;
  --color-bright-snow: #f6f6f6;
  --color-red: #ff0000;
  --color-blue: #3d83f6;

  --account-hairline-width: 0.7px;
  --account-hairline-color: rgba(0, 0, 0, 0.2);

  --font-commissioner: 'Commissioner Variable', system-ui, sans-serif;

  --text-body: 15px;
  --text-body-weight: 300;
  --text-caption: 14px;
  --text-caption-weight: 300;
  --line-height-sm: 18px;
  --text-secondary: #9d9d9d;

  --admin-text-primary: var(--color-black);
  --admin-text-tertiary: var(--text-secondary);
  --admin-border-secondary: var(--account-hairline-color);
  --admin-bg-quaternary: var(--color-bright-snow);

  --text-card-20-400: 20px;
  --text-card-16-400: 16px;
  --cursor-radius-full: 9999px;
}
```

---

## 2. Оболочка страницы

```html
<div class="admin-shell">
  <aside class="admin-sidebar">
    <p class="admin-brand">Forne Admin</p>
    <nav class="admin-nav">
      <a class="admin-nav-link admin-nav-link--active" href="#">Заказы</a>
      <a class="admin-nav-link" href="#">Каталог</a>
      <button class="admin-nav-link" type="button">
        <span class="admin-nav-label">Настройки</span>
      </button>
    </nav>
  </aside>
  <main class="admin-content">
    <!-- контент раздела -->
  </main>
</div>
```

```css
.admin-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f7f7f7;
}

.admin-shell > .admin-body,
.admin-shell {
  display: flex;
  flex: 1;
  min-height: 0;
}

.admin-sidebar {
  width: 240px;
  flex-shrink: 0;
  padding: 16px 8px 8px;
  background: #f3f3f3;
  border-right: var(--account-hairline-width) solid var(--account-hairline-color);
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.admin-brand {
  margin: 0 0 8px;
  padding: 0 10px;
  font-family: var(--font-commissioner);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-ink-black);
}

.admin-nav {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.admin-nav-link {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  height: 30px;
  padding: 0 10px;
  border: none;
  border-radius: 6px;
  background: transparent;
  font-family: var(--font-commissioner);
  font-size: var(--text-body);
  font-weight: var(--text-body-weight);
  color: var(--color-black);
  text-decoration: none;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.admin-nav-link:hover,
.admin-nav-link--active {
  background: #e6e6e6;
}

.admin-nav-count {
  color: var(--color-red);
  font-size: var(--text-body);
}

.admin-content {
  flex: 1;
  min-width: 0;
  padding: 24px 28px;
  background: #f7f7f7;
}
```

---

## 3. Заголовки и текст

```html
<h1 class="admin-title">Заказы</h1>
<p class="admin-lead">Список заказов и заявок на подбор.</p>
<p class="admin-muted">Загрузка…</p>
```

```css
.admin-title {
  margin: 0 0 8px;
  font-family: var(--font-commissioner);
  font-size: var(--text-card-20-400);
  font-weight: 400;
  text-transform: uppercase;
  color: var(--color-ink-black);
}

.admin-lead {
  margin: 0 0 20px;
  font-size: var(--text-body);
  color: var(--color-gray);
  line-height: 1.5;
}

.admin-muted {
  margin: 12px 0 0;
  font-size: 0.875rem;
  color: var(--color-gray);
}

.admin-error {
  margin: 0 0 12px;
  padding: 10px 12px;
  border-radius: 8px;
  background: #fdf5f5;
  color: #c53029;
  font-size: 0.875rem;
}
```

---

## 4. Поля ввода (input / textarea / select)

### Разметка

```html
<div class="admin-field">
  <label class="admin-field-label" for="email">Email</label>
  <input class="admin-control admin-control--input" id="email" type="email" placeholder="name@example.com" />
</div>

<div class="admin-field">
  <label class="admin-field-label" for="note">Комментарий</label>
  <textarea class="admin-control admin-control--textarea" id="note" rows="4"></textarea>
</div>

<div class="admin-field">
  <label class="admin-field-label" for="status">Статус</label>
  <select class="admin-control admin-control--select" id="status">
    <option>Новый</option>
    <option>В работе</option>
  </select>
</div>

<!-- ошибка -->
<div class="admin-field">
  <label class="admin-field-label" for="bad">Поле</label>
  <input class="admin-control admin-control--input" id="bad" aria-invalid="true" />
  <p class="admin-field-error" role="alert">Обязательное поле</p>
</div>
```

### Стили

```css
.admin-field {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
  width: 100%;
  min-width: 0;
}

.admin-field-label {
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  color: var(--color-gray);
}

.admin-control {
  box-sizing: border-box;
  width: 100%;
  min-width: 0;
  margin: 0;
  border: var(--account-hairline-width) solid var(--admin-border-secondary);
  border-radius: 6px;
  background-color: var(--color-white);
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  line-height: var(--line-height-sm);
  color: var(--color-black);
  outline: none;
  transition: border-color 0.15s ease, background-color 0.15s ease;
}

.admin-control--input,
.admin-control--select {
  height: 28px;
  min-height: 28px;
  padding: 0 8px;
}

.admin-control--textarea {
  min-height: 88px;
  padding: 6px 8px;
  resize: vertical;
}

.admin-control--select {
  padding-right: 32px;
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none'%3E%3Cpath d='M6 9l6 6 6-6' stroke='%235c6569' stroke-width='2.25' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  background-size: 14px;
}

.admin-control::placeholder {
  color: var(--admin-text-tertiary);
}

.admin-control:hover:not(:disabled):not(:read-only):not([aria-invalid='true']):not(:focus) {
  border-color: rgba(0, 0, 0, 0.35);
}

.admin-control:focus {
  border-color: var(--color-blue);
}

.admin-control:disabled,
.admin-control:read-only {
  cursor: not-allowed;
  background: var(--admin-bg-quaternary);
  color: var(--admin-text-tertiary);
}

.admin-control[aria-invalid='true'] {
  border-color: var(--color-red);
}

.admin-field-error {
  margin: 0;
  font-size: var(--text-caption);
  color: var(--color-red);
}
```

### Форма (вертикальный стек)

```html
<form class="admin-form">
  <div class="admin-field">…</div>
  <div class="admin-field">…</div>
  <div class="admin-form-actions">
    <button type="submit" class="admin-btn admin-btn--accent">Сохранить</button>
    <button type="button" class="admin-btn admin-btn--outline">Отмена</button>
  </div>
</form>
```

```css
.admin-form {
  max-width: 480px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.admin-form--wide {
  max-width: min(1100px, 100%);
}

.admin-form-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}
```

---

## 5. Поиск (компактный, как инпут)

```html
<div class="admin-search">
  <svg class="admin-search-icon" width="16" height="16" viewBox="0 0 20 20" aria-hidden="true">
    <path d="M9.58 17.5C13.96 17.5 17.5 13.96 17.5 9.58C17.5 5.21 13.96 1.67 9.58 1.67C5.21 1.67 1.67 5.21 1.67 9.58C1.67 13.96 5.21 17.5 9.58 17.5Z" stroke="currentColor" stroke-width="1.3" fill="none"/>
    <path d="M18.33 18.33L16.67 16.67" stroke="currentColor" stroke-width="1.3"/>
  </svg>
  <input class="admin-search-input" type="search" placeholder="Поиск…" aria-label="Поиск" />
</div>
```

```css
.admin-search {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  height: 28px;
  padding: 0 8px;
  box-sizing: border-box;
  background: var(--color-white);
  border: var(--account-hairline-width) solid var(--admin-border-secondary);
  border-radius: 6px;
  transition: border-color 0.15s ease;
}

.admin-search:hover {
  border-color: rgba(0, 0, 0, 0.35);
}

.admin-search:focus-within {
  border-color: var(--color-blue);
}

.admin-search-icon {
  flex-shrink: 0;
  color: var(--admin-text-tertiary);
}

.admin-search-input {
  flex: 1;
  min-width: 0;
  border: none;
  background: none;
  padding: 0;
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  color: var(--color-black);
  outline: none;
}

.admin-search-input::placeholder {
  color: var(--admin-text-tertiary);
}
```

---

## 6. Табы

### 6.1 Underline — переключение разделов

```html
<div class="admin-tabs-underline" role="tablist" aria-label="Разделы">
  <button type="button" role="tab" aria-selected="true" class="admin-tab-underline admin-tab-underline--active">Заказы</button>
  <button type="button" role="tab" aria-selected="false" class="admin-tab-underline">Подбор <span class="admin-nav-count">(3)</span></button>
</div>
<div style="margin-top: 20px"><!-- контент вкладки --></div>
```

```css
.admin-tabs-underline {
  display: flex;
  flex-wrap: wrap;
  margin: 16px 0;
  border-bottom: var(--account-hairline-width) solid var(--account-hairline-color);
}

.admin-tabs-underline--compact {
  margin: 0 0 8px;
}

.admin-tab-underline {
  margin-bottom: -1px;
  padding: 10px 12px;
  border: none;
  border-bottom: 1px solid transparent;
  border-radius: 6px 6px 0 0;
  background: transparent;
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  line-height: var(--line-height-sm);
  color: var(--text-secondary);
  cursor: pointer;
  transition: color 0.15s ease, border-color 0.15s ease;
}

.admin-tab-underline:hover {
  color: var(--color-black);
}

.admin-tab-underline--active {
  color: var(--color-black);
  border-bottom-color: var(--color-black);
}
```

### 6.2 Pill — фильтры / статусы

```html
<div class="admin-tabs-pill" role="tablist" aria-label="Фильтр">
  <button type="button" role="tab" aria-selected="true" class="admin-tab-pill admin-tab-pill--active">Все</button>
  <button type="button" role="tab" aria-selected="false" class="admin-tab-pill">Новые</button>
  <button type="button" role="tab" aria-selected="false" class="admin-tab-pill">В работе</button>
</div>
```

```css
.admin-tabs-pill {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin-bottom: 16px;
}

.admin-tab-pill {
  display: flex;
  min-width: 32px;
  min-height: 28px;
  padding: 5px 10px;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: var(--cursor-radius-full);
  background: transparent;
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  line-height: var(--line-height-sm);
  color: var(--text-secondary);
  white-space: nowrap;
  cursor: pointer;
  transition: color 0.15s ease, background-color 0.15s ease;
}

.admin-tab-pill:hover {
  color: var(--color-black);
}

.admin-tab-pill--active {
  color: var(--color-black);
  background: #e6e6e6;
}
```

---

## 7. Кнопки

### 7.1 Компактные (основные в админке) — h 28px

```html
<button type="button" class="admin-btn admin-btn--neutral">Действие</button>
<button type="button" class="admin-btn admin-btn--accent">Сохранить</button>
<button type="button" class="admin-btn admin-btn--danger">Удалить</button>
<button type="button" class="admin-btn admin-btn--outline">Отмена</button>
```

```css
.admin-btn {
  box-sizing: border-box;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 28px;
  padding: 0 8px;
  border: none;
  border-radius: 6px;
  white-space: nowrap;
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  line-height: 1;
  color: var(--color-white);
  cursor: pointer;
  transition: background-color 0.15s ease, filter 0.15s ease;
}

.admin-btn--neutral {
  background: var(--color-black);
}

.admin-btn--neutral:hover:not(:disabled) {
  filter: brightness(1.22);
}

.admin-btn--accent {
  background: var(--color-blue);
}

.admin-btn--accent:hover:not(:disabled) {
  filter: brightness(1.12);
}

.admin-btn--danger {
  background: var(--color-red);
}

.admin-btn--danger:hover:not(:disabled) {
  filter: brightness(1.12);
}

.admin-btn--outline {
  background: var(--color-white);
  color: var(--color-black);
  border: var(--account-hairline-width) solid var(--account-hairline-color);
}

.admin-btn--outline:hover:not(:disabled) {
  background: #e6e6e6;
}

.admin-btn:focus-visible {
  outline: 2px solid var(--color-blue);
  outline-offset: 2px;
}

.admin-btn:disabled {
  background: var(--color-bright-snow);
  color: var(--color-gray);
  cursor: not-allowed;
  filter: none;
}
```

---

## 8. Таблицы

```html
<div class="admin-toolbar">
  <div class="admin-search admin-search--toolbar">…</div>
  <button type="button" class="admin-btn admin-btn--accent">Добавить</button>
</div>

<div class="admin-table-wrap">
  <table class="admin-table">
    <thead>
      <tr>
        <th><input type="checkbox" /></th>
        <th>Название</th>
        <th>Статус</th>
        <th class="admin-table-actions"></th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><input type="checkbox" /></td>
        <td><a href="#">Товар 1</a></td>
        <td><span class="admin-badge admin-badge--on">Активен</span></td>
        <td class="admin-table-actions">
          <button type="button" class="admin-table-remove" aria-label="Удалить">×</button>
        </td>
      </tr>
      <tr class="admin-table-row--inactive">
        <td>…</td>
      </tr>
    </tbody>
  </table>
</div>
```

```css
.admin-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 18px;
}

.admin-search--toolbar {
  flex: 1;
  min-width: 200px;
  max-width: 360px;
}

.admin-table-wrap {
  overflow-x: auto;
  border-radius: 12px;
  border: var(--account-hairline-width) solid var(--account-hairline-color);
  background: var(--color-white);
}

.admin-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  font-family: var(--font-commissioner);
  font-size: var(--text-body);
  font-weight: var(--text-body-weight);
}

.admin-table th,
.admin-table td {
  padding: 10px 12px;
  text-align: left;
  vertical-align: middle;
  border: none;
}

.admin-table th {
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  color: var(--color-gray);
}

.admin-table thead tr th {
  border-bottom: var(--account-hairline-width) solid var(--account-hairline-color);
}

.admin-table tbody tr + tr td {
  border-top: var(--account-hairline-width) solid var(--account-hairline-color);
}

.admin-table tbody tr:hover td {
  background: #e6e6e6;
}

.admin-table a {
  color: var(--color-black);
  text-decoration: none;
}

.admin-table a:hover {
  text-decoration: underline;
}

.admin-table-actions {
  width: 1%;
  white-space: nowrap;
  text-align: right;
}

.admin-table-row--inactive td:not(:first-child) {
  opacity: 0.55;
}

/* миниатюра в ячейке */
.admin-table-thumb {
  width: 46px;
  height: 46px;
  object-fit: cover;
  border-radius: 6px;
  border: 1px solid var(--account-hairline-color);
  background: #f5f7f8;
}

/* статус в ячейке */
.admin-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 500;
}

.admin-badge--on {
  background: #e6f4ea;
  color: #1e6b2f;
}

.admin-badge--off {
  background: #f0f0f0;
  color: var(--color-gray);
}

/* кнопка удаления в строке */
.admin-table-remove {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  padding: 0;
  border: 1px solid rgba(197, 48, 41, 0.38);
  border-radius: 50%;
  background: rgba(197, 48, 41, 0.06);
  color: #c53029;
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
}

.admin-table-remove:hover:not(:disabled) {
  background: rgba(197, 48, 41, 0.12);
}
```

### Пагинация

```html
<div class="admin-pagination">
  <button type="button" class="admin-btn admin-btn--outline" disabled>Назад</button>
  <span class="admin-pagination-label">Стр. 1 из 5 · всего 42</span>
  <button type="button" class="admin-btn admin-btn--outline">Вперёд</button>
</div>
```

```css
.admin-pagination {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
}

.admin-pagination-label {
  font-size: var(--text-caption);
  color: var(--color-gray);
}
```

---

## 9. Модальное окно

```html
<div class="admin-modal-overlay" role="presentation">
  <div class="admin-modal" role="dialog" aria-labelledby="modal-title">
    <header class="admin-modal-head">
      <h2 class="admin-modal-title" id="modal-title">Подтверждение</h2>
      <button type="button" class="admin-modal-close" aria-label="Закрыть">×</button>
    </header>
    <div class="admin-modal-body">
      <p>Удалить запись?</p>
    </div>
    <footer class="admin-modal-footer">
      <button type="button" class="admin-btn admin-btn--outline">Отмена</button>
      <button type="button" class="admin-btn admin-btn--danger">Удалить</button>
    </footer>
  </div>
</div>
```

```css
.admin-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1250;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
  background: rgba(5, 24, 38, 0.4);
}

.admin-modal {
  width: 100%;
  max-width: min(560px, 100%);
  max-height: min(92vh, 880px);
  display: flex;
  flex-direction: column;
  background: var(--color-white);
  border: var(--account-hairline-width) solid var(--account-hairline-color);
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 12px 40px rgba(5, 24, 38, 0.12);
}

.admin-modal--wide {
  max-width: min(960px, 100%);
}

.admin-modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: var(--account-hairline-width) solid var(--account-hairline-color);
}

.admin-modal-title {
  margin: 0;
  font-family: var(--font-commissioner);
  font-size: var(--text-card-16-400);
  font-weight: 400;
  text-transform: uppercase;
  color: var(--color-ink-black);
}

.admin-modal-close {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: var(--color-gray);
  font-size: 1.25rem;
  cursor: pointer;
}

.admin-modal-close:hover {
  background: #f5f7f8;
  color: var(--color-ink-black);
}

.admin-modal-body {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.admin-modal-footer {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 16px;
  border-top: var(--account-hairline-width) solid var(--account-hairline-color);
}
```

---

## 10. Чипы (теги)

```html
<ul class="admin-chips">
  <li class="admin-chip">
    <span class="admin-chip-label">Красный</span>
    <button type="button" class="admin-chip-remove" aria-label="Убрать">×</button>
  </li>
</ul>
```

```css
.admin-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.admin-chip {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  min-height: 28px;
  padding: 5px 4px 5px 10px;
  border-radius: var(--cursor-radius-full);
  background: #e6e6e6;
  font-family: var(--font-commissioner);
  font-size: var(--text-caption);
  font-weight: var(--text-caption-weight);
  color: var(--color-black);
}

.admin-chip-remove {
  width: 22px;
  height: 22px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--color-gray);
  font-size: 1.125rem;
  cursor: pointer;
}

.admin-chip-remove:hover {
  background: rgba(0, 0, 0, 0.08);
  color: var(--color-black);
}
```

---

## 11. Карточки дашборда

```html
<ul class="admin-dashboard-grid">
  <li>
    <a class="admin-card" href="#">
      <span class="admin-card-title">Каталог</span>
      <span class="admin-card-note">Товары и категории</span>
    </a>
  </li>
</ul>
```

```css
.admin-dashboard-grid {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
}

.admin-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 14px 16px;
  min-height: 88px;
  border-radius: 8px;
  background: var(--color-white);
  border: var(--account-hairline-width) solid var(--account-hairline-color);
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.15s ease, background-color 0.15s ease;
}

.admin-card:hover {
  background: var(--color-bright-snow);
  box-shadow: 0 4px 16px rgba(5, 24, 38, 0.06);
}

.admin-card-title {
  font-size: var(--text-card-16-400);
  color: var(--color-black);
}

.admin-card-note {
  font-size: var(--text-caption);
  color: var(--color-gray);
  line-height: 1.4;
}
```

---

## 12. Типовая страница списка (собранный пример)

```html
<main class="admin-content">
  <h1 class="admin-title">Заказы</h1>

  <!-- разделы -->
  <div class="admin-tabs-underline" role="tablist">
    <button class="admin-tab-underline admin-tab-underline--active" type="button">Заказы</button>
    <button class="admin-tab-underline" type="button">Подбор</button>
  </div>

  <!-- фильтры -->
  <div class="admin-tabs-pill" role="tablist">
    <button class="admin-tab-pill admin-tab-pill--active" type="button">Новые</button>
    <button class="admin-tab-pill" type="button">В работе</button>
    <button class="admin-tab-pill" type="button">Закрытые</button>
  </div>

  <!-- toolbar + table + pagination — см. §8 -->
</main>
```

---

## 13. Шпаргалка размеров

| Элемент | Высота | Шрифт | Radius | Border |
|---------|--------|-------|--------|--------|
| Input / Select / Search / Compact btn | 28px | 14px / 300 | 6px | hairline 0.7px |
| Textarea | min 88px | 14px | 6px | hairline |
| Underline tab | auto | 14px | 6px 6px 0 0 | bottom 1px active |
| Pill tab / Chip | 28px | 14px | 9999px | none |
| Table cell padding | — | body 15px | — | row dividers hairline |
| Modal | — | title 16px caps | 8px | hairline |
| Page title | — | 20px caps | — | — |

Цвета состояний:
- **Hover** поля: border `rgba(0,0,0,0.35)`
- **Focus** поля: border `#3d83f6`
- **Error** поля: border `#ff0000`
- **Hover** строки таблицы: bg `#e6e6e6`
- **Active** pill/nav: bg `#e6e6e6`
