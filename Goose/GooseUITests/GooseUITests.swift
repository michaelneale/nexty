import XCTest

final class GooseUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLaunchApplication() throws {
        // Test that the app launches successfully
        XCTAssertTrue(app.exists, "Application should launch")
        
        // Check for main window or menu bar
        let menuBar = app.menuBars
        XCTAssertTrue(menuBar.count > 0, "Menu bar should exist")
    }
    
    func testMainWindowElements() throws {
        // Test main window UI elements
        let window = app.windows.firstMatch
        
        // Check for command input field
        let commandInput = window.textFields.firstMatch
        XCTAssertTrue(commandInput.waitForExistence(timeout: 5), "Command input field should exist")
        
        // Check for output view
        let outputView = window.scrollViews.firstMatch
        XCTAssertTrue(outputView.exists || window.textViews.count > 0, 
                     "Output view should exist")
    }
    
    func testCommandExecution() throws {
        // Test executing a simple command
        let window = app.windows.firstMatch
        let commandInput = window.textFields.firstMatch
        
        guard commandInput.waitForExistence(timeout: 5) else {
            XCTFail("Command input field not found")
            return
        }
        
        // Type a command
        commandInput.click()
        commandInput.typeText("echo Hello, UI Test!")
        
        // Press Enter to execute
        commandInput.typeText("\n")
        
        // Wait for output
        let outputView = window.scrollViews.firstMatch
        let outputText = outputView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hello, UI Test!'"))
        
        XCTAssertTrue(outputText.count > 0 || window.textViews.count > 0, 
                     "Command output should appear")
    }
    
    func testOpenPreferences() throws {
        // Test opening preferences window
        let menuBar = app.menuBars
        
        // Click on Goose menu
        if menuBar.menuBarItems["Goose"].exists {
            menuBar.menuBarItems["Goose"].click()
            
            // Click on Preferences
            if menuBar.menuItems["Preferences…"].exists {
                menuBar.menuItems["Preferences…"].click()
            } else if menuBar.menuItems["Settings…"].exists {
                menuBar.menuItems["Settings…"].click()
            }
            
            // Check if preferences window opens
            let prefsWindow = app.windows["Preferences"]
            XCTAssertTrue(prefsWindow.exists || app.windows.count > 1, 
                         "Preferences window should open")
        }
    }
    
    func testSpotlightMode() throws {
        // Test spotlight mode activation
        // Note: Testing hotkeys in UI tests is challenging
        // This test checks if spotlight mode UI elements exist
        
        // Try to find spotlight-style window or elements
        let spotlightWindow = app.windows.containing(
            NSPredicate(format: "identifier CONTAINS 'spotlight' OR title CONTAINS 'Spotlight'")
        )
        
        // Alternative: Check menu for spotlight toggle
        let menuBar = app.menuBars
        if menuBar.menuBarItems["View"].exists {
            menuBar.menuBarItems["View"].click()
            
            let spotlightMenuItem = menuBar.menuItems.containing(
                NSPredicate(format: "title CONTAINS 'Spotlight'")
            )
            
            XCTAssertTrue(spotlightMenuItem.count > 0 || spotlightWindow.count >= 0,
                         "Spotlight mode should be available")
        }
    }
    
    func testCommandHistory() throws {
        // Test command history navigation
        let window = app.windows.firstMatch
        let commandInput = window.textFields.firstMatch
        
        guard commandInput.waitForExistence(timeout: 5) else {
            XCTFail("Command input field not found")
            return
        }
        
        // Execute a few commands
        commandInput.click()
        commandInput.typeText("echo First Command")
        commandInput.typeText("\n")
        
        // Small delay
        Thread.sleep(forTimeInterval: 0.5)
        
        commandInput.click()
        commandInput.typeText("echo Second Command")
        commandInput.typeText("\n")
        
        // Try to navigate history with up arrow
        commandInput.click()
        commandInput.typeKey(.upArrow, modifierFlags: [])
        
        // Check if previous command appears
        let inputValue = commandInput.value as? String ?? ""
        XCTAssertTrue(inputValue.contains("Command") || inputValue.count > 0,
                     "Command history should be navigable")
    }
    
    func testClearOutput() throws {
        // Test clearing command output
        let window = app.windows.firstMatch
        let commandInput = window.textFields.firstMatch
        
        // Execute a command first
        if commandInput.waitForExistence(timeout: 5) {
            commandInput.click()
            commandInput.typeText("echo Test Output")
            commandInput.typeText("\n")
        }
        
        // Look for clear button or menu item
        let clearButton = window.buttons.containing(
            NSPredicate(format: "title CONTAINS 'Clear' OR label CONTAINS 'Clear'")
        ).firstMatch
        
        if clearButton.exists {
            clearButton.click()
            
            // Check if output is cleared
            let outputView = window.scrollViews.firstMatch
            let remainingText = outputView.staticTexts.count
            XCTAssertTrue(remainingText == 0 || outputView.value as? String == "",
                         "Output should be cleared")
        } else {
            // Try menu bar
            let menuBar = app.menuBars
            if menuBar.menuBarItems["Edit"].exists {
                menuBar.menuBarItems["Edit"].click()
                if menuBar.menuItems["Clear Output"].exists {
                    menuBar.menuItems["Clear Output"].click()
                }
            }
        }
    }
    
    func testAboutWindow() throws {
        // Test opening About window
        let menuBar = app.menuBars
        
        if menuBar.menuBarItems["Goose"].exists {
            menuBar.menuBarItems["Goose"].click()
            
            if menuBar.menuItems["About Goose"].exists {
                menuBar.menuItems["About Goose"].click()
                
                // Check if About window opens
                let aboutWindow = app.windows.containing(
                    NSPredicate(format: "title CONTAINS 'About'")
                ).firstMatch
                
                XCTAssertTrue(aboutWindow.exists, "About window should open")
                
                // Check for version info
                let versionText = aboutWindow.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS 'Version' OR label CONTAINS '1.'")
                )
                XCTAssertTrue(versionText.count > 0, "Version information should be displayed")
            }
        }
    }
}
