//
//  ViewController.swift
//  VideoGamesApp
//
//  Created by Sedat Dalkıran on 6.03.2022.
//

import UIKit
import Alamofire
import SDWebImage
import ObjectMapper

class ViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var pageControlScrollView: UIScrollView!
    @IBOutlet var collectionViewHeightAnchor: NSLayoutConstraint!

    private let searchController = UISearchController(searchResultsController: nil)
    private var gameList = [GameModel]()
    private var filteredGameList = [GameModel]()
    
    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.backgroundColor = .clear
        return pageControl
    }()
    
    private var isSearchBarEmpty: Bool {
        let searchText = searchController.searchBar.text
        return searchText!.count >= 4 ? false : true
    }
    
    private var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControlScrollView.delegate = self
        view.addSubview(pageControl)
        pageControl.addTarget(self, action: #selector(pageControlChange(_:)), for: .valueChanged)
        pageControlConfiguration()
        searchControllerConfiguration()
        scrollViewConfiguration()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pageControl.frame = CGRect(x: 10, y: pageControlScrollView.frame.size.height * 1.45, width: pageControlScrollView.frame.size.width - 20 , height: 70)
        
        if pageControlScrollView.subviews.count == 2 {
            scrollViewConfiguration()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        gameList.removeAll()
        getGameList()
        collectionView.reloadData()
        
    }
    
    private func getGameList() {
        
        let headers : HTTPHeaders = [
            "x-rapidapi-key": "20c3e5eea7msh37f0d8fabce0e0bp184712jsn95b641fd3834",
            "x-rapidapi-host": "rawg-video-games-database.p.rapidapi.com"
        ]
        
        spinner.startAnimating()
        spinner.isHidden = false
        
        AF.request("https://api.rawg.io/api/games?key=4d0fed44d30643a0a0044d684bb3af11", headers: headers).responseJSON { [self] response in
            
            switch response.result {
            
            case .success(let jsonData):
                if let response = jsonData as? Dictionary<String,Any> {
                    if let gameList = response["results"] as? [[String : Any]] {
                        for game in gameList {
                            let mappingGame = Mapper<GameModel>().map(JSON: game)
                            self.gameList.append(mappingGame!)
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
                getScrollImages()
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
            }
        }
    }
    
    private func getScrollImages() {
        for i in 0..<3 {
            let image = UIImageView(frame: CGRect(x: CGFloat(i) * view.frame.size.width, y: 0, width: view.frame.width, height: pageControlScrollView.frame.height))
            image.sd_setImage(with: URL(string: gameList[i].image ?? ""), placeholderImage: UIImage(named: "customImage"))
            pageControlScrollView.addSubview(image)
        }
    }

}

extension ViewController: UIScrollViewDelegate {
    
    private func pageControlConfiguration() {
        pageControl.numberOfPages = 3
        pageControl.pageIndicatorTintColor = .black
        pageControl.currentPageIndicatorTintColor = .orange
        pageControl.backgroundColor = .clear
    }
    
    private func scrollViewConfiguration() {
        
        pageControlScrollView.contentSize = CGSize(width: view.frame.size.width * 3, height: pageControlScrollView.frame.height)
        pageControlScrollView.isPagingEnabled = true
        pageControlScrollView.showsHorizontalScrollIndicator = false
        pageControlScrollView.showsVerticalScrollIndicator = false
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = floorf(Float(scrollView.contentOffset.x / scrollView.frame.size.width))
        pageControl.currentPage = Int(currentPage)
    }
    
    @objc private func pageControlChange(_ sender: UIPageControl) {
        let current = sender.currentPage
        pageControlScrollView.setContentOffset(CGPoint(x: CGFloat(current) * view.frame.size.width, y: 0), animated: true)
    }
}


extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tbc = self.tabBarController as! TabBarController
        let game = gameList[indexPath.row]
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let viewController = sb.instantiateViewController(identifier: "GameDetailViewController") as! GameDetailsViewController
        
        viewController.game = game
        if tbc.isGameFavorite(game: game) {
            viewController.isGameFavorite = true
        } else {
            viewController.isGameFavorite = false
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            if filteredGameList.count == 0 {
                self.collectionView.setEmptyMessage("The game was not found.")
            } else {
                self.collectionView.restore()
            }
            return filteredGameList.count
        }
        self.collectionView.restore()
        return gameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let game: GameModel
        
        if isFiltering {
            game = filteredGameList[indexPath.row]
        } else {
            game = gameList[indexPath.row]
        }
        
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

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = self.view.frame.width - 16.0 * 2
        let height: CGFloat = 90.0
        
        return CGSize(width: width, height: height)
    }
    
}

extension ViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        activeSearchScreenConfiguration()
        let searchBar = searchController.searchBar
        filterContextForSearchText(searchText: searchBar.text!)
        
        if !searchController.isActive{
            notActiveSearchScreenConfiguration()
        }
    }
    
    private func searchControllerConfiguration() {
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.placeholder = "Search Game"
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    func filterContextForSearchText(searchText: String) {
        filteredGameList = gameList.filter({ (game: GameModel) -> Bool in
            return (game.name?.lowercased().contains(searchText.lowercased()))!
        })
        
        collectionView.reloadData()
    }
    
    func activeSearchScreenConfiguration() {
        pageControl.isHidden = true
        UIView.animate(withDuration: 0.4, animations: {
            self.collectionViewHeightAnchor.constant = CGFloat(self.view.bounds.height - (self.navigationController?.navigationBar.bounds.height)!)
            self.view.layoutIfNeeded()
        })
    }
    
    func notActiveSearchScreenConfiguration() {
        UIView.animate(withDuration: 0.4, animations: {
            self.collectionViewHeightAnchor.constant = CGFloat(445.0)
            self.view.layoutIfNeeded()
        })
        pageControl.isHidden = false
    }
    
}

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel;
    }

    func restore() {
        self.backgroundView = nil
    }
    
}

