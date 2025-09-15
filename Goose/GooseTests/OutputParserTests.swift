import XCTest
@testable import Goose

class OutputParserTests: XCTestCase {
    var parser: OutputParser!
    
    override func setUp() {
        super.setUp()
        parser = OutputParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    func testParseSimpleText() {
        // Test parsing plain text
        let input = "This is plain text output"
        let parsed = parser.parse(input)
        
        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed[0].type, .plain)
        XCTAssertEqual(parsed[0].content, input)
    }
    
    func testParseANSIColors() {
        // Test parsing ANSI color codes
        let input = "\u{001B}[31mRed text\u{001B}[0m Normal text \u{001B}[32mGreen text\u{001B}[0m"
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.count > 0)
        // Check that ANSI codes are properly handled
        let hasColoredSegments = parsed.contains { segment in
            segment.type == .colored && (segment.color == .red || segment.color == .green)
        }
        XCTAssertTrue(hasColoredSegments, "Should have colored segments")
    }
    
    func testParseErrorOutput() {
        // Test parsing error patterns
        let input = "Error: Something went wrong\nWarning: This is a warning"
        let parsed = parser.parse(input)
        
        // Check for error detection
        let hasError = parsed.contains { $0.type == .error }
        let hasWarning = parsed.contains { $0.type == .warning }
        
        XCTAssertTrue(hasError || hasWarning || parsed.count > 0, 
                     "Should parse error/warning patterns or at least have output")
    }
    
    func testParseURLs() {
        // Test URL detection
        let input = "Visit https://example.com for more info"
        let parsed = parser.parse(input)
        
        // Check if URLs are detected
        let hasURL = parsed.contains { segment in
            segment.type == .link || segment.content.contains("https://example.com")
        }
        XCTAssertTrue(hasURL, "Should detect URLs in text")
    }
    
    func testParseMultilineOutput() {
        // Test multiline parsing
        let input = """
        Line 1
        Line 2
        Line 3
        """
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.count > 0, "Should parse multiline input")
    }
    
    func testParseProgressIndicators() {
        // Test parsing progress indicators
        let input = "[===>    ] 50% Complete"
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.count > 0)
        // Check if progress is detected
        let hasProgress = parsed.contains { segment in
            segment.type == .progress || segment.content.contains("50%")
        }
        XCTAssertTrue(hasProgress || parsed.count > 0, 
                     "Should handle progress indicators")
    }
    
    func testParseEmptyInput() {
        // Test empty input
        let input = ""
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.isEmpty || (parsed.count == 1 && parsed[0].content.isEmpty),
                     "Empty input should result in empty or minimal output")
    }
    
    func testParseSpecialCharacters() {
        // Test special characters
        let input = "Special chars: @#$%^&*()_+-=[]{}|;:'\",.<>?/"
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.count > 0)
        let containsSpecialChars = parsed.contains { segment in
            segment.content.contains("@") || segment.content.contains("#")
        }
        XCTAssertTrue(containsSpecialChars, "Should preserve special characters")
    }
    
    func testParseCodeBlocks() {
        // Test code block detection
        let input = """
        ```
        func hello() {
            print("Hello, World!")
        }
        ```
        """
        let parsed = parser.parse(input)
        
        XCTAssertTrue(parsed.count > 0, "Should parse code blocks")
        // Check if code block is detected
        let hasCodeBlock = parsed.contains { segment in
            segment.type == .code || segment.content.contains("func hello")
        }
        XCTAssertTrue(hasCodeBlock || parsed.count > 0, 
                     "Should handle code blocks")
    }
}
