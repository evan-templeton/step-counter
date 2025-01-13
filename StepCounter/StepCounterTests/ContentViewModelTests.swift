//
//  ContentViewModelTests.swift
//  StepCounterTests
//
//  Created by Evan Templeton on 1/2/25.
//

import XCTest
@testable import StepCounter

@MainActor
final class ContentViewModelTests: XCTestCase {

    private var viewModel: ContentViewModel!
    private var stepsService: StepsServiceMock!
    
    override func setUp() {
        stepsService = StepsServiceMock()
        viewModel = ContentViewModel(stepsService: stepsService)
    }
    
    func testIsAuthorizedTrue() {
        stepsService.isAuthorizedOverride = true
        XCTAssertTrue(viewModel.isAuthorized)
    }
    
    func testIsAuthorizedFalse() {
        stepsService.isAuthorizedOverride = false
        XCTAssertFalse(viewModel.isAuthorized)
    }
    
    func testRequestAuthorizationSuccess() async {
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.requestAuthorization()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testRequestAuthorizationThrows() async {
        stepsService.requestAuthorizationShouldThrow = true
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.requestAuthorization()
        XCTAssertEqual(viewModel.errorMessage, StepsServiceError.healthKitDataUnavailable.userMessage)
    }
    
    func testGetStepsByHourSuccess() async {
        let expectedSteps = Array(repeating: 10, count: 24)
        stepsService.stepsByHourOverride = expectedSteps
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.getStepsByHour()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.stepsByHour, expectedSteps)
    }
    
    func testGetStepsByHourThrows() async {
        stepsService.fetchStepsByHourShouldThrow = true
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.getStepsByHour()
        XCTAssertEqual(viewModel.errorMessage, StepsServiceError.fetchSteps.userMessage)
    }
    
    func testGetStepsByDaySuccess() async {
        let expectedSteps = DailyStepsResult.mocks(5)
        stepsService.stepsByDayOverride = expectedSteps
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.getStepsByDay()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.stepsByDay, expectedSteps)
    }
    
    func testGetStepsByDayThrows() async {
        stepsService.fetchStepsByDayShouldThrow = true
        XCTAssertNil(viewModel.errorMessage)
        await viewModel.getStepsByDay()
        XCTAssertEqual(viewModel.errorMessage, StepsServiceError.fetchSteps.userMessage)
    }
}

extension DailyStepsResult {
    static func mocks(_ count: Int) -> [DailyStepsResult] {
        (1..<count).map { DailyStepsResult(id: $0, datetime: Date(timeIntervalSince1970: TimeInterval($0)), totalSteps: $0 * 500) }
    }
}
