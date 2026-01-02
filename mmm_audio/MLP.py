import torch.nn as nn

class MLP(nn.Module):
    def __init__(self, input_size, layers_data: list):
        super(MLP, self).__init__()

        self.layers = nn.ModuleList()
        for size, activation in layers_data:
            self.layers.append(nn.Linear(input_size, size))
            input_size = size  # For the next layer
            print(activation)
            if activation is not None:
                assert isinstance(activation, nn.Module), \
                    "Each tuples should contain a size (int) and a torch.nn.modules.Module."
                self.layers.append(activation)
       
    def forward(self, input_data):
        for layer in self.layers:
            input_data = layer(input_data)
        return input_data
    
    def get_input_size(self):
        return self.input_size

    def get_output_size(self):
        return self.output_size