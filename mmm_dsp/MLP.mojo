from python import PythonObject
from python import Python

struct MLP(Representable, Movable, Copyable):
    var input: List[Float64]  
    var output: List[Float64]  
    var input_size: Int64  
    var output_size: Int64 
    var py_input: PythonObject  
    var py_output: PythonObject  
    var model: PythonObject  
    var MLP: PythonObject  
    var torch: PythonObject  

    fn __init__(out self, file_name: String, input_size: Int64, output_size: Int64):
        self.input_size = input_size  
        self.input = List[Float64]()  
        for _ in range(input_size):
            self.input.append(0.0)  # Initialize input list with zeros

        self.output = List[Float64]()  
        self.output_size = output_size  # Set the output size
        for _ in range(self.output_size):
            self.output.append(0.0)  # Initialize output list with zeros
        
        self.py_input = PythonObject(None)  # Placeholder for input data
        self.py_output = PythonObject(None)  # Placeholder for output data
        self.model = PythonObject(None)  # Placeholder for the model
        self.MLP = PythonObject(None)  # Placeholder for the MLP class
        self.torch = PythonObject(None)  # Placeholder for the torch module

        try:
            # Python.add_to_path("neural_nets/MLP.py")
            self.MLP = Python.import_module("mmm_dsp.MLP")
            self.torch = Python.import_module("torch")
            self.py_input = self.torch.zeros(1, input_size)  # Create a tensor with shape [1, 2] filled with zeros
            self.model = self.torch.jit.load(file_name)  # Load your PyTorch model
            self.model.eval()  # Set the model to evaluation mode
            for _ in range (5):
                self.model(self.torch.randn(1, input_size))  # warm it up CHris

            print("Torch model loaded successfully")

        except ImportError:
            print("Error importing MLP_py or torch module")

    fn __repr__(self) -> String:
        return String("MLP_Ugen(input_size: " + String(self.input_size) + ", output_size: " + String(self.output_size) + ")")

    fn next(mut self: MLP, input: List[Float64]) raises -> List[Float64]:
        """Process the input through the MLP model."""
        if self.torch is None:
            return self.output  # Return the output if torch is not available

        if Int64(len(input)) != self.input_size:
            print("Input size mismatch: expected", self.input_size, "got", len(input))
            return self.output  # Return the output if input size does not match

        try:
            for i in range(self.input_size):
                self.py_input[0][i] = input[i]
            self.py_output = self.model(self.py_input)  # Run the model with the input
        except Exception:
            print("Error processing input through MLP")

        try:
            py_output = self.model(self.py_input)  # Run the model with the input
            for i in range(self.output_size):
                self.output[i] = Float64(py_output[0][i].item())  # Convert each output to Float64
            return self.output  # Return the output tensor
        except Exception:
            print("Error processing input through MLP:")
            return self.output  # Return the output if an error occurs