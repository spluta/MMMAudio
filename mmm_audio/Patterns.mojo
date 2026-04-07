

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

    fn __init__(out self, in_list: List[Self.T]):
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
        self.vals = in_list.copy()
        self.index = -1

    fn next(mut self) -> Self.T:
        """
        Get the next value in the sequence.
        
        Returns:
            The next value in the list, cycling back to the beginning when reaching the end. Returns None if the list is empty.
        """
        self.index = (self.index + 1) % len(self.vals)
        if self.index >= len(self.vals):
            self.index = 0
        return self.vals[self.index]

    fn go_back(mut self, n: Int = 1):
        """
        Move the sequence index back by n steps.
        
        Args:
            n: Number of steps to move back in the sequence
        """
        self.index = (self.index - n) % len(self.vals)

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

    
# class Prand:
#     """
#     Random pattern that selects values randomly from a list.
    
#     Prand generates values by randomly selecting from a list with
#     equal probability for each element. The same value can be
#     selected consecutively.
    
#     Attributes:
#         list: The list of values to select from randomly
        
#     Example:
#         ```python
#         pattern = Prand([1, 2, 3, 4])
#         print(pattern.next())  # Random selection: 1, 2, 3, or 4
#         print(pattern.next())  # Another random selection
#         ```
#     """
#     def __init__(self, list: list[float]):
#         """
#         Random pattern that selects values randomly from a list.
        
#         Prand generates values by randomly selecting from a list with
#         equal probability for each element. The same value can be
#         selected consecutively.
        
#         Attributes:
#             list: The list of values to select from randomly
            
#         Example:
#             ```python
#             pattern = Prand([1, 2, 3, 4])
#             print(pattern.next())  # Random selection: 1, 2, 3, or 4
#             print(pattern.next())  # Another random selection
#             ```
#         """
#         self.list = list

#     def next(self) -> Optional[float]:
#         """
#         Get a random value from the list.
        
#         Returns:
#             A randomly selected value from the list. Returns None if the list is empty.
#         """
#         if not self.list:
#             return None
#         return choice(self.list)

# class Pxrand:
#     """
#     Exclusive random pattern that avoids immediate repetition.
    
#     Pxrand generates values by randomly selecting from a list while
#     ensuring that the same value is never selected twice in a row.
#     This is useful for creating varied sequences without consecutive
#     duplicates.
    
#     Attributes:
#         list: The list of values to select from
#         last_index: Index of the previously selected value
        
#     Note:
#         This pattern requires a list with at least 2 elements to
#         function properly and avoid repetition.
        
#     Example:
#         ```python
#         pattern = Pxrand([1, 2, 3, 4])
#         print(pattern.next())  # Random selection: 1, 2, 3, or 4
#         print(pattern.next())  # Different from previous selection
#         ```
#     """
#     def __init__(self, list: list[float]):
#         """
#         Exclusive random pattern that avoids immediate repetition.
        
#         Pxrand generates values by randomly selecting from a list while
#         ensuring that the same value is never selected twice in a row.
#         This is useful for creating varied sequences without consecutive
#         duplicates.
        
#         Attributes:
#             list: The list of values to select from
#             last_index: Index of the previously selected value
            
#         Note:
#             This pattern requires a list with at least 2 elements to
#             function properly and avoid repetition.
            
#         Example:
#             ```python
#             pattern = Pxrand([1, 2, 3, 4])
#             print(pattern.next())  # Random selection: 1, 2, 3, or 4
#             print(pattern.next())  # Different from previous selection
#             ```
#         """
#         self.list = list
#         self.last_index = -1

#     def next(self) -> Optional[float]:
#         """
#         Get a random value that differs from the previous selection.
        
#         Returns:
#             A randomly selected value from the list that is guaranteed to be different from the previous selection. Returns None if the list is empty.
#         """
#         if not self.list:
#             return None
#         self.last_index = (self.last_index + randint(1, len(self.list) - 1)) % len(self.list)
#         return self.list[self.last_index]