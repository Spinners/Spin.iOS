//
//  Producer.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Producer: ReactiveStream where Value: Command {
    associatedtype Input: Producer where Input.Value == Value, Input.Executer == Executer, Input.Lifecycle == Lifecycle

    static func from(function: () -> Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle>
    func feedback(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle>
    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle>
    func toReactiveStream() -> Input
}

public extension Producer {
    static func from(function: () -> Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle> {
        return function().eraseToAnyProducer()
    }
}

public extension Producer {
    func feedback(initial value: Value.State,
                  reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State,
                  spies: (Value.State, Value.Stream.Value) -> Void...) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        let spiesAndReducer: (Value.State, Value.Stream.Value) -> Value.State = { (result, value) -> Value.State in
            spies.forEach { $0(result, value) }
            return reducer(result, value)
        }
        return self.feedback(initial: value, reducer: spiesAndReducer)
    }
}

public extension Producer {
    func eraseToAnyProducer() -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return AnyProducer(producer: self)
    }
}

class AbstractProducer<AbstractInput: Producer, AbstractValue, AbstractExecuter, AbstractLifecycle>: Producer
where AbstractInput.Value == AbstractValue, AbstractInput.Executer == AbstractExecuter, AbstractInput.Lifecycle == AbstractLifecycle {
    typealias Input = AbstractInput
    typealias Value = AbstractValue
    typealias Executer = AbstractExecuter
    typealias Lifecycle = AbstractLifecycle

    func feedback(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle> {
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

    override func feedback(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        return self.producer.feedback(initial: value, reducer: reducer)
    }

    override func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return self.producer.spy(function: function)
    }
    
    override func toReactiveStream() -> Input {
        return self.producer.toReactiveStream()
    }
}

public final class AnyProducer<AnyInput: Producer, AnyValue, AnyExecuter, AnyLifecycle>: Producer
    where AnyInput.Value == AnyValue, AnyInput.Executer == AnyExecuter, AnyInput.Lifecycle == AnyLifecycle {
    public typealias Input = AnyInput
    public typealias Value = AnyValue
    public typealias Executer = AnyExecuter
    public typealias Lifecycle = AnyLifecycle

    private let producer: AbstractProducer<Input, Value, Executer, Lifecycle>

    init<ProducerType: Producer>(producer: ProducerType)
        where  ProducerType.Input == Input, ProducerType.Value == Value, ProducerType.Executer == Executer, ProducerType.Lifecycle == Lifecycle {
        self.producer = ProducerWrapper(producer: producer)
    }

    public func feedback(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        return self.producer.feedback(initial: value, reducer: reducer)
    }

    public func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return self.producer.spy(function: function)
    }
    
    public func toReactiveStream() -> Input {
        return self.producer.toReactiveStream()
    }
}

public typealias Spin = AnyProducer
