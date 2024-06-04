//
//  EditViewController+Action.swift
//  Edit
//
//  Created by FunWidget on 2024/5/30.
//

import UIKit

extension EditViewController {
    @objc
    func didCancelButtonClick(button: UIButton) {
        backClick(true)
    }
    
    @objc
    func didFinishButtonClick(button: UIButton) {
        processing()
    }
    
    @objc
    func didResetButtonClick(button: UIButton) {
        editorView.reset(true)
    }
    
    @objc
    func didLeftRotateButtonClick(button: UIButton) {
        editorView.rotateLeft(true)
    }
    
    @objc
    func didRightRotateButtonClick(button: UIButton) {
        editorView.rotateRight(true)
    }
    
    func checkFinishButtonState() {
        if editorView.state == .edit {
            finishButton.isEnabled = true
        }else {
            if config.isWhetherFinishButtonDisabledInUneditedState {
                finishButton.isEnabled = isEdited
            }else {
                finishButton.isEnabled = true
            }
        }
    }
}
