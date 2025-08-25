import torch
import numpy as np
import time
import torch.nn as nn
import torch.optim as optim
from torch.nn.modules import Module
from typing import List
import json


import os, sys
dir_path = os.path.dirname(os.path.realpath(__file__))
parent_path = os.path.abspath(os.path.join(dir_path, os.pardir))
sys.path.append(parent_path)

import argparse
import os

parser = argparse.ArgumentParser(
    description='Train a Linear only neural net on data from a file.')

parser.add_argument('-f', '--file', type=str, default='MLP_control/data.json', help='Path to the JSON file with the NN data.')
parser.add_argument('-o', '--outfile', type=str, default=None, help='Path to the output JSON training in Pytorch format.')

args = parser.parse_args()
print(args)

# Load the data from a JSON file
json_path = args.file
with open(json_path, 'r') as json_file:
    data = json.load(json_file)

json_dir = os.path.dirname(json_path)
raw_filename = os.path.splitext(os.path.basename(json_path))[0]

# use a gpu for training if available
if torch.backends.mps.is_available():
    device = torch.device("mps")
else:
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Using device:", device)

# Define the neural network model
class MLP(nn.Module):
    def __init__(self, input_size, layers_data: list):
        super(MLP, self).__init__()
        self.layers = nn.ModuleList()
        for size, activation in layers_data:
            self.layers.append(nn.Linear(input_size, size))
            input_size = size  # For the next layer
            print(activation)
            if activation is not None:
                assert isinstance(activation, Module), \
                    "Each tuples should contain a size (int) and a torch.nn.modules.Module."
                self.layers.append(activation)
       
    def forward(self, input_data):
        for layer in self.layers:
            input_data = layer(input_data)
        return input_data

# Assuming the data contains 'X_train' and 'y_train' keys
X_train_list = data['in_vals']
y_train_list = data['out_vals']

learn_rate = data['learn_rate']
epochs = data['epochs']

data_list = data['layers_data']

print(data_list)

for i, vals in enumerate(data_list):
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
    data_list[i] = [val, activation]
print(data_list)

# Convert lists to torch tensors and move to the appropriate device
X_train = torch.tensor(X_train_list, dtype=torch.float32).to(device)
y_train = torch.tensor(y_train_list, dtype=torch.float32).to(device)

input_size = X_train.shape[1]
model = MLP(input_size, data['layers_data']).to(device)
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

if args.outfile is None:
    args.outfile = raw_filename+".pt"
    out_path = json_dir+"/"+args.outfile
else:
    out_path = args.outfile

if out_path[-3:] != ".pt":
    out_path += ".pt"

torch.save(model, out_path)

# Save the model in ONNX format if onnxscript is installed
try:
    onnx_out_path = out_path.replace(".pt", ".onnx")
    torch_input = torch.randn(1, input_size)
    onnx_program = torch.onnx.dynamo_export(model, torch_input)
    onnx_program.save(onnx_out_path)
except Exception as e:
    print("ONNX export failed. If you want to export the model in ONNX format, install onnxscript with pip.")

layers = model.layers

print("Model layers:")
for layer in layers:
    print(layer)

# # # Create a Keras model with the same architecture
keras_input = Input(shape=(layers[0].in_features,))
match str(layers[1]):
    case 'ReLU()':
        activation = 'relu'
    case 'Sigmoid()':
        activation = 'sigmoid'
    case 'Tanh()':
        activation = 'tanh'
    case _:
        activation = 'linear'
keras_output = keras.layers.Dense(layers[0].out_features, activation)(keras_input)

for i in range(2, len(layers), 2):
    print(i, layers[i+1])
    match str(layers[i+1]):
        case 'ReLU()':
            activation = 'relu'
        case 'Sigmoid()':
            activation = 'sigmoid'
        case 'Tanh()':
            activation = 'tanh'
        case _:
            activation = 'linear'
    keras_output = keras.layers.Dense(layers[i].out_features, activation)(keras_output)

keras_model = Model(inputs=keras_input, outputs=keras_output)

# Get the number of layers in the Keras model
num_layers = len(keras_model.layers)
# # # Copy the weights from PyTorch model to Keras model
with torch.no_grad():
    for i in range(num_layers-1):
        keras_model.layers[i+1].set_weights([model.layers[i*2].weight.T.numpy(), model.layers[i*2].bias.numpy()])

# Generate a sample input
sample_input = torch.randn(1, input_size)

# Set PyTorch model to evaluation mode
model.eval()

# Get PyTorch model prediction
with torch.no_grad():
    pytorch_output = model(sample_input)
    print("pytorch: ", pytorch_output)

# Get Keras model prediction
keras_output = keras_model.predict(sample_input.numpy(), verbose = 0)

# Convert Keras output to a PyTorch tensor
keras_output_tensor = torch.tensor(keras_output)
print("keras: ", keras_output_tensor)

# Compare predictions
if torch.allclose(pytorch_output, keras_output_tensor, atol=1e-6):
    print("The predictions are the same.")
    # Save the Keras model
    out_path = out_path.replace(".pt", "_RTNeural.json")
    print("out_path: ", out_path)
    save_model(keras_model, out_path)
    print("RT Neural model saved to: ", out_path)

