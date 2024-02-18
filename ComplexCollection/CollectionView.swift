//
//  CollectionView.swift
//  ComplexCollection
//
//  Created by 小田島 直樹 on 2/18/24.
//

import UIKit

final class CellModel {
    let text: String
    
    init(text: String) {
        self.text = text
    }
}

final class Cell: UICollectionViewCell {
    private let label: UILabel = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textColor = .black
        contentView.backgroundColor = .lightGray
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpLayout() {
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(cellModel: CellModel) {
        label.text = cellModel.text
    }
}

protocol CustomLayoutDelegate: AnyObject {
    func itemWidth(for indexPath: IndexPath) -> CGFloat
}

final class CustomLayout: UICollectionViewFlowLayout {
    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentsBounds: CGRect = .zero
    
    private let lineSpacing: CGFloat = 8
    private let itemSpacing: CGFloat = 8
    // アイテムのサイズを取得するためのDelegate
    weak var delegate: CustomLayoutDelegate?
    
    override init() {
        super.init()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var collectionViewContentSize: CGSize {
        contentsBounds.size
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView, let delegate else { return }
        cachedAttributes.removeAll()
        contentsBounds = CGRect(origin: .zero, size: collectionView.bounds.size)
        
        let itemCount = collectionView.numberOfItems(inSection: 0)
        // 列数。今回は5個以上のアイテムがあれば2列にする
        let columns = itemCount > 4 ? 2 : 1
        // 各列の最後のアイテムのフレーム
        var lineLastFrames: [Int: CGRect] = [:]
        for column in 0..<columns {
            lineLastFrames[column] = .init(
                origin: .init(
                    x: -itemSpacing, // 仮装の-1番目のアイテムなのでスペース分引いておく
                    y: CGFloat(column) * 32 + CGFloat(column) * lineSpacing
                ),
                size: .zero
            )
        }
        // アイテム全ての位置を設定する
        for row in 0..<itemCount {
            let indexPath = IndexPath(row: row, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemWidth = delegate.itemWidth(for: indexPath)
            // 最も短い列に追加する。追加後に最後のアイテムを更新する
            if let lastFrame = lineLastFrames.max(by: { $0.value.maxX > $1.value.maxX }) {
                attributes.frame = .init(
                    origin: .init(
                        x: lastFrame.value.maxX + itemSpacing,
                        y: lastFrame.value.minY
                    ),
                    size: .init(width: itemWidth, height: 32)
                )
                lineLastFrames[lastFrame.key] = attributes.frame
            }
            cachedAttributes.append(attributes)
        }
        // 最終的なコンテンツ（スクロール領域）の大きさを更新
        if let longestFrame = cachedAttributes.max(by: { $0.frame.maxX < $1.frame.maxX }),
           let highestFrame = cachedAttributes.max(by: { $0.frame.maxY < $1.frame.maxY }) {
            contentsBounds = .init(
                origin: .zero,
                size: .init(
                    width: longestFrame.frame.maxX,
                    height: highestFrame.frame.maxY
                )
            )
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // 部分的にでもrectに表示されるものでフィルタ
        cachedAttributes.filter { rect.intersects($0.frame) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if cachedAttributes.indices.contains(indexPath.row) {
            cachedAttributes[indexPath.row]
        } else {
            nil
        }
    }
}

final class ViewController: UIViewController {
    private let collectionView: UICollectionView = .init(
        frame: .zero,
        collectionViewLayout: CustomLayout()
    )
    private let dataSource: [CellModel] = [
        .init(text: "わかばシューター"), .init(text: "スプラシューター"),
        .init(text: "スプラチャージャー"), .init(text: "H3リールガン"),
        .init(text: "ボールドマーカー"), .init(text: "カーボンローラー"),
        .init(text: "52ガロン"), .init(text: "ジムワイパー"), 
        .init(text: "ジェットスイーパー"), .init(text: "ダイナモローラー"),
        .init(text: "プロモデラーMG"), .init(text: "ボトルガイザー"),
        .init(text: "ワイドローラー"), .init(text: "96ガロン"),
        .init(text: "スプラマニューバ"), .init(text: "ヒッセン")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        setUpCollectionView()
    }
    
    private func setUpLayout() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    private func setUpCollectionView() {
        (collectionView.collectionViewLayout as? CustomLayout)?.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            Cell.self,
            forCellWithReuseIdentifier: "Cell"
        )
    }
}

extension ViewController: CustomLayoutDelegate {
    func itemWidth(for indexPath: IndexPath) -> CGFloat {
        let label = UILabel(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        label.text = dataSource[indexPath.row].text
        label.sizeToFit()
        return label.intrinsicContentSize.width
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        dataSource.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let anyCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        guard let cell = anyCell as? Cell else { return anyCell }
        cell.configure(cellModel: dataSource[indexPath.row])
        return cell
    }
}

#Preview {
    ViewController()
}
