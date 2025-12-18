//
//  LaunchViewController.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 16.12.2025.
//

import UIKit

protocol LaunchViewInput: AnyObject {
    func startAnimation()
    func stopAnimation()
}

class LaunchViewController: UIViewController {

    var output: LaunchViewOutput?

    // MARK: - UI Elements

    // Скрытый лейбл-чертеж
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 33, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        label.text = "Demo Application"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let maskedContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let slidingGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        return layer
    }()

    // MARK: - Animation Configuration

    private var isAnimating = false

    // Полный цикл прокрутки занимает 2 секунды
    private let loopDuration: TimeInterval = 2.0

    // Время на разгон и торможение (симметричное)
    private let rampDuration: TimeInterval = 0.3

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateGradientColors()
        }

        output?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayersGeometry()
    }

    // MARK: - Setup UI & Layers

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)
        view.addSubview(maskedContainerView)
        titleLabel.alpha = 0
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            maskedContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            maskedContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            maskedContainerView.widthAnchor.constraint(equalTo: titleLabel.widthAnchor),
            maskedContainerView.heightAnchor.constraint(equalTo: titleLabel.heightAnchor)
        ])
        maskedContainerView.layer.addSublayer(slidingGradientLayer)
        updateGradientColors()
    }

    private func configureLayersGeometry() {
        view.layoutIfNeeded()

        let textWidth = titleLabel.bounds.width
        let textHeight = titleLabel.bounds.height

        guard textWidth > 0, textHeight > 0 else { return }

        // 1. Создаем маску
        let maskLabel = UILabel()
        maskLabel.text = titleLabel.text
        maskLabel.font = titleLabel.font
        maskLabel.textAlignment = titleLabel.textAlignment
        maskLabel.numberOfLines = titleLabel.numberOfLines
        maskLabel.frame = titleLabel.bounds
        maskedContainerView.mask = maskLabel

        // 2. Ставим слой в начальную позицию
        // Начало: -2W
        slidingGradientLayer.frame = CGRect(
            x: -2 * textWidth,
            y: 0,
            width: textWidth * 3,
            height: textHeight
        )
    }

    private func updateGradientColors() {
        let labelColor = UIColor.label.resolvedColor(with: traitCollection).cgColor

        let rainbowColors: [CGColor] = [
            labelColor,
            UIColor.systemRed.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemYellow.cgColor,
            UIColor.systemGreen.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemIndigo.cgColor,
            UIColor.systemPurple.cgColor,
            labelColor
        ]

        var gradientColors: [CGColor] = []
        gradientColors.append(labelColor) // Начало A1
        gradientColors.append(contentsOf: rainbowColors) // A2
        gradientColors.append(labelColor) // Конец A3

        slidingGradientLayer.colors = gradientColors

        var locations: [NSNumber] = []
        let oneThird = 1.0 / 3.0

        locations.append(0.0)

        let rainbowCount = rainbowColors.count
        for i in 0..<rainbowCount {
            let relativePos = Double(i) / Double(rainbowCount - 1)
            let absolutePos = oneThird + (relativePos * oneThird)
            locations.append(NSNumber(value: absolutePos))
        }

        locations.append(1.0)

        slidingGradientLayer.locations = locations
    }

    // MARK: - Physics Helpers

    /// Вычисляет расстояние, необходимое для разгона/торможения, чтобы сохранить симметрию
    private func calculateRampDistance() -> CGFloat {
        let textWidth = titleLabel.bounds.width

        // 1. Дистанция полного цикла (-2W -> 0) равна 2W
        let loopDistance = 2 * textWidth

        // 2. Скорость цикла (пикселей в секунду)
        // V = S / t
        let loopVelocity = loopDistance / loopDuration

        // 3. Расстояние для разгона/торможения (S = V * t / 2)
        // Это формула площади под графиком скорости для линейного изменения
        let rampDistance = (loopVelocity * rampDuration) / 2.0

        return rampDistance
    }

    /// Вычисляет время, необходимое для прохождения оставшейся части пути с постоянной скоростью
    private func calculateDuration(for distance: CGFloat) -> TimeInterval {
        let textWidth = titleLabel.bounds.width
        let loopDistance = 2 * textWidth
        let loopVelocity = loopDistance / loopDuration

        guard loopVelocity > 0 else { return 0 }
        return TimeInterval(distance / loopVelocity)
    }
}

// MARK: - LaunchViewInput (Animation Logic)

extension LaunchViewController: LaunchViewInput {

    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        let rampDist = calculateRampDistance()
        let layerWidth = slidingGradientLayer.bounds.width

        // 1. Определяем координаты
        // Начальная точка (как в configureGeometry): -2W
        // Но нам нужен центр слоя для анимации position.x
        let startX = slidingGradientLayer.frame.origin.x
        let startCenter = startX + (layerWidth / 2)

        // Целевая точка разгона
        let targetCenter = startCenter + rampDist

        // 2. Анимация разгона
        let accelerationAnim = CABasicAnimation(keyPath: "position.x")
        accelerationAnim.fromValue = startCenter
        accelerationAnim.toValue = targetCenter
        accelerationAnim.duration = rampDuration
        accelerationAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        accelerationAnim.fillMode = .forwards
        accelerationAnim.isRemovedOnCompletion = false
        accelerationAnim.delegate = self
        accelerationAnim.setValue("acceleration", forKey: "animType")
        // Сохраняем, где мы остановимся, чтобы продолжить оттуда
        accelerationAnim.setValue(targetCenter, forKey: "endValue")

        slidingGradientLayer.add(accelerationAnim, forKey: "slideAnim")
    }

    func stopAnimation() {
        guard isAnimating else { return }
        isAnimating = false

        // 1. Получаем текущую позицию
        guard let presentationLayer = slidingGradientLayer.presentation() else { return }
        let currentPos = presentationLayer.position

        slidingGradientLayer.removeAnimation(forKey: "slideAnim")
        slidingGradientLayer.position = currentPos

        // 2. Рассчитываем тормозной путь (такой же, как при разгоне)
        let rampDist = calculateRampDistance()
        let finalPos = CGPoint(x: currentPos.x + rampDist, y: currentPos.y)

        // 3. Анимация остановки
        let decelerationAnim = CABasicAnimation(keyPath: "position")
        decelerationAnim.fromValue = currentPos
        decelerationAnim.toValue = finalPos
        decelerationAnim.duration = rampDuration
        decelerationAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        decelerationAnim.fillMode = .forwards
        decelerationAnim.isRemovedOnCompletion = false

        slidingGradientLayer.add(decelerationAnim, forKey: "stopAnim")
    }

    // Запуск остатка первого цикла (после разгона)
    private func runLoopRemainder(from currentCenterX: CGFloat) {
        guard isAnimating else { return }

        let layerWidth = slidingGradientLayer.bounds.width

        // Конец цикла — это когда левая граница слоя равна 0.
        // Центр при этом равен 0 + layerWidth/2
        let loopEndLeftX: CGFloat = 0
        let loopEndCenterX = loopEndLeftX + (layerWidth / 2)

        // Считаем дистанцию, которую осталось пройти до конца цикла
        let remainingDistance = loopEndCenterX - currentCenterX

        // Если вдруг мы уже пролетели (редкий кейс), сразу идем в новый цикл
        if remainingDistance <= 0 {
            runFullLoop()
            return
        }

        // Считаем время, чтобы скорость была такая же, как V_loop
        let duration = calculateDuration(for: remainingDistance)

        let remainderAnim = CABasicAnimation(keyPath: "position.x")
        remainderAnim.fromValue = currentCenterX
        remainderAnim.toValue = loopEndCenterX
        remainderAnim.duration = duration
        remainderAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        remainderAnim.fillMode = .forwards
        remainderAnim.isRemovedOnCompletion = false
        remainderAnim.delegate = self
        remainderAnim.setValue("loopRemainder", forKey: "animType")

        slidingGradientLayer.add(remainderAnim, forKey: "slideAnim")
    }

    // Запуск полного бесконечного цикла
    private func runFullLoop() {
        guard isAnimating else { return }

        let textWidth = titleLabel.bounds.width
        let layerWidth = slidingGradientLayer.bounds.width

        // Старт: -2W
        // Финиш: 0
        let startX = -2 * textWidth
        let endX: CGFloat = 0

        let startCenter = startX + (layerWidth / 2)
        let endCenter = endX + (layerWidth / 2)

        let loopAnim = CABasicAnimation(keyPath: "position.x")
        loopAnim.fromValue = startCenter
        loopAnim.toValue = endCenter
        loopAnim.duration = loopDuration
        loopAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        loopAnim.fillMode = .forwards
        loopAnim.isRemovedOnCompletion = false
        loopAnim.delegate = self
        loopAnim.setValue("fullLoop", forKey: "animType")

        slidingGradientLayer.add(loopAnim, forKey: "slideAnim")
    }
}

// MARK: - CAAnimationDelegate

extension LaunchViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard isAnimating, flag else { return }

        guard let type = anim.value(forKey: "animType") as? String else { return }

        if type == "acceleration" {
            // Разгон завершен.
            // Получаем координату, где мы остановились
            if let endValue = anim.value(forKey: "endValue") as? CGFloat {
                // Запускаем доигрывание до конца текущего цикла
                runLoopRemainder(from: endValue)
            }
        } else if type == "loopRemainder" {
            // Мы доиграли первый (неполный) цикл.
            // Теперь можно запускать стандартный полный цикл с начала.
            runFullLoop()
        } else if type == "fullLoop" {
            // Полный цикл прошел, запускаем заново
            runFullLoop()
        }
    }
}
