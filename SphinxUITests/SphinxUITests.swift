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
        
        //MARK: Editing User name
        let textField = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 0).children(matching: .textField).element
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
        
        let newtextField = profileWindow.groups.containing(.button, identifier:"Save changes").children(matching: .group).element(boundBy: 3).children(matching: .group).element(boundBy: 0).children(matching: .textField).element
        
        XCTAssertEqual(newtextField.value as! String, username)
        XCTAssertEqual(tipTextField.value as! String, newTipAmount)
        sleep(5)
        
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
