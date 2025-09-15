import Foundation
import Combine

/// Handles Process/NSTask management for executing CLI commands
public class CommandExecutor: ObservableObject {
    private var runningProcesses: [UUID: Process] = [:]
    private let processQueue = DispatchQueue(label: "com.goose.commandexecutor", attributes: .concurrent)
    private var outputBuffers: [UUID: OutputBufferManager] = [:]
    private var outputProcessors: [UUID: BackgroundOutputProcessor] = [:]
    
    /// Execute a command asynchronously with streaming output
    public func execute(
        command: GooseCommand,
        outputHandler: @escaping (String, ResponseType) -> Void
    ) async throws {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // Find goose CLI path
        let goosePath = try findGooseCLI()
        
        process.executableURL = URL(fileURLWithPath: goosePath)
        process.arguments = command.arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.standardInput = FileHandle.nullDevice
        
        // Store process for potential cancellation
        processQueue.sync(flags: .barrier) {
            runningProcesses[command.id] = process
        }
        
        // Set up output handlers
        setupOutputHandler(pipe: outputPipe, type: .stdout, handler: outputHandler)
        setupOutputHandler(pipe: errorPipe, type: .stderr, handler: outputHandler)
        
        do {
            try process.run()
            
            // Wait for process to complete
            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
            
            // Clean up
            _ = processQueue.sync(flags: .barrier) {
                runningProcesses.removeValue(forKey: command.id)
            }
            
            // Check termination status
            if process.terminationStatus != 0 {
                throw GooseCliError.executionFailed("Command exited with status \(process.terminationStatus)")
            }
        } catch {
            _ = processQueue.sync(flags: .barrier) {
                runningProcesses.removeValue(forKey: command.id)
            }
            
            if let gooseError = error as? GooseCliError {
                throw gooseError
            } else {
                throw GooseCliError.executionFailed(error.localizedDescription)
            }
        }
    }
    
    /// Execute a command with timeout
    public func execute(
        command: GooseCommand,
        timeout: TimeInterval,
        outputHandler: @escaping (String, ResponseType) -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.execute(command: command, outputHandler: outputHandler)
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.cancel(commandId: command.id)
                throw GooseCliError.timeout
            }
            
            // Wait for first task to complete
            try await group.next()
            group.cancelAll()
        }
    }
    
    /// Cancel a running command
    public func cancel(commandId: UUID) {
        processQueue.sync(flags: .barrier) {
            if let process = runningProcesses[commandId], process.isRunning {
                process.terminate()
                runningProcesses.removeValue(forKey: commandId)
            }
        }
    }
    
    /// Check if a command is currently running
    public func isRunning(commandId: UUID) -> Bool {
        processQueue.sync {
            if let process = runningProcesses[commandId] {
                return process.isRunning
            }
            return false
        }
    }
    
    /// Cancel all running commands
    public func cancelAll() {
        processQueue.sync(flags: .barrier) {
            for (_, process) in runningProcesses {
                if process.isRunning {
                    process.terminate()
                }
            }
            runningProcesses.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupOutputHandler(
        pipe: Pipe,
        type: ResponseType,
        handler: @escaping (String, ResponseType) -> Void
    ) {
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    handler(output, type)
                }
            }
        }
    }
    
    private func findGooseCLI() throws -> String {
        // Try common paths
        let commonPaths = [
            "/usr/local/bin/goose",
            "/opt/homebrew/bin/goose",
            "/usr/bin/goose",
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".local/bin/goose").path
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try to find using which command
        let whichProcess = Process()
        let pipe = Pipe()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["goose"]
        whichProcess.standardOutput = pipe
        whichProcess.standardError = FileHandle.nullDevice
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            if whichProcess.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // which command failed, continue to throw error
        }
        
        throw GooseCliError.cliNotFound
    }
}
