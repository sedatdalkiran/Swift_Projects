//
//  GameDetailsViewController.swift
//  VideoGamesApp
//
//  Created by Sedat Dalkıran on 6.03.2022.
//

import UIKit
import ObjectMapper
import SDWebImage
import Alamofire
import CoreData

class GameDetailsViewController: UIViewController {
    @IBOutlet weak var likeClickImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var gameDescription: UITextView!
    @IBOutlet weak var gameRelease: UILabel!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameMetacritic: UILabel!
    
    var game: GameModel? = nil
    var isGameFavorite: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transformer = SDImageResizingTransformer(size: CGSize(width: 414, height: 323), scaleMode: .fill)
        
        gameImage.sd_setImage(with: URL(string: (game?.image!)!), placeholderImage: UIImage(named: "customImage"),context: [.imageTransformer: transformer])
        gameName.text = game?.name ?? "Game Name"
        gameRelease.text = game?.released ?? "00.00.00"
        gameMetacritic.text = "\(game?.metacritc ?? 0.0)"
        
        if isGameFavorite {
            imageButtonConfigurationDeleteFavourite()
        } else {
            imageButtonConfigurationAddFavourite()
        }
        
        getGameDescription(gameID: game?.id ?? 0)
    }
    
    func getGameDescription(gameID: Int) {
        
        let id : String = String(gameID)
        
        let headers : HTTPHeaders = [
            "x-rapidapi-key": "20c3e5eea7msh37f0d8fabce0e0bp184712jsn95b641fd3834",
            "x-rapidapi-host": "rawg-video-games-database.p.rapidapi.com",
        ]
        
        spinner.startAnimating()
        spinner.isHidden = false
        
        AF.request("https://api.rawg.io/api/games/\(id)?key=f487e6c36cb54e3a98b0c1bb8cc4a1a4", headers: headers).responseJSON { [self] response in
            
            switch response.result {
            
            case .success(let jsonData):
                if let description = jsonData as? Dictionary<String, Any> {
                    self.gameDescription.text = description["description_raw"] as? String
                }
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
            }
        }
    }
}

extension GameDetailsViewController {
    
    func imageButtonConfigurationAddFavourite() {
        
        likeClickImage.image = likeClickImage.image?.withRenderingMode(.alwaysTemplate)
        likeClickImage.tintColor = UIColor.black
        likeClickImage.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(addFavourite))
        likeClickImage.addGestureRecognizer(tapRecognizer)
        
    }
    
    func imageButtonConfigurationDeleteFavourite() {
        
        likeClickImage.image = likeClickImage.image?.withRenderingMode(.alwaysTemplate)
        likeClickImage.tintColor = UIColor.orange
        likeClickImage.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeFavourite))
        likeClickImage.addGestureRecognizer(tapRecognizer)
        
    }
    
    @objc func addFavourite() {
        
        let tbc = self.tabBarController as! TabBarController
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let newGameID = NSEntityDescription.insertNewObject(forEntityName: "VideoGamesApp", into: context)
        newGameID.setValue(game?.id!, forKey: "gameID")
        
        do {
            try context.save()
            likeClickImage.tintColor = UIColor.orange
            tbc.getFavouriteGames()
            print(tbc.favoriteGameIdList)
            makeAlert(title: "Success", message: "Game is your favorites list now.", back: true)
        } catch {
            makeAlert(title: "Error", message: "The game could not be added to your favorites list.", back: false)
        }
    }
    
    @objc func removeFavourite() {
        
        let tbc = self.tabBarController as! TabBarController
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VideoGamesApp")
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    guard let gameID = result.value(forKey: "gameID")as? Int else { return }
                    if game?.id! == gameID {
                        context.delete(result)
                    }
                }
                try context.save()
                likeClickImage.tintColor = UIColor.black
                tbc.getFavouriteGames()
                print(tbc.favoriteGameIdList)
                makeAlert(title: "Success", message: "We're so sorry you don't like this game anymore.", back: true)
            }
        } catch {
            print("Error")
            makeAlert(title: "Error", message: "Game could not be removed from favorites.", back: false)
        }
    }
}

extension GameDetailsViewController {
    func makeAlert(title: String, message: String, back: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default, handler: {_ in
            if back{
                self.navigationController?.popViewController(animated: true)
            }
        })
        alert.addAction(okButton)
        present(alert, animated: true, completion: nil)
    }
}
