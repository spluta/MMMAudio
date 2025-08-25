from random import *

class Pseq:
    def __init__(self, list):
        self.list = list
        self.index = -1

    def next(self):
        if not self.list:
            return None
        self.index = (self.index + 1) % len(self.list)
        if self.index > len(self.list):
            self.index = 0
        return self.list[self.index]
    
class Prand:
    def __init__(self, list):
        self.list = list

    def next(self):
        if not self.list:
            return None
        return choice(self.list)

class Pxrand:
    def __init__(self, list):
        self.list = list
        self.last_index = -1

    def next(self):
        if not self.list:
            return None
        self.last_index = (self.last_index + randint(1, len(self.list) - 1)) % len(self.list)
        return self.list[self.last_index]

