//
//  PortalViewController.swift
//  Tsqaure
//
//  Created by Prabhav Chawla on 8/15/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit
import SwiftSoup

class PortalViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var classArr = [Class]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        
        collectionView.isHidden = true
        collectionView.dataSource = self
        
        let space: CGFloat = 20.0
        let dimension = (view.frame.size.width - 3 * space) / 2.0
        
        flowLayout.minimumInteritemSpacing = space // space between items in the same row or column
        flowLayout.minimumLineSpacing = space // space between rows or columns
        flowLayout.itemSize = CGSize(width: dimension, height: dimension * 2 / 3) // governs cell size
        
        self.loginGetId()
    }
    
    private func loginGetId() {
        networkRequest(request: URLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!)) { data in
            let html_string = String(data: data, encoding: .utf8)
            
            if let lt_id = html_string?.components(separatedBy: "name=\"lt\" value=\"")[1].components(separatedBy: "\" />")[0] {
                self.loginPostCredentials(lt_id)
            }
        }
    }
    
    private func loginPostCredentials(_ id: String) {
        let request = NSMutableURLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!)
        request.httpMethod = "POST"
        request.httpBody = "username=pchawla8&password=&lt=\(id)&execution=e1s1&_eventId=submit&submit=LOGIN".data(using: .utf8)
        
        networkRequest(request: request as URLRequest) { _ in
            self.getTsquare()
        }
    }
    
    private func getTsquare() {
        networkRequest(request: URLRequest(url: URL(string: "https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")!)) { data in
            
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                for element in try doc.select("#siteLinkList > *") {
                    if try element.className().isEmpty {
                        let link = try element.select("a").first()!
                        self.classArr.append(Class(name: try link.text(), getURL: try link.attr("href")))
                    }
                }
                DispatchQueue.main.async {
                    self.activityIndicator.isHidden = true
                    self.collectionView.isHidden = false
                    self.collectionView.reloadData()
                }

            } catch {
                print("error")
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClassViewCell", for: indexPath) as! ClassViewCell
        cell.className.text = classArr[indexPath.row].name
        return cell
    }
}
