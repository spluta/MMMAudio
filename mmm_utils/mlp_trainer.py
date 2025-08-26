import torch
import time
import torch.nn as nn
import torch.optim as optim

from mmm_dsp.MLP import MLP 

# train the neural network - run everything below at once
def train_nn(X_train_list, y_train_list, layers, learn_rate, epochs, file_name):

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
    example_input = torch.randn(1, 2)
    traced_model = torch.jit.trace(model, example_input)

    # Save the traced model
    traced_model.save(file_name)

    print(f"Model saved to {file_name}")