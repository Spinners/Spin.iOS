//
//  Consumable.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Consumable: ReactiveStream {
    func consume(by: @escaping (Value) -> Void, on: Executer) -> AnyConsumable<Value, Executer, Lifecycle>
    func spin() -> Lifecycle
}

public extension Consumable {
    func eraseToAnyConsumable() -> AnyConsumable<Value, Executer, Lifecycle> {
        return AnyConsumable(consumable: self)
    }
}

class AbstractConsumable<AbstractValue, AbstractContext, AbstractRuntime>: Consumable {
    typealias Value = AbstractValue
    typealias Executer = AbstractContext
    typealias Lifecycle = AbstractRuntime

    func consume(by: @escaping (Value) -> Void, on: Executer) -> AnyConsumable<Value, Executer, Lifecycle> {
        fatalError("must implement")
    }

    func spin() -> Lifecycle {
        fatalError("must implement")
    }
}

final class ConsumableWrapper<ConsumableType: Consumable>: AbstractConsumable<ConsumableType.Value, ConsumableType.Executer, ConsumableType.Lifecycle> {
    private let consumable: ConsumableType

    init(consumable: ConsumableType) {
        self.consumable = consumable
    }

    override func consume(by: @escaping (ConsumableType.Value) -> Void,
                          on: ConsumableType.Executer) -> AnyConsumable<ConsumableType.Value, ConsumableType.Executer, ConsumableType.Lifecycle> {
        return self.consumable.consume(by: by, on: on)
    }

    override func spin() -> ConsumableType.Lifecycle {
        return self.consumable.spin()
    }
}

public final class AnyConsumable<AnyValue, AnyContext, AnyRuntime>: Consumable {
    public typealias Value = AnyValue
    public typealias Executer = AnyContext
    public typealias Lifecycle = AnyRuntime

    private let consumable: AbstractConsumable<Value, Executer, Lifecycle>

    init<ConsumableType: Consumable>(consumable: ConsumableType)
        where ConsumableType.Value == Value, ConsumableType.Executer == AnyContext,  ConsumableType.Lifecycle == AnyRuntime {
        self.consumable = ConsumableWrapper(consumable: consumable)
    }

    public func consume(by: @escaping (Value) -> Void, on: Executer) -> AnyConsumable<Value, Executer, Lifecycle> {
        return self.consumable.consume(by: by, on: on)
    }

    public func spin() -> Lifecycle {
        return self.consumable.spin()
    }
}
