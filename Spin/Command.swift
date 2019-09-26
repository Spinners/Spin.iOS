//
//  Command.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-09-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Command {
    associatedtype Stream: ReactiveStream
    associatedtype State
    func execute(basedOn state: State) -> Stream
}

public extension Command {
    func eraseToAnyCommand() -> AnyCommand<Stream, State> {
        return AnyCommand<Stream, State>(command: self)
    }
}

public class AnyCommand<AnyStream: ReactiveStream, AnyState>: Command {
    public typealias Stream = AnyStream
    public typealias State = AnyState
    
    private let executeClosure: (State) -> Stream
    
    init<CommandType: Command>(command: CommandType) where CommandType.Stream == Stream, CommandType.State == State {
        self.executeClosure = command.execute
    }
    
    public func execute(basedOn state: State) -> Stream {
        return self.executeClosure(state)
    }
}
