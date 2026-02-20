//
//  RouterAliases.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 20.02.2026.
//

/// Семантические алиасы для контейнеров навигации.
///
/// Зачем:
/// - Координатор взаимодействует с контейнером именно в роли роутера.
/// - Единые алиасы убирают дублирование `typealias ...Router = ...Container` в каждом координаторе.
///
/// Как использовать:
/// - В координаторах указывайте generic через `*Router` (`StackRouter`, `InlineRouter`, `TabRouter`, `SwitchRouter`).
/// - Во внешнем слое (компоузеры, фабрики, SceneDelegate) используйте конкретные `*Container`.
///
/// Почему это безопасно:
/// - `typealias` не создает новый тип и не влияет на runtime.
/// - Это только читаемая договоренность по ролям на уровне исходного кода.
public typealias StackRouter = StackContainer
public typealias InlineRouter = InlineContainer
public typealias TabRouter = TabContainer
public typealias SwitchRouter = SwitchContainer
