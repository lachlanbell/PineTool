//
//  TemperatureSetViewController.swift
//  Polymer
//
//  Created by Lachlan Bell on 17/12/20.
//  Copyright © 2020 Lachlan Bell. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  This Source Code Form is “Incompatible With Secondary Licenses”,
//  as defined by the Mozilla Public License, v. 2.0.
//

import UIKit
import SwiftUI
import TinyConstraints
import KeyboardGuide

// MARK: - UIKit Implementation
class TemperatureSetViewController: UIViewController {

    private let prevTemperature: UInt32?
    private let setCallback: (UInt32) -> Void
    private let validateCallback: ((UInt32) -> Bool)?

    // MARK: - UI Elements
    lazy private var degreeLabel = UILabel()
    lazy private var dimmingView = UIView()
    lazy private var inputContainer = UIView()
    lazy private var textField = UITextField()

    private var inputToolbar: UIToolbar!

    init(
        temperature: UInt32?,
        setCallback: @escaping (UInt32) -> Void,
        validateCallback: ((UInt32) -> (Bool))? = nil
    ) {
        self.prevTemperature = temperature
        self.setCallback = setCallback
        self.validateCallback = validateCallback

        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup
    override func viewDidLoad() {
        self.transitioningDelegate = self

        // Setup dimming view
        dimmingView.backgroundColor = .black
        self.view.addSubview(dimmingView)
        dimmingView.edgesToSuperview(usingSafeArea: false)

        // Add dismiss gesture recogniser to background view
        let backgroundGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(closeTapped)
        )
        dimmingView.addGestureRecognizer(backgroundGestureRecognizer)

        // Add container
        inputContainer.layer.cornerCurve = .continuous
        inputContainer.layer.cornerRadius = 12

        inputContainer.layer.applyShadow(
            color: .black,
            alpha: 0.3,
            x: 0,
            y: 3,
            blur: 45,
            spread: 0
        )

        inputContainer.backgroundColor = .secondarySystemBackground
        self.view.addSubview(inputContainer)
        inputContainer.centerXToSuperview()
        inputContainer.centerYToSuperview(offset: -30, priority: .defaultLow)

        inputContainer.bottom(
            to: view.keyboardSafeArea.layoutGuide,
            offset: -30,
            relation: .equalOrLess,
            priority: .required
        )

        inputContainer.width(170)
        inputContainer.height(55)

        // Add background text view
        self.inputContainer.addSubview(textField)
        textField.delegate = self
        textField.tintColor = UIColor(named: "AccentColor")
        textField.centerYToSuperview()
        textField.left(to: inputContainer, offset: 15)
        textField.right(to: inputContainer, offset: -40)
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 20, weight: .semibold)
        textField.keyboardType = .numberPad
        textField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged
        )

        if let prevTemperature {
            textField.placeholder = "\(prevTemperature)"
        }

        // Add accessory toolbar
        // Toolbar needs an explicit frame with h >= 12 to avoid layout errors
        inputToolbar = UIToolbar(
            frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 35)
        )
        inputToolbar.setItems([
            UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                title: NSLocalizedString("Set", comment: "Set temperature"),
                style: .done,
                target: self,
                action: #selector(setTapped)
            )
        ], animated: false)
        inputToolbar.sizeToFit()
        inputToolbar.items?.last?.isEnabled = false
        textField.inputAccessoryView = inputToolbar

        // Add degrees label
        self.inputContainer.addSubview(degreeLabel)
        degreeLabel.text = "℃"
        degreeLabel.textColor = .secondaryLabel
        degreeLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        degreeLabel.centerYToSuperview()
        degreeLabel.right(to: inputContainer, offset: -15)
    }

    override func viewWillAppear(_ animated: Bool) {
        // Select text field
        textField.becomeFirstResponder()
    }

    @objc func closeTapped() {
        dismissView()
    }

    func dismissView() {
        textField.resignFirstResponder()
        self.dismiss(animated: true)
    }

    // MARK: - Input Handling
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Change 'Set' button enabled state if text is valid
        inputToolbar.items?.last?.isEnabled = inputValid
    }

    override func pressesBegan(
        _ presses: Set<UIPress>,
        with event: UIPressesEvent?
    ) {
        super.pressesBegan(presses, with: event)

        guard let key = presses.first?.key else { return }

        // Dismiss on escape keypress
        if key.keyCode == .keyboardEscape {
            dismissView()
        }
    }

    @objc func setTapped() {
        guard inputValid else { return }

        // Set temperature
        if let temperature = UInt32(textField.text ?? "") {
            setCallback(temperature)
        }

        dismissView()
    }

    var inputValid: Bool {
        guard let validateCallback = validateCallback else { return true }
        guard let value = UInt32(textField.text ?? "") else { return false }
        return validateCallback(value)
    }
}

// MARK: - UITextFieldDelegate methods
extension TemperatureSetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if inputValid {
            setTapped()
            return true
        }

        return false
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension TemperatureSetViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return TemperatureSetAnimatedTransitioning(
            inputContainer: inputContainer,
            dimmingView: dimmingView,
            isReverse: false
        )
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return TemperatureSetAnimatedTransitioning(
            inputContainer: inputContainer,
            dimmingView: dimmingView,
            isReverse: true
        )
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
private class TemperatureSetAnimatedTransitioning: NSObject {

    weak var inputContainer: UIView?
    weak var dimmingView: UIView?
    private let isReverse: Bool

    init(inputContainer: UIView, dimmingView: UIView, isReverse: Bool) {
        self.inputContainer = inputContainer
        self.dimmingView = dimmingView
        self.isReverse = isReverse
    }
}

extension TemperatureSetAnimatedTransitioning: UIViewControllerAnimatedTransitioning {

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return isReverse ? 0.1 : 0.25
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        let duration = self.transitionDuration(using: transitionContext)

        guard let view = transitionContext.view(
            forKey: isReverse ? .from : .to
        ) else { return }
        transitionContext.containerView.addSubview(view)

        if isReverse {
            // Animate out
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.dimmingView?.alpha = 0
                    self.inputContainer?.alpha = 0
                    self.inputContainer?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                },
                completion: { _ in
                    transitionContext.completeTransition(true)
                }
            )
        } else {
            // Prepare UI for transition
            inputContainer?.alpha = 0.0
            inputContainer?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            dimmingView?.alpha = 0.0

            // Animate in
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.dimmingView?.alpha = 0.6
                    self.inputContainer?.alpha = 1
                    self.inputContainer?.transform = .identity
                },
                completion: { _ in
                    transitionContext.completeTransition(true)
                }
            )
        }
    }
}

// MARK: - CALayer+applyShadow extension
extension CALayer {
    /// Apply a Sketch-style shadow to a CALayer
    func applyShadow(
        color: UIColor = .black,
        alpha: Float = 0.25,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 8,
        spread: CGFloat = 0
    ) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
