from .RisingBoolDetector_Module import RisingBoolDetector

trait PolyObject(Movable, Copyable):
    fn check_active(mut self) -> Bool:
        ...
    fn make_inactive(mut self):
        ...

    # set_played is helpful in polyphonic synths where multiple voices can be triggered at the same time
    fn set_trigger(mut self, trigger: Bool):
        pass
    
    # set_gate is helpful in polyphonic synths with ASR or ADSR envelopes
    fn set_gate(mut self, gate: Bool):
        pass

struct Poly(Movable, Copyable):
    """Manages voice allocation for polyphonic Synths. Keeps track of which voices are active and tells the parent struct which voice to trigger. Also tells the parent struct when all voices are active and a new voice needs to be added to the voices list.

    Poly can be used with two different patterns of PolyObject, depending on the needs of the synth:

        1) Triggered PolyObjects: In this pattern, the PolyObject has a `set_trigger` function that takes a boolean trigger. Poly calls this function in `find_free_voice_and_trigger` to set the PolyObject to trigger the next time its `next` function is called. Poly also has a `reset` function that sets all voices to not triggered at the after each sample or top of each block.
        2) Gated PolyObjects: In this pattern, the PolyObject has a set_gate function that takes a boolean gate. Poly calls this function in `find_free_voice_and_open` and `close_voice` to open and close the synth's envelope. This works for PolyObjects that need a gate to control the duration of the sound, like an ASR or ADSR envelope.

    Poly can also be configured to only look for triggers at the top of each block or every sample. When triggering samples with messages from Python, the program should only look for triggers at the top of each block. When triggering samples with Impulse or Dust generators or other audio-rate triggers, look for triggers every sample.
    
    When configured to only look for triggers at the top of each block, run the `reset` function with `only_top_of_block=True` (the default) and only call `find_free_voice_and_open` or `find_free_voice_and_trigger` when a trigger is received from Python. To run Poly on each sample, run the `reset` function with `only_top_of_block=False` and call `find_free_voice` or `find_free_voice_and_trigger` on each sample.

    """
    var active_list: List[Bool]
    var active_dict: Dict[Int, Int]
    var max_voices: Int
    var messages: List[String]
    var world: World

    fn __init__(out self, initial_num_voices: Int, max_voices: Int, world: World):
        """
        Args:
            initial_num_voices (Int): the number of voices to start with. This can be changed later by the Poly object itself if more voices need to be added.
            max_voices (Int): the maximum number of voices that can be allocated.
            world (World): A pointer to the MMMWorld instance.
        """
        self.active_list = [False for _ in range(initial_num_voices)]
        self.active_dict = Dict[Int, Int]()
        self.max_voices = max_voices
        self.messages = List[String]()
        self.world = world

    fn reset[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T]):
        """Checks which voices are active and sets all voices to not triggered.

        Params:
            only_top_of_block: If True, Poly will only check which voices are active at the top of each block and reset the triggers after the first sample of the block. If False, it will check every sample. 

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. This function calls the set_triggered function for each PolyObject to set it to False at the beginning of each block.
        """
        @parameter
        if only_top_of_block:
            if self.world[].top_of_block:
                for i in range(len(poly_objects)):
                    self.active_list[i] = poly_objects[i].check_active()
            else: 
                if self.world[].block_state == 1:
                    for i in range(len(poly_objects)):
                        poly_objects[i].set_trigger(False)
        else: 
            for i in range(len(poly_objects)):
                self.active_list[i] = poly_objects[i].check_active()
                poly_objects[i].set_trigger(False)

    fn find_free_voice[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int:
        """
        Finds the next available inactive voice. If all voices are active and a new voice needs to be added, it adds a new voice to the poly_objects list. This function will not trigger the voice. Instead, it should be combined with open_voice and close_voice to open and close the voice's gate.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. Poly manages this list and grows it as needed if the number of voices allocated is exceeded.
            trig: The trigger for the next voice. This should be a boolean that goes from False to True when a new note or sound is triggered.
        Returns:
            Int: the index of the voice that will be used. This is the index of the voice in the poly_objects list. Returns -1 if no voice should be triggered.
        """

        trigger_grain = -1
        if trig:
            list_len = len(self.active_list)
            trigger_grain, add_voice_bool = self._find_voice(list_len)
            # print(trigger_grain, end=" ")
            if add_voice_bool:
                if list_len < self.max_voices:
                    # print("\n new voice added:", trigger_grain, end="\n")
                    self.active_list.append(True)
                    poly_objects.append(poly_objects[0].copy())
                else:
                    trigger_grain = -1
                    print("Max polyphony reached, cannot add more voices.")

        return trigger_grain

    @doc_private
    fn _find_voice(mut self, list_len: Int) -> Tuple[Int, Bool]:
        found = False
        counter = 0
        while not found and counter < list_len:
            if not self.active_list[counter]:
                found = True
            else:
                counter += 1
        if found:
            self.active_list[counter] = True
            return (counter, False)  
        else:
            counter = list_len  # this is the index of the next voice to be added 
            return (counter, True) 

    fn open_voice[T: PolyObject](mut self, mut poly_objects: List[T], key: Int, active_list_index: Int):
        """Calls set_gate(True) on the PolyObject at the given index and remembers the voice by the given key.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. 
            key: The key to remember the voice by. This could be a MIDI note number, for example.
            active_list_index: The index of the voice in the active_list that is playing the PolyObject corresponding to the key.
        """
        poly_objects[active_list_index].set_gate(True)
        self.active_dict[key] = active_list_index

    fn close_voice[T: PolyObject](mut self, mut poly_objects: List[T], key: Int):
        """Calls set_gate(False) on the PolyObject that is being played for the given key and forgets that voice.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait.
            key: The key in the active_dict that corresponds to the voice that needs to be released.
        """

        active_list_index = self.active_dict.pop(key, -1)
        if active_list_index != -1:
            poly_objects[active_list_index].set_gate(False)

    fn find_free_voice_and_open[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool, key: Int) -> Int:
        trigger_grain = self.find_free_voice(poly_objects, trig)
        if trigger_grain != -1:
            self.open_voice(poly_objects, key, trigger_grain)
        return trigger_grain

    fn find_free_voice_and_trigger[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int:
        """Finds the next available inactive voice and triggers it. If all voices are active and a new voice needs to be added, it adds a new voice to the poly_objects list. This will also set the chosen PolyObject to triggered by calling the set_triggered function for that PolyObject. When the `next` function is called on the PolyObject, it will be triggered for one sample, so it will open its envelope and become active.
        """
        trigger_grain = self.find_free_voice(poly_objects, trig)

        if trigger_grain != -1:
            poly_objects[trigger_grain].set_trigger(True)
            # print("triggering voice:", trigger_grain, end="\n")

        return trigger_grain