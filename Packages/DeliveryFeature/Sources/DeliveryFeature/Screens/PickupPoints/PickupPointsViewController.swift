//
//  PickupPointsViewController.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

@MainActor
final class PickupPointsViewController: UIViewController {
    init(viewOutput: PickupPointsViewOutput) {
        self.viewOutput = viewOutput
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        title = "Выбор ПВЗ"

        setupNavigation()
        setupLayout()

        viewOutput.viewDidLoad()
    }

    // MARK: - Private members

    private final class TableDataSource: UITableViewDiffableDataSource<PickupPointsSectionKind, PickupPointsRow.ID> {
        var sectionTitleProvider: ((PickupPointsSectionKind) -> String?)?

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKinds = snapshot().sectionIdentifiers
            guard sectionKinds.indices.contains(section) else { return nil }
            return sectionTitleProvider?(sectionKinds[section])
        }
    }

    private let viewOutput: PickupPointsViewOutput

    private var rowsByID: [PickupPointsRow.ID: PickupPointsRow] = [:]
    private var sectionTitlesByKind: [PickupPointsSectionKind: String] = [:]
    private var hasRenderedAtLeastOnce = false

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        return tableView
    }()

    private lazy var dataSource = makeDataSource()

    private lazy var confirmButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Подтвердить выбор"
        configuration.cornerStyle = .large

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.addAction(UIAction { [weak self] _ in
            self?.viewOutput.confirmSelectionButtonDidTap()
        }, for: .touchUpInside)
        return button
    }()

    private let cellReuseIdentifier = "pickup-point-cell"

    private func setupNavigation() {
        let addButtonAction = UIAction { [weak self] _ in
            self?.viewOutput.addButtonDidTap()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Добавить",
            primaryAction: addButtonAction
        )
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

    private func makeDataSource() -> TableDataSource {
        let dataSource = TableDataSource(tableView: tableView) { [weak self] tableView, indexPath, rowID in
            guard let reuseID = self?.cellReuseIdentifier else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
            guard let row = self?.rowsByID[rowID] else { return cell }
            self?.configureCell(cell, with: row)
            return cell
        }

        dataSource.sectionTitleProvider = { [weak self] sectionKind in
            self?.sectionTitlesByKind[sectionKind]
        }

        return dataSource
    }

    private func updateConfirmButtonState(isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
        confirmButton.alpha = isEnabled ? 1 : 0.55
    }

    private func configureCell(_ cell: UITableViewCell, with row: PickupPointsRow) {
        switch row {
        case let .active(title, subtitle):
            var content = cell.defaultContentConfiguration()
            content.text = title
            content.secondaryText = subtitle
            content.textProperties.color = .label
            content.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.accessoryType = .none
            cell.selectionStyle = .none

        case let .activePlaceholder(title, subtitle):
            var content = cell.defaultContentConfiguration()
            content.text = title
            content.secondaryText = subtitle
            content.textProperties.color = .secondaryLabel
            content.secondaryTextProperties.color = .tertiaryLabel
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.accessoryType = .none
            cell.selectionStyle = .none

        case let .favorite(_, title, selected):
            var content = cell.defaultContentConfiguration()
            content.text = title
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.accessoryType = selected ? .checkmark : .none
            cell.selectionStyle = .default

        case let .favoritePlaceholder(text):
            var content = cell.defaultContentConfiguration()
            content.text = text
            content.textProperties.color = .secondaryLabel
            content.textProperties.numberOfLines = 0
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
    }

    private func row(at indexPath: IndexPath) -> PickupPointsRow? {
        guard let rowID = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return rowsByID[rowID]
    }

}

extension PickupPointsViewController: PickupPointsView {
    func render(_ state: PickupPointsViewState) {
        sectionTitlesByKind = state.sections.reduce(into: [:]) { result, section in
            result[section.kind] = section.title
        }

        rowsByID = state.sections
            .flatMap(\.rows)
            .reduce(into: [:]) { result, row in
                result[row.id] = row
            }

        var snapshot = NSDiffableDataSourceSnapshot<PickupPointsSectionKind, PickupPointsRow.ID>()

        for section in state.sections {
            snapshot.appendSections([section.kind])
            let rowIDs = section.rows.map(\.id)
            snapshot.appendItems(rowIDs, toSection: section.kind)
        }

        let allRowIDs = state.sections.flatMap { $0.rows.map(\.id) }
        if allRowIDs.isEmpty == false {
            snapshot.reconfigureItems(allRowIDs)
        }

        dataSource.apply(snapshot, animatingDifferences: hasRenderedAtLeastOnce)
        hasRenderedAtLeastOnce = true

        updateConfirmButtonState(isEnabled: state.isConfirmButtonEnabled)
    }
}

extension PickupPointsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let row = row(at: indexPath) else { return }
        guard case .favorite = row else { return }
        viewOutput.favoritePickupPointDidTap(row)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let row = row(at: indexPath) else { return nil }
        guard case .favorite = row else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.viewOutput.favoriteDeleteButtonDidTap(row)
            completion(true)
        }

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
