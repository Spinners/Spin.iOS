//
//  Producer.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Producer: ReactiveStream {
    associatedtype Input: Producer where Input.Value == Value, Input.Executer == Executer, Input.Lifecycle == Lifecycle

    static func from(function: () -> Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle>
    func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Executer, Output.Lifecycle>
    func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Executer, Lifecycle>
    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle>
    func toReactiveStream() -> Input
}

public extension Producer {
    static func from(function: () -> Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle> {
        return function().eraseToAnyProducer()
    }
}

public extension Producer {
    func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result, middlewares: (Result, Value) -> Void...) -> AnyConsumable<Result, Executer, Lifecycle> {
        let middlewaresAndReducer: (Result, Value) -> Result = { (result, value) -> Result in
            middlewares.forEach { $0(result, value) }
            return reducer(result, value)
        }
        return self.scan(initial: value, reducer: middlewaresAndReducer)
    }
}

public extension Producer {
    func eraseToAnyProducer() -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return AnyProducer(producer: self)
    }
}

class AbstractProducer<AbstractInput: Producer, AbstractValue, AbstractContext, AbstractRuntime>: Producer
    where AbstractInput.Value == AbstractValue, AbstractInput.Executer == AbstractContext, AbstractInput.Lifecycle == AbstractRuntime {
    typealias Input = AbstractInput
    typealias Value = AbstractValue
    typealias Executer = AbstractContext
    typealias Lifecycle = AbstractRuntime

    func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Executer, Output.Lifecycle> {
        fatalError("must implement")
    }

    func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Executer, Lifecycle> {
        fatalError("must implement")
    }

    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        fatalError("must implement")
    }
    
    func toReactiveStream() -> AbstractInput {
        fatalError("must implement")
    }
}

final class ProducerWrapper<ProducerType: Producer>: AbstractProducer<ProducerType.Input, ProducerType.Value, ProducerType.Executer, ProducerType.Lifecycle> {
    private let producer: ProducerType

    init(producer: ProducerType) {
        self.producer = producer
    }

    override func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Executer, Output.Lifecycle> {
        return self.producer.compose(function: function)
    }

    override func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Executer, Lifecycle> {
        return self.producer.scan(initial: value, reducer: reducer)
    }

    override func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return self.producer.spy(function: function)
    }
    
    override func toReactiveStream() -> Input {
        return self.producer.toReactiveStream()
    }
}

public final class AnyProducer<AnyInput: Producer, AnyValue, AnyContext, AnyRuntime>: Producer
    where AnyInput.Value == AnyValue, AnyInput.Executer == AnyContext, AnyInput.Lifecycle == AnyRuntime {
    public typealias Input = AnyInput
    public typealias Value = AnyValue
    public typealias Executer = AnyContext
    public typealias Lifecycle = AnyRuntime

    private let producer: AbstractProducer<Input, Value, Executer, Lifecycle>

    init<ProducerType: Producer>(producer: ProducerType)
        where  ProducerType.Input == Input, ProducerType.Value == Value, ProducerType.Executer == Executer, ProducerType.Lifecycle == Lifecycle {
        self.producer = ProducerWrapper(producer: producer)
    }
    
    public func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Executer, Output.Lifecycle> {
        return self.producer.compose(function: function)
    }

    public func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Executer, Lifecycle> {
        return self.producer.scan(initial: value, reducer: reducer)
    }

    public func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return self.producer.spy(function: function)
    }
    
    public func toReactiveStream() -> Input {
        return self.producer.toReactiveStream()
    }
}
