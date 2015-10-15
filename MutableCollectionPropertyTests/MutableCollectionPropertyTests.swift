//
//  MutableCollectionPropertyTests.swift
//  MutableCollectionPropertyTests
//
//  Created by Pedro Pinera Buendia on 14/10/15.
//  Copyright © 2015 com.gitdo. All rights reserved.
//

import XCTest
import Quick
import Nimble
import ReactiveCocoa

@testable import MutableCollectionProperty

class MutableCollectionPropertyTests: QuickSpec {

    override func spec() {

        describe("initialization") {

            it("should properly update the value once initialized") {
                let array: [String] = ["test1, test2"]
                let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                expect(property.value) == array
            }
        }

        describe("updates") {

            context("full update") {

                it("should notify the main producer") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: { (done) -> Void in
                        property.producer.on(event: { event in
                            switch event {
                            case .Next(_):
                                done()
                            default: break
                            }
                        }).start()
                        property.value = ["test2", "test3"]
                    })
                }

                it("should notify the changes producer with the replaced enum type") {
                    let array: [String] = ["test1", "test2"]
                    let newArray: [String] = ["test2", "test3"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: {
                        (done) -> Void in
                        var i: Int = 0
                        property.changes.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                switch change {
                                case .StartChange:
                                    expect(i) == 0
                                case .Replacement(let newValue):
                                    expect(newValue) == newArray
                                    expect(i) == 1
                                case .EndChange:
                                    done()
                                default: break
                                }
                                i++
                            default: break
                            }
                        }).start()
                        property.value = newArray
                    })
                }
            }

        }

        describe("deletion") {

            context("delete at a given index") {

                it("should notify the main producer") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: {
                        (done) -> Void in
                        property.producer.on(event: {
                            event in
                            switch event {
                            case .Next(let newValue):
                                expect(newValue) == ["test1"]
                                done()
                            default: break
                            }
                        }).start()
                        property.removeAtIndex(1)
                    })
                }

                it("should notify the changes producer with the right type") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: {
                        (done) -> Void in
                        var i: Int = 0
                        property.changes.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                switch change {
                                case .StartChange:
                                    expect(i) == 0
                                case .Deletion(let index, let element):
                                    expect(i) == 1
                                    expect(index) == 1
                                    expect(element) == "test2"
                                case .EndChange:
                                    done()
                                default: break
                                }
                            default: break
                            }
                            i++
                        }).start()
                        property.removeAtIndex(1)
                    })
                }
            }
            
            context("deleting the last element", {
                
                it("should notify the deletion to the main producer") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: { (done) -> Void in
                        property.producer.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                expect(change) == ["test1"]
                                done()
                            default: break
                            }
                        }).start()
                        property.removeLast()
                    })
                }
                
                it("should notify the deletion to the changes producer with the right type") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: { (done) -> Void in
                        var i: Int = 0
                        property.changes.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                switch change {
                                case .StartChange:
                                    expect(i) == 0
                                case .Deletion(let index, let element):
                                    expect(i) == 1
                                    expect(index) == 1
                                    expect(element) == "test2"
                                case .EndChange:
                                    done()
                                default: break
                                }
                            default: break
                            }
                            i++
                        }).start()
                        property.removeLast()
                    })
                }
                
            })
            
            context("deleting the first element", {
                it("should notify the deletion to the main producer") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: { (done) -> Void in
                        property.producer.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                expect(change) == ["test2"]
                                done()
                            default: break
                            }
                        }).start()
                        property.removeFirst()
                    })
                }
                
                it("should notify the deletion to the changes producer with the right type") {
                    let array: [String] = ["test1", "test2"]
                    let property: MutableCollectionProperty<String> = MutableCollectionProperty(array)
                    waitUntil(action: { (done) -> Void in
                        var i: Int = 0
                        property.changes.on(event: {
                            event in
                            switch event {
                            case .Next(let change):
                                switch change {
                                case .StartChange:
                                    expect(i) == 0
                                case .Deletion(let index, let element):
                                    expect(i) == 1
                                    expect(index) == 0
                                    expect(element) == "test1"
                                case .EndChange:
                                    done()
                                default: break
                                }
                            default: break
                            }
                            i++
                        }).start()
                        property.removeFirst()
                    })
                }
            })

        }

    }

}
