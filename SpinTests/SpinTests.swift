//
//  SpinTests.swift
//  SpinTests
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

import Spin
import XCTest

class MockExecuter {
}

class MockLifecycle {
    func afterSpin(function: () -> Void) {
        function()
    }
}

class MockState {
}

class MockAction {
}

class MockCommand: Command {
    func execute(basedOn state: MockState) -> MockStream<MockAction> {
        return MockStream<MockAction>(value: MockAction())
    }
}

protocol StreamType {
    associatedtype Element

    var value: Element { get }
}

class MockStream<Event>: StreamType {

    typealias Element = Event

    var value: Event
    var isFeedbackExecuted = false
    var isSpyExecuted = false
    var isToReactiveStreamExecuted = false
    var isConsumeExecuted = false

    init(value: Event) {
        self.value = value
    }
}

extension MockStream: Consumable {
    typealias Value = Element
    typealias Executer = MockExecuter
    typealias Lifecycle = MockLifecycle

    func consume(by: @escaping (Element) -> Void, on: MockExecuter) -> AnyConsumable<Element, MockExecuter, MockLifecycle> {
        by(self.value)
        self.isConsumeExecuted = true
        return self.eraseToAnyConsumable()
    }

    func spin() -> MockLifecycle {
        return MockLifecycle()
    }
}

extension MockStream: Producer where Element: Command, Element.Stream: StreamType, Element.Stream.Element == Element.Stream.Value {
    typealias Input = MockStream

    func executeAndScan(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        let newState = reducer(value, self.value.execute(basedOn: value).value)
        self.isFeedbackExecuted = true
        return MockStream<Value.State>(value: newState).eraseToAnyConsumable()
    }

    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        function(self.value)
        self.isSpyExecuted = true
        return self.eraseToAnyProducer()
    }

    func toReactiveStream() -> Input {
        self.isToReactiveStreamExecuted = true
        return self
    }
}

final class SpinTests: XCTestCase {

    func testAll_actors_in_the_loop_are_executed() {

        // Given:
        let exp = expectation(description: "executeAndScan")
        //        exp.expectedFulfillmentCount = 3
        exp.expectedFulfillmentCount = 2

        let inputStream = MockStream<AnyCommand<MockStream<MockAction>, MockState>>(value: MockCommand().eraseToAnyCommand())
        var feedbackSpyIsCalled = false

        // When: executing a full loop
        Spinner
            .from { return inputStream }
            //            .spy { _ in exp.fulfill() }
            .toReactiveStream()
            .executeAndScan(initial: MockState(), reducer: { (state, action) -> MockState in
                return MockState()
            }) { (state, action) in
                feedbackSpyIsCalled = true
                exp.fulfill()
        }
        .spin()
        .afterSpin {
            exp.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Then: All actors in the loop are executed
        XCTAssertTrue(feedbackSpyIsCalled)
        //        XCTAssertTrue(inputStream.isSpyExecuted)
        XCTAssertTrue(inputStream.isFeedbackExecuted)
        XCTAssertTrue(inputStream.isToReactiveStreamExecuted)
        XCTAssertTrue(inputStream.isFeedbackExecuted)
    }
}
