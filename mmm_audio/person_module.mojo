from std.python import PythonObject
from std.python.bindings import PythonModuleBuilder
from std.os import abort

@export
def PyInit_person_module() -> PythonObject:
    try:
        var mb = PythonModuleBuilder("person_module")
        _ = mb.add_type[Person]("Person").def_py_init[Person.py_init]()
        return mb.finalize()
    except e:
        abort(String("error creating Python Mojo module:", e))

@fieldwise_init
struct Person(Movable, Writable):
    var name: String
    var age: Int

    @staticmethod
    def py_init(
        out self: Person, args: PythonObject, kwargs: PythonObject
    ) raises:
        # Validate argument count
        if len(args) != 2:
            raise Error("Person() takes exactly 2 arguments")

        # Convert Python arguments to Mojo types
        var name = String(args[0])
        var age = Int(py=args[1])

        self = Self(name, age)