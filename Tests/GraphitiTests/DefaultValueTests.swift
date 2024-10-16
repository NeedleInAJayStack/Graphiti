import Foundation
@testable import Graphiti
import GraphQL
import NIO
import XCTest

class DefaultValueTests: XCTestCase {
    func testDefaultValues() throws {
        struct Resolver {
            struct BoolArgs: Codable {
                let bool: Bool
            }
            func bool(context _: NoContext, arguments: BoolArgs) -> Bool {
                return arguments.bool
            }
            
            struct IntArgs: Codable {
                let int: Int
            }
            func int(context _: NoContext, arguments: IntArgs) -> Int {
                return arguments.int
            }
            
            struct StrArgs: Codable {
                let str: String
            }
            func str(context _: NoContext, arguments: StrArgs) -> String {
                return arguments.str
            }
            
            struct IDArgs: Codable {
                let id: ID
            }
            func id(context _: NoContext, arguments: IDArgs) -> ID {
                return arguments.id
            }
        }
        
        let schema = try Schema<Resolver, NoContext> {
            Scalar(ID.self, as: "ID")
            Query {
                Field("bool", at: Resolver.bool) {
                    Argument("bool", at: \.bool).defaultValue(true)
                }
                Field("int", at: Resolver.int) {
                    Argument("int", at: \.int).defaultValue(5)
                }
                Field("str", at: Resolver.str) {
                    Argument("str", at: \.str).defaultValue("five")
                }
                Field("id", at: Resolver.id) {
                    Argument("id", at: \.id).defaultValue(.init("123"))
                }
            }
        }
        
        let resolver = Resolver()
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        XCTAssertEqual(
            try schema.execute(
                request: """
                query {
                    bool
                    int
                    str
                    id
                }
                """,
                resolver: resolver,
                context: NoContext(),
                eventLoopGroup: group
            ).wait(),
            GraphQLResult(
                data: [
                    "bool": true,
                    "int": 5,
                    "str": "five",
                    "id": "123"
                ]
            )
        )
        
        // test non-defaults
        XCTAssertEqual(
            try schema.execute(
                request: """
                query {
                    bool(bool: false)
                    int(int: 2)
                    str(str: "two")
                    id(id: "456")
                }
                """,
                resolver: resolver,
                context: NoContext(),
                eventLoopGroup: group
            ).wait(),
            GraphQLResult(
                data: [
                    "bool": false,
                    "int": 2,
                    "str": "two",
                    "id": "456"
                ]
            )
        )
    }
}
