//
//  WordListViewController
//  Kotoba
//
//  Created by Will Hains on 2014-11-24.
//  Copyright (c) 2014 Will Hains. All rights reserved.
//

import UIKit
import LinkPresentation

class WordListViewController: UITableViewController
{
	@IBOutlet weak var shareButton: UIBarButtonItem!
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		debugLog("_____ tableView")
		debugLog("iCloud=\(NSUbiquitousKeyValueStore.iCloudEnabledInSettings)")
		debugLog("wordListStore.data=\(wordListStore.data.asText())")
		
		self.shareButton.isEnabled = wordListStore.data.count > 0
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		prepareSelfSizingTableCells()
	}
	
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	@IBAction func closeHistory(_ sender: Any)
	{
		self.dismiss(animated: true, completion: nil)
	}
}

// MARK:- Export Word List
extension WordListViewController: UIActivityItemSource
{
	@IBAction func exportWordList(_ sender: Any)
	{
		let path = NSTemporaryDirectory() + "Kotoba Word List.txt"
		let exportText = wordListStore.data.asText()
		if let data = exportText.data(using: .utf8) {
			let url = URL.init(fileURLWithPath: path)
			try? data.write(to: url)
			
			let items = [url]
			let shareSheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
			shareSheet.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
				try? FileManager.default.removeItem(at: url)
			}
			present(shareSheet, animated: true)
			if let popOver = shareSheet.popoverPresentationController
			{
				popOver.barButtonItem = self.shareButton
			}
		}
	}
	
	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
	{
		return "placeholder\nword\nlist\n"
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
	{
		return nil
	}

	func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata?
	{
		let metadata = LPLinkMetadata()
		let count = wordListStore.data.count
		let format = NSLocalizedString("WordCount", comment: "Count of words available")
		let wordCount = String.localizedStringWithFormat(format, count)
		let exportMessage = NSLocalizedString("EXPORT_WORDS_MESSAGE", comment: "Count of words to be exported")
		metadata.title = String(format: exportMessage, wordCount)
		return metadata
	}
}

// MARK:- Dynamic Type
extension WordListViewController
{
	func prepareTextLabelForDynamicType(label: UILabel?)
	{
		label?.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
	}
	
	func prepareSelfSizingTableCells()
	{
		// Self-sizing table rows
		tableView.estimatedRowHeight = 44
		tableView.rowHeight = UITableView.automaticDimension
		
		// Update view when dynamic type changes
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(WordListViewController.dynamicTypeSizeDidChange),
			name: UIContentSizeCategory.didChangeNotification,
			object: nil)
	}
	
	@objc func dynamicTypeSizeDidChange()
	{
		self.tableView.reloadData()
	}
}

// MARK:- Tap a word in the list to see its description
extension WordListViewController
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Search the dictionary
		let word = wordListStore.data[indexPath.row]
		showDefinition(forWord: word)
		
		// Reset the table view
		self.tableView.deselectRow(at: indexPath, animated: true)
	}
}

// MARK:- Swipe left to delete words
extension WordListViewController
{
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
	{
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
	{
		if editingStyle == .delete
		{
			var words = wordListStore.data
			words.delete(wordAt: indexPath.row)
			self.tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}
}

// MARK:- Data source
extension WordListViewController
{
	override func numberOfSections(in tableView: UITableView) -> Int
	{
		// Just a single, simple list
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return wordListStore.data.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
		let text = wordListStore.data[indexPath.row].text
		cell.textLabel?.text = UserDefaults.standard.CHOCKTUBA_DUH ? text.uppercased() : text
		prepareTextLabelForDynamicType(label: cell.textLabel)
		return cell
	}
}
