//
//  ReactiveStream.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-21.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol ReactiveStream {
    associatedtype Value
    associatedtype Context
    associatedtype Runtime
}
