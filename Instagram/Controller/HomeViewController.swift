//
//  HomeViewController.swift
//  Instagram
//
//  Created by user on 2020/08/11.
//  Copyright © 2020 user. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var submitForm: UIView!
    @IBOutlet weak var submitTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textInputBackground: UIView!

    var submitFormY:CGFloat = 0.0

    var postData: PostData!

    // 投稿データを格納する配列
    var postArray: [PostData] = []
    // Firestoreのリスナー
    var listener: ListenerRegistration!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        submitTextField.delegate = self

        //入力時の背景を非表示で初期化
        textInputBackground.isHidden = true


        // 通知センターの取得
        let notification =  NotificationCenter.default

        // keyboardのframe変化時
        notification.addObserver(self,
                                 selector: #selector(self.keyboardChangeFrame(_:)),
                                 name: UIResponder.keyboardDidChangeFrameNotification,
                                 object: nil)

        // keyboard登場時
        notification.addObserver(self,
                                 selector: #selector(self.keyboardWillBeShow),
                                 name: UIResponder.keyboardWillShowNotification,
                                 object: nil)

        // keyboard退場時
        notification.addObserver(self,
                                 selector: #selector(self.keyboardWillBeHide(_:)),
                                 name: UIResponder.keyboardDidHideNotification,
                                 object: nil)

        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")

        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    // TableViewの表示を更新する
                    self.tableView.reloadData()
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }

    // キーボードのフレーム変化時の処理
    @objc func keyboardChangeFrame(_ notification: NSNotification) {
        // keyboardのframeを取得
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        // submitFormの最大Y座標と、keybordの最小Y座標の差分を計算
        let diff = self.submitForm.frame.maxY -  keyboardFrame.minY

        if (diff > 0) {
            //submitFormのbottomの制約に差分をプラス
            self.submitButtonBottomConstraint.constant += diff
            self.view.layoutIfNeeded()
        }
    }

    // キーボード登場時の処理
    @objc func keyboardWillBeShow(_ notification: NSNotification) {
        // 現在のsubmitFormの最大Y座標を保存
        submitFormY = self.submitForm.frame.maxY
    }

    //キーボードが退場時の処理
    @objc func keyboardWillBeHide(_ notification: NSNotification) {
        //submitFormのbottomの制約を元に戻す
        self.submitButtonBottomConstraint.constant = -submitFormY
        self.view.layoutIfNeeded()
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])

        // セル内のlikeボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleLikeButton(_:forEvent:)), for: .touchUpInside)

        // セル内のcommentボタンのアクションをソースコードで設定する
        cell.commentButton.addTarget(self, action:#selector(handleCommentButton(_:forEvent:)), for: .touchUpInside)

        // セル内のコメント表示/非表示ボタンのアクションをソースコードで設定する
        cell.commentDisplayButton.addTarget(self, action:#selector(displayCommentButton(_:forEvent:)), for: .touchUpInside)

        return cell
    }

    // セル内のlikeボタンがタップされた時に呼ばれるメソッド
    @objc func handleLikeButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")

        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]

        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
    }

    // セル内のcommentボタンがタップされた時に呼ばれるメソッド
    @objc func handleCommentButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: commentボタンがタップされました。")

        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]

        // キーボードを表示
        submitTextField.becomeFirstResponder()

        //Viewをテキストフィールドの背景に表示させて他操作を不可にする
        textInputBackground.isHidden = false

    }

    @IBAction func closeKeyboard(_ sender: Any) {
        //　タップされたものがtextInputBackgroundならば、キーボードを閉じる
        if textInputBackground is UIView {
            // キーボードをしまう
            view.endEditing(true)
            textInputBackground.isHidden = true
        }

    }

    @IBAction func sendButton(_ sender: Any) {
        print("DEBUG_PRINT: 送信ボタンがタップされました")
        //　投稿者名を現在の表示名に
        let commentName = Auth.auth().currentUser?.displayName
        let postDic = ["comment": "\(commentName!) : \(self.submitTextField.text)",] as [String: Any]
        let comment = postDic["comment"]
        let updateValue: FieldValue = FieldValue.arrayUnion([comment!])

        //保存処理
        let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
        postRef.updateData(["comment":updateValue])

        SVProgressHUD.show()

        //ラベルに投稿を反映させる
        

        // キーボードをしまう
        view.endEditing(true)
        textInputBackground.isHidden = true

        //HUDで投稿完了を表示する
        SVProgressHUD.showSuccess(withStatus: "コメントを投稿しました")
        print("DEBUG_PRINT: コメント投稿完了")

    }

    // セル内の表示/非表示ボタンがタップされた時に呼ばれるメソッド
    @objc func displayCommentButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: 表示/非表示ボタンがタップされました。")
        tableView.reloadData()
    }
}
