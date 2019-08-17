//
//  Producer.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Producer {
    associatedtype Input: Producer where Input.Value == Value
    associatedtype Value
    associatedtype Context
    associatedtype Runtime

    static func from(function: () -> Input ) -> AnyProducer<Input, Value, Context, Runtime>
    func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Context, Output.Runtime>
    func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Context, Runtime>
    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Context, Runtime>
}

public extension Producer {
    static func from(function: () -> Input ) -> AnyProducer<Input, Value, Context, Runtime> {
        return function().eraseToAnyProducer() as! AnyProducer<Self.Input, Self.Value, Self.Context, Self.Runtime>
    }
}

public extension Producer {
    func eraseToAnyProducer() -> AnyProducer<Input, Value, Context, Runtime> {
        return AnyProducer(producer: self)
    }
}

class AbstractProducer<AbstractInput: Producer, AbstractValue, AbstractContext, AbstractRuntime>: Producer where AbstractInput.Value == AbstractValue {
    typealias Input = AbstractInput
    typealias Value = AbstractValue
    typealias Context = AbstractContext
    typealias Runtime = AbstractRuntime

    func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Context, Output.Runtime> {
        fatalError("must implement")
    }

    func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Context, Runtime> {
        fatalError("must implement")
    }

    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Context, Runtime> {
        fatalError("must implement")
    }
}

final class ProducerWrapper<ProducerType: Producer>: AbstractProducer<ProducerType.Input, ProducerType.Value, ProducerType.Context, ProducerType.Runtime> {
    private let producer: ProducerType

    init(producer: ProducerType) {
        self.producer = producer
    }

    override func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Context, Output.Runtime> {
        return self.producer.compose(function: function)
    }

    override func scan<Result>(initial value: Result, reducer: @escaping (Result, ProducerType.Value) -> Result) -> AnyConsumable<Result, Context, Runtime> {
        return self.producer.scan(initial: value, reducer: reducer)
    }

    override func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Context, Runtime> {
        return self.producer.spy(function: function)
    }
}

public final class AnyProducer<AnyInput: Producer, AnyValue, AnyContext, AnyRuntime>: Producer where AnyInput.Value == AnyValue {
    public typealias Input = AnyInput
    public typealias Value = AnyValue
    public typealias Context = AnyContext
    public typealias Runtime = AnyRuntime

    private let producer: AbstractProducer<Input, Value, Context, Runtime>

    init<ProducerType: Producer>(producer: ProducerType) where  ProducerType.Input == Input,
                                                                ProducerType.Value == Value,
                                                                ProducerType.Context == Context,
                                                                ProducerType.Runtime == Runtime {
        self.producer = ProducerWrapper(producer: producer)
    }

    public func compose<Output: Producer>(function: (Input) -> Output) -> AnyProducer<Output.Input, Output.Value, Output.Context, Output.Runtime> {
        return self.producer.compose(function: function)
    }

    public func scan<Result>(initial value: Result, reducer: @escaping (Result, Value) -> Result) -> AnyConsumable<Result, Context, Runtime> {
        return self.producer.scan(initial: value, reducer: reducer)
    }

    public func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Context, Runtime> {
        return self.producer.spy(function: function)
    }
}