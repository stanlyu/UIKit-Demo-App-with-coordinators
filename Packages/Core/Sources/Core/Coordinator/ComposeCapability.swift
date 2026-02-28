//
//  ComposeCapability.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

/// Capability-токен, подтверждающий право собрать `ContainerItem`.
///
/// Конструируется только внутри `Core` и используется инфраструктурой,
/// чтобы ограничить сборку контейнерных элементов выделенным слоем.
public struct ComposeCapability {
    internal init() {}
}
