//
//  ViewController.swift
//  Project 10 Music Album
//
//  Created by Chris on 15/9/2018.
//  Copyright © 2018 Chris. All rights reserved.
//

import UIKit

class AlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private static let selectPathKey = "select path"
    
    private var selectedPath: Int?
    private var model = AlbumModel(){
        didSet{
            covers = [Album: UIImage]()
            if let albums = model.albums{
                for a in albums{
                    covers[a] = #imageLiteral(resourceName: "placeholder")
                }
            }
        }
    }
    private var cellSize: CGFloat = 200.0
    private var cellInset: CGFloat = 0
    private var covers = [Album: UIImage]()
    private var deletedAlbums = [(index: Int, album: Album)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if covers.count == 0, model.count > 0{
            for a in model.albums!{
                covers[a] = #imageLiteral(resourceName: "placeholder")
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            UserDefaults.standard.set(self?.selectedPath == nil ?999 :self!.selectedPath, forKey: AlbumViewController.selectPathKey)
            FileHelper.default.save(file: self?.model.albums, withName: "albums", asCache: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
 
        let saveSelectedPath = UserDefaults.standard.integer(forKey: AlbumViewController.selectPathKey)
        if saveSelectedPath != 999{
            selection(at: IndexPath(row: saveSelectedPath, section: 0))
        } else {
            selection(at: IndexPath(row: 0, section: 0))
        }
        
        if model.count > 0 {trashButton.isEnabled = true}
    }

    
    @IBOutlet private weak var trashButton: UIBarButtonItem!
    @IBOutlet private weak var undoButton: UIBarButtonItem!
    @IBOutlet private weak var year: UILabel!
    @IBOutlet private weak var genre: UILabel!
    @IBOutlet private weak var album: UILabel!
    @IBOutlet private weak var artist: UILabel!
    @IBOutlet private weak var albumCollection: UICollectionView!{
        didSet{
            albumCollection.delegate = self
            albumCollection.dataSource = self
//            albumCollection.dragDelegate = self
//            albumCollection.dropDelegate = self
            cellSize = albumCollection.frame.height * 0.9
            cellInset = (albumCollection.frame.width - cellSize)/2
            
            albumCollection.dragInteractionEnabled = true
            
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
            albumCollection.addGestureRecognizer(longPressGesture)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        collectionView.performBatchUpdates({
            let album = model.albums!.remove(at: sourceIndexPath.row)
            model.albums!.insert(album, at: destinationIndexPath.row)
            if selectedPath == sourceIndexPath.row{
                selectedPath = destinationIndexPath.row
            } else if selectedPath != nil{
                if selectedPath! > sourceIndexPath.row, selectedPath! <= destinationIndexPath.row{
                    selectedPath! -= 1
                } else if selectedPath! < sourceIndexPath.row, selectedPath! >= destinationIndexPath.row{
                    selectedPath! += 1
                }
            }
        }, completion: {completed in collectionView.reloadData()})
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
        return model.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selection(at: indexPath)
    }
    
    func selection(at indexPath: IndexPath?, asUndoAction undo: Bool = false){
        selectedPath = indexPath?.row
        
        
        if let indexPath = indexPath{
            trashButton.isEnabled = true
            let selectedAlbum = model.albums![indexPath.row]
            artist.text = selectedAlbum.artist
            album.text = selectedAlbum.title
            genre.text = selectedAlbum.genre
            year.text = selectedAlbum.year

            if !undo {
            albumCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }

            for cell in albumCollection.visibleCells{
                cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
            if let selectedCell = albumCollection.cellForItem(at: indexPath){
                selectedCell.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            }
            

        } else {
            trashButton.isEnabled = false
            artist.text = nil
            album.text = nil
            genre.text = nil
            year.text = nil
            for cell in albumCollection.visibleCells{
                cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if indexPath.row == selectedPath{
            cell.backgroundColor =  #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        } else {cell.backgroundColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)}
        
        if let cell = cell as? AlbumCollectionViewCell{
            let a = model.albums![indexPath.row]
            
            cell.albumPic.image = covers[a]
            
            if covers[a] == #imageLiteral(resourceName: "placeholder"), let url = URL(string: a.coverUrl){
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var data = FileHelper.default.read(fileName: a.title, as: Data.self, fromCache: true)
                    
                    if data == nil {
                        data = try? Data(contentsOf: url)
                        if let data = data{
                            FileHelper.default.save(file: data, withName: a.title, asCache: true)
                        }
                    }
                    
                    if let data = data{
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cellSize = albumCollection.frame.height * 0.9
        cellInset = (albumCollection.frame.width - cellSize)/2
        albumCollection.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func undoTrash(_ sender: Any) {
        if deletedAlbums.count > 0{
            let album = deletedAlbums.removeLast()
            albumCollection.performBatchUpdates({
                model.albums!.insert(album.album, at: album.index)
                albumCollection.insertItems(at: [IndexPath(row: album.index, section: 0)])
            }, completion: {complete in
                if let selectedPath = self.selectedPath,  selectedPath + 1 < self.model.count{
                    if album.index < selectedPath + 1 {
                        self.selection(at: IndexPath(row: (self.selectedPath)! + 1, section: 0), asUndoAction: true)
                    } else{
                        self.selection(at: IndexPath(row: (self.selectedPath)!, section: 0), asUndoAction: true)
                    }
                }
            })

            if deletedAlbums.count == 0{
                undoButton.isEnabled = false
            }
        }
    }
    
    @IBAction func trashAlbum(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Album", message: "Do you want to delete the selected album?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            if let pathToDelete = self.selectedPath, pathToDelete < self.model.count{
                self.albumCollection.performBatchUpdates({
                    let a = self.model.albums!.remove(at: pathToDelete)
                    self.covers[a] = nil
                    self.albumCollection.deleteItems(at: [IndexPath(row: pathToDelete, section: 0)])
                    self.deletedAlbums.append((index: pathToDelete, album: a))
                })
                
                var newSelectPath = pathToDelete - 1
                newSelectPath = max(newSelectPath, 0)
                if (self.model.count <= 0){
                    self.trashButton.isEnabled = false
                    self.selection(at: nil)
                } else {
                    self.selection(at: IndexPath(row: newSelectPath, section: 0))
                }
                
                self.undoButton.isEnabled = true
            }
        }
        ))
        if let popover = alert.popoverPresentationController{
            popover.barButtonItem = trashButton
        }
        present(alert, animated: true, completion: nil)
    }
    
//    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: model.albums![indexPath.row].title as NSItemProviderWriting))
//        dragItem.localObject = model.albums![indexPath.row]
//        return [dragItem]
//    }
//
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        return UICollectionViewDropProposal(operation: .move)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
//        return true
//    }
//
//    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//        //TODO
//    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
            
        case .began:
            guard let selectedIndexPath = albumCollection.indexPathForItem(at: gesture.location(in: albumCollection)) else {
                break
            }
            albumCollection.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            albumCollection.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            albumCollection.endInteractiveMovement()
        default:
            albumCollection.cancelInteractiveMovement()
        }
    }
}

