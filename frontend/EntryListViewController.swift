//
//  EntryListViewController.swift
//  HackChallengeJournalApp
//
//  Created by Ethan Khan on 12/1/25.
//

import UIKit

class EntryListViewController: UIViewController {
    
    private let tableView = UITableView()
    private var entries: [JournalEntry] = []
    private let cellReuseId = "EntryCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Journal"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        loadEntries()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEntries()
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
    }
    
    private func loadEntries() {
        entries = PersistenceManager.shared.loadEntries()
        tableView.reloadData()
    }
    
    @objc private func addButtonTapped() {
        let newEntryVC = NewEntryViewController()
        newEntryVC.delegate = self
        let navController = UINavigationController(rootViewController: newEntryVC)
        present(navController, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension EntryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        let entry = entries[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = entry.title
        config.secondaryText = formatDate(entry.date)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

extension EntryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = entries[indexPath.row]
        let detailVC = EntryDetailViewController(entry: entry)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension EntryListViewController: NewEntryDelegate {
    func didSaveEntry() {
        loadEntries()
    }
}
