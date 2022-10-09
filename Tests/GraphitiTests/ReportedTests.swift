import Graphiti
import NIO
import XCTest

private protocol InterfaceA: Codable {
    var interfaceAField: String? { get }
}
private protocol InterfaceB: Codable {
    var interfaceBField: String? { get }
}
private struct ParentObject: Codable, InterfaceA, InterfaceB {
    let interfaceAField: String?
    let interfaceBField: String?
    let objects: [ObjectA]
}
private struct ObjectA: Codable, InterfaceA {
    let interfaceAField: String?
    let objectB: ObjectB?
    let objectC: ObjectC?
}
private struct ObjectB: Codable {
    let scalar: String
}
private struct ObjectC: Codable {
    let scalar: String
}
private struct TestResolver {
    func parentObject(context _: NoContext, arguments _: NoArguments) -> ParentObject {
        return ParentObject(
            interfaceAField: "ParentObject is A",
            interfaceBField: "ParentObject is B",
            objects: [
                ObjectA(
                    interfaceAField: "ObjectA1 is A",
                    objectB: ObjectB(scalar: "I'm A1's B"),
                    objectC: ObjectC(scalar: "I'm A1's C")
                ),
                ObjectA(
                    interfaceAField: "ObjectA2 is A",
                    objectB: ObjectB(scalar: "I'm A2's B"),
                    objectC: ObjectC(scalar: "I'm A2's C")
                )
            ]
        )
    }
}
private class TestAPI<Resolver, ContextType>: API {
    public let resolver: Resolver
    public let schema: Schema<Resolver, ContextType>

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}

class ReportedTests: XCTestCase {
    func testReportedError() throws {
        let testSchema = try Schema<TestResolver, NoContext> {
            Interface(InterfaceA.self) {
                Field("interfaceAField", at: \.interfaceAField)
            }
            Interface(InterfaceB.self) {
                Field("interfaceBField", at: \.interfaceBField)
            }
            
            Type(ParentObject.self, interfaces: [InterfaceA.self, InterfaceB.self]) {
                Field("interfaceAField", at: \.interfaceAField)
                Field("interfaceBField", at: \.interfaceBField)
                Field("objects", at: \.objects, as: [ObjectA].self)
            }
            Type(ObjectA.self, interfaces: [InterfaceA.self]) {
                Field("interfaceAField", at: \.interfaceAField)
                Field("objectB", at: \.objectB, as: ObjectB?.self)
                Field("objectC", at: \.objectC, as: ObjectC?.self)
            }
            Type(ObjectB.self) {
                Field("scalar", at: \.scalar)
            }
            Type(ObjectC.self) {
                Field("scalar", at: \.scalar)
            }
            
            Query {
                Field("parentObject", at: TestResolver.parentObject)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }

        print(
            try api.execute(
                request: """
                query {
                  parentObject {
                    interfaceAField
                    interfaceBField
                    objects {
                        interfaceAField
                        objectB {
                            scalar
                        }
                        objectC {
                            scalar
                        }
                    }
                  }
                }
                """,
                context: NoContext(),
                on: group
            ).wait()
        )
//        Prints:
//        {
//          "data": {
//            "parentObject": {
//              "interfaceAField": "ParentObject is A",
//              "interfaceBField": "ParentObject is B",
//              "objects": [
//                {
//                  "interfaceAField": "ObjectA1 is A",
//                  "objectB": {
//                    "scalar": "I'm A1's B"
//                  },
//                  "objectC": {
//                    "scalar": "I'm A1's C"
//                  }
//                },
//                {
//                  "interfaceAField": "ObjectA2 is A",
//                  "objectB": {
//                    "scalar": "I'm A2's B"
//                  },
//                  "objectC": {
//                    "scalar": "I'm A2's C"
//                  }
//                }
//              ]
//            }
//          }
//        }
    }
}
