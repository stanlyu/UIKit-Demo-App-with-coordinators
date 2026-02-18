//
//  AddPickupPointsViewController.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

@MainActor
final class AddPickupPointsViewController: UIViewController {
    init(viewOutput: AddPickupPointsViewOutput) {
        self.viewOutput = viewOutput
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        title = "Добавить ПВЗ"

        setupNavigation()
        setupLayout()

        viewOutput.viewDidLoad()
    }

    // MARK: - Private members

    private let viewOutput: AddPickupPointsViewOutput
    private var items: [AddPickupPointsItemViewState] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        return tableView
    }()

    private lazy var confirmButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Добавить в избранные"
        configuration.cornerStyle = .large

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.addAction(UIAction { [weak self] _ in
            self?.viewOutput.confirmButtonDidTap()
        }, for: .touchUpInside)
        return button
    }()

    private let cellReuseIdentifier = "add-pickup-point-cell"

    private func setupNavigation() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackButtonTap)
        )

        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            confirmButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -12)
        ])
    }

    private func updateConfirmButtonState(isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
        confirmButton.alpha = isEnabled ? 1 : 0.55
    }

    @objc private func handleBackButtonTap() {
        viewOutput.backButtonDidTap()
    }

    private func configureCell(_ cell: UITableViewCell, with item: AddPickupPointsItemViewState) {
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        cell.contentConfiguration = content

        cell.backgroundConfiguration = .listGroupedCell()
        cell.accessoryType = item.isSelected ? .checkmark : .none
    }
}

extension AddPickupPointsViewController: AddPickupPointsView {
    func render(_ state: AddPickupPointsViewState) {
        let previousItems = items
        let newItems = state.items

        // Первичный рендер: предыдущих данных для диффа еще нет.
        guard previousItems.isEmpty == false else {
            items = newItems
            tableView.reloadData()
            updateConfirmButtonState(isEnabled: state.isConfirmButtonEnabled)
            return
        }

        let previousIDs = previousItems.map(\.id)
        let newIDs = newItems.map(\.id)

        // Список тех же элементов в том же порядке: обновляем только строки с изменившимся выделением.
        if previousIDs == newIDs {
            items = newItems
            let rowsToReload = previousItems.enumerated().compactMap { index, oldItem -> IndexPath? in
                guard oldItem.isSelected != newItems[index].isSelected else { return nil }
                return IndexPath(row: index, section: 0)
            }

            if !rowsToReload.isEmpty {
                tableView.reloadRows(at: rowsToReload, with: .none)
            }

            updateConfirmButtonState(isEnabled: state.isConfirmButtonEnabled)
            return
        }

        // Состав строк изменился: считаем вставки/удаления для анимированного обновления таблицы.
        let previousIDSet = Set(previousIDs)
        let newIDSet = Set(newIDs)
        let removedIDs = previousIDSet.subtracting(newIDSet)
        let insertedIDs = newIDSet.subtracting(previousIDSet)

        let previousIndexByID = Dictionary(uniqueKeysWithValues: previousItems.enumerated().map { ($1.id, $0) })
        let newIndexByID = Dictionary(uniqueKeysWithValues: newItems.enumerated().map { ($1.id, $0) })

        let removedIndexPaths = removedIDs.compactMap { id -> IndexPath? in
            guard let index = previousIndexByID[id] else { return nil }
            return IndexPath(row: index, section: 0)
        }

        let insertedIndexPaths = insertedIDs.compactMap { id -> IndexPath? in
            guard let index = newIndexByID[id] else { return nil }
            return IndexPath(row: index, section: 0)
        }

        // Для элементов, оставшихся в списке, обновляем состояние выделения в том же batch.
        let reloadIndexPaths = previousIDSet
            .intersection(newIDSet)
            .compactMap { id -> IndexPath? in
                guard
                    let oldIndex = previousIndexByID[id],
                    let newIndex = newIndexByID[id],
                    previousItems[oldIndex].isSelected != newItems[newIndex].isSelected
                else {
                    return nil
                }

                return IndexPath(row: oldIndex, section: 0)
            }

        items = newItems

        tableView.performBatchUpdates {
            if removedIndexPaths.isEmpty == false {
                tableView.deleteRows(at: removedIndexPaths, with: .automatic)
            }
            if insertedIndexPaths.isEmpty == false {
                tableView.insertRows(at: insertedIndexPaths, with: .automatic)
            }
            if reloadIndexPaths.isEmpty == false {
                tableView.reloadRows(at: reloadIndexPaths, with: .none)
            }
        }

        updateConfirmButtonState(isEnabled: state.isConfirmButtonEnabled)
    }
}

extension AddPickupPointsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        configureCell(cell, with: items[indexPath.row])
        return cell
    }
}

extension AddPickupPointsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        viewOutput.pickupPointDidTap(id: item.id)
    }
}

extension AddPickupPointsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
