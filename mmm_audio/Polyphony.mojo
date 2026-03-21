from mmm_audio import *

trait PolyObject(Movable, Copyable):
    fn check_active(mut self) -> Bool:
        """A required, user defind function to check if the voice is active. This is usually done by checking if the envelope is active or if a Play object is still playing. This function is used internally by Poly to keep track of which voices are active and which are not.
        """
        ...

    # set_trigger
    fn set_trigger(mut self, trigger: Bool):
        """Necessary for triggered PolyObjects. This function is used internally by Poly to set the PolyObject to triggered. That way, the PolyObject can open its own envelope or trigger other parameters in the subsequent `next` call."""
        # self.trigger = trigger # usually it is just this
        pass
    
    # set_gate is helpful in polyphonic synths with ASR or ADSR envelopes
    fn set_gate(mut self, gate: Bool):
        """Necessary for gated PolyObjects. This function is used internally by Poly to open and close the gate of the PolyObject."""
        # self.gate = gate # usually it is just this
        pass

struct PolyM(Movable, Copyable):
    """A Poly implementation that has an internal Messenger for handling messages from Python. It is designed to be used with the `next_gate` and `next_trigger` functions, each of which conform to a specific pattern of messages from Python. The `next_gate` function is designed to be used with messages that have a note and velocity, where the note is used to trigger the voice and the velocity is used to control the volume or turn the gate off. The `next_trigger` function is designed to be used with messages that simply trigger a voice.
    """
    var poly: Poly
    var m: Messenger
    var num_messages: Int
    var world: World

    fn __init__(out self, initial_num_voices: Int, max_voices: Int, world: World, name_space: String, num_messages: Int = 10):
        self.poly = Poly(initial_num_voices=initial_num_voices, max_voices=max_voices, num_messages=num_messages)
        self.m = Messenger(world, name_space)
        self.num_messages = num_messages
        self.world = world

    @doc_private
    fn _reset[T: PolyObject](mut self, mut poly_objects: List[T]):
        """Must be called before any subsequent calls to find_free_voice or find_voice_and_open_gate. This function resets the triggered state of all voices at the beginning of each block or every sample, depending on the only_top_of_block parameter.

        Params:
            only_top_of_block: If True, Poly will only check which voices are active at the top of each block and reset the triggers after the first sample of the block. If False, it will check every sample. 

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. This function calls the set_triggered function for each PolyObject to set it to False at the beginning of each block.
        """

        if self.world[].top_of_block:
            for i in range(len(poly_objects)):
                self.poly.active_list[i] = poly_objects[i].check_active()
        else: 
            if self.world[].block_state == 1:
                for i in range(len(poly_objects)):
                    poly_objects[i].set_trigger(False)


    fn next_gate[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut vals: List[Int])):
        """This convenience function acheives all functionality of a Gated PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and opens and closes gates for PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_gate` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64, where the first value is the note or key to trigger and the second value is the velocity or value of the note. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        vals = List[Int]()
        for i in range(self.num_messages):
            trig = self.m.notify_update(vals, String(i))
            if trig:
                if vals[1] > 0: # if the velocity is greater than 0, trigger the note on
                    free_voice = self.poly.find_voice_and_open_gate(poly_objects, trig, String(vals[0])) # get the index of the free voice
                    call_back(poly_objects[free_voice], vals)
                else: # if the velocity is 0, trigger the note off for that note
                    # close the gate for the voice that is playing and forget that is was playing
                    freed_voice = self.poly.close_gate(poly_objects, String(vals[0]))
                    if freed_voice != -1:
                        call_back(poly_objects[freed_voice], vals)

    fn next_gate[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut vals: List[Float64])):
        """This convenience function acheives all functionality of a Gated PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and opens and closes gates for PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_gate` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64, where the first value is the note or key to trigger and the second value is the velocity or value of the note. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        vals = List[Float64]()
        for i in range(self.num_messages):
            trig = self.m.notify_update(vals, String(i))
            if trig:
                if vals[1] > 0: # if the velocity is greater than 0, trigger the note on
                    free_voice = self.poly.find_voice_and_open_gate(poly_objects, trig, String(vals[0])) # get the index of the free voice
                    call_back(poly_objects[free_voice], vals)
                else: # if the velocity is 0, trigger the note off for that note
                    # close the gate for the voice that is playing and forget that is was playing
                    freed_voice = self.poly.close_gate(poly_objects, String(vals[0]))
                    if freed_voice != -1:
                        call_back(poly_objects[freed_voice], vals)

    fn next_trigger[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut vals: List[Int])):
        """This convenience function acheives all functionality of a Triggered PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and triggers PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_trigger` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        vals = List[Int]()
        for i in range(self.num_messages):
            trig = self.m.notify_update(vals, String(i))
            # if we received a trig, find and play a free voice
            if trig:
                free_voice = self.poly.find_voice_and_trigger(poly_objects, trig) # get the index of the free voice and trigger the PolyObject
                if free_voice != -1:
                    call_back(poly_objects[free_voice], vals)
    
    fn next_trigger[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut vals: List[Float64])):
        """This convenience function acheives all functionality of a Triggered PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and triggers PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_trigger` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        vals = List[Float64]()
        for i in range(self.num_messages):
            trig = self.m.notify_update(vals, String(i))
            # if we received a trig, find and play a free voice
            if trig:
                free_voice = self.poly.find_voice_and_trigger(poly_objects, trig) # get the index of the free voice and trigger the PolyObject
                if free_voice != -1:
                    call_back(poly_objects[free_voice], vals)

    fn next_trigger[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut val: Int)):
        """This convenience function acheives all functionality of a Triggered PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and triggers PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_trigger` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        val: Int = 0
        for i in range(self.num_messages):
            trig = self.m.notify_update(val, String(i))
            # if we received a trig, find and play a free voice
            if trig:
                free_voice = self.poly.find_voice_and_trigger(poly_objects, trig) # get the index of the free voice and trigger the PolyObject
                if free_voice != -1:
                    call_back(poly_objects[free_voice], val)
    
    fn next_trigger[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn (mut poly_object: T, mut val: Float64)):
        """This convenience function acheives all functionality of a Triggered PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and triggers PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next_trigger` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.
        """
        self._reset(poly_objects)
        val: Float64 = 0.0
        for i in range(self.num_messages):
            trig = self.m.notify_update(val, String(i))
            # if we received a trig, find and play a free voice
            if trig:
                free_voice = self.poly.find_voice_and_trigger(poly_objects, trig) # get the index of the free voice and trigger the PolyObject
                if free_voice != -1:
                    call_back(poly_objects[free_voice], val)


# I think there could be a PolyGate struct that is designed specifically for the next_gate pattern on signals. I think this will be a separate struct because, like the PolyM struct, it has a lot of internal functionality that is specific to itself.

struct Poly(Movable, Copyable):
    """Manages voice allocation for polyphonic Synths. Keeps track of which voices in a list of PolyObjects are inactive/active and triggers or controls the gate for PolyObjects as they are allocated. Also adds new voices to the List[PolyObject], when the list is full.

    Poly can be used with two different patterns of PolyObject, depending on the needs of the synth:

        1) Triggered PolyObjects: In this pattern, the PolyObject has a `set_trigger` function that takes a boolean trigger. Poly calls this function in `next_trigger`. This sets the PolyObject to trigger the subsequent time its `next` function is called. 
        2) Gated PolyObjects: In this pattern, the PolyObject has a `set_gate` function that takes a boolean gate. Poly calls this function in `find_voice_and_open_gate` and `close_gate` to open and close the synth's envelope. This works for PolyObjects that have gated control, like an ASR or ADSR envelope.

    Synths receiving messages from Python will likely want to use the PolyM struct, which has an internal Messenger and functions that are designed to receive multiple messages per block from Python.

    """
    var active_list: List[Bool]
    var active_dict: Dict[String, Int]
    var max_voices: Int
    var messages: List[String]
    var num_messages: Int

    fn __init__(out self, initial_num_voices: Int, max_voices: Int, num_messages: Int = 10):
        """
        Args:
            initial_num_voices (Int): the number of voices to start with. This can be changed later by the Poly object itself if more voices need to be added.
            max_voices (Int): the maximum number of voices that can be allocated. Poly will not allocate more than this number of voices.
            world (World): A pointer to the MMMWorld instance.
        """
        self.active_list = [False for _ in range(initial_num_voices)]
        self.active_dict = Dict[String, Int]()
        self.max_voices = max_voices
        self.messages = List[String]()
        self.num_messages = num_messages

    fn next_trigger[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int:
        """This convenience function acheives all functionality of a triggered PolyObject synth in one function. Upon receiving a trigger, it will find a free voice and call the `set_trigger(True)` method on that voice's PolyObject. The next time that PolyObject's `next` function is called, it will be triggered. On the next sample, the `set_trigger` method will be called with False to reset the trigger. An optional call_back function can be provided for further control of the PolyObject.

        If you need to request multiple voices in one audio loop, call `next_trigger` for the first request and then call `find_voice_and_trigger` for subsequent requests in the same loop.
        """
        self._reset(poly_objects)
        return self.find_voice_and_trigger(poly_objects, trig)

    fn next_trigger[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool, call_back: fn (mut poly_object: T, trig: Bool)) -> Int:
        """This convenience function acheives all functionality of a triggered PolyObject synth in one function. Upon receiving a trigger, it will find a free voice and call the `set_trigger(True)` method on that voice's PolyObject. The next time that PolyObject's `next` function is called, it will be triggered. On the next sample, the `set_trigger` method will be called with False to reset the trigger. An optional call_back function can be provided for further control of the PolyObject.

        If you need to request multiple voices in one audio loop, call `next_trigger` for the first request and then call `find_voice_and_trigger` for subsequent requests in the same loop.
        """
        self._reset(poly_objects)
        voice_index = self.find_voice_and_trigger(poly_objects, trig)
        if voice_index != -1:
            call_back(poly_objects[voice_index], trig)
        return voice_index

    @doc_private
    fn _reset[T: PolyObject](mut self, mut poly_objects: List[T]):
        """Must be called before any subsequent calls to find_voice_and_trigger or find_voice_and_open_gate. This function resets the triggered state of all voices at the beginning of each block or every sample, depending on the only_top_of_block parameter.

        Params:
            only_top_of_block: If True, Poly will only check which voices are active at the top of each block and reset the triggers after the first sample of the block. If False, it will check every sample. 

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. This function calls the set_triggered function for each PolyObject to set it to False at the beginning of each block.
        """
        for i in range(len(poly_objects)):
            self.active_list[i] = poly_objects[i].check_active()
            poly_objects[i].set_trigger(False)

    @doc_private
    fn _find_free_voice[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int:
        """
        Finds the next available inactive voice. If all voices are active and a new voice needs to be added, it adds a new voice to the poly_objects list. This function will not trigger the voice. Instead, it should be combined with open_voice and close_gate to open and close the voice's gate.

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

    @doc_private
    fn _open_voice[T: PolyObject](mut self, mut poly_objects: List[T], key: String, active_list_index: Int):
        """Calls set_gate(True) on the PolyObject at the given index and remembers the voice by the given key.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait.
            key: The key to remember the voice by. This could be a MIDI note number, for example.
            active_list_index: The index of the voice in the active_list that is playing the PolyObject corresponding to the key.
        """
        poly_objects[active_list_index].set_gate(True)
        self.active_dict[key] = active_list_index

    fn find_voice_and_trigger[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int:
        """Finds the next available inactive voice and triggers it. If all voices are active and a new voice needs to be added, it adds a new voice to the poly_objects list. This will also call the `set_trigger(True)` method on the PolyObject, so the PolyObject is triggered the next time its `next` function is called.
        """
        trigger_grain = self._find_free_voice(poly_objects, trig)

        if trigger_grain != -1:
            poly_objects[trigger_grain].set_trigger(True)
            # print("triggering voice:", trigger_grain, end="\n")

        return trigger_grain

    fn find_voice_and_open_gate[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool, key: String) -> Int:
        """Finds the next available inactive voice and opens its gate. If all voices are active and a new voice needs to be added, it adds a new voice to the poly_objects list. Also, stores a key/value pair with the provided key and the index of the voice found voice as the value. This allows the close_gate function to close the correct voice when it is given the same key.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait. Poly manages this list and grows it as needed if the number of voices allocated is exceeded.
            trig: The trigger for the next voice. This should be a boolean that goes from False to True when a new note or sound is triggered.
            key: The key to remember the voice by. This could be a MIDI note number, for example.
        Returns:
            Int: the index of the voice that will be used. This is the index of the voice in the poly_objects list. Returns -1 if no voice should be triggered.
        """
        trigger_grain = self._find_free_voice(poly_objects, trig)
        if trigger_grain != -1:
            self._open_voice(poly_objects, key, trigger_grain)
        return trigger_grain

    fn close_gate[T: PolyObject](mut self, mut poly_objects: List[T], key: String) -> Int:
        """Calls set_gate(False) on the PolyObject that is being played for the given key and forgets that voice.

        Args:
            poly_objects: A list of structs conforming to the PolyObject trait.
            key: The key in the active_dict that corresponds to the voice that needs to be released.
        """

        active_list_index = self.active_dict.pop(key, -1)
        if active_list_index != -1:
            poly_objects[active_list_index].set_gate(False)
        return active_list_index