

struct Pseq[T: Movable & Copyable & ImplicitlyCopyable](Movable, Copyable):
    """
    Sequential pattern that cycles through a list of values.
    
    Pseq generates values by iterating through a list sequentially,
    wrapping back to the beginning when it reaches the end.
    
    Attributes:
        list: The list of values to cycle through
        index: Current position in the list (starts at -1)
        
    Example:
        ```python
        pattern = Pseq([1, 2, 3])
        print(pattern.next())  # 1
        print(pattern.next())  # 2
        print(pattern.next())  # 3
        print(pattern.next())  # 1 (cycles back)
        ```
    """
    var vals: List[Self.T]
    var index: Int
    var len: Int

    fn __init__(out self, in_list: List[Self.T]):
        self.vals = in_list.copy()
        self.index = -1
        self.len = len(self.vals)

    fn next(mut self) -> Self.T:
        """
        Get the next value in the sequence.
        
        Returns:
            The next value in the list, cycling back to the beginning when reaching the end. Returns None if the list is empty.
        """
        self.index = (self.index + 1) % self.len
        if self.index >= self.len:
            self.index = 0
        return self.vals[self.index]

    fn go_back(mut self, n: Int = 1):
        """
        Move the sequence index back by n steps.
        
        Args:
            n: Number of steps to move back in the sequence
        """
        self.index = (self.index - n) % self.len

    fn val(mut self) -> Self.T:
        """
        Get the current value in the sequence without advancing.
        
        Returns:
            The current value in the list. Returns None if the list is empty.
        """
        if self.index == -1:
            return self.vals[0]
        else:
            return self.vals[self.index]


struct Prand[T: Movable & Copyable & ImplicitlyCopyable](Movable, Copyable):
    """
    Random pattern generator that picks from a list of values.
    
    Attributes:
        list: The list of values to cycle through
        index: Current position in the list (starts at -1)
    """
    var vals: List[Self.T]
    var index: Int
    var len: Int

    fn __init__(out self, in_list: List[Self.T]):
        self.vals = in_list.copy()
        self.index = -1
        self.len = len(self.vals)

    fn next(mut self) -> Self.T:
        """
        Get the next value in the sequence.
        
        Returns:
            A random value from the list. Can repeat indices.
        """
        self.index = rrand(0, self.len-1)
        return self.vals[self.index]

    fn val(mut self) -> Self.T:
        """
        Get the current value in the sequence without advancing.
        
        Returns:
            The current value in the list. Returns None if the list is empty.
        """
        if self.index == -1:
            return self.vals[0]
        else:
            return self.vals[self.index]

struct Pxrand[T: Movable & Copyable & ImplicitlyCopyable](Movable, Copyable):
    """
    Random pattern generator that picks from a list of values. Will not repeat the same value twice in a row.
    """
    var vals: List[Self.T]
    var index: Int
    var len: Int

    fn __init__(out self, in_list: List[Self.T]):
        self.vals = in_list.copy()
        self.index = -1
        self.len = len(self.vals)

    fn next(mut self) -> Self.T:
        """
        Get the next value in the sequence.
        
        Returns:
            A random value from the list. Can repeat indices.
        """
        self.index = (self.index+rrand(1, self.len-1)) % self.len
        return self.vals[self.index]

    fn val(mut self) -> Self.T:
        """
        Get the current value in the sequence without advancing.
        
        Returns:
            The current value in the list. Returns None if the list is empty.
        """
        if self.index == -1:
            return self.vals[0]
        else:
            return self.vals[self.index]