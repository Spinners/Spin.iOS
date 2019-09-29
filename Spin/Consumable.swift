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

public final class AnyConsumable<AnyValue, AnyExecuter, AnyLifecycle>: Consumable {
    public typealias Value = AnyValue
    public typealias Executer = AnyExecuter
    public typealias Lifecycle = AnyLifecycle

    private let consumeClosure: (@escaping (Value) -> Void, Executer) -> AnyConsumable<Value, Executer, Lifecycle>
    private let spinClosure: () -> Lifecycle

    init<ConsumableType: Consumable>(consumable: ConsumableType) where ConsumableType.Value == Value, ConsumableType.Executer == Executer, ConsumableType.Lifecycle == Lifecycle {
        self.consumeClosure = consumable.consume
        self.spinClosure = consumable.spin
    }

    public func consume(by: @escaping (Value) -> Void, on: Executer) -> AnyConsumable<AnyValue, AnyExecuter, AnyLifecycle> {
        return self.consumeClosure(by, on)
    }

    public func spin() -> Lifecycle {
        return self.spinClosure()
    }
}
