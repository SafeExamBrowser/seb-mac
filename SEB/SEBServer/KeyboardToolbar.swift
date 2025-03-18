//
//  KeyboardToolbar.swift
//  SEB
//
//  Created by Daniel Schneider on 15.03.2025.
//

import UIKit

protocol KeyboardToolbarDelegate: AnyObject {
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, isInputAccessoryViewOf textField: UITextField)
}

@objc class KeyboardToolbar: UIToolbar {

    private weak var toolBarDelegate: KeyboardToolbarDelegate?
    private weak var textField: UITextField!

    init(for textField: UITextField, toolBarDelegate: KeyboardToolbarDelegate) {
        super.init(frame: .init(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 44)))
        barStyle = .default
        isTranslucent = true
        self.textField = textField
        self.toolBarDelegate = toolBarDelegate
        textField.inputAccessoryView = self
    }

    func setup(leftButtons: [KeyboardToolbarButton], rightButtons: [KeyboardToolbarButton]) {
        let leftBarButtons = leftButtons.map {
            $0.createButton(target: self, action: #selector(buttonTapped))
        }
        let rightBarButtons = rightButtons.map {
            $0.createButton(target: self, action: #selector(buttonTapped(sender:)))
        }
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setItems(leftBarButtons + [spaceButton] + rightBarButtons, animated: false)
    }

    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    @objc func buttonTapped(sender: UIBarButtonItem) {
        guard let type = KeyboardToolbarButton.detectType(barButton: sender) else { return }
        toolBarDelegate?.keyboardToolbar(button: sender, type: type, isInputAccessoryViewOf: textField)
    }
    
}

extension UITextField {
    func addKeyboardToolBar(leftButtons: [KeyboardToolbarButton],
                            rightButtons: [KeyboardToolbarButton],
                            toolBarDelegate: KeyboardToolbarDelegate) {
        let toolbar = KeyboardToolbar(for: self, toolBarDelegate: toolBarDelegate)
        toolbar.setup(leftButtons: leftButtons, rightButtons: rightButtons)
    }
}

@objc class KeyboardToolbarController: NSObject, KeyboardToolbarDelegate {
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, isInputAccessoryViewOf textField: UITextField) {
        print("Tapped button type: \(type) | \(textField)")
    }
    
    
    @objc func addKeyboardToolbar(view: UIView) {
        createTextField(view: view, frame: CGRect(x: 50, y: 50, width: 200, height: 40), leftButtons: [.backDisabled, .forward], rightButtons: [.cancel])
    }

    private func createTextField(view: UIView, frame: CGRect, leftButtons: [KeyboardToolbarButton] = [], rightButtons: [KeyboardToolbarButton] = []) {
        let textField = UITextField(frame: frame)
        textField.borderStyle = .roundedRect
        view.addSubview(textField)
        textField.addKeyboardToolBar(leftButtons: leftButtons, rightButtons: rightButtons, toolBarDelegate: self)
    }
}
