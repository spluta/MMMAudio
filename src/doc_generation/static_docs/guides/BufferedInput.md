BufferedInput struct handles buffering of input samples and handing them as "windows" 
to a user defined struct for processing (The user defined struct must implement the 
BufferedProcessable trait). The user defined struct's `next_window()` function is called every
`hop_size` samples. BufferedInput passes the user defined struct a List of `window_size` samples. 
The user can process can do whatever they want with the samples in the List and then must replace the 
values in the List with the values.