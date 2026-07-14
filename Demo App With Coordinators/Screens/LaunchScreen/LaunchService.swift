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
        // Эмитируем загрузку необходимых данных
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}
