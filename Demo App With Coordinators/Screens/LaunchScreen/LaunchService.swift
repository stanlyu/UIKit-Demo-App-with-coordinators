//
//  LaunchService.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 23.12.2025.
//

import Foundation

protocol LaunchServicing: Sendable {
    @concurrent func fetchData() async
}

struct LaunchService: LaunchServicing {
    @concurrent func fetchData() async {
        // Эмитируем загрузку необходимых данных для того, чтобы можно было обновить UI
        try? await Task.sleep(nanoseconds: UInt64.random(in: 2_000_000_000...5_000_000_000))
    }
}
