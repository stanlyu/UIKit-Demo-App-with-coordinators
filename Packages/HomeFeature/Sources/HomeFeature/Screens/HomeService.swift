//
//  HomeService.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

protocol HomeServicing {
    @concurrent func fetchHomeData() async
}

struct HomeService: HomeServicing {
    @concurrent func fetchHomeData() async {
        // Эмитируем загрузку данных
        try? await Task.sleep(nanoseconds: 2_500_000_000)
    }
}
