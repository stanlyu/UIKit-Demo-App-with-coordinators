//
//  UIButton.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public extension UIButton {
    /// Создает стилизованную кнопку с указанными параметрами
    /// - Parameters:
    ///   - title: Заголовок кнопки
    ///   - backgroundColor: Цвет фона кнопки (по умолчанию .systemBlue)
    ///   - onTap: Замыкание, вызываемое при нажатии на кнопку
    /// - Returns: Сконфигурированный экземпляр UIButton
    static func styledButton(
        title: String,
        backgroundColor: UIColor = .systemBlue,
        onTap: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        button.setTitleColor(.label, for: .normal)

        // Конфигурация для отступов
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15)
        button.configuration = configuration

        // Настройка внешнего вида
        button.backgroundColor = backgroundColor
        button.tintColor = .white

        // Добавление тени
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 7
        button.layer.shadowOpacity = 0.5

        // Обработчик нажатия
        button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)

        return button
    }
}
