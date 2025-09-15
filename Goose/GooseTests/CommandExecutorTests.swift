import XCTest
@testable import Goose

class CommandExecutorTests: XCTestCase {
    var executor: CommandExecutor!
    
    override func setUp() {
        super.setUp()
        executor = CommandExecutor()
    }
    
    override func tearDown() {
        executor = nil
        super.tearDown()
    }
    
    func testExecuteSimpleCommand() async throws {
        // Test executing a simple echo command
        let expectation = XCTestExpectation(description: "Command execution")
        var outputReceived = false
        
        let result = await executor.execute(
            command: "echo",
            arguments: ["Hello, Test!"]
        ) { output in
            if output.contains("Hello, Test!") {
                outputReceived = true
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(outputReceived, "Expected output was not received")
        XCTAssertTrue(result, "Command should have executed successfully")
    }
    
    func testExecuteInvalidCommand() async throws {
        // Test executing an invalid command
        let result = await executor.execute(
            command: "invalid_command_that_doesnt_exist",
            arguments: []
        ) { _ in }
        
        XCTAssertFalse(result, "Invalid command should fail")
    }
    
    func testExecuteWithArguments() async throws {
        // Test command with multiple arguments
        let expectation = XCTestExpectation(description: "Command with args")
        var outputReceived = false
        
        let result = await executor.execute(
            command: "echo",
            arguments: ["arg1", "arg2", "arg3"]
        ) { output in
            if output.contains("arg1 arg2 arg3") {
                outputReceived = true
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(outputReceived, "Arguments were not properly passed")
        XCTAssertTrue(result, "Command should have executed successfully")
    }
    
    func testCancelExecution() async throws {
        // Test canceling a long-running command
        let task = Task {
            await executor.execute(
                command: "sleep",
                arguments: ["10"]
            ) { _ in }
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Cancel the command
        executor.cancel()
        
        // The task should complete quickly after cancellation
        let result = await task.value
        XCTAssertFalse(result, "Cancelled command should return false")
    }
    
    func testMultilineOutput() async throws {
        // Test handling multiline output
        let expectation = XCTestExpectation(description: "Multiline output")
        var lines: [String] = []
        
        let result = await executor.execute(
            command: "sh",
            arguments: ["-c", "echo 'Line 1'; echo 'Line 2'; echo 'Line 3'"]
        ) { output in
            lines.append(output)
            if lines.count >= 3 {
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(lines.contains { $0.contains("Line 1") })
        XCTAssertTrue(lines.contains { $0.contains("Line 2") })
        XCTAssertTrue(lines.contains { $0.contains("Line 3") })
        XCTAssertTrue(result, "Command should have executed successfully")
    }
    
    func testErrorOutput() async throws {
        // Test capturing error output
        let expectation = XCTestExpectation(description: "Error output")
        var errorReceived = false
        
        let result = await executor.execute(
            command: "sh",
            arguments: ["-c", "echo 'Error message' >&2"]
        ) { output in
            if output.contains("Error message") {
                errorReceived = true
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(errorReceived, "Error output should be captured")
        XCTAssertTrue(result, "Command should still succeed even with stderr output")
    }
}
