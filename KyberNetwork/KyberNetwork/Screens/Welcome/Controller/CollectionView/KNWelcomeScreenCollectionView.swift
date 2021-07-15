// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWelcomeScreenCollectionView: XibLoaderView {

  static let height: CGFloat = KNWelcomeScreenCollectionViewCell.height + 20.0
  @IBOutlet weak var collectionView: UICollectionView!

  fileprivate let viewModel: KNWelcomeScreenViewModel = KNWelcomeScreenViewModel()

  @IBOutlet var pageViews: [UIView]!
  @IBOutlet weak var landingTitle: UILabel!
  @IBOutlet weak var landingDescription: UILabel!
  
  override func commonInit() {
    super.commonInit()
    self.backgroundColor = .clear
    let nib = UINib(nibName: KNWelcomeScreenCollectionViewCell.className, bundle: nil)
    self.collectionView.register(
      nib,
      forCellWithReuseIdentifier: KNWelcomeScreenCollectionViewCell.cellID
    )
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.pageViews.forEach { $0.rounded(radius: 3.0) }
    self.updateSelectedPageView(index: 0)
    self.collectionView.reloadData()
  }

  fileprivate func updateSelectedPageView(index: Int) {
    self.pageViews.forEach { view in
      view.backgroundColor = view.tag == index ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "warningBoxBgColor")
    }
  }

  fileprivate func updateUIFor(index: Int) {
    let data = self.viewModel.welcomeData(at: index)
    self.landingTitle.text = data.title
    self.landingDescription.text = data.subtitle
  }
}

extension KNWelcomeScreenCollectionView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNWelcomeScreenCollectionViewCell.height
    )
  }
}

extension KNWelcomeScreenCollectionView: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let offsetX = scrollView.contentOffset.x
    let currentPage = Int(round(offsetX / scrollView.frame.width))
    self.updateSelectedPageView(index: currentPage)
    self.updateUIFor(index: currentPage)
  }
}

extension KNWelcomeScreenCollectionView: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNWelcomeScreenCollectionViewCell.cellID,
      for: indexPath
    ) as! KNWelcomeScreenCollectionViewCell
    let data = self.viewModel.welcomeData(at: indexPath.row)
    cell.updateCell(with: data)
    return cell
  }
}
