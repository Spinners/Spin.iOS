//
//  Consumable.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Consumable {
    associatedtype Value
    associatedtype Context
    associatedtype Runtime

    func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Value, Context, Runtime>
    func spin() -> Runtime
}

public extension Consumable {
    func eraseToAnyConsumable() -> AnyConsumable<Value, Context, Runtime> {
        return AnyConsumable(consumable: self)
    }
}

class AbstractConsumable<AbstractValue, AbstractContext, AbstractRuntime>: Consumable {
    typealias Value = AbstractValue
    typealias Context = AbstractContext
    typealias Runtime = AbstractRuntime

    func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Value, Context, Runtime> {
        fatalError("must implement")
    }

    func spin() -> Runtime {
        fatalError("must implement")
    }
}

final class ConsumableWrapper<ConsumableType: Consumable>: AbstractConsumable<ConsumableType.Value, ConsumableType.Context, ConsumableType.Runtime> {
    private let consumable: ConsumableType

    init(consumable: ConsumableType) {
        self.consumable = consumable
    }

    override func consume(by: @escaping (ConsumableType.Value) -> Void,
                          on: ConsumableType.Context) -> AnyConsumable<ConsumableType.Value, ConsumableType.Context, ConsumableType.Runtime> {
        return self.consumable.consume(by: by, on: on)
    }

    override func spin() -> ConsumableType.Runtime {
        return self.consumable.spin()
    }
}

public final class AnyConsumable<AnyValue, AnyContext, AnyRuntime>: Consumable {
    public typealias Value = AnyValue
    public typealias Context = AnyContext
    public typealias Runtime = AnyRuntime

    private let consumable: AbstractConsumable<Value, Context, Runtime>

    init<ConsumableType: Consumable>(consumable: ConsumableType) where  ConsumableType.Value == Value,
                                                                        ConsumableType.Context == AnyContext,
                                                                        ConsumableType.Runtime == AnyRuntime {
        self.consumable = ConsumableWrapper(consumable: consumable)
    }

    public func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Value, Context, Runtime> {
        return self.consumable.consume(by: by, on: on)
    }

    public func spin() -> Runtime {
        return self.consumable.spin()
    }
}
