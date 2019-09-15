//
//  Command.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-09-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Command {
    associatedtype State
    func execute<Output: Producer>(basedOn state: State) -> Output
}

class AbstractCommand<AbstractState>: Command {
    typealias State = AbstractState
    
    func execute<Output: Producer>(basedOn state: State) -> Output {
        fatalError("must implement")
    }
}

final class CommandWrapper<CommandType: Command>: AbstractCommand<CommandType.State> {
    private let command: CommandType

    init(command: CommandType) {
        self.command = command
    }

    override func execute<Output: Producer>(basedOn state: State) -> Output {
        return self.command.execute(basedOn: state)
    }
}

public final class AnyCommand<AnyState>: Command {
    public typealias State = AnyState

    private let command: AbstractCommand<State>

    init<CommandType: Command>(command: CommandType) where  CommandType.State == State {
        self.command = CommandWrapper(command: command)
    }

    public func execute<Output: Producer>(basedOn state: State) -> Output {
        return self.command.execute(basedOn: state)
    }
}

extension Command {
    func eraseToAnyCommand() -> AnyCommand<State> {
        return AnyCommand<State>(command: self)
    }
}
