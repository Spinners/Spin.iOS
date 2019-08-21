//
//  Consumable.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Consumable: ReactiveStream where Input: Consumable {
    func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Input, Value, Context, Runtime>
    func spin() -> Runtime
}

public extension Consumable {
    func eraseToAnyConsumable() -> AnyConsumable<Input, Value, Context, Runtime> {
        return AnyConsumable(consumable: self)
    }
}

class AbstractConsumable<AbstractInput: Consumable, AbstractValue, AbstractContext, AbstractRuntime>: Consumable
    where AbstractInput.Value == AbstractValue, AbstractInput.Context == AbstractContext, AbstractInput.Runtime == AbstractRuntime {
    
    typealias Value = AbstractValue
    typealias Context = AbstractContext
    typealias Runtime = AbstractRuntime

    func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Input, Value, Context, Runtime> {
        fatalError("must implement")
    }

    func spin() -> Runtime {
        fatalError("must implement")
    }
    
    func toReactiveStream() -> AbstractInput {
        fatalError("must implement")
    }
}

final class ConsumableWrapper<ConsumableType: Consumable>: AbstractConsumable<ConsumableType.Input, ConsumableType.Value, ConsumableType.Context, ConsumableType.Runtime> {
    private let consumable: ConsumableType

    init(consumable: ConsumableType) {
        self.consumable = consumable
    }

    override func consume(by: @escaping (ConsumableType.Value) -> Void,
                          on: ConsumableType.Context) -> AnyConsumable<ConsumableType.Input, ConsumableType.Value, ConsumableType.Context, ConsumableType.Runtime> {
        return self.consumable.consume(by: by, on: on)
    }

    override func spin() -> ConsumableType.Runtime {
        return self.consumable.spin()
    }
    
    override func toReactiveStream() -> Input {
        return self.consumable.toReactiveStream()
    }
}

public final class AnyConsumable<AnyInput: Consumable, AnyValue, AnyContext, AnyRuntime>: Consumable
    where AnyInput.Value == AnyValue, AnyInput.Context == AnyContext, AnyInput.Runtime == AnyRuntime {
    public typealias Input = AnyInput
    public typealias Value = AnyValue
    public typealias Context = AnyContext
    public typealias Runtime = AnyRuntime

    private let consumable: AbstractConsumable<Input, Value, Context, Runtime>

    init<ConsumableType: Consumable>(consumable: ConsumableType)
        where ConsumableType.Input == Input, ConsumableType.Value == Value, ConsumableType.Context == AnyContext, ConsumableType.Runtime == AnyRuntime {
        self.consumable = ConsumableWrapper(consumable: consumable)
    }

    public func consume(by: @escaping (Value) -> Void, on: Context) -> AnyConsumable<Input, Value, Context, Runtime> {
        return self.consumable.consume(by: by, on: on)
    }

    public func spin() -> Runtime {
        return self.consumable.spin()
    }
    
    public func toReactiveStream() -> AnyInput {
        return self.consumable.toReactiveStream()
    }
}
