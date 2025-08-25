"""this examples uses a Torch MLP model to control a 16 parameter synth
to play the synth, just hang out in the top 4 lines of code and play with the mouse

you can also train the synth by creating any number of input/output pairs and making a new training
"""

from mmm_src.MMMAudio import MMMAudio
from random import random

mmm_audio = MMMAudio(128, graph_name="Torch_MLP", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio()  # stop/pause the mojo thread

# if you make a new training below, you can load it into the synth
mmm_audio.send_text_msg("load_mlp_training", "examples/nn_trainings/model_traced.pt")  


# toggle inference off so you can set the synth values directly
mmm_audio.send_msg("toggle_inference", 0.0)

out_size = 16

def make_setting():
    setting = []
    for i in range(out_size):
        setting.append(random())
        mmm_audio.send_msg("model_output" + str(i), setting[i])

    return setting

outputs = make_setting()

X_train_list = []
y_train_list = []

for i, element in enumerate(y_train_list):
    print(f"Element {i}: {element}")

# when you like a setting add an input and output pair
# this is assuming you are training on 4 pairs of data points
X_train_list.append([0,0])
y_train_list.append(outputs)

X_train_list.append([0,1])
y_train_list.append(outputs)

X_train_list.append([1,1])
y_train_list.append(outputs)

X_train_list.append([1,0])
y_train_list.append(outputs)


# train the neural network - run everything below at once
def train_nn():
    import torch
    import time
    import torch.nn as nn
    import torch.optim as optim

    from mmm_dsp.MLP import MLP 

    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Using device:", device)

    learn_rate = 0.001
    epochs = 5000

    data_list = [ [ 64, "relu" ], [ 64, "relu" ], [ out_size, "sigmoid" ] ]

    print(data_list)

    for i, vals in enumerate(data_list):
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
        data_list[i] = [val, activation]


    print(data_list)

    # Convert lists to torch tensors and move to the appropriate device
    X_train = torch.tensor(X_train_list, dtype=torch.float32).to(device)
    y_train = torch.tensor(y_train_list, dtype=torch.float32).to(device)

    input_size = X_train.shape[1]
    model = MLP(input_size, data_list).to(device)
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
    traced_model.save('examples/nn_trainings/model_traced.pt')

train_nn()