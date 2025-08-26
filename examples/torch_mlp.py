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
mmm_audio.send_msg("toggle_inference", 1.0)

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

for i in range(len(y_train_list)):
    print(f"Element {i}: {X_train_list[i]}")
    print(f"Element {i}: {y_train_list[i]}")

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

learn_rate = 0.001
epochs = 5000

layers = [ [ 64, "relu" ], [ 64, "relu" ], [ out_size, "sigmoid" ] ]

from mmm_utils.mlp_trainer import train_nn

train_nn(X_train_list, y_train_list, layers, learn_rate, epochs, "examples/nn_trainings/model_traced.pt")


