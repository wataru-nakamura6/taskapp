//
//  ViewController.swift
//  taskapp
//
//  Created by 中村航 on 2021/03/26.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    let realm = try! Realm()  // ←追加
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchMemo: UISearchBar!
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchMemo.delegate = self
        searchMemo.enablesReturnKeyAutomatically = false

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return taskArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let task = taskArray[indexPath.row]
            cell.textLabel?.text = task.title
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"

            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString

        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil) // ←追加する
    }

    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // --- ここから ---
         if editingStyle == .delete {
            let task = self.taskArray[indexPath.row]
            // ローカル通知をキャンセルする
              let center = UNUserNotificationCenter.current()
              center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

             // データベースから削除する
             try! realm.write {
                 self.realm.delete(self.taskArray[indexPath.row])
                 tableView.deleteRows(at: [indexPath], with: .fade)
             }
            // 未通知のローカル通知一覧をログ出力
             center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                 for request in requests {
                     print("/---------------")
                     print(request)
                     print("---------------/")
                 }
             }
         } // --- ここまで追加 ---
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
        }
            inputViewController.task = task
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchMemo.autocapitalizationType = .none
        searchMemo.text = ""
        return true
        }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchMemo.endEditing(true)
        guard let searchtext = searchMemo.text else {return}
        let result = realm.objects(Task.self)
            .filter("category CONTAINS '\(searchtext)'")
            .sorted(byKeyPath: "date", ascending: true)
       
        if result.count == 0{
            taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }else{
            taskArray = result
        }
        tableView.reloadData()
    }
}

