//
//  Command.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-09-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Command {
    associatedtype State
    associatedtype Mutation
    func execute<Output: Producer>(basedOn state: State) -> Output where Output.Value == Mutation
}

class AbstractCommand<AbstractState, AbstractMutation>: Command {
    typealias State = AbstractState
    typealias Mutation = AbstractMutation

    func execute<Output: Producer>(basedOn state: State) -> Output where Output.Value == Mutation {
        fatalError("must implement")
    }
}

final class CommandWrapper<CommandType: Command>: AbstractCommand<CommandType.State, CommandType.Mutation> {
    private let command: CommandType

    init(command: CommandType) {
        self.command = command
    }

    override func execute<Output: Producer>(basedOn state: State) -> Output where Output.Value == Mutation {
        return self.command.execute(basedOn: state)
    }
}

public final class AnyCommand<AnyState, AnyMutation>: Command {
    public typealias State = AnyState
    public typealias Mutation = AnyMutation

    private let command: AbstractCommand<State, Mutation>

    init<CommandType: Command>(command: CommandType) where CommandType.State == State, CommandType.Mutation == Mutation {
        self.command = CommandWrapper(command: command)
    }

    public func execute<Output: Producer>(basedOn state: State) -> Output where Output.Value == Mutation {
        return self.command.execute(basedOn: state)
    }
}

extension Command {
    func eraseToAnyCommand() -> AnyCommand<State, Mutation> {
        return AnyCommand<State, Mutation>(command: self)
    }
}
