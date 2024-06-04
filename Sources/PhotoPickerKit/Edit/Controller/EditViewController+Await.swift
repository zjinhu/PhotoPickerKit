//
//  EditViewController+Await.swift
//  Edit
//
//  Created by FunWidget on 2024/6/3.
//

import UIKit

public extension EditViewController {
    
    @MainActor
    static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        let vc = show(asset, config: config, delegate: delegate, fromVC: fromVC)
        return try await vc.edit()
    }
    
    @MainActor
    @discardableResult
    static func show(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) -> EditViewController {
        let topVC = fromVC ?? UIViewController.topViewController
        let vc = EditViewController(asset, config: config, delegate: delegate)
        topVC?.present(vc, animated: true)
        return vc
    }
    
    func edit() async throws -> EditorAsset {
        try await withCheckedThrowingContinuation { continuation in
            var isDimissed: Bool = false
            finishHandler = { result, _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .success(result))
            }
            cancelHandler = { _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .failure(EditorError.canceled))
            }
        }
    }
    
    enum EditorError: Error, LocalizedError, CustomStringConvertible {
        case canceled
        
        public var errorDescription: String? {
            switch self {
            case .canceled:
                return "canceled：取消编辑"
            }
        }
        
        public var description: String {
            errorDescription ?? "nil"
        }
    }
}
