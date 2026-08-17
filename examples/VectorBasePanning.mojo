from mmm_audio import *

# THE SYNTH


struct VectorBasePanning(Movable, Copyable):
    var world: World  
    var dust: Dust[1] 
    var messenger: Messenger
    var az: Float64
    var filt: Reson[1]
    var wsl: Int
    var pos: List[Float64]
    var mouse: Bool
    var vbap_4: VBAP2D
    var vbap_7: VBAP2D
    def __init__(out self, world: World):
        self.world = world
        self.dust = Dust[1](world)
        self.filt = Reson[1](world)
        self.messenger = Messenger(self.world)
        self.az = 0.0
        self.wsl = 0
        self.pos = [0.0, -1.0]
        self.mouse = False
        self.vbap_4 = VBAP2D([
            deg_to_rad(-55),
            deg_to_rad(55),
            deg_to_rad(-110),
            deg_to_rad(110)
            ])

        #A Left-Front, Left-Right, Center, Left, Right, Rear-Left, Rear-Right array where Center is channel 3
        self.vbap_7 = VBAP2D([
            deg_to_rad(-30),
            deg_to_rad(30),
            0,
            deg_to_rad(-90),
            deg_to_rad(90),
            deg_to_rad(-150),
            deg_to_rad(150)
        ])

    def next(mut self) -> MFloat[8]:
        
        comptime max_simd = 8
        comptime two_pi = 2 * pi

        self.messenger.update("az", self.az)
        self.messenger.update("pos", self.pos)
        self.messenger.update("mouse", self.mouse)
       
        
     
        comptime offset = deg_to_rad(90)
        if self.mouse:
            var x = linlin(self.world[].mouse_x(), 0.0, 1.0, -1.0, 1.0)
            var y = linlin(self.world[].mouse_y(), 0.0, 1.0, 1.0, -1.0)
            self.az = atan2(y, x) + offset
        
        var sig = self.dust.next(10, 40) * 0.5
        sig = self.filt.bpf(sig, 1200, 10.0, 1.0)

        # 4 speaker setup
        # var pan = self.vbap_4.next[4](sig, self.az)
        # var out = MFloat[max_simd](pan[0], pan[1], pan[2], pan[3], 0.0, 0.0, 0.0, 0.0)
        

        # 7 speaker setup, note that the simd_out_size must be a power of two and larger than the speaker array size.
        var out = self.vbap_7.next[8](sig, self.az)

        return out * 0.5



def deg_to_rad(degrees: Float64) -> Float64:
    """
    Converts from degrees to radians.
    """
    return degrees * (pi/180)



def rad_to_deg(radians: Float64) -> Float64:
    """
    Converts from radians to degrees.
    """
    return radians * (180/pi)