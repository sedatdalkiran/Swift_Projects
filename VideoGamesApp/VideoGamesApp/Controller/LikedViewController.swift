//
//  LikedViewController.swift
//  VideoGamesApp
//
//  Created by Sedat Dalkıran on 6.03.2022.
//

import UIKit
import SDWebImage
import Alamofire
import ObjectMapper

class LikedViewController: UIViewController {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    var gameList = [GameModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        gameList.removeAll()
        getGameList()
        collectionView.reloadData()
        
    }
    
    func getGameList() {
        let tbc = self.tabBarController as! TabBarController
        let headers : HTTPHeaders = [
            "x-rapidapi-key": "20c3e5eea7msh37f0d8fabce0e0bp184712jsn95b641fd3834",
            "x-rapidapi-host": "rawg-video-games-database.p.rapidapi.com",
        ]
        
        spinner.startAnimating()
        spinner.isHidden = false
        
        AF.request("https://api.rawg.io/api/games?key=f487e6c36cb54e3a98b0c1bb8cc4a1a4", headers: headers).responseJSON { [self] response in
            
            switch response.result {
            
            case .success(let jsonData):
                if let response = jsonData as? Dictionary<String,Any> {
                    if let gameList = response["results"] as? [[String : Any]] {
                        for game in gameList {
                            let mappingGame = Mapper<GameModel>().map(JSON: game)
                            if tbc.isGameFavorite(game: mappingGame!) {
                                self.gameList.append(mappingGame!)
                            }
                            self.collectionView.reloadData()
                        }
                    } else {
                        print("Json mapping error")
                    }
                }else{
                    print("JSON parse error")
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

extension LikedViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tbc = self.tabBarController as! TabBarController
        let game = gameList[indexPath.row]
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let viewController = sb.instantiateViewController(identifier: "GameDetailsViewController") as! GameDetailsViewController
        
        viewController.game = game
        if tbc.isGameFavorite(game: game) {
            viewController.isGameFavorite = true
        } else {
            viewController.isGameFavorite = false
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let game = gameList[indexPath.row]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameListCollectionViewCell", for: indexPath) as? GameListCollectionViewCell {
            
            cell.gameImage.sd_setImage(with: URL(string: game.image!), placeholderImage: UIImage(named: "customImage"))
            cell.gameName.text = game.name ?? "Game Name"
            cell.gameInformation.text = "\(game.rating ?? 0.0) - \(game.released ?? "00.00.00")"
            
            return cell
            
        } else {
            
            return UICollectionViewCell()
        }
    }
}

extension LikedViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = self.view.frame.width - 16.0 * 2
        let height: CGFloat = 90.0
        
        return CGSize(width: width, height: height)
    }
    
}

