//
//  ViewController.swift
//  Project 10 Music Album
//
//  Created by Chris on 15/9/2018.
//  Copyright © 2018 Chris. All rights reserved.
//

import UIKit

class AlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var selectedPath: IndexPath?
    var model = AlbumModel(){
        didSet{
            covers = [Album: UIImage]()
            if let albums = model.albums{
                for a in albums{
                    covers[a] = #imageLiteral(resourceName: "placeholder")
                }
            }
        }
    }
    var cellSize: CGFloat = 200.0
    var cellInset: CGFloat = 0
    var covers = [Album: UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if covers.count == 0, model.count > 0{
            for a in model.albums!{
                covers[a] = #imageLiteral(resourceName: "placeholder")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selection(at: IndexPath(row: 0, section: 0))
    }
    
    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var year: UILabel!
    @IBOutlet weak var genre: UILabel!
    @IBOutlet weak var album: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var albumCollection: UICollectionView!{
        didSet{
            albumCollection.delegate = self
            albumCollection.dataSource = self
            cellSize = albumCollection.frame.height * 0.9
            
            cellInset = (albumCollection.frame.width - cellSize)/2
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: cellInset, bottom: 0, right: cellInset)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = model.count
        trashButton.isEnabled = count > 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selection(at: indexPath)

        
    }
    
    func selection(at indexPath: IndexPath?){
        selectedPath = indexPath
        
        if let indexPath = indexPath{
            let selectedAlbum = model.albums![indexPath.row]
            artist.text = selectedAlbum.artist
            album.text = selectedAlbum.title
            genre.text = selectedAlbum.genre
            year.text = selectedAlbum.year
            
            albumCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
            albumCollection.reloadData()
            
        } else {
            artist.text = nil
            album.text = nil
            genre.text = nil
            year.text = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if indexPath == selectedPath{
            cell.backgroundColor =  #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        } else {cell.backgroundColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)}
        
        if let cell = cell as? AlbumCollectionViewCell{
            let a = model.albums![indexPath.row]
            
            cell.albumPic.image = covers[a]
            
            if covers[a] == #imageLiteral(resourceName: "placeholder"), let url = URL(string: a.coverUrl){
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    if let data = try? Data(contentsOf: url){
                        
                        if (self?.covers[a] != nil){
                            let image = UIImage(data: data)
                            self?.covers[a] = image != nil ? image! : #imageLiteral(resourceName: "error")
                            DispatchQueue.main.async { [weak self] in
                                self?.albumCollection.reloadItems(at: [indexPath])
                            }
                        }
                    }
                }
            }
        }
        return cell
    }
    
    
    @IBAction func trashAlbum(_ sender: Any) {
        if let pathToDelete = selectedPath{
            albumCollection.performBatchUpdates({
                albumCollection.deleteItems(at: [pathToDelete])
                let a = model.albums!.remove(at: pathToDelete.row)
                covers[a] = nil
            })
   
            var newSelectPath = pathToDelete
            if newSelectPath.row >= model.albums!.count{
                newSelectPath.row = model.albums!.count - 1
            }
            if newSelectPath.row >= 0{
                selection(at: newSelectPath)
            } else {
                selection(at: nil)
            }
            
            undoButton.isEnabled = true
        }
    }
    
    //    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        let endMidPoint = targetContentOffset.pointee.x + (scrollView.frame.width / 2)
//        var targetCell = Float(endMidPoint / (cellSize + 10)) - 1
//        if targetCell < 0.5 {
//            targetCell = 0
//        } else if targetCell > Float(model.albums!.count - 1){
//            targetCell = Float(model.albums!.count) - 1
//        }
//
//        currentItem = lroundf(targetCell)
//
//        albumCollection.scrollToItem(at: IndexPath(row: currentItem, section: 0), at: .centeredHorizontally, animated: true)
//    }
    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let endMidPoint = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//        var targetCell = Float(endMidPoint / (cellSize + 10)) - 1
//        if targetCell < 0.5 {
//            targetCell = 0
//        } else if targetCell > Float(model.albums!.count - 1){
//            targetCell = Float(model.albums!.count) - 1
//        }
//
//        currentItem = lroundf(targetCell)
//
//        albumCollection.scrollToItem(at: IndexPath(row: currentItem, section: 0), at: .centeredHorizontally, animated: true)
//    }
    
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        let currentAlbum = model.albums![currentItem]
//        artist.text = currentAlbum.artist
//        album.text = currentAlbum.title
//        genre.text = currentAlbum.genre
//        year.text = currentAlbum.year
//    }
    

    
    
}

