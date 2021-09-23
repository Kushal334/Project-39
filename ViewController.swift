//
//  ViewController.swift
//  RigPhotoViewerDemo
//
//  Created by Michael Skiba on 2/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import UIKit
import RIGImageGallery

class ViewController: UIViewController {

    fileprivate let imageSession = URLSession(configuration: .default)

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        navigationItem.title = NSLocalizedString("RIG Image Gallery", comment: "Main screen title")

        let remoteGalleryButton = UIButton(type: .system)
        remoteGalleryButton.addTarget(self, action: #selector(ViewController.showOnlineGallery(_:)), for: .touchUpInside)
        remoteGalleryButton.setTitle(NSLocalizedString("Show Online Gallery", comment: "Show gallery button title"), for: .normal)
        let localGalleryButton = UIButton(type: .system)
        localGalleryButton.setTitle(NSLocalizedString("Show Local Gallery", comment: "Show Local Gallery"), for: .normal)
        localGalleryButton.addTarget(self, action: #selector(ViewController.showLocalGallery(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [remoteGalleryButton, localGalleryButton])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        stackView.distribution = .fill
        stackView.spacing = 10
        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        let constraints: [NSLayoutConstraint] = [
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomLayoutGuide.topAnchor),
            stackView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

}

private extension ViewController {

    @objc func showOnlineGallery(_ sender: UIButton) {
        let photoViewController = prepareRemoteGallery()
        photoViewController.dismissHandler = dismissPhotoViewer
        photoViewController.actionButtonHandler = actionButtonHandler
        photoViewController.actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        photoViewController.traitCollectionChangeHandler = traitCollectionChangeHandler
        photoViewController.countUpdateHandler = updateCount
        let navigationController = navBarWrappedViewController(photoViewController)
        present(navigationController, animated: true, completion: nil)
    }

    @objc func showLocalGallery(_ sender: UIButton) {
        let photoViewController = prepareLocalGallery()
        photoViewController.dismissHandler = dismissPhotoViewer
        photoViewController.actionButtonHandler = actionButtonHandler
        photoViewController.actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        photoViewController.traitCollectionChangeHandler = traitCollectionChangeHandler
        photoViewController.countUpdateHandler = updateCount
        let navigationController = navBarWrappedViewController(photoViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

private extension ViewController {

    func dismissPhotoViewer(_ :RIGImageGalleryViewController) {
        dismiss(animated: true, completion: nil)
    }

    func actionButtonHandler(_: RIGImageGalleryViewController, galleryItem: RIGImageGalleryItem) {
    }

    func updateCount(_ gallery: RIGImageGalleryViewController, position: Int, total: Int) {
        gallery.countLabel.text = "\(position + 1) of \(total)"
    }

    func traitCollectionChangeHandler(_ photoView: RIGImageGalleryViewController) {
        let isPhone = UITraitCollection(userInterfaceIdiom: .phone)
        let isCompact = UITraitCollection(verticalSizeClass: .compact)
        let allTraits = UITraitCollection(traitsFrom: [isPhone, isCompact])
        photoView.doneButton = photoView.traitCollection.containsTraits(in: allTraits) ? nil : UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
    }

}

private extension ViewController {

    static let urls: [URL] = [
        "https://placehold.it/1920x1080",
        "https://placehold.it/1080x1920",
        "https://placehold.it/350x150",
        "https://placehold.it/150x350",
        ].flatMap(URL.init(string:))

    func prepareRemoteGallery() -> RIGImageGalleryViewController {

        let urls = type(of: self).urls

        let rigItems: [RIGImageGalleryItem] = urls.map { url in
            RIGImageGalleryItem(placeholderImage: #imageLiteral(resourceName: "placeholder"),
                                title: url.pathComponents.last ?? "",
                                isLoading: true)
        }

        let rigController = RIGImageGalleryViewController(images: rigItems)

        for (index, URL) in  urls.enumerated() {
            let completion = rigController.handleImageLoadAtIndex(index)
            let request = imageSession.dataTask(with: URLRequest(url: URL),
                                                completionHandler: completion)
            request.resume()
        }

        rigController.setCurrentImage(2, animated: false)

        return rigController
    }

    func prepareLocalGallery() -> RIGImageGalleryViewController {

        let items: [UIImage] = ["1", "2", "3", "4", "5", "6"].flatMap(UIImage.init(named:))

        let rigItems: [RIGImageGalleryItem] = items.map { item in
            RIGImageGalleryItem(image: item)
        }

        let rigController = RIGImageGalleryViewController(images: rigItems)

        return rigController
    }

    func navBarWrappedViewController(_ viewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.barStyle = .blackTranslucent
        navigationController.navigationBar.tintColor = .white
        navigationController.toolbar.barStyle = .blackTranslucent
        navigationController.toolbar.tintColor = .white
        return navigationController
    }

}

private extension RIGImageGalleryViewController {
    // swiftlint:disable:next large_tuple
    func handleImageLoadAtIndex(_ index: Int) -> ((Data?, URLResponse?, Error?) -> Void) {
        return { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let image = data.flatMap(UIImage.init), error == nil else {
                if let error = error {
                    print(error)
                }
                return
            }
            self?.images[index].isLoading = false
            self?.images[index].image = image
        }
    }
}
