from python import PythonObject
from python import Python
from mmm_dsp.Osc import Impulse
from mmm_utils.Messengers import Messenger, TextMessenger
from mmm_src.MMMWorld import MMMWorld

struct MLP[input_size: Int = 2, output_size: Int = 16](Representable, Movable, Copyable): 
    """
    A Mojo wrapper for a PyTorch MLP model using Python interop.

    ``MLP[input_size, output_size](world_ptr,file_name)``

    Parameters:
      input_size: The size of the input vector - defaults to 2.
      output_size: The size of the output vector - defaults to 16.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var py_input: PythonObject  
    var py_output: PythonObject  
    var model: PythonObject  
    var MLP: PythonObject  
    var torch: PythonObject  
    var model_input: InlineArray[Float64, input_size]  # Input list for audio synthesis
    var model_output: InlineArray[Float64, output_size]  # Output list from the model
    var inference_trig: Impulse
    var inference_gate: Bool
    var trig_rate: Float64
    var text_messenger: TextMessenger
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], file_name: String, trig_rate: Float64 = 25.0):
        self.world_ptr = world_ptr
        self.py_input = PythonObject(None) 
        self.py_output = PythonObject(None) 
        self.model = PythonObject(None)  
        self.MLP = PythonObject(None)  
        self.torch = PythonObject(None) 
        self.model_input = InlineArray[Float64, input_size](fill=0.0)
        self.model_output = InlineArray[Float64, output_size](fill=0.0)
        self.inference_trig = Impulse(self.world_ptr)
        self.inference_gate = False
        self.trig_rate = trig_rate
        self.text_messenger = TextMessenger(world_ptr)
        self.messenger = Messenger(world_ptr)

        try:
            # Python.add_to_path("neural_nets/MLP.py")
            self.MLP = Python.import_module("mmm_dsp.MLP")
            self.torch = Python.import_module("torch")
            self.py_input = self.torch.zeros(1, input_size)  # Create a tensor with shape [1, 2] filled with zeros
            self.model = self.torch.jit.load(file_name)  # Load your PyTorch model
            self.model.eval()  # Set the model to evaluation mode
            for _ in range (5):
                self.model(self.torch.randn(1, input_size))  # warm it up CHris

            self.inference_gate = True
            print("Torch model loaded successfully")

        except ImportError:
            print("Error importing MLP_py or torch module")
    
    fn reload_model(mut self: MLP, file_name: String):
        """
        Reload the MLP model from a specified file.

        Parameters:
          file_name: The path to the model file.
        """
        try:
            self.model = self.torch.jit.load(file_name)
            self.model.eval()
            for _ in range (5):
                self.model(self.torch.randn(1, input_size))  # I'm about to
            print("Torch model reloaded successfully")
        except Exception:
            print("Error reloading MLP model")

    fn __repr__(self) -> String:
        return String("MLP_Ugen(input_size: " + String(self.input_size) + ", output_size: " + String(self.output_size) + ")")

    @always_inline
    fn next(mut self: MLP):
        """
        Process the input through the MLP model.
            
        """
        if self.world_ptr[0].top_of_block:
            # this will return a tuple (model_path(String), triggered(Bool))
            load_msg = self.text_messenger.get_text_msg_val("load_mlp_training")
            if load_msg != "":
                print("loading new model", end="\n")
                self.reload_model(load_msg)


            self.inference_gate = self.messenger.get_val("toggle_inference", 1.0) == 1.0

            if not self.inference_gate:
                triggered = self.messenger.triggered("model_output")
                if triggered:
                    print("receiving model output values", end="\n")
                    model_output = self.messenger.get_list("model_output")
                    num = Int(min(self.output_size, len(model_output)))
                    for i in range(num):
                        self.model_output[i] = model_output[i]

        # do the inference only when triggered and the gate is on
        if self.inference_gate and self.inference_trig.next_bool(self.trig_rate):
            if self.torch is None:
                return 

            try:
                for i in range(self.input_size):
                    self.py_input[0][i] = self.model_input[Int(i)]
                self.py_output = self.model(self.py_input)  # Run the model with the input
            except Exception:
                print("Error processing input through MLP")

            try:
                py_output = self.model(self.py_input)  # Run the model with the input
                for i in range(self.output_size):
                    self.model_output[Int(i)] = Float64(py_output[0][i].item())  # Convert each output to Float64
            except Exception:
                print("Error processing input through MLP:")