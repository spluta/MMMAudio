"""Contains a Multi-Layer Perceptron (MLP) implementation using PyTorch and the train_nn function to train the network."""

import torch
import time
import torch.nn as nn
import torch.optim as optim

class MLP(nn.Module):
    """The Multi-Layer Perceptron (MLP) class."""
    def __init__(self, input_size: int, layers_data: list):
        """
        Initialize the MLP.

        Args:
            input_size: Size of the input layer.
            layers_data: A list of tuples where each tuple contains the size of the layer and the activation function.
        """

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
       
    def forward(self, input_data: list[list[float]]):
        """
        Forward pass through the MLP.

        Args:
            input_data: Input tensor.
        """
        for layer in self.layers:
            input_data = layer(input_data)
        return input_data
    
    def get_input_size(self):
        """Get the input size of the MLP."""
        return self.input_size

    def get_output_size(self):
        """Get the output size of the MLP."""
        return self.output_size
    
def train_nn(X_train_list: list[list[float]], y_train_list: list[list[float]], layers: list[tuple[int, str | None]], learn_rate: float, epochs: int, file_name: str):
    """Train the MLP and save the trained model.

    Args:
        X_train_list: List of input training data.
        y_train_list: List of output training data.
        layers: List of layer specifications (size and activation).
        learn_rate: Learning rate for the optimizer.
        epochs: Number of training epochs.
        file_name: File name to save the trained model.
    """

    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Using device:", device)


    print(layers)

    for i, vals in enumerate(layers):
        print(f"Layer {i}: {vals}")
        val, activation = vals
        if activation is not None:
            if activation == 'relu':
                activation = nn.ReLU()
            elif activation == 'sigmoid':
                activation = nn.Sigmoid()
            elif activation == 'tanh':
                activation = nn.Tanh()
            else:
                raise ValueError("Activation function not recognized.")
        layers[i] = [val, activation]


    print(layers)

    # Convert lists to torch tensors and move to the appropriate device
    X_train = torch.tensor(X_train_list, dtype=torch.float32).to(device)
    y_train = torch.tensor(y_train_list, dtype=torch.float32).to(device)

    input_size = X_train.shape[1]
    model = MLP(input_size, layers).to(device)
    criterion = nn.MSELoss()
    last_time = time.time()

    for nums in [[learn_rate,epochs]]:
        optimizer = optim.Adam(model.parameters(), lr=nums[0])

        # Train the model
        for epoch in range(nums[1]):
            optimizer.zero_grad()
            outputs = model(X_train)
            loss = criterion(outputs, y_train)
            if epoch % 100 == 0:
                elapsed_time = time.time() - last_time
                last_time = time.time()
                print(epoch, loss.item(), elapsed_time)
            loss.backward()
            optimizer.step()


    # Print the training loss
    print("Training loss:", loss.item())

    # Save the model
    model = model.to('cpu')

    # Trace the model
    example_input = torch.randn(1, input_size)
    traced_model = torch.jit.trace(model, example_input)

    # Save the traced model
    traced_model.save(file_name)

    print(f"Model saved to {file_name}")