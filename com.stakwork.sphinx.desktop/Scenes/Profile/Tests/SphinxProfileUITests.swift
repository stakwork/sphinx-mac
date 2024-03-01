//
//  SphinxUITests.swift
//  SphinxUITests
//
//  Created by Oko-osi Korede on 16/02/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import XCTest

final class SphinxUITests: XCTestCase {

    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app.launch()
        let mainWindow = app/*@START_MENU_TOKEN@*/.windows["MainWindow"]/*[[".windows[\"Sphinx\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let mainView = mainWindow.windows["MainView"]
        let secureFields = mainView.windows["SecureFields"]
        let securefieldsSecureTextField = secureFields.secureTextFields["SecureFields"]
        securefieldsSecureTextField.click()
        securefieldsSecureTextField.typeText("333330")
        
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["Sphinx"].click()
        menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["Profile"]/*[[".menuBarItems[\"Sphinx\"]",".menus.menuItems[\"Profile\"]",".menuItems[\"Profile\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testProfileBasicTab() {
        let newTipAmount = "19"
        let profileWindow = app.windows["Profile"]
        
//        //MARK: Editing User name
        let textField = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 0).children(matching: .textField).element(boundBy: 0)
        
        textField.click()
        textField.typeText("1")
        textField.typeKey(.escape, modifierFlags:[])
        let username = textField.value as! String
        
        //MARK: Share my Profile Photo with Contact
        let group = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 0)
        let button = group.children(matching: .button).element(boundBy: 3)
        button.click()
        
        //MARK: Tapping on the Address QR code icon
        let qrCode = group.children(matching: .button).element(boundBy: 1)
        qrCode.click()
        let xcuiQRClosewindowButton = app.windows["Public Key"].buttons[XCUIIdentifierCloseWindow]
        xcuiQRClosewindowButton.click()
        
        //MARK: Editing default tip amount
        let tipTextField = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 1).children(matching: .textField).element(boundBy: 0)
        tipTextField.click()
        tipTextField.typeKey(.delete, modifierFlags:[])
        tipTextField.typeKey(.delete, modifierFlags:[])
        tipTextField.typeText(newTipAmount)
        
        //MARK: Backup your key
        profileWindow/*@START_MENU_TOKEN@*/.buttons["Backup your key"]/*[[".groups.buttons[\"Backup your key\"]",".buttons[\"Backup your key\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.click()
        let xcuiBackupClosewindowButton = app.windows["Enter Restore PIN"].buttons[XCUIIdentifierCloseWindow]
        xcuiBackupClosewindowButton.click()
        
        let xcuiProfileFullwindowButton = profileWindow.buttons[XCUIIdentifierFullScreenWindow]
        xcuiProfileFullwindowButton.click()
        
        // Click on Save Changes
        let saveChangesButton = app.windows["Profile"]/*@START_MENU_TOKEN@*/.buttons["Save changes"]/*[[".groups.buttons[\"Save changes\"]",".buttons[\"Save changes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        saveChangesButton.click()
        tipTextField.typeKey(.escape, modifierFlags:[])
        sleep(5)
        // Click on Close Button
        let xcuiProfileClosewindowButton = profileWindow.buttons[XCUIIdentifierCloseWindow]
        xcuiProfileClosewindowButton.click()
        
        app.menuBars.menuBarItems["Sphinx"].click()
        app.menuBars/*@START_MENU_TOKEN@*/.menuItems["Profile"]/*[[".menuBarItems[\"Sphinx\"]",".menus.menuItems[\"Profile\"]",".menuItems[\"Profile\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        
        let newtextField = profileWindow.groups
            .containing(.button, identifier:"Save changes")
            .children(matching: .group).element(boundBy: 3)
            .children(matching: .group).element(boundBy: 0)
            .children(matching: .textField).element(boundBy: 0)
        
        XCTAssertEqual(newtextField.value as! String, username)
        XCTAssertEqual(tipTextField.value as! String, newTipAmount)
        sleep(5)
        
    }
    
    func testProfileAdvanceTab() {
        let profileWindow = app.windows["Profile"]
        let advanceTab = profileWindow/*@START_MENU_TOKEN@*/.buttons["Advanced"]/*[[".groups.buttons[\"Advanced\"]",".buttons[\"Advanced\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        advanceTab.click()
        
        //MARK: Changing Pin Timeout slider
        let profileSlider = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 1).children(matching: .slider).element
        profileSlider.click()
        profileSlider.adjust(toNormalizedSliderPosition: 0.8)
        let tempSliderValue = profileSlider.value as! Int
        sleep(5)
        
        //MARK: Tapping on Change Pin
        let changePin = profileWindow/*@START_MENU_TOKEN@*/.buttons["Change PIN"]/*[[".groups.buttons[\"Change PIN\"]",".buttons[\"Change PIN\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        changePin.click()
        let changePinView = app.windows["Standard PIN"]
        XCTAssertTrue(changePinView.exists)
        changePinView.buttons[XCUIIdentifierCloseWindow].click()
        
        //MARK: Tapping on Change Privacy Pin
        let changePrivacyPin = profileWindow/*@START_MENU_TOKEN@*/.buttons["Change Privacy PIN"]/*[[".groups.buttons[\"Change Privacy PIN\"]",".buttons[\"Change Privacy PIN\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        changePrivacyPin.click()
        let changePrivacyPinView = app.windows["Privacy PIN"]
        XCTAssertTrue(changePrivacyPinView.exists)
        changePrivacyPinView.buttons[XCUIIdentifierCloseWindow].click()
        
        let xcuiProfileFullwindowButton = profileWindow.buttons[XCUIIdentifierFullScreenWindow]
        xcuiProfileFullwindowButton.click()
        
        // Click on Save Changes
        let saveChangesButton = app.windows["Profile"]/*@START_MENU_TOKEN@*/.buttons["Save changes"]/*[[".groups.buttons[\"Save changes\"]",".buttons[\"Save changes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        saveChangesButton.click()
        profileWindow.typeKey(.escape, modifierFlags:[])
        sleep(5)
        
        // Click on Close Button
        let xcuiProfileClosewindowButton = profileWindow.buttons[XCUIIdentifierCloseWindow]
        xcuiProfileClosewindowButton.click()
        
        app.menuBars.menuBarItems["Sphinx"].click()
        app.menuBars/*@START_MENU_TOKEN@*/.menuItems["Profile"]/*[[".menuBarItems[\"Sphinx\"]",".menus.menuItems[\"Profile\"]",".menuItems[\"Profile\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        advanceTab.click()
        
        XCTAssertEqual(tempSliderValue, profileSlider.value as! Int)
        
    }
    
    func testProfileViewQRCode() {
        let qrcodeButton = app.windows["Profile"].groups
            .containing(.button, identifier:"Save changes")
            .children(matching: .group).element(boundBy: 3)
            .children(matching: .group).element(boundBy: 0)
            .children(matching: .button).element(boundBy: 1)
        qrcodeButton.click()
        
        let publicKeyWindow = app.windows["Public Key"]
        let copyButton = publicKeyWindow.children(matching: .button).element(boundBy: 0)
        copyButton.click()
        publicKeyWindow.buttons[XCUIIdentifierCloseWindow].click()
        
    }
    
    func testProfileViewBackupYourKeys() {
        let backupButton = app.windows["Profile"]/*@START_MENU_TOKEN@*/.buttons["Backup your key"]/*[[".groups.buttons[\"Backup your key\"]",".buttons[\"Backup your key\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        backupButton.click()
        let secureField = app.windows["Enter Restore PIN"].windows["SecureFields"].secureTextFields["SecureFields"]
            secureField.click()
        secureField.typeText("333330")
        
        let confirmButton = app/*@START_MENU_TOKEN@*/.buttons["action-button-1"]/*[[".dialogs[\"alert\"]",".buttons[\"Confirm\"]",".buttons[\"action-button-1\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        confirmButton.click()
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
