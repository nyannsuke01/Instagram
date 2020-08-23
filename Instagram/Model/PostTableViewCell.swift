//
//  PostTableViewCell.swift
//  Instagram
//
//  Created by user on 2020/08/20.
//  Copyright © 2020 user. All rights reserved.
//

import UIKit
import FirebaseUI

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!

    //コメント表示に関するUI部品
    @IBOutlet weak var commentTexts: UIStackView!
    @IBOutlet weak var commentDisplayButton: UIButton!
    @IBOutlet weak var commentText1: UILabel!
    @IBOutlet weak var commentText2: UILabel!
    @IBOutlet weak var commentText3: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //コメントを非表示で初期化
        commentTexts.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func showCommentButton(_ sender: Any) {
        if commentTexts.isHidden {
            commentDisplayButton.setTitle("非表示", for: .normal)

        } else {
            commentDisplayButton.setTitle("表示", for: .normal)
        }
        //　表示/非表示の切り替え
        commentTexts.isHidden = !commentTexts.isHidden
    }

    func setPostData(_ postData: PostData) {
        // 画像の表示
        postImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let imageRef = Storage.storage().reference().child(Const.ImagePath).child(postData.id + ".jpg")
        postImageView.sd_setImage(with: imageRef)

        // キャプションの表示
        self.captionLabel.text = "\(postData.name!) : \(postData.caption!)"

        // 日時の表示
        self.dateLabel.text = ""
        if let date = postData.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: date)
            self.dateLabel.text = dateString
        }

        // いいね数の表示
        let likeNumber = postData.likes.count
        likeLabel.text = "\(likeNumber)"

        //　コメント数の表示
        let commentNumber = postData.comments.count
        commentLabel.text = "\(commentNumber)"

        // いいねボタンの表示
        if postData.isLiked {
            let buttonImage = UIImage(named: "like_exist")
            self.likeButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "like_none")
            self.likeButton.setImage(buttonImage, for: .normal)
        }

    }
    
}
