//
//  Feedback.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-09-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Feedback: ReactiveStream where Value: Command {
    func feedback<Result>(initial value: Result, reducer: @escaping (Result, Value.Mutation) -> Result) -> AnyConsumable<Result, Executer, Lifecycle> where Result == Value.State
}
